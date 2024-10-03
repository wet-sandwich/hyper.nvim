local Text = require("hyper.view.text")
local Window = require("hyper.view.float")
local Screen = require("hyper.view.screen")
local Menu = require("hyper.view.menu")
local Config = require("hyper.config")
local Ui = require("hyper.utils.ui")
local Http = require("hyper.utils.http")
local Table = require("hyper.utils.table")
local History = require("hyper.history")

local strings = {
  method = "[M]ethod: ",
  url = "[U]rl: ",
  query = "[P]arams (%d)",
  body = "[B]ody",
  headers = "[H]eaders (%d)",
  envars = "[E]nv Variables",
  request = "Make [R]equest",
  clear_all = "[X] Clear All",
  response = "Response:",
  res_status = "STATUS %d",
  res_status_time = "%-25sTIME %dms",
  history = "Hi[S]tory (%d)",
  collections = "[C]ollections",
}

local M = {}

function M.new(mode, State)

  local col_width = Config.layout_config.col_width
  local width, height, row, col = Ui.get_viewbox()

  local function create_menu()
    local state = State.get_state()
    local menu = Text.new()

    -- method and url
    menu:append(table.concat({
      strings.method,
      state.method,
      string.rep(" ", col_width - #strings.method - #state.method),
      strings.url,
      state.url,
    }))

    -- query params and body
    local params = string.format(strings.query, Table.dict_length(state.query_params))
    local body_hl = not Http.is_body_method(state.method) and { hl_group = "Comment", end_col = col_width + 6, col = col_width } or nil
    menu:append(table.concat({
      params,
      string.rep(" ", col_width - #params),
      strings.body,
    }), body_hl)

    -- headers and env variables
    local headers = string.format(strings.headers, Table.dict_length(state.headers))
    menu:append(table.concat({
      headers,
      string.rep(" ", col_width - #headers),
      strings.envars,
    }))

    -- history and collections
    local history = string.format(strings.history, #History.order)
    menu:append(table.concat({
      history,
      string.rep(" ", col_width - #history),
      strings.collections,
    }))

    -- make request and clear all commands
    menu:nl()
    menu:append(table.concat({
      strings.request,
      string.rep(" ", col_width - #strings.request),
      strings.clear_all,
    }))

    return menu
  end

  local function create_http_response()
    local response = Text.new()
    local res = State.get_state("res")

    if res ~= nil then
      local body, extras = Http.parse_response_body(res.body)
      local res_time = body and math.floor(extras.response_time*1000) or 0

      local status = string.format(strings.res_status, res.status)
      local str = string.format(strings.res_status_time, status, res_time)
      response:append(str, { hl_group = Ui.get_status_hl(res.status), end_col = 10 })

      response:nl()
      response:append(body)
    end

    return response
  end

  -- [[ Setup Windows ]]

  local req_height = 6
  local request_win = Window.new({
    title = "Request",
    row = row,
    col = col,
    width = width,
    height = req_height,
    content = create_menu,
  })

  local res_height = height - request_win.height - 2

  local response_win = Window.new({
    title = "Response",
    row = request_win.row + request_win.height + 2,
    col = col,
    width = width,
    height = res_height,
    enter = true,
    content = create_http_response,
  })

  local RequestScreen = Screen.new(mode, { request_win, response_win })

  response_win:add_autocmd("BufLeave", {
    callback = function()
      RequestScreen:hide()
    end
  })

  -- [[ Setup Keymaps ]]

  response_win:add_keymap({"n", "M", function()
    local methods = {"GET", "PUT", "POST", "PATCH", "DELETE"}
    Menu.select_menu(methods, {
      title = "Method",
      width = 30,
      row = -req_height - 2,
      col = 0,
      callback = function(selection)
        State.set_state("method", methods[selection])
        request_win:render()
      end,
    })
  end})

  response_win:add_keymap({"n", "U", function()
    local state = State.get_state()
    Menu.entry(state.url, {
      title = "URL",
      row = -req_height - 2,
      col = Config.layout_config.col_width,
      width = width - 2 * Config.layout_config.col_width,
      submit_in_insert = true,
      callback = function(entry)
        State.set_state("url", entry[1])
        request_win:render()
      end,
    })
  end})

  response_win:add_keymap({"n", "P", function()
    local state = State.get_state()
    Menu.entry(state.query_params, {
      title = "Query Parameters",
      overlay = true,
      width = width,
      height = res_height,
      filetype = "sh",
      callback = function(entry)
        State.set_state("query_params", Table.lines_to_kv(entry, "="))
        request_win:render()
      end,
    })
  end})

  response_win:add_keymap({"n", "B", function()
    local state = State.get_state()
    if Http.is_body_method(state.method) then
      Menu.entry(state.body, {
        title = "Body",
        overlay = true,
        width = width,
        height = res_height,
        filetype = "json",
        callback = function(entry)
          State.set_state("body", entry)
          request_win:render()
        end,
      })
    end
  end})

  response_win:add_keymap({"n", "H", function()
    local state = State.get_state()
    Menu.entry(state.headers, {
      title = "Headers",
      overlay = true,
      width = width,
      height = res_height,
      separator = ": ",
      callback = function(entry)
        State.set_state("headers", Table.lines_to_kv(entry, ":"))
        request_win:render()
      end,
    })
  end})

  response_win:add_keymap({"n", "X", function()
    State.clear_state()
    request_win:render()
    response_win:render()
  end})

  response_win:add_keymap({"n", "R", function()
    local state = State.get_state()
    local response = Http.http_request(state)
    State.set_state("res", response)
    History.add_item(state)
    response_win:render()
    request_win:render()
  end})

  return RequestScreen
end

return M
