local Text = require("hyper.view.text")
local Float = require("hyper.view.float")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Util = require("hyper.util")

local width, height, row, col = Util.get_viewbox()
local list_width = math.floor(width * 0.3) - 2
local coll_height = math.floor(height * 0.4)

local M = {}

function M.new(State)
  -- local avail_coll = Util.find_collections()
  -- print(vim.inspect(avail_coll))
  local collections = State.get_state("collections")

  local function coll_list()
    local list = {}
    for _, coll in ipairs(collections) do
      table.insert(list, coll.name)
    end
    return list
  end

  local function req_list(idx)
    local reqs = {}
    for _, req in ipairs(collections[idx].requests) do
      table.insert(reqs, ("%-6s %s"):format(req.method, req.url))
    end
    return reqs
  end

  local coll_list_win = Selector.new({
    title = "Collections",
    row = row,
    col = col,
    width = list_width,
    height = coll_height,
    options = coll_list(),
    enter = true,
  })

  local req_list_win = Selector.new({
    title = "Requests",
    row = coll_height + 4,
    col = col,
    width = list_width,
    height = height - coll_height - 2,
    options = req_list(coll_list_win.selection + 1),
    action_icon = "↵",
  })

  local function create_preview()
    local c_idx = coll_list_win.selection + 1
    local r_idx = req_list_win.selection + 1
    local req = collections[c_idx].requests[r_idx]

    local text = Text.new()
    text:append(string.format("%-6s %s", req.method, req.url))
    if next(req.params) ~= nil then
      text:nl()
      text:append("Query Parameters:")
      for k, v in pairs(req.params) do
        text:append(string.format("  %s=%s", k, v))
      end
    end
    if req.body ~= nil then
      text:nl()
      text:append("Body:")
      text:append("{")
      for k, v in pairs(req.body) do
        text:append(string.format("  %s: %s", k, v))
      end
      text:append("}")
    end
    return text
  end

  local req_prev_win = Float.new({
    title = "Request",
    row = row,
    col = col + list_width + 2,
    width = width - list_width - 2,
    height = height,
    content = create_preview,
  })

  local CollectionScreen = Screen.new({ coll_list_win, req_list_win, req_prev_win })

  req_prev_win:add_autocmd("BufLeave", {
    callback = function()
      CollectionScreen:hide()
    end
  })

  coll_list_win:add_keymap({"n", "<Tab>", function()
    coll_list_win:toggle_focus()
    req_list_win:toggle_focus()
  end})

  req_list_win:add_keymap({"n", "<Tab>", function()
    coll_list_win:toggle_focus()
    req_list_win:toggle_focus()
  end})

  req_list_win:add_keymap({"n", "j", function()
    if req_list_win:is_focused() then
      req_list_win:select_next()
      req_prev_win:render()
    end
  end})

  req_list_win:add_keymap({"n", "k", function()
    if req_list_win:is_focused() then
      req_list_win:select_previous()
      req_prev_win:render()
    end
  end})

  coll_list_win:add_keymap({"n", "j", function()
    if coll_list_win:is_focused() then
      coll_list_win:select_next()
      req_list_win:update_options(req_list(coll_list_win.selection + 1))
      req_prev_win:render()
    end
  end})

  coll_list_win:add_keymap({"n", "k", function()
    if coll_list_win:is_focused() then
      coll_list_win:select_previous()
      req_list_win:update_options(req_list(coll_list_win.selection + 1))
      req_prev_win:render()
    end
  end})

  return CollectionScreen
end

return M
