local Fs = require("hyper.utils.fs")
local hyper = require("hyper")

local M = {}

local data = {}

local default_state = {
  mode = "main",
  url = "",
  method = "GET",
  res = nil,
  query_params = {},
  body = {"{}"},
  headers = {},
  env = {
    available = {},
    selected = nil,
  },
  collections = {},
}

function M.init()
  if next(data) ~= nil then
    return
  end
  M.read()
end

function M.get_state(key)
  if next(data) == nil then
    M.read()
  end
  if key then
    return data[key]
  else
    return data
  end
end

function M.set_state(key, value)
  data[key] = value
  M.write()
end

function M.clear_state()
  data = vim.deepcopy(default_state)
  M.write()
end

function M.read()
  local saved_state = {}
  if pcall(function()
    saved_state = vim.json.decode(Fs.read_file(hyper.state_path))
  end) then
    data = vim.tbl_deep_extend("force", default_state, saved_state)
  else
    data = default_state
  end
end

function M.write()
  vim.fn.mkdir(vim.fn.fnamemodify(hyper.state_path, ":p:h"), "p")
  local state = vim.deepcopy(data)
  state.res = nil
  state.mode = nil
  Fs.write_file(hyper.state_path, vim.json.encode(state))
end

return M
