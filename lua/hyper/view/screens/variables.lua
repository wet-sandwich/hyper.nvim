local File = require("hyper.view.file-preview")
local Radio = require("hyper.view.radio")
local Screen = require("hyper.view.screen")
local Util = require("hyper.util")

local width, height, row, col = Util.get_viewbox()
local list_width = math.floor(width * 0.4)

local M = {}

function M.new(State)
  local env = State.get_state("env")
  local function sync_selection()
    if env.selected ~= nil then
      for i, path in ipairs(env.available) do
        if path == env.selected then
          return i - 1
        end
      end
    end
    return 0
  end

  local env_file_selector = Radio.new({
    title = "Available Files",
    row = row,
    col = col,
    width = list_width,
    height = height,
    options = env.available,
  }, sync_selection)

  local preview_win = File.new({
    title = "File Preview",
    row = row,
    col = col + list_width + 2,
    width = width - list_width - 2,
    height = height,
    enter = true,
    filetype = "sh",
  })

  if env.selected ~= nil then
    preview_win:set_file(env.selected)
  end

  preview_win:add_autocmd("BufLeave", {
    callback = function()
      preview_win:save()
    end
  })

  local VariablesScreen = Screen.new({ env_file_selector, preview_win })

  preview_win:add_keymap({"n", "<c-n>", function()
    preview_win:save()
    env_file_selector:hover_next()
    local file = env.available[env_file_selector.hover + 1]
    preview_win:set_file(file)
    preview_win:render()
  end})

  preview_win:add_keymap({"n", "<c-p>", function()
    preview_win:save()
    env_file_selector:hover_previous()
    local file = env.available[env_file_selector.hover + 1]
    preview_win:set_file(file)
    preview_win:render()
  end})

  preview_win:add_keymap({"n", "<Tab>", function()
    env_file_selector:select()
    env.selected = env.available[env_file_selector.selection + 1]
    State.set_state("env", env)
    preview_win:set_file(env.selected)
    preview_win:render()
  end})

  return VariablesScreen
end

return M
