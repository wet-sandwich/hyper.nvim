local Float = require("hyper.view.float")
local Text = require("hyper.view.text")

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

local Selector = {}
Selector.__index = Selector

function Selector.new(opts)
  local self = Float.new(opts)
  self.options = opts.options or {}
  self.selection = 0
  self.action_icon = "↵"
  setmetatable(self, { __index = setmetatable(Selector, { __index = Float }) })
  return self
end

function Selector:create_window()
  self:_format_list()
  Float.create_window(self)

  if #self.options == 0 then return end

  self.hl_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
  })
  if self.action_icon then
    self.vt_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, self.width-1, {
      virt_text = {{self.action_icon, "PmenuSel"}},
      virt_text_pos = "overlay",
    })
  end
end

function Selector:update_highlight()
  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
    id = self.hl_extid,
  })
  if self.action_icon then
    vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, self.width-1, {
      virt_text = {{self.action_icon, "PmenuSel"}},
      virt_text_pos = "overlay",
      id = self.vt_extid,
    })
  end
end

function Selector:select_next()
  if self.selection < #self.options - 1 then
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
    self.selection = #self.options - 1
  end
  self:update_highlight()
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
