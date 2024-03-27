local Float = require("hyper.view.float2")

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

local Selector = {}
Selector.__index = Selector

-- function Selector.new(opts, initial)
function Selector.new(opts, syncSelection)
  local float = Float.new(opts)
  -- float.selection = initial or 0
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
  self:update_highlight()
end

function Selector:sync_selection(val)
  self.selection = val
end

function Selector:update_highlight()
  vim.api.nvim_buf_clear_namespace(self.buf, ns_hyper_selection, 0, -1)
  vim.api.nvim_buf_add_highlight(self.buf, ns_hyper_selection, "PmenuSel", self.selection, 0, -1)
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
