local Text = require("hyper.view.text")
local Config = require "hyper.config"
local Util = require "hyper.util"

local M = {}

function M.new(view)
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Text }) })
  self.view = view
  return self
end

function M:main()
  local state = self.view.state.get_state()
  local col_width = Config.layout_config.col_width

  local strings = {
    method = "[M]ethod: ",
    url = "[U]rl: ",
    query = "[P]arams (%d)",
    body = "[B]ody",
    headers = "[H]eaders (%d)",
    envars = "[E]nv Variables",
    request = "Make [R]equest",
    clear_all = "[C]lear All",
    response = "Response:",
    res_status = "STATUS %d",
    res_time = "TIME %dms",
  }

  -- request method and url
  self.view.render:append(table.concat{
    strings.method,
    state.method,
    string.rep(" ", col_width - #strings.method - #state.method),
    strings.url,
    state.url,
  })

  -- query parameters and body
  local params = string.format(strings.query, Util.dict_length(state.query_params))
  if Util.is_body_method(state.method) then
    self.view.render:append(table.concat({
      params,
      string.rep(" ", col_width - #params),
      strings.body,
    }))
  else
    self.view.render:append(params)
  end

  -- headers and env variables
  local headers = string.format(strings.headers, Util.dict_length(state.headers))
  self.view.render:append(table.concat({
    headers,
    string.rep(" ", col_width - #headers),
    strings.envars,
  }))

  -- request and clear all commands
  self.view.render:append("")
  self.view.render:append(table.concat({
    strings.request,
    string.rep(" ", col_width - #strings.request),
    strings.clear_all,
  }))

  -- response display
  self.view.render:append("")
  if state.res and state.res.status ~= nil then
    local body, extras = Util.parse_response_body(state.res.body)
    local res_time = body and math.floor(extras.response_time*1000) or 0

    self.view.render:append(strings.response)
    self:separator("-")

    local status = string.format(strings.res_status, state.res.status)
    local time = string.format(strings.res_time, res_time)
    self.view.render:append(table.concat({
      status,
      string.rep(" ", col_width - #status),
      time,
    }))

    self.view.render:append("")
    for _, line in ipairs(Util.pretty_format(body)) do
      self.view.render:append(line)
    end
  end
end

function M:env()
  Util.validate_env_files(self.view.state)
  local env = self.view.state.get_state("env")
  local col_width = Config.layout_config.col_width

  local strings = {
    back = "[B]ack",
    select = "[S]elect File",
    edit = "[E]dit File",
    nofiles = "No .env files found",
  }

  -- back, select file, edit file commands
  local menu_tt = {}
  table.insert(menu_tt, strings.back)
  if next(env.available) ~= nil then
    table.insert(menu_tt, string.rep(" ", col_width - #strings.back))
    table.insert(menu_tt, strings.select)
  end
  if env.selected ~= nil then
    table.insert(menu_tt, string.rep(" ", col_width - #strings.select))
    table.insert(menu_tt, strings.edit)
  end
  self.view.render:append(table.concat(menu_tt))

  -- env file display
  self.view.render:append("")
  if env.selected ~= nil then
    local env_lines = vim.fn.readfile(env.selected)
    self.view.render:append(env.selected)
    self:separator("-")
    for _, line in ipairs(env_lines) do
      self.view.render:append(line)
    end
  else
    self.view.render:append(strings.nofiles)
  end
end

-- WIP, might refactor
-- function M:collection()
--   local strings = {
--     home = "[O] Home",
--     new = "[N] New",
--   }
--
--   local found = Util.find_collections()
--   local existing = self.view.state.get_state("collections")
--   local updated = Util.load_collections(existing, found)
--   self.view.state.set_state("collections", updated)
--
--   self:collection_menu()
--   self:collection_body(updated)
-- end
--
-- function M:collection_menu()
--   local t = {
--     strings.collection.home,
--     string.rep(" ", col_width - #strings.collection.home),
--     strings.collection.new,
--   }
--   self:append(table.concat(t))
--   self:separator("-", vim.api.nvim_win_get_width(self.view.win))
--   self:append("")
-- end
--
-- function M:collection_body(collections)
--   local isEmpty = true
--   for _, v in pairs(collections) do
--     if (v.data.info.name ~= nil) then
--       isEmpty = false
--       self:append(v.data.info.name)
--       self:append("  Description: " .. v.data.info.description)
--       self:append("  Groups:")
--
--       for _, req in ipairs(v.data.item) do
--         self:append("    " .. req.name)
--       end
--     end
--   end
--
--   if (isEmpty) then
--     self:append("No collections found :(")
--   end
-- end

function M:separator(char)
  self.view.render:append(string.rep(char, vim.api.nvim_win_get_width(self.view.win)))
end

return M
