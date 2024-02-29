local Text = {}

function Text.new()
  local self = setmetatable({}, {
    __index = Text,
  })
  self._lines = {}

  return self
end

function Text:append(str)
  if #self._lines == 0 then
    self:nl()
  end

  table.insert(self._lines[#self._lines], {str = str})
end

function Text:nl()
  table.insert(self._lines, {})
  return self
end

function Text:separator(symbol, width)
  self:append(string.rep(symbol, width))
end

function Text:render(buf)
  local lines = {}

  for _, line in ipairs(self._lines) do
    for _, seg in ipairs(line) do
      table.insert(lines, seg.str)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function Text:trim()
  while #self._lines > 0 and #self._lines[#self._lines] == 0 do
    table.remove(self._lines)
  end
end

return Text
