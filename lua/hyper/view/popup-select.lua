local Selector = require("hyper.view.selector")

local PopupSelect = {}
PopupSelect.__index = PopupSelect

local function new(opts)
  opts.relative = opts.relative or "win"
  opts.height = #opts.options
  local self = Selector.new(opts)
  setmetatable(self, { __index = setmetatable(PopupSelect, { __index = Selector }) })
  return self
end

function PopupSelect.select(opts)
  local self = new(opts)

  self:add_keymap({"n", "<CR>", function()
    if self.callback and type(self.callback) == "function" then
      self.callback(self.selection + 1)
    end
    vim.api.nvim_win_close(self.win, true)
  end})

  self:add_keymap({"n", "j", function()
    self:select_next()
  end})

  self:add_keymap({"n", "k", function()
    self:select_previous()
  end})

  self:add_keymap({"n", "q", function()
    vim.api.nvim_win_close(self.win, true)
  end})

  vim.o.eventignore = "BufLeave"
  self:create_window()
  vim.o.eventignore = ""
end

return PopupSelect
