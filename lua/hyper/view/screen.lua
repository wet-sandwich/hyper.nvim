local Screen = {}
Screen.__index = Screen

function Screen.new(windows)
  windows.isVisible = false
  windows.main = {}
  setmetatable(windows, Screen)
  return windows
end

function Screen:display()
  for _, win in ipairs(self) do
    win:create_window()
    if win.enter then
      self.main = win
      self.isVisible = vim.api.nvim_win_is_valid(win.win)
    end
    win:set_keymap("n", "<c-c>", function()
      self:hide()
    end)
  end
end

function Screen:hide()
  for _, win in ipairs(self) do
    pcall(vim.api.nvim_win_close, win.win, true)
    self.isVisible = vim.api.nvim_win_is_valid(win.win)
  end
end

function Screen:on_key(mode, lhs, rhs)
  self.main:set_keymap(mode, lhs, rhs)
end

return Screen
