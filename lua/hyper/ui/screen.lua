local Envs = require("hyper.envs")
local Help = require("hyper.ui.help")
local hyper = require("hyper")

local Screen = {}
Screen.__index = Screen

function Screen.new(State, mode, windows)
  if mode == hyper.mode.main or mode == hyper.mode.variables then
    Envs.update_env_files(State)
  end

  windows.isVisible = false
  windows.main = {}
  windows.mode = mode
  windows.State = State
  setmetatable(windows, Screen)
  return windows
end

function Screen:display()
  for _, win in ipairs(self) do
    win:add_autocmd("WinClosed", {
      callback = function()
        self:hide()
      end,
      nested = true,
    })
    win:create_window()
    if win.enter then
      self.main = win
      self.isVisible = vim.api.nvim_win_is_valid(win.win)
    end
  end

  self:setup_cmds()
end

function Screen:hide()
  for _, win in ipairs(self) do
    pcall(vim.api.nvim_win_close, win.win, true)
    self.isVisible = vim.api.nvim_win_is_valid(win.win)
  end
  self:hide_help()
end

function Screen:on_key(mode, lhs, rhs)
  for _, win in ipairs(self) do
    win:set_keymap(mode, lhs, rhs)
  end
end

function Screen:show_help()
  self.help = Help.show(self.mode)
end

function Screen:hide_help()
  if self.help ~= nil and vim.api.nvim_win_is_valid(self.help) then
    vim.api.nvim_win_close(self.help, true)
  end
  self.help = nil
end

function Screen:setup_cmds()
  self:on_key("n", "<c-o>", function()
    if self.mode == hyper.mode.main then
      return
    end
    self:hide()
    self.State.set_state("mode", hyper.mode.main)
    require("hyper.drive").open()
  end)

  self:on_key("n", "?", function()
    self:show_help()
  end)

  self:on_key("n", "q", function()
    self:hide_help()
  end)

  self:on_key("n", "<c-c>", function()
    self:hide()
  end)
end

return Screen
