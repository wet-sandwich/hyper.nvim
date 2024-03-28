local Text = require("hyper.view.text2")
local Window = require("hyper.view.float2")
local Screen = require("hyper.view.screen")
local Menu = require("hyper.view.menu")
local Config = require("hyper.config")
local Util = require("hyper.util")
local History = require("hyper.history")

local col_width = Config.layout_config.col_width
local width, height, row, col = Util.get_viewbox()

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
  res_time = "TIME %dms",
  history = "Hi[S]tory (%d)",
}

local M = {}

function M.new(State)
  local state = State.get_state()

  local function create_menu()
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
    local params = string.format(strings.query, Util.dict_length(state.query_params))
    if Util.is_body_method(state.method) then
      menu:append(table.concat({
        params,
        string.rep(" ", col_width - #params),
        strings.body,
      }))
    else
      menu:append(params)
    end

    -- headers and env variables
    local headers = string.format(strings.headers, Util.dict_length(state.headers))
    menu:append(table.concat({
      headers,
      string.rep(" ", col_width - #headers),
      strings.envars,
    }))

    -- history
    local history = string.format(strings.history, #History.order)
    menu:append(history)

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
      local body, extras = Util.parse_response_body(res.body)
      local res_time = body and math.floor(extras.response_time*1000) or 0

      local status = string.format(strings.res_status, res.status)
      local time = string.format(strings.res_time, res_time)
      response:append(table.concat({
        status,
        string.rep(" ", col_width - #status),
        time,
      }))

      response:nl()
      for _, line in ipairs(Util.pretty_format(body)) do
        response:append(line)
      end
    end

    return response
  end

  -- [[ Setup Windows ]]

  local req = Window.new({
    title = "Request",
    row = row,
    col = col,
    width = width,
    height = 6,
    content = create_menu,
  })

  local res = Window.new({
    title = "Response",
    row = req.row + req.height + 2,
    col = col,
    width = width,
    height = height - req.height - 2,
    enter = true,
    content = create_http_response,
  })

  local RequestScreen = Screen.new({ req, res })

  -- [[ Setup Keymaps ]]

  res:add_keymap({"n", "M", function()
    local methods = {"GET", "PUT", "POST", "PATCH", "DELETE"}
    Menu.popup_menu(methods, {
      title = "Method",
      row = 0,
      col = 0,
      width = 15,
      height = #methods,
      callback = function(selection)
        State.set_state("method", methods[selection])
        req:render()
      end,
    })
  end})

  res:add_keymap({"n", "U", function()
    Menu.entry(state.url, {
      title = "URL",
      row = 0,
      col = Config.layout_config.col_width,
      width = width - 2 * Config.layout_config.col_width,
      submit_in_insert = true,
      callback = function(entry)
        State.set_state("url", entry[1])
        req:render()
      end,
    })
  end})

  res:add_keymap({"n", "P", function()
    Menu.entry(state.query_params, {
      title = "Query Parameters",
      row = 1,
      col = 0,
      width = 40,
      height = 20,
      filetype = "sh",
      callback = function(entry)
        State.set_state("query_params", Util.lines_to_kv(entry, "="))
        req:render()
      end,
    })
  end})

  res:add_keymap({"n", "B", function()
    if Util.is_body_method(state.method) then
      Menu.entry(state.body, {
        title = "Body",
        row = 1,
        col = Config.layout_config.col_width,
        width = width - 2 * Config.layout_config.col_width,
        height = height - 4,
        filetype = "json",
        callback = function(entry)
          State.set_state("body", entry)
          req:render()
        end,
      })
    end
  end})

  res:add_keymap({"n", "H", function()
    Menu.entry(state.headers, {
      title = "Headers",
      row = 2,
      col = 0,
      width = 40,
      height = 20,
      separator = ": ",
      callback = function(entry)
        State.set_state("headers", Util.lines_to_kv(entry, ":"))
        req:render()
      end,
    })
  end})

  res:add_keymap({"n", "X", function()
    State.clear_state()
    req:update(create_menu())
  end})

  res:add_keymap({"n", "R", function()
    local response = Util.http_request(state)
    History.add_item(state)
    State.set_state("res", response)
    res:render()
    req:render()
  end})

  return RequestScreen
end

return M
