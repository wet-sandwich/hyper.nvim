local Float = require("hyper.view.float")
local Selector = require("hyper.view.selector")
local Screen = require("hyper.view.screen")
local Collections = require("hyper.collections")
local Text = require("hyper.view.text")
local Ui = require("hyper.utils.ui")
local Http = require("hyper.utils.http")

local width, height, row, col = Ui.get_viewbox()
local list_width = math.floor(width * 0.3) - 2
local coll_height = math.floor(height * 0.4)

local M = {}

function M.new(mode, State)
  Collections.sync_collections(State)
  local collections = State.get_state("collections")

  local function noCollections()
    return #collections == 0
  end

  local function emptyCollection(i)
    return #collections[i].requests == 0
  end

  local function coll_list()
    if noCollections() then
      return {"No collections found"}
    end

    local list = {}
    for _, coll in ipairs(collections) do
      table.insert(list, coll.name)
    end
    return list
  end

  local function req_list(idx)
    if noCollections() then
      return {""}
    end
    if emptyCollection(idx) then
      return {"Collection is empty"}
    end

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

  local function req_list_title()
    if #collections > 0 then
      return string.format("Requests: %s", collections[coll_list_win.selection + 1].name)
    end
    return "Requests"
  end

  local req_list_win = Selector.new({
    title = req_list_title(),
    row = row + coll_height + 2,
    col = col,
    width = list_width,
    height = height - coll_height - 2,
    options = req_list(coll_list_win.selection + 1),
    action_icon = "↵",
  })

  local function create_preview()
    local c_idx = coll_list_win.selection + 1
    local r_idx = req_list_win.selection + 1

    if noCollections() or emptyCollection(c_idx) then
      return Text.new()
    end

    local req = collections[c_idx].requests[r_idx]
    return Ui.create_request_preview(req)
  end

  local req_prev_win = Float.new({
    title = "Request",
    row = row,
    col = col + list_width + 2,
    width = width - list_width - 2,
    height = height,
    content = create_preview,
  })

  local CollectionScreen = Screen.new(mode, { coll_list_win, req_list_win, req_prev_win })

  coll_list_win:add_keymap({"n", "<Tab>", function()
    if noCollections() or emptyCollection(coll_list_win.selection + 1) then
      return
    end
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

  req_list_win:add_keymap({"n", "<CR>", function()
    local req = collections[coll_list_win.selection + 1].requests[req_list_win.selection + 1]

    Http.select_request(State, req)
    vim.api.nvim_input("<c-o>")
  end})

  coll_list_win:add_keymap({"n", "j", function()
    if coll_list_win:is_focused() then
      coll_list_win:select_next()
      req_list_win:update_options(req_list(coll_list_win.selection + 1))
      vim.api.nvim_win_set_config(req_list_win.win, { title = req_list_title() })
      req_prev_win:render()
    end
  end})

  coll_list_win:add_keymap({"n", "k", function()
    if coll_list_win:is_focused() then
      coll_list_win:select_previous()
      req_list_win:update_options(req_list(coll_list_win.selection + 1))
      vim.api.nvim_win_set_config(req_list_win.win, { title = req_list_title() })
      req_prev_win:render()
    end
  end})

  return CollectionScreen
end

return M
