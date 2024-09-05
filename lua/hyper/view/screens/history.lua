local Float = require("hyper.view.float")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Util = require("hyper.util")
local History = require("hyper.history")

local width, height, row, col = Util.get_viewbox()
local list_width = math.floor(width * 0.5) - 2

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
    focused = true,
    action_icon = "↵",
  })

  local function create_preview()
    local id = History.order[list_win.selection + 1]
    local req = History.requests[id]
    return Util.create_request_preview(req)
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

  preview_win:add_autocmd("BufLeave", {
    callback = function()
      HistoryScreen:hide()
    end
  })

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
