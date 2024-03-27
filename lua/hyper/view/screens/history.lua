local Text = require("hyper.view.text2")
local Float = require("hyper.view.float2")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Util = require("hyper.util")
local History = require("hyper.history")
local State = require("hyper.state")

local width, height, row, col = Util.get_viewbox()
local list_width = math.floor(width * 0.3)

local function create_list()
  local list = Text.new()
  for _, id in ipairs(History.order) do
    local req = History.requests[id]
    local str = req.method .. " " .. req.url
    list:append(str)
  end
  return list
end

local list_win = Selector.new({
  title = "Request History",
  row = row,
  col = col,
  width = list_width,
  height = height,
  content = create_list,
})

local function create_preview()
  local id = History.order[list_win.selection + 1]
  local req = History.requests[id]
  local preview = Text.new()

  if req ~= nil then
    preview:append(req.method .. " " .. req.url)
    preview:nl()
    if req.query_params ~= nil then
      preview:append("Query Params:")
      for key, val in pairs(req.query_params) do
        preview:append("  " .. key .. ": " .. val)
      end
    end
  end

  return preview
end

local preview_win = Float.new({
  title = "Request Preview",
  row = row,
  col = col + list_width + 2,
  width = width - list_width - 2,
  height = height,
  enter = true,
  content = create_preview
})

local HistoryScreen = Screen.new({ list_win, preview_win })

preview_win:add_keymap({"n", "<c-n>", function()
  list_win:select_next()
  preview_win:render()
end})

preview_win:add_keymap({"n", "<c-p>", function()
  list_win:select_previous()
  preview_win:render()
end})

preview_win:add_keymap({"n", "<CR>", function()
  local id = History.order[list_win.selection + 1]
  local request = History.requests[id]

  State.set_state("method", request.method or "")
  State.set_state("url", request.url or "")
  State.set_state("query_params", request.query_params or {})
  State.set_state("headers", request.headers or {})
  State.set_state("body", request.body or {})

  vim.api.nvim_input("<c-o>")
end})

return HistoryScreen
