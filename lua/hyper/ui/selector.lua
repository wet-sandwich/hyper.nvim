local Float = require("hyper.ui.float")
local Text = require("hyper.ui.text")
local Dialog = require("hyper.ui.dialog")
local hyper = require("hyper")

local Selector = {}
Selector.__index = Selector

function Selector.new(opts)
  opts.hide_cursor = true
  local self = Float.new(opts)
  self.options = opts.options or {}
  self.selection = 0
  self.action_icon = opts.action_icon or nil
  self.has_focus = opts.focused or opts.enter or false
  setmetatable(self, { __index = setmetatable(Selector, { __index = Float }) })
  return self
end

function Selector:create_window()
  if type(self.options) == "function" then
    self.content = self.options
    self.num_opts = self.content():len()
  else
    self:_format_list()
    self.num_opts = #self.options
  end
  Float.create_window(self)

  if type(self.options) == "table" and #self.options == 0 then return end

  self:update_highlight()
end

function Selector:update_highlight()
  if self.has_focus then
    self.hl_extid = vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.selection, 0, {
      end_col = self.width,
      hl_group = "PmenuSel",
      id = self.hl_extid,
    })
    if self.action_icon then
      self.vt_extid = vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.selection, self.width-1, {
        virt_text = {{self.action_icon, "PmenuSel"}},
        virt_text_pos = "overlay",
        id = self.vt_extid,
      })
    end
  end
end

function Selector:remove_highlight()
  if self.hl_extid then
    vim.api.nvim_buf_del_extmark(self.buf, hyper.ns, self.hl_extid)
  end

  if self.vt_extid then
    vim.api.nvim_buf_del_extmark(self.buf, hyper.ns, self.vt_extid)
  end
end

function Selector:toggle_focus()
  if self.has_focus then
    self:remove_highlight()
    self.has_focus = false
  else
    self.has_focus = true
    self:update_highlight()
    vim.api.nvim_set_current_win(self.win)
  end
end

function Selector:is_focused()
  return self.has_focus
end

function Selector:select_next()
  if self.selection < self.num_opts - 1 then
    self.selection = self.selection + 1
  else
    self.selection = 0
  end
  self:update_highlight()
end

function Selector:select_previous()
  if self.selection > 0 then
    self.selection = self.selection - 1
  else
    self.selection = self.num_opts - 1
  end
  self:update_highlight()
end

function Selector:update_options(new_options)
  self.options = new_options
  self.num_opts = #new_options
  self.selection = 0
  self:_format_list()
  self:render()
end

function Selector:delete_item(f)
  Dialog.confirm(
    "Are you sure you want to delete the selected item? (y/n)",
    function()
      f(self.selection + 1)
      self.num_opts = self.num_opts - 1
      if self.selection > self.num_opts - 1 then
        self.selection = self.selection - 1
      end
      self:render()
      self:update_highlight()
    end
  )
end

function Selector:_format_list()
  local lines = Text.new()
  for _, item in ipairs(self.options) do
    item = item .. string.rep(" ", self.width - #item)
    lines:append(item)
  end
  self.content = lines:read()
end

return Selector
