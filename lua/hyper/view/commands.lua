local Menu = require("hyper.view.menu")
local Config = require("hyper.config")
local Util = require("hyper.util")

local M = {}

function M.setup(view)
  M.view = view
  local state = M.view.state.get_state()

  if state.mode == "main" then
    M:main_commands()
  end

  if state.mode == "env" then
    M:env_commands()
  end
end

function M:main_commands()
  local state = self.view.state.get_state()

  self.view:on_key("M", function()
    local methods = {"GET", "PUT", "POST", "PATCH", "DELETE"}
    Menu.popup_menu(methods, {
      title = "Method",
      row = 0,
      col = 0,
      width = 15,
      height = #methods,
      callback = function(selection)
        self.view.state.set_state("method", methods[selection])
        return self.view:update()
      end,
    })
  end, "select http method")

  self.view:on_key("U", function()
    Menu.entry(state.url, {
      title = "URL",
      row = 0,
      col = Config.layout_config.col_width,
      width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
      submit_in_insert = true,
      callback = function(entry)
        self.view.state.set_state("url", entry[1])
        return self.view:update()
      end,
    })
  end, "enter URL")

  self.view:on_key("Q", function()
    Menu.entry(state.query_params, {
      title = "Query Parameters",
      row = 1,
      col = 0,
      width = 40,
      height = 20,
      filetype = "sh",
      callback = function(entry)
        self.view.state.set_state("query_params", Util.lines_to_kv(entry, "="))
        return self.view:update()
      end,
    })
  end, "set query params")

  self.view:on_key("B", function()
    if Util.is_body_method(state.method) then
      Menu.entry(state.body, {
        title = "Body",
        row = 1,
        col = Config.layout_config.col_width,
        width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
        height = self.view.win_opts.height - 4,
        filetype = "json",
        callback = function(entry)
          self.view.state.set_state("body", entry)
          return self.view:update()
        end,
      })
    end
  end, "set request body")

  self.view:on_key("H", function()
    Menu.entry(state.headers, {
      title = "Headers",
      row = 2,
      col = 0,
      width = 40,
      height = 20,
      separator = ": ",
      callback = function(entry)
        self.view.state.set_state("headers", Util.lines_to_kv(entry, ":"))
        return self.view:update()
      end,
    })
  end, "set request headers")

  self.view:on_key("E", function()
    self.view.show("env")
  end, "open environment variables page")

  self.view:on_key("R", function()
    local res = Util.http_request(state)
    self.view.state.set_state("res", res)
    return self.view:update()
  end, "make request")

  self.view:on_key("C", function()
    self.view.state.clear_state()
    return self.view:update()
  end, "clear all")
end

function M:env_commands()
  local state = self.view.state.get_state()

  self.view:on_key("B", function()
    self.view.show("main")
  end, "back to main page")

  self.view:on_key("S", function()
    local env = state.env

    if next(env.available) == nil then
      return
    end

    Menu.popup_menu(env.available, {
      title = "Select a file:",
      row = 0,
      col = Config.layout_config.col_width,
      width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
      height = #env.available,
      callback = function(selection)
        env.selected = env.available[selection]
        self.view.state.set_state("env", env)
        return self.view:update()
      end,
    })
  end, "select env file")

  self.view:on_key("E", function()
    if state.env.selected == nil then
      return
    end

    local env_lines = vim.fn.readfile(state.env.selected)
    Menu.entry(env_lines, {
      title = state.env.selected,
      row = 2,
      col = 0,
      width = self.view.win_opts.width - 2,
      height = self.view.win_opts.height - 4,
      callback = function(entry)
        vim.fn.writefile(entry, state.env.selected)
        return self.view:update()
      end,
    })
  end, "edit env file")
end

-- WIP
-- function M.collection_commands(view ,state)
  -- self.view:on_key("C", function()
  --   Menu.entry({"Collections"}, {
  --     title = "Collections",
  --     row = 2,
  --     col = 2 * Config.layout_config.col_width,
  --     width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
  --     height = self.view.win_opts.height - 6,
  --   })
  --   M.show("collection")
  -- end, "open collections page")
-- end

return M
