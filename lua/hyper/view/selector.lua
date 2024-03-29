local Float = require("hyper.view.float2")

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

local Selector = {}
Selector.__index = Selector

function Selector.new(opts, syncSelection)
  local float = Float.new(opts)
  float.syncSelection = syncSelection
  setmetatable(float, { __index = setmetatable(Selector, { __index = Float }) })
  return float
end

function Selector:create_window()
  Float.create_window(self)
  if self.syncSelection then
    self.selection = self:syncSelection()
  else
    self.selection = 0
  end
  self.hl_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
  })
  self.vt_extid = vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, self.width-1, {
    virt_text = {{"↵", "PmenuSel"}},
    virt_text_pos = "overlay",
  })
end

function Selector:sync_selection(val)
  self.selection = val
end

function Selector:update_highlight()
  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, 0, {
    end_col = self.width,
    hl_group = "PmenuSel",
    id = self.hl_extid,
  })
  vim.api.nvim_buf_set_extmark(self.buf, ns_hyper_selection, self.selection, self.width-1, {
    virt_text = {{"↵", "PmenuSel"}},
    virt_text_pos = "overlay",
    id = self.vt_extid,
  })
end

function Selector:select_next()
  if self.selection < self.content():len() - 1 then
    self.selection = self.selection + 1
    self:update_highlight()
  end
end

function Selector:select_previous()
  if self.selection > 0 then
    self.selection = self.selection - 1
    self:update_highlight()
  end
end

return Selector
