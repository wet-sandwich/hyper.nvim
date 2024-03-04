local Float = require("hyper.view.float")
local Render = require("hyper.view.render")
local Menu = require("hyper.view.menu")
local Util = require("hyper.util")
local State = require("hyper.state")
local Config = require("hyper.config")

local M = {}

M.view = nil

function M.visible()
  return M.view and M.view.win and vim.api.nvim_win_is_valid(M.view.win)
end

function M.show(mode)
  M.view = M.visible() and M.view or M.create()
  if mode then
    M.view.state.set_state("mode", mode)
  end
  M.view:update()
end

function M.create()
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Float }) })

  self.state = State
  self.state.init()

  Float.init(self, {
    title = "Hyper",
    title_pos = "center",
    noautocmd = true,
  })

  self.render = Render.new(self)

  self:setup_commands()

  return self
end

function M:update()
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    vim.bo[self.buf].modifiable = true
    self.render:update()
    vim.bo[self.buf].modifiable = false
    vim.cmd.redraw()
    self:setup_commands()
  end
end

function M:setup_commands()
  local state = self.state.get_state()

  if state.mode == "main" then
    self:on_key("M", function()
      local methods = {"GET", "PUT", "POST", "PATCH", "DELETE"}
      Menu.popup_menu(methods, {
        title = "Method",
        row = 0,
        col = 0,
        width = 15,
        height = #methods,
        callback = function(selection)
          self.state.set_state("method", methods[selection])
          return self:update()
        end,
      })
    end, "select http method")

    self:on_key("U", function()
      Menu.entry(state.url, {
        title = "URL",
        row = 0,
        col = Config.layout_config.col_width,
        width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
        submit_in_insert = true,
        callback = function(entry)
          self.state.set_state("url", entry[1])
          return self:update()
        end,
      })
    end, "enter URL")

    self:on_key("Q", function()
      Menu.entry(state.query_params, {
        title = "Query Parameters",
        row = 1,
        col = 0,
        width = 40,
        height = 20,
        filetype = "sh",
        callback = function(entry)
          self.state.set_state("query_params", Util.lines_to_kv(entry, "="))
          return self:update()
        end,
      })
    end, "set query params")

    self:on_key("B", function()
      if Util.is_body_method(state.method) then
        Menu.entry(state.body, {
          title = "Body",
          row = 1,
          col = Config.layout_config.col_width,
          width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
          height = self.view.win_opts.height - 4,
          filetype = "json",
          callback = function(entry)
            self.state.set_state("body", entry)
            return self:update()
          end,
        })
      end
    end, "set request body")

    self:on_key("H", function()
      Menu.entry(state.headers, {
        title = "Headers",
        row = 2,
        col = 0,
        width = 40,
        height = 20,
        separator = ": ",
        callback = function(entry)
          self.state.set_state("headers", Util.lines_to_kv(entry, ":"))
          return self:update()
        end,
      })
    end, "set request headers")

    self:on_key("E", function()
      M.show("vars")
    end, "open environment variables page")

    self:on_key("R", function()
      local res = Util.http_request(state)
      self.state.set_state("res", res)
      return self:update()
    end, "make request")

    self:on_key("C", function()
      self.state.clear_state()
      return self:update()
    end, "clear all")
  end

  if state.mode == "vars" then
    self:on_key("B", function()
      M.show("main")
    end, "back to main page")

    self:on_key("S", function()
      local vars = state.variables
      Menu.popup_menu(vars.paths, {
        title = "Select a file:",
        row = 0,
        col = Config.layout_config.col_width,
        width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
        height = #vars.paths,
        callback = function(selection)
          vars.selection = vars.paths[selection]
          self.state.set_state("variables", vars)
          return self:update()
        end,
      })
    end, "select env file")

    self:on_key("E", function()
      local env_lines = vim.fn.readfile(state.variables.selection)
      Menu.entry(env_lines, {
        title = state.variables.selection,
        row = 2,
        col = 0,
        width = self.view.win_opts.width - 2,
        height = self.view.win_opts.height - 4,
        callback = function(entry)
          vim.fn.writefile(entry, state.variables.selection)
          return self:update()
        end,
      })
    end, "edit env file")
  end

  -- WIP
  -- self:on_key("C", function()
  --   Menu.entry({"Collections"}, {
  --     title = "Collections",
  --     row = 2,
  --     col = 2 * Config.layout_config.col_width,
  --     width = self.view.win_opts.width - 2 * Config.layout_config.col_width,
  --     height = self.view.win_opts.height - 6,
  --   })
  --   M.show("collection")
  -- end, "open collections page")
end

return M
