local Config = require("hyper.config")
local Util = require("hyper.util")

local M = {}

local default_state = {
  mode = "main",
  url = "",
  method = "GET",
  res = {},
  query_params = {},
  body = {},
  headers = {},
  env = {
    available = {},
    selected = nil,
  },
  -- collections = {},
}

local example_state = {
  mode = "main",
  url = "https://echo.zuplo.io",
  method = "POST",
  res = {},
  query_params = {
    param = "value",
  },
  body = {"{","  \"my_var\": \"{{my_var}}\"","}"},
  headers = {
    ["User-Agent"] = "{{user}}",
  },
  env = {
    available = {},
    selected = nil,
  },
  -- collections = {},
}

function M.init()
  if vim.g.hyper then
    return
  end
  M.read()
end

function M.get_state(key)
  if key then
    return vim.g.hyper[key]
  else
    return vim.g.hyper
  end
end

function M.set_state(key, value)
  local state = vim.g.hyper
  state[key] = value
  vim.g.hyper = state
  M.write()
end

function M.clear_state()
  vim.g.hyper = default_state
end

function M.read()
  local saved_state = {}
  if pcall(function()
    saved_state = vim.json.decode(Util.read_file(Config.options.state))
  end) then
    vim.g.hyper = saved_state
  else
    vim.g.hyper = example_state
  end
end

function M.write()
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.state, ":p:h"), "p")
  local state = vim.g.hyper
  state.res = nil
  Util.write_file(Config.options.state, vim.json.encode(state))
end

return M
