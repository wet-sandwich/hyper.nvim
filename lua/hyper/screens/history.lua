local Float = require("hyper.ui.float")
local Selector = require("hyper.ui.selector")
local Screen = require("hyper.ui.screen")
local Ui = require("hyper.utils.ui")
local Http = require("hyper.utils.http")
local History = require("hyper.history")
local Text = require("hyper.ui.text")
local hyper = require("hyper")

local width, height, row, col = Ui.get_viewbox()
local list_width = math.floor(width * 0.5) - 2
local req_width = width - list_width - 2
local cutoff = list_width - 2

local M = {}

function M.new(State)
  local function create_list()
    local list = Text.new()
    for _, id in ipairs(History.order) do
      local req = History.requests[id]
      local tpl = "%s  %s  %-6s  %s"
      local short_url = string.gsub(req.url, "^https?://", "")
      local str = tpl:format(req.timestamp, req.status, req.method, short_url)
      if #str > cutoff then
        str = string.sub(str, 1, cutoff - 3) .. "..."
      end
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
    action_icon = hyper.opts.icon_enter,
    enter = true,
  })

  local function create_preview()
    local id = History.order[list_win.selection + 1]
    local req = History.requests[id]
    return Ui.create_request_preview(req, req_width)
  end

  local preview_win = Float.new({
    title = "Request",
    row = row,
    col = col + list_width + 2,
    width = req_width,
    height = height,
    content = create_preview
  })

  local HistoryScreen = Screen.new(State, hyper.mode.history, { list_win, preview_win })

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

  list_win:add_keymap({"n", "<del>", function()
    if #History.order == 0 then return end

    list_win:delete_item(function(index)
      History.delete_item(index)
      preview_win:render()
    end)
  end})

  return HistoryScreen
end

return M
