local M = {}

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

return M
