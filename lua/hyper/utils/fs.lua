local uv = vim.loop

local M = {}

function M.read_file(file)
  if uv.fs_stat(file) == nil then
    return nil
  end

  local f = assert(io.open(file, "r"))
  local s = f:read("*all")
  f:close()
  return s
end

function M.write_file(file, data)
  local f = assert(io.open(file, "w+"))
  f:write(data)
  f:close()
end

return M
