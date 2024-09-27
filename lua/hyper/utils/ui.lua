local Config = require("hyper.config")
local Text = require("hyper.view.text")

local M = {}

function M.get_viewbox()
  local width = math.floor(vim.o.columns * Config.viewbox.width)
  local height = math.floor(vim.o.lines * Config.viewbox.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2) - 2
  return width, height, row, col
end

function M.get_dimension(d, min, max, ratio)
  local dim = math.min(math.floor(d * ratio), max)

  if d < min then
    dim = d - 2
  end

  local pos = math.floor((d - dim) / 2)

  return { dim = dim, pos = pos }
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

function M.pretty_format(object)
  local lines = {}
  pretty_print(object, lines)
  return lines
end

function M.ltrim(str)
  return str:match'^%s*(.*)'
end

function M.create_request_preview(req)
  local templates = {
    url = "%-6s %s",
    params = "  %s=%s",
    headers = "  %s: %s",
  }

  local preview = Text.new()

  if req ~= nil then
    preview:append(templates.url:format(req.method, req.url))

    if req.query_params ~= nil and next(req.query_params) ~= nil then
      preview:nl()
      preview:append("Query Params:")
      for key, val in pairs(req.query_params) do
        preview:append(templates.params:format(key, val))
      end
    end

    if next(req.headers) ~= nil then
      preview:nl()
      preview:append("Headers:")
      for key, val in pairs(req.headers) do
        preview:append(templates.headers:format(key, val))
      end
    end

    if req.body ~= nil then
      preview:nl()
      preview:append("Body:")
      for _, line in ipairs(req.body) do
        preview:append(line)
      end
    end
  end

  return preview
end

function M.get_status_hl(code)
  if code < 200 then
    return Config.hl_grp.HttpStatusInfo
  end
  if code < 300 then
    return Config.hl_grp.HttpStatusOk
  end
  if code < 400 then
    return Config.hl_grp.HttpStatusWarning
  end
  return Config.hl_grp.HttpStatusError
end

return M