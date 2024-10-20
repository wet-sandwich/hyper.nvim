local Text = require("hyper.view.text")
local hyper = require("hyper")

local M = {}

function M.get_viewbox()
  local width = math.floor(vim.o.columns * hyper.opts.viewbox_width_ratio)
  local height = math.floor(vim.o.lines * hyper.opts.viewbox_height_ratio)
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

function M.line_wrap(str, len)
  if len == nil or #str <= len then
    return str
  end
  local lines = {}
  local a = str
  repeat
    table.insert(lines, string.sub(a, 1, len))
    a = string.sub(a, len + 1, -1)
  until #a == 0
  return table.concat(lines, "\n")
end

function M.create_request_preview(req, width)
  local templates = {
    url = "%-6s %s",
    params = "  %s=%s",
    headers = "  %s: %s",
  }

  local preview = Text.new()

  if req ~= nil then
    local url_str = M.line_wrap(templates.url:format(req.method, req.url), width)
    preview:append(url_str)

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
    return hyper.opts.hl_grp_StatusInfo
  end
  if code < 300 then
    return hyper.opts.hl_grp_StatusOkay
  end
  if code < 400 then
    return hyper.opts.hl_grp_StatusWarning
  end
  return hyper.opts.hl_grp_StatusError
end

return M
