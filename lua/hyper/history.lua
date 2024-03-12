local Util = require("hyper.util")
local Config = require("hyper.config")

local M = {}

local history = nil

local initial = {
  order = {},
  requests = {},
}

function M.read()
  pcall(function()
    history = vim.json.decode(Util.read_file(Config.options.history))
  end)
  history = vim.tbl_deep_extend("force", {}, initial, history or {})
end

function M.write()
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.history, ":p:h"), "p")
  Util.write_file(Config.options.history, vim.json.encode(history))
end

function M.__index(_, key)
  if not history then
    M.read()
  end
  if not history then
    return nil
  end
  return history[key]
end

function M.add_item(state)
  if not history then
    M.read()
  end
  if not history then
    return
  end

  local request = state
  request.env = nil
  request.res = nil
  request.mode = nil
  if not Util.is_body_method(request.method) then
    request.body = nil
  end

  local json = nil
  pcall(function()
    json = vim.json.encode(request)
  end)
  if json == nil then
    error("Error encoding request to JSON")
    return
  end

  local id = Util.hash_http_request(request)
  if history.requests[id] ~= nil then
    -- already exists in history, move to top of order array
    for i, v in ipairs(history.order) do
      if v == id then
        if i == 1 then return end
        table.remove(history.order, i)
        table.insert(history.order, 1, id)
        M.write()
        return
      end
    end
  end

  history.requests[id] = json
  if history.order ~= nil then
    if #history.order == Config.options.max_history then
      local last_id = table.remove(history.order)
      history.requests[last_id] = nil
    end
    table.insert(history.order, 1, id)
  end

  M.write()
end

return setmetatable(M, M)
