local hyper = require("hyper")

local M = {}

function M.update_env_files(State)
  local env = State.get_state("env")
  local env_files = vim.fs.find(function(name, _)
    return name:match('^%.env.*') or name:match('.*%.env')
  end, {
      limit = hyper.opts.search_depth,
      type = 'file',
    })

  -- check if env files are (still) there
  if next(env_files) == nil then
    -- if files no longer exist then reset env state
    if #env.available > 0 then
      env.available = {}
      env.selected = nil
      State.set_state("env", env)
    end
    return
  end

  env.available = env_files

  if env.selected then
    State.set_state("env", env)
    return
  end

  if #env_files > 1 then
    for _, file in ipairs(env_files) do
      if vim.fs.basename(file) == ".env" then
        env.selected = file
        State.set_state("env", env)
        return
      end
    end
  end

  env.selected = env_files[1]
  State.set_state("env", env)
end

return M
