local State = require("hyper.state")

State.init()

local screens = {
  main = require("hyper.screens.request").new,
  history = require("hyper.screens.history").new,
  variables = require("hyper.screens.variables").new,
  collections = require("hyper.screens.collections").new,
}

local M = {}
M.screen = nil

function M.open()
  vim.g.prev_cursor = vim.go.guicursor

  if M.screen and M.screen.isVisible then
    M.screen:hide()
  end

  local mode = State.get_state("mode") or "main"

  M.screen = screens[mode](State)
  M.screen:display()
end

function M.jump()
  local Http = require("hyper.utils.http")

  local path = vim.api.nvim_buf_get_name(0)
  if vim.fn.filereadable(path) == 0 or path:match('.*%.http$') == nil then
    vim.notify("HyperJump failed: must be in a valid http file", vim.log.levels.WARN)
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local requests = Http.parse(lines)

  for _, req in ipairs(requests) do
    if row <= req._end then
      Http.select_request(State, req)
      State.set_state("mode", "main")
      M.open()
      break
    end
  end
end

return M
