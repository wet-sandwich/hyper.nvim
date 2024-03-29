local curl = require("plenary.curl")
local uv = vim.loop
local State = require("hyper.state")

local M = {}

function M.get_dimension(d, min, max, ratio)
  local dim = math.min(math.floor(d * ratio), max)

  if d < min then
    dim = d - 2
  end

  local pos = math.floor((d - dim) / 2)

  return { dim = dim, pos = pos }
end

function M.is_body_method(method)
  local body_methods = {
    PUT = true,
    POST = true,
    PATCH = true,
  }

  return body_methods[method] and true or false
end

local function pretty_print(object, lines, depth)
  depth = depth or 0
  if depth == 0 then
    table.insert(lines, "{")
  end

  local function indent(d)
    return string.rep("  ", d)
  end

  for k, v in pairs(object) do
    if type(v) == "table" then
      table.insert(lines, indent(depth+1) .. k .. ": {")
      pretty_print(v, lines, depth+1)
      table.insert(lines, indent(depth+1) .. "},")
    elseif type(v) == "string" then
      table.insert(lines, indent(depth+1) .. k .. ": " .. '"' .. v .. '",')
    else
      table.insert(lines, indent(depth+1) .. k .. ": " .. tostring(v) .. ",")
    end
  end

  if depth == 0 then
    table.insert(lines, "}")
  end
end

local function read_file(path)
  if path == nil then
    return {}
  end
  return vim.fn.readfile(path)
end

function M.pretty_format(object)
  local lines = {}
  pretty_print(object, lines)
  return lines
end

function M.parse_response_body(body_str)
  local i = string.find(body_str, "} ")
  local body = vim.json.decode(string.sub(body_str, 1, i))

  local write_out = string.sub(body_str, i+2, -1)
  local extras = {}
  for k, v in string.gmatch(write_out, "(.+)=(.+)") do
    extras[k] = tonumber(v) or v
  end
  return body, extras
end

function M.dict_length(t)
  local c = 0
  for _, _ in pairs(t) do
    c = c + 1
  end
  return c
end

function M.lines_to_kv(lines, sep)
  local tbl = {}
  local pattern = "%s*(#?%s*%a[%w%-_]*)%s*" .. sep .. "%s*(.*)"
  for _, line in ipairs(lines) do
    for k, v in line:gmatch(pattern) do
      tbl[k] = tonumber(v) or v
    end
  end
  return tbl
end

local function replace_tokens(str, tbl)
  -- it's possible to receive non-string values, simply return the value
  if type(str) ~= "string" then
    return str
  end

  local newstr = str
  for token, value in pairs(tbl) do
    newstr = newstr:gsub(token, value)
  end
  if newstr:find("{{.+}}") ~= nil then
    error("Unreplaced token in string: " .. newstr)
  end
  return newstr
end

local function substitute_envars(tt, variables)
  local token_map = {}
  for k, v in pairs(M.lines_to_kv(variables, "=")) do
    if k:sub(1,1) ~= "#" then
      token_map["{{" .. k .. "}}"] = v
    end
  end

  local new_tt = {}
  for opt, value in pairs(tt) do
    new_tt[opt] = {}
    if type(value) == "string" then
      new_tt[opt] = replace_tokens(value, token_map)
    elseif value[1] == nil then
      for k, v in pairs(value) do
        new_tt[opt][k] = replace_tokens(v, token_map)
      end
    else
      for _, str in ipairs(value) do
        table.insert(new_tt[opt], replace_tokens(str, token_map))
      end
    end
  end

  return new_tt
end

local function find_env_files()
  local paths = vim.fs.find(function(name, _)
    return name:match('^%.env.*') or name:match('.*%.env')
  end, {
      limit = 4,
      type = 'file',
    })

  return paths
end

local function filter_params(params)
  local filtered = params
  for k, _ in pairs(params) do
    if k:sub(1,1) == "#" then
      filtered[k] = nil
    end
  end
  return filtered
end

function M.http_request(opts)
  local raw = {"-w response_time=%{time_total}"}

  local env_lines = read_file(opts.env.selected)

  local filled_opts = substitute_envars({
    query_params = filter_params(opts.query_params),
    headers = opts.headers,
    body = M.is_body_method(opts.method) and opts.body or {},
    url = opts.url,
  }, env_lines)

  local body = {}
  for _, v in ipairs(filled_opts.body) do
    table.insert(body, M.ltrim(v))
  end

  local res = curl.request {
    url = filled_opts.url,
    method = opts.method,
    query = filled_opts.query_params,
    body = table.concat(body, ""),
    headers = filled_opts.headers,
    raw = raw,
  }

  return res
end

function M.ltrim(str)
  return str:match'^%s*(.*)'
end

function M.init_env_files(state)
  local env_files = find_env_files()
  local env = state.get_state("env")

  if next(env_files) == nil then
    return
  end

  env.available = env_files

  if #env_files == 1 then
    env.selected = env_files[1]
    state.set_state("env", env)
    return
  end

  for _, file in ipairs(env_files) do
    if vim.fs.basename(file) == ".env" then
      env.selected = file
      state.set_state("env", env)
      return
    end
  end
end

function M.validate_env_files()
  local env = State.get_state("env")
  local env_files = find_env_files()

  if #env.available == #env_files then
    return
  end
  env.available = env_files

  for _, v in ipairs(env.available) do
    if v == env.selected then
      State.set_state("env", env)
      return
    end
  end

  env.selected = env.available[1]
  State.set_state("env", env)
end

function M.find_collections()
  local cwd = vim.fn.getcwd()

  local paths = vim.fs.find(function(name, path)
    return name:match('.*%.json$') and path:match(cwd .. '.*[/\\]collections$')
  end, {
      limit = math.huge,
      type = 'file',
    })

  local collections = {}
  for _, path in ipairs(paths) do
    local stat = uv.fs_stat(path)
    local mtime = stat and stat.mtime.sec or os.time()

    collections[path] = {
      last_modified = mtime,
      data = {},
    }
  end

  return collections
end

function M.load_collections(existing, found)
  for k, v in pairs(found) do
    if (existing[k] == nil or existing[k]["last_modified"] ~= v["last_modified"]) then
      local cfile = vim.fn.readfile(k)
      local cstring = table.concat(cfile, "")
      local ctable = vim.json.decode(cstring)
      existing[k] = {
        last_modified = v["last_modified"],
        data = ctable,
      }
    end
  end

  return existing
end

return M
