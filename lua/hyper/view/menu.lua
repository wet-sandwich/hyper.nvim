local M = {}

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

local function create_window(width, height, opts)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    style = "minimal",
    relative = "win",
    width = width,
    height = height,
    row = opts.row,
    col = opts.col,
    border = "rounded",
    title = opts.title,
  })

  return bufnr, winid
end

function M.popup_menu(entries, opts)
  local width = opts.width or 20
  local height = opts.height or 20

  local bufnr, winid = create_window(width, height, {
    title = opts.title or "Menu",
    row = opts.row or 1,
    col = opts.col or 1,
  })

  local lines = {}
  for _, v in ipairs(entries) do
    table.insert(lines, v .. string.rep(" ", width-1-#v) .. "↵")
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
  vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, {})

  vim.api.nvim_win_set_cursor(winid, {1,0})
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  vim.api.nvim_buf_add_highlight(bufnr, ns_hyper_selection, "PmenuSel", 0, 0, -1)

  vim.keymap.set("n", "<CR>", function()
    local pos = vim.fn.line(".")

    if opts.callback and type(opts.callback) == "function" then
      opts.callback(pos)
    else
      print("Selected option:", pos)
    end
    vim.api.nvim_win_close(winid, true)
  end, {
      nowait = true,
      buffer = bufnr,
    })

  local sel = 1

  vim.keymap.set("n", "j", function()
    sel = sel == #entries and #entries or sel + 1
    vim.api.nvim_buf_clear_namespace(bufnr, ns_hyper_selection, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, ns_hyper_selection, "PmenuSel", sel-1, 0, -1)
    vim.api.nvim_win_set_cursor(winid, {sel,0})
  end, {
      nowait = true,
      buffer = bufnr,
    })

  vim.keymap.set("n", "k", function()
    sel = sel == 1 and 1 or sel - 1
    vim.api.nvim_buf_clear_namespace(bufnr, ns_hyper_selection, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, ns_hyper_selection, "PmenuSel", sel-1, 0, -1)
    vim.api.nvim_win_set_cursor(winid, {sel,0})
  end, {
      nowait = true,
      buffer = bufnr,
    })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(winid, true)
  end, {
      nowait = true,
      buffer = bufnr
    })
end

function M.entry(value, opts)
  local width = opts.width or 100
  local height = opts.height or 1

  local bufnr, winid = create_window(width, height, {
    title = opts.title or "Entry",
    row = opts.row or 1,
    col = opts.col or 1,
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

  vim.keymap.set("n", "q", function()
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
