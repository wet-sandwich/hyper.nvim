local RequestScreen = require("hyper.view.screens.request")
local HistoryScreen = require("hyper.view.screens.history")
local VariablesScreen = require("hyper.view.screens.variables")
local CollectionScreen = require("hyper.view.screens.collections")
local State = require("hyper.state")
local Util = require("hyper.util")
local http = require "hyper.http-parser"

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
    M.screen = RequestScreen.new(mode, State)
  end

  if mode == "history" then
    M.screen = HistoryScreen.new(mode, State)
  end

  if mode == "variables" then
    M.screen = VariablesScreen.new(mode, State)
  end

  if mode == "collections" then
    M.screen = CollectionScreen.new(mode, State)
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
    M.screen:on_key("n", "<c-o>", function()
      M.screen:hide()
      State.set_state("mode", "main")
      M.show()
    end)
  end
end

function M.jump()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.fn.filereadable(path) == 0 or path:match('.*%.http$') == nil then
    vim.notify("HyperJump failed: must be in a valid http file", vim.log.levels.WARN)
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local requests = http.parse(lines)

  for _, req in ipairs(requests) do
    if row <= req._end then
      Util.select_request(State, req)
      State.set_state("mode", "main")
      M.show()
      break
    end
  end
end

return M
