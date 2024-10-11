local Selector = require("hyper.view.selector")
local Float = require("hyper.view.float")

local Popup = {}
Popup.__index = Popup

local function new_select(opts)
  opts.relative = opts.relative or "win"
  opts.height = #opts.options
  opts.focused = true
  opts.action_icon = "↵"
  opts.enter = true
  return Selector.new(opts)
end

function Popup.select(opts)
  local self = new_select(opts)

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

local function prepare_content(content, separator)
  local lines = {}
  if type(content) == "string" then
    table.insert(lines, content)
  else
    separator = separator or "="
    if content[1] == nil then
      for k, v in pairs(content) do
        table.insert(lines, k .. separator .. v)
      end
    else
      for _, v in ipairs(content) do
        table.insert(lines, v)
      end
    end
  end

  return lines
end

local function new_entry(opts)
  opts.relative = opts.relative or "win"
  opts.editable = true
  opts.width = opts.width or 100
  opts.height = opts.height or 1
  opts.title = opts.overlay and ("🞂🞂 %s ↵ 🞀🞀"):format(opts.title) or opts.title
  opts.row = opts.row or -1
  opts.col = opts.col or -1
  opts.enter = true
  return Float.new(opts)
end

function Popup.entry(content, opts)
  opts.content = prepare_content(content, opts.separator)
  local self = new_entry(opts)

  self:add_keymap({"n", "<c-c>", function()
    vim.api.nvim_win_close(self.win, true)
  end})

  local enter_modes = opts.submit_in_insert and {"n", "i"} or "n"
  self:add_keymap({enter_modes, "<CR>", function()
    local entry = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
    if self.callback and type(self.callback) == "function" then
      self.callback(entry)
    end

    local current_mode = vim.api.nvim_get_mode()
    if current_mode.mode == "i" then
      local key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(key, "i", true)
    end

    vim.api.nvim_win_close(self.win, true)
  end})

  vim.o.eventignore = "BufLeave"
  self:create_window()
  vim.o.eventignore = ""
end

return Popup
