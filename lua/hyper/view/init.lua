local RequestScreen = require("hyper.view.screens.request")
local HistoryScreen = require("hyper.view.screens.history")
local VariablesScreen = require("hyper.view.screens.variables")
local State = require("hyper.state")

local M = {}
M.screen = nil

State.init()

function M.visible()
  return M.screen and M.screen.isVisible
end

function M.show()
  M.screen = M.visible() and M.screen or RequestScreen
  M.screen:hide()

  local mode = State.get_state("mode")

  if mode == "main" then
    M.screen = RequestScreen
  end

  if mode == "history" then
    M.screen = HistoryScreen
  end

  if mode == "variables" then
    M.screen = VariablesScreen
  end

  M.screen:display()
  M:setup_cmds(mode)
end

function M:setup_cmds(mode)
  if mode == "main" then
    M.screen:on_key("n", "S", function()
      State.set_state("mode", "history")
      M.show()
    end)

    M.screen:on_key("n", "E", function()
      State.set_state("mode", "variables")
      M.show()
    end)
  else
    self.screen:on_key("n", "<c-o>", function()
      self.screen:hide()
      State.set_state("mode", "main")
      self.show()
    end)
  end
end

return M

-- local Float = require("hyper.view.float")
-- local Render = require("hyper.view.render")
-- local State = require("hyper.state")
-- local Commands = require("hyper.view.commands")
-- local Util = require("hyper.util")
--
-- local M = {}
--
-- M.view = nil
--
-- function M.visible()
--   return M.view and M.view.win and vim.api.nvim_win_is_valid(M.view.win)
-- end
--
-- function M.show(mode)
--   M.view = M.visible() and M.view or M.create()
--   if mode then
--     M.view.state.set_state("mode", mode)
--   end
--   M.view:update()
-- end
--
-- function M.create()
--   local self = setmetatable({}, { __index = setmetatable(M, { __index = Float }) })
--
--   self.state = State
--   self.state.init()
--
--   Util.init_env_files(self.state)
--
--   Float.init(self, {
--     title = "Hyper",
--     title_pos = "center",
--     noautocmd = true,
--   })
--
--   self.render = Render.new(self)
--
--   Commands.setup(self)
--
--   return self
-- end
--
-- function M:update()
--   if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
--     vim.bo[self.buf].modifiable = true
--     self.render:update()
--     vim.bo[self.buf].modifiable = false
--     vim.cmd.redraw()
--     Commands.setup(self)
--   end
-- end
--
-- return M
