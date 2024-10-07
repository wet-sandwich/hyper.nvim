local Config = require("hyper.config")

local M = {}

local function create_window(width, height, opts)
  vim.o.eventignore = "BufLeave"

  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    style = "minimal",
    relative = opts.relative or "win",
    width = width,
    height = height,
    row = opts.row,
    col = opts.col,
    border = "rounded",
    title = opts.title,
  })

  vim.o.eventignore = ""

  return bufnr, winid
end

-- [[Entry Menu]]

function M.entry(value, opts)
  local width = opts.width or 100
  local height = opts.height or 1

  local title = opts.overlay and ("🞂🞂 %s ↵ 🞀🞀"):format(opts.title) or opts.title

  local bufnr, winid = create_window(width, height, {
    title = title,
    row = opts.row or -1,
    col = opts.col or -1,
  })

  local lines = {}
  if type(value) == "string" then
    table.insert(lines, value)
  else
    opts.separator = opts.separator or "="
    if value[1] == nil then
      for k, v in pairs(value) do
        table.insert(lines, k .. opts.separator .. v)
      end
    else
      for _, v in ipairs(value) do
        table.insert(lines, v)
      end
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
  vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, {})

  if opts.filetype ~= nil then
    vim.bo.ft = opts.filetype
  end

  vim.keymap.set("n", "<c-c>", function()
    vim.api.nvim_win_close(winid, true)
  end, {
    nowait = true,
    buffer = bufnr
  })

  local on_enter_modes = opts.submit_in_insert and {"n", "i"} or "n"

  vim.keymap.set(on_enter_modes, "<CR>", function()
    local entry = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if opts.callback and type(opts.callback) == "function" then
      opts.callback(entry)
    else
      print(entry)
    end

    local current_mode = vim.api.nvim_get_mode()
    if current_mode.mode == "i" then
      local key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(key, "i", true)
    end

    vim.api.nvim_win_close(winid, true)
  end, {
      nowait = true,
      buffer = bufnr,
  })
end

return M
