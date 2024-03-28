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
  -- collections = {},
}

function M.init()
  if next(data) == nil then
    data = vim.deepcopy(default_state)
  end
end

function M.get_state(key)
  if key then
    return data[key]
  else
    return data
  end
end

function M.set_state(key, value)
  data[key] = value
end

return M
