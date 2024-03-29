local Float = require("hyper.view.float2")
local Text = require("hyper.view.text2")

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

local Radio = {}
Radio.__index = Radio

function Radio.new(opts, syncSelection)
  local float = Float.new(opts)
  float.syncSelection = syncSelection
  float.selected_icon = "✔"
  float.action_icon = "⇥"
  setmetatable(float, { __index = setmetatable(Radio, { __index = Float }) })
  return float
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

  self.hl_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.hover, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
  })
  self.check_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    virt_text = {{self.selected_icon, "PmenuSel"}},
    virt_text_pos = "overlay",
  })
  self.tab_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.hover, self.width-1, {
    virt_text = {{self.action_icon, "PmenuSel"}},
    virt_text_pos = "overlay",
  })
end

function Radio:update_highlight()
  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.hover, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
    id = self.hl_extid,
  })

  local hl_select = self.selection == self.hover and "PmenuSel" or ""
  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    virt_text = {{self.selected_icon, hl_select}},
    virt_text_pos = "overlay",
    id = self.check_extid,
  })

  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.hover, self.width-1, {
    virt_text = {{self.action_icon, "PmenuSel"}},
    virt_text_pos = "overlay",
    id = self.tab_extid,
  })
end

function Radio:hover_next()
  if self.hover < #self.options - 1 then
    self.hover = self.hover + 1
    self:update_highlight()
  end
end

function Radio:hover_previous()
  if self.hover > 0 then
    self.hover = self.hover - 1
    self:update_highlight()
  end
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
