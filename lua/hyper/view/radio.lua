local Float = require("hyper.view.float")
local Text = require("hyper.view.text")
local hyper = require("hyper")

local Radio = {}
Radio.__index = Radio

function Radio.new(opts, syncSelection)
  local self = Float.new(opts)
  self.options = opts.options or {}
  self.syncSelection = syncSelection
  self.selected_icon = "✔"
  self.action_icon = "⇥"
  setmetatable(self, { __index = setmetatable(Radio, { __index = Float }) })
  return self
end

function Radio:create_window()
  self:_format_list()
  Float.create_window(self)

  if self.syncSelection then
    self.selection = self:syncSelection()
  else
    self.selection = 0
  end

  self.hover = self.selection

  if #self.options == 0 then return end

  self.hl_extid = vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.hover, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
  })
  self.check_extid = vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.selection, 0, {
    virt_text = {{self.selected_icon, "PmenuSel"}},
    virt_text_pos = "overlay",
  })
  self.action_extid = vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.hover, 0, {})
end

function Radio:update_highlight()
  vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.hover, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
    id = self.hl_extid,
  })

  local hl_select = self.selection == self.hover and "PmenuSel" or ""
  vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.selection, 0, {
    virt_text = {{self.selected_icon, hl_select}},
    virt_text_pos = "overlay",
    id = self.check_extid,
  })

  local vt = self.hover ~= self.selection and self.action_icon or ""
  vim.api.nvim_buf_set_extmark(self.buf, hyper.ns, self.hover, 0, {
    virt_text = {{vt, "PmenuSel"}},
    virt_text_pos = "overlay",
    id = self.action_extid,
  })
end

function Radio:hover_next()
  if self.hover < #self.options - 1 then
    self.hover = self.hover + 1
  else
    self.hover = 0
  end
  self:update_highlight()
end

function Radio:hover_previous()
  if self.hover > 0 then
    self.hover = self.hover - 1
  else
    self.hover = #self.options - 1
  end
  self:update_highlight()
end

function Radio:select()
  if self.hover == self.selection then
    return
  end
  self.selection = self.hover
  self:update_highlight()
end

function Radio:_format_list()
  local lines = Text.new()
  for _, item in ipairs(self.options) do
    local str = "  " .. item
    str = str .. string.rep(" ", self.width - #str)
    lines:append(str)
  end
  self.content = lines:read()
end

return Radio
