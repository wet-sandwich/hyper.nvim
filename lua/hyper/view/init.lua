local RequestScreen = require("hyper.view.screens.request")
local HistoryScreen = require("hyper.view.screens.history")
local VariablesScreen = require("hyper.view.screens.variables")
local CollectionScreen = require("hyper.view.screens.collections")
local State = require("hyper.state")
local Util = require("hyper.util")

local M = {}
M.screen = nil

State.init()

function M.show()
  vim.g.prev_cursor = vim.go.guicursor

  if M.screen and M.screen.isVisible then
    M.screen:hide()
  end

  local mode = State.get_state("mode") or "main"
  Util.update_env_files(State)

  if mode == "main" then
    M.screen = RequestScreen.new(State)
  end

  if mode == "history" then
    M.screen = HistoryScreen.new(State)
  end

  if mode == "variables" then
    M.screen = VariablesScreen.new(State)
  end

  if mode == "collections" then
    M.screen = CollectionScreen.new(State)
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

    M.screen:on_key("n", "C", function()
      State.set_state("mode", "collections")
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
