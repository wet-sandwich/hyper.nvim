local Config = require("hyper.config")

local Text = {}

function Text.new()
  local self = setmetatable({}, { __index = Text })
  self._lines = {}
  return self
end

function Text:append(str, hl)
  table.insert(self._lines, { str = str, hl = hl })
end

function Text:nl()
  table.insert(self._lines, {})
end

function Text:read()
  local lines = {}
  for _, text in ipairs(self._lines) do
    table.insert(lines, text.str or "")
  end
  return lines
end

function Text:render(buf)
  local lines = {}
  for _, text in ipairs(self._lines) do
    table.insert(lines, text.str or "")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, Config.ns, 0, -1)

  for i, text in ipairs(self._lines) do
    if text.hl ~= nil then
      local col = text.hl.col or 0
      text.hl.col = nil
      vim.api.nvim_buf_set_extmark(buf, Config.ns, i - 1, col, text.hl)
    end
  end
end

function Text:len()
  return #self._lines
end

return Text
