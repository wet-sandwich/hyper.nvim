local M = {}

local default_state = {
  mode = "main",
  url = "https://echo.zuplo.io",
  method = "GET",
  response = {},
  query_params = {
    param = "value",
  },
  body = {"{}"},
  headers = {
    ["User-Agent"] = "user",
  },
  variables = {
    user = "wet-sandwich",
    my_var = "foo",
  },
  collections = {},
}

function M.init()
  if vim.g.hyper then
    return
  end
  vim.g.hyper = default_state
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
end

return M
