local Text = require "hyper.view.text"
local Util = require "hyper.util"
local Config = require "hyper.config"

local M = {}

local col_width = Config.layout_config.col_width
local strings = {
  home = {
    method = "[M]ethod: ",
    url = "[U]rl: ",
    query = "[Q]uery Params (%d)",
    body = "[B]ody",
    headers = "[H]eaders (%d)",
    envars = "[E]nv Variables",
    request = "Make [R]equest",
    clear = "[C]lear All",
    -- collection = "[C]ollections",
  },
  -- collection = {
  --   home = "[O] Home",
  --   new = "[N] New",
  -- },
}

function M.new(view)
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Text }) })
  self.view = view
  return self
end

function M:update()
  self._lines = {}

  local mode = self.view.state.get_state("mode")

  if mode == "main" then
    self:main()
  elseif mode == "collection" then
    self:collection()
  end

  self:render(self.view.buf)
end

function M:main()
  self:method_url()
  self:query_params_and_body()
  self:headers_vars_collections()
  self:request_and_clear()
  self:response()
  self:trim()
end

function M:method_url()
  local state = self.view.state.get_state()
  local t = {
    strings.home.method,
    state.method,
    string.rep(" ", col_width - #strings.home.method - #state.method),
    strings.home.url,
    state.url,
  }
  self:append(table.concat(t))
end

function M:query_params_and_body()
  local state = self.view.state.get_state()
  local query = string.format(strings.home.query, Util.dict_length(state.query_params))

  if Util.is_body_method(state.method) then
    local t = {
      query,
      string.rep(" ", col_width - #query),
      strings.home.body,
    }
    self:append(table.concat(t))
  else
    self:append(query)
  end
end

function M:headers_vars_collections()
  local state = self.view.state.get_state()
  local headers = string.format(strings.home.headers, Util.dict_length(state.headers))

  local t = {
    headers,
    string.rep(" ", col_width - #headers),
    strings.home.envars,
    -- string.rep(" ", col_width - #strings.home.envars),
    -- strings.home.collection,
  }
  self:append(table.concat(t))
end

function M:request_and_clear()
  self:append("")
  local t = {
    strings.home.request,
    string.rep(" ", col_width - #strings.home.request),
    strings.home.clear,
  }
  self:append(table.concat(t))
end

function M:response()
  self:append("")

  local res = self.view.state.get_state("res")
  if res and res.status ~= nil then
    local body, extras = Util.parse_body(res.body)
    local res_time = body and math.floor(extras.response_time*1000) or 0

    self:append("Response:")

    self:append(string.rep("-", vim.api.nvim_win_get_width(self.view.win)))

    self:append("STATUS " .. res.status .. "        " .. "TIME " .. res_time .. "ms")
    self:append("")

    local body_lines = Util.pretty_format(body)
    for _, line in ipairs(body_lines) do
      self:append(line)
    end
  end
end

-- WIP, might refactor
-- function M:collection()
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

return M
