local hyper = require("hyper")

local uv = vim.loop
local http = require("hyper.http-parser")

local M = {}

local function find_collections()
  local paths = vim.fs.find(function(name, _)
    return name:match('.*%.http$')
  end, {
      limit = hyper.opts.search_depth,
      type = 'file',
    })

  local collections = {}
  for _, path in ipairs(paths) do
    local stat = uv.fs_stat(path)
    local modtime = stat and stat.mtime.sec or os.time()

    collections[path] = modtime
  end

  return collections
end

local function read_collection(path)
  local lines = {}
  for line in io.lines(path) do
    lines[#lines + 1] = line
  end

  return http.parse(lines)
end

function M.sync_collections(State)
  local collections = State.get_state("collections")
  local available_collections = find_collections()

  local items_to_add = vim.deepcopy(available_collections)
  local items_to_update = {}
  local items_to_remove = {}

  for i, collection in ipairs(collections) do
    if available_collections[collection.path] == nil then
      -- collection file was removed, mark to remove from state
      table.insert(items_to_remove, i)
      break
    end

    if available_collections[collection.path] ~= collection.modtime then
      table.insert(items_to_update, i)
    end

    items_to_add[collection.path] = nil
  end

  -- update collections
  for _, i in ipairs(items_to_update) do
    local path = collections[i].path
    collections[i].modtime = available_collections[path]
    collections[i].requests = read_collection(path)
  end

  -- remove collections
  table.sort(items_to_remove, function(a, b) return a > b end)
  for _, i in ipairs(items_to_remove) do
    table.remove(collections, i)
  end

  -- add new collection
  for path, _ in pairs(items_to_add) do
    table.insert(collections, {
      path = path,
      modtime = available_collections[path],
      name = string.match(path, ".*/(.*)%.http$"),
      requests = read_collection(path)
    })
  end

  State.set_state("collections", collections)
end

return M
