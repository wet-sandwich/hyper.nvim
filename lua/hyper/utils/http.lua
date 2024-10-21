local curl = require("plenary.curl")
local http = require("hyper.utils.http-parser")
local Fs = require("hyper.utils.fs")
local Ui = require("hyper.utils.ui")
local Table = require("hyper.utils.table")

local M = {}

function M.is_body_method(method)
  local body_methods = {
    PUT = true,
    POST = true,
    PATCH = true,
  }

  return body_methods[method] and true or false
end

function M.parse_response_body(body_str)
  local i = string.find(body_str, "%s+response_time=")
  local body = string.sub(body_str, 1, i)
  local write_out = string.sub(body_str, i+1, -1)

  local extras = {}
  for k, v in string.gmatch(write_out, "(%S+)=(%S+)") do
    extras[k] = tonumber(v) or v
  end

  if vim.fn.executable("jq") == 1 then
    local jobid = vim.fn.jobstart({"jq", "."}, {
      on_stdout = function(_, out, _)
        local str = table.concat(out, "\n")
        if str ~= "" then
          body = str
        end
      end,
    })
    vim.fn.chansend(jobid, body)
    vim.fn.chanclose(jobid, "stdin")

    vim.fn.jobwait({ jobid }, -1)
  end

  return body, extras
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
    vim.notify(string.format("Unreplaced token in string: '%s'", newstr), vim.log.levels.WARN)
  end
  return newstr
end

local function substitute_envars(tt, variables)
  local token_map = {}
  for k, v in pairs(Table.lines_to_kv(variables, "=")) do
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

function M.http_request(opts)
  local raw = {"-w response_time=%{time_total} response_size=%{size_download}"}

  local env_lines = Table.string_to_table(Fs.read_file(opts.env.selected))

  local filled_opts = substitute_envars({
    query_params = filter_params(opts.query_params),
    headers = opts.headers,
    body = M.is_body_method(opts.method) and opts.body or {},
    url = opts.url,
  }, env_lines)

  local body = {}
  for _, v in ipairs(filled_opts.body) do
    table.insert(body, Ui.ltrim(v))
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

local function sort_keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

local function flatten_table(t)
  local sorted_keys = sort_keys(t)
  local str = ""
  for _, k in ipairs(sorted_keys) do
    str = str .. k .. t[k]
  end
  return str
end

function M.hash_http_request(req)
  local t = {
    req.method,
    req.url,
    flatten_table(req.query_params),
    flatten_table(req.headers),
    req.body and table.concat(req.body, "") or "",
  }
  return vim.fn.sha256(table.concat(t, ""))
end

function M.select_request(state, request)
    state.set_state("method", request.method or "")
    state.set_state("url", request.url or "")
    state.set_state("query_params", request.query_params or {})
    state.set_state("headers", request.headers or {})
    state.set_state("body", request.body or {})
end

function M.parse(lines)
  return http.parse(lines)
end

return M
