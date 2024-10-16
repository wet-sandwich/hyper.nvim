local Fs = require("hyper.utils.fs")
local Http = require("hyper.utils.http")
local Config = require("hyper.config")

local M = {}

local history = nil

local initial = {
  order = {},
  requests = {},
}

function M.read()
  pcall(function()
    history = vim.json.decode(Fs.read_file(Config.options.history))
  end)
  history = vim.tbl_deep_extend("force", {}, initial, history or {})
end

function M.write()
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.history, ":p:h"), "p")
  Fs.write_file(Config.options.history, vim.json.encode(history))
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

  local request = vim.deepcopy(state)
  request.status = request.res.status
  request.env = nil
  request.res = nil
  request.mode = nil
  if not Http.is_body_method(request.method) then
    request.body = nil
  end

  local timestamp = vim.fn.strftime("%b %d %Y %T")
  local id = Http.hash_http_request(request)
  if history.requests[id] ~= nil then
    -- request already exists in history, move to top of order array
    for order, existing_id in ipairs(history.order) do
      if existing_id == id then
        if order ~= 1 then
          table.remove(history.order, order)
          table.insert(history.order, 1, id)
        end
        history.requests[id].timestamp = timestamp
        history.requests[id].status = request.status
        M.write()
        return
      end
    end
  end

  request.timestamp = timestamp
  history.requests[id] = request
  if history.order ~= nil then
    if #history.order == Config.options.max_history then
      local last_id = table.remove(history.order)
      history.requests[last_id] = nil
    end
    table.insert(history.order, 1, id)
  end

  M.write()
end

function M.delete_item(index)
  if not history then
    M.read()
  end
  if not history then
    return
  end

  local id = history.order[index]

  history.requests[id] = nil
  table.remove(history.order, index)

  M.write()
end

return setmetatable(M, M)
