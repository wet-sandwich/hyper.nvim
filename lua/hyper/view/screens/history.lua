local Float = require("hyper.view.float")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Ui = require("hyper.utils.ui")
local Http = require("hyper.utils.http")
local History = require("hyper.history")
local Text = require("hyper.view.text")

local width, height, row, col = Ui.get_viewbox()
local list_width = math.floor(width * 0.5) - 2

local M = {}

function M.new(mode, State)
  local function create_list()
    local list = Text.new()
    for _, id in ipairs(History.order) do
      local req = History.requests[id]
      local tpl = "%s  %s  %-6s  %s"
      local short_url = string.gsub(req.url, "^https?://", "")
      local str = tpl:format(req.timestamp, req.status, req.method, short_url)
      str = str .. (" "):rep(list_width - #str)
      list:append(str, { hl_group = Ui.get_status_hl(req.status), col = 22, end_col = 25 })
    end
    return list
  end

  local list_win = Selector.new({
    title = "History",
    row = row,
    col = col,
    width = list_width,
    height = height,
    options = create_list,
    focused = true,
    action_icon = "↵",
    enter = true,
  })

  local function create_preview()
    local id = History.order[list_win.selection + 1]
    local req = History.requests[id]
    return Ui.create_request_preview(req)
  end

  local preview_win = Float.new({
    title = "Request",
    row = row,
    col = col + list_width + 2,
    width = width - list_width - 2,
    height = height,
    content = create_preview
  })

  local HistoryScreen = Screen.new(mode, { list_win, preview_win })

  preview_win:add_autocmd("BufLeave", {
    callback = function()
      HistoryScreen:hide()
    end
  })

  list_win:add_keymap({"n", "j", function()
    list_win:select_next()
    preview_win:render()
  end})

  list_win:add_keymap({"n", "k", function()
    list_win:select_previous()
    preview_win:render()
  end})

  list_win:add_keymap({"n", "<CR>", function()
    if #History.order == 0 then return end

    local id = History.order[list_win.selection + 1]
    local request = History.requests[id]

    Http.select_request(State, request)
    vim.api.nvim_input("<c-o>")
  end})

  return HistoryScreen
end

return M
