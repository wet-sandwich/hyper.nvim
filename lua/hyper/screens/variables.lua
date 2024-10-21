local File = require("hyper.ui.file")
local Radio = require("hyper.ui.radio")
local Screen = require("hyper.ui.screen")
local Ui = require("hyper.utils.ui")

local width, height, row, col = Ui.get_viewbox()
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

  local function relative_paths()
    local paths = {}
    for _, path in ipairs(env.available) do
      table.insert(paths, vim.fn.fnamemodify(path, ":."))
    end
    return paths
  end

  local file_picker = Radio.new({
    title = "Available Files",
    row = row,
    col = col,
    width = list_width,
    height = height,
    options = relative_paths(),
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

  local VariablesScreen = Screen.new(State, "variables", { file_picker, preview_win })

  preview_win:add_keymap({"n", "<c-n>", function()
    preview_win:save()
    file_picker:hover_next()
    local file = env.available[file_picker.hover + 1]
    preview_win:set_file(file)
    preview_win:render()
  end})

  preview_win:add_keymap({"n", "<c-p>", function()
    preview_win:save()
    file_picker:hover_previous()
    local file = env.available[file_picker.hover + 1]
    preview_win:set_file(file)
    preview_win:render()
  end})

  preview_win:add_keymap({"n", "<Tab>", function()
    if #env.available == 0 then return end

    file_picker:select()
    env.selected = env.available[file_picker.selection + 1]
    State.set_state("env", env)
    preview_win:set_file(env.selected)
    preview_win:render()
  end})

  return VariablesScreen
end

return M
