local Text = require "hyper.view.text"
local Screens = require("hyper.view.screens")

local M = {}

function M.new(view)
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Text }) })
  self.view = view
  return self
end

function M:update()
  self._lines = {}

  self.screens = Screens.new(self.view)
  local mode = self.view.state.get_state("mode")

  if mode == "main" then
    self.screens:main()
  end

  if mode == "vars" then
    self.screens:vars()
  end

  -- if mode == "collection" then
  --   self.screens:collection()
  -- end

  self:render(self.view.buf)
end

return M
