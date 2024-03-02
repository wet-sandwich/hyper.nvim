local M = {}

local default_state = {
  mode = "main",
  url = "",
  method = "GET",
  response = {},
  query_params = {},
  body = {},
  headers = {},
  variables = {},
  -- collections = {},
}

local example_state = {
  mode = "main",
  url = "https://echo.zuplo.io",
  method = "POST",
  response = {},
  query_params = {
    param = "value",
  },
  body = {"{","  \"my_var\": \"{{my_var}}\"","}"},
  headers = {
    ["User-Agent"] = "{{user}}",
  },
  variables = {
    user = "wet-sandwich",
    my_var = "foo",
  },
  -- collections = {},
}

function M.init()
  if vim.g.hyper then
    return
  end
  vim.g.hyper = example_state
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

function M.clear_state()
  vim.g.hyper = default_state
end

return M
