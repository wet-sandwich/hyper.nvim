local Float = require("hyper.view.float")
local Render = require("hyper.view.render")
local State = require("hyper.state")
local Commands = require("hyper.view.commands")

local M = {}

M.view = nil

function M.visible()
  return M.view and M.view.win and vim.api.nvim_win_is_valid(M.view.win)
end

function M.show(mode)
  M.view = M.visible() and M.view or M.create()
  if mode then
    M.view.state.set_state("mode", mode)
  end
  M.view:update()
end

function M.create()
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Float }) })

  self.state = State
  self.state.init()

  Float.init(self, {
    title = "Hyper",
    title_pos = "center",
    noautocmd = true,
  })

  self.render = Render.new(self)

  Commands.setup(self)

  return self
end

function M:update()
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    vim.bo[self.buf].modifiable = true
    self.render:update()
    vim.bo[self.buf].modifiable = false
    vim.cmd.redraw()
    Commands.setup(self)
  end
end

return M
