local Float = require("hyper.view.float")

local File = {}
File.__index = File

function File.new(opts)
  opts.editable = true
  local float = Float.new(opts)
  setmetatable(float, { __index = setmetatable(File, { __index = Float }) })
  return float
end

function File:set_file(path)
  self.path = path
end

function File:create_window()
  self:add_autocmd("BufLeave", {
    callback = function()
      self:save()
    end,
  })
  Float.create_window(self)
end

function File:render()
  if self.path == nil then return end
  self.content = vim.fn.readfile(self.path)
  Float.render(self)
end

function File:save()
  if self.path == nil then return end
  local content = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
  vim.fn.writefile(content, self.path)
end

return File
