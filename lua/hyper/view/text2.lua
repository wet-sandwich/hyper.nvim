local Text = {}

function Text.new()
  local self = setmetatable({}, { __index = Text })
  self._lines = {}
  return self
end

function Text:append(str)
  table.insert(self._lines, str)
end

function Text:nl()
  table.insert(self._lines, "")
end

function Text:read()
  return self._lines
end

function Text:len()
  return #self._lines
end

return Text
