local Text = require("hyper.view.text2")
local Float = require("hyper.view.float2")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Util = require("hyper.util")
local History = require("hyper.history")

local width, height, row, col = Util.get_viewbox()
local list_width = math.floor(width * 0.5) - 2

local templates = {
  url = "%-6s %s",
  params = "  %s=%s",
  headers = "  %s: %s",
}

local M = {}

function M.new(State)
  local function create_list()
    local list = {}
    for _, id in ipairs(History.order) do
      local req = History.requests[id]
      local str = "%s  %s  %-6s  %s"
      local short_url = string.gsub(req.url, "^https?://", "")
      table.insert(list, str:format(req.timestamp, req.status, req.method, short_url))
    end
    return list
  end

  local list_win = Selector.new({
    title = "History",
    row = row,
    col = col,
    width = list_width,
    height = height,
    options = create_list(),
  })

  local function create_preview()
    local id = History.order[list_win.selection + 1]
    local req = History.requests[id]
    local preview = Text.new()

    if req ~= nil then
      preview:append(templates.url:format(req.method, req.url))

      if req.query_params ~= nil then
        preview:nl()
        preview:append("Query Params:")
        for key, val in pairs(req.query_params) do
          preview:append(templates.params:format(key, val))
        end
      end

      if next(req.headers) ~= nil then
        preview:nl()
        preview:append("Headers:")
        for key, val in pairs(req.headers) do
          preview:append(templates.headers:format(key, val))
        end
      end

      if req.body ~= nil then
        preview:nl()
        preview:append("Body:")
        for _, line in ipairs(req.body) do
          preview:append(line)
        end
      end
    end

    return preview
  end

  local preview_win = Float.new({
    title = "Request",
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
    if #History.order == 0 then return end

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
end

return M
