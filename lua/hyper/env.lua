local Env = {}

local function find_env_files()
  local env_paths = vim.fs.find(function(name, _)
    return name:match('^%.env.*') or name:match('.*%.env')
  end, {
      limit = 4,
      type = 'file',
    })

  return env_paths
end

function Env.init()
  local self = {}
  -- local self = setmetatable({}, { __index = Env })

  local env_paths = find_env_files()
  self.available = env_paths

  if #env_paths == 1 then
    self.selected = env_paths[1]
  elseif #env_paths > 1 then
    for _, file in ipairs(env_paths) do
      if vim.fs.basename(file) == ".env" then
        self.selected = file
        break
      end
    end
  else
    self.selected = nil
  end

  return self
end

return Env
