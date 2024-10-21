local Float = require("hyper.ui.float")

local Dialog = {}

local function new_dialog(prompt)
  local width = #prompt
  return Float.new({
    content = {prompt},
    width = width,
    height = 1,
    row = math.floor(vim.o.lines / 2 - 2),
    col = math.floor((vim.o.columns - width - 1) / 2),
    zindex = 100,
    enter = true,
  })
end

function Dialog.confirm(prompt, on_confirm)
  local self = new_dialog(prompt)

  local function confirm(affirmation)
    if affirmation then
      on_confirm()
    end
    vim.api.nvim_win_close(self.win, true)
  end

  self:add_keymap({"n", "<CR>", function()
    confirm(true)
  end})

  self:add_keymap({"n", "<Esc>", function()
    confirm(false)
  end})

  self:add_keymap({"n", "y", function()
    confirm(true)
  end})

  self:add_keymap({"n", "n", function()
    confirm(false)
  end})

  vim.o.eventignore = "BufLeave"
  self:create_window()
  vim.o.eventignore = ""
end

return Dialog
