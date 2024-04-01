local M = {}

local ns_hyper_selection = vim.api.nvim_create_namespace("hyper_selection")

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

-- [[Select Menu]]

function M.select_menu(entries, opts)
  local width = opts.width or 20
  local height = #entries

  local bufnr, winid = create_window(width, height, {
    title = opts.title or "Menu",
    row = opts.row or (vim.o.lines - height) / 2 - 1,
    col = opts.col or (vim.o.columns - width) / 2 - 1,
  })

  local lines = {}
  for _, v in ipairs(entries) do
    table.insert(lines, v .. string.rep(" ", width))
  end

  local sel = 1
  local action_icon = "↵"

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.api.nvim_win_set_cursor(winid, {1,0})
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  local hl_id = vim.api.nvim_buf_set_extmark(bufnr, ns_hyper_selection, sel - 1, 0, {
    end_col = width,
    hl_group = "PmenuSel",
  })
  local vt_id = vim.api.nvim_buf_set_extmark(bufnr, ns_hyper_selection, sel - 1, width - 1, {
    virt_text = {{action_icon, "PmenuSel"}},
    virt_text_pos = "overlay",
  })

  local function update_highlight()
    vim.api.nvim_buf_set_extmark(bufnr, ns_hyper_selection, sel - 1, 0, {
      end_col = width,
      hl_group = "PmenuSel",
      id = hl_id,
    })
    vim.api.nvim_buf_set_extmark(bufnr, ns_hyper_selection, sel - 1, width - 1, {
      virt_text = {{action_icon, "PmenuSel"}},
      virt_text_pos = "overlay",
      id = vt_id,
    })
  end

  local function set_keymap(key, func)
    vim.keymap.set("n", key, func, {
      nowait = true,
      buffer = bufnr,
    })
  end

  local function sel_next()
    sel = sel == #entries and #entries or sel + 1
    vim.api.nvim_win_set_cursor(winid, {sel,0})
    update_highlight()
  end

  local function sel_prev()
    sel = sel == 1 and 1 or sel - 1
    vim.api.nvim_win_set_cursor(winid, {sel,0})
    update_highlight()
  end

  local function close()
    vim.api.nvim_win_close(winid, true)
  end

  set_keymap("<CR>", function()
    local pos = vim.fn.line(".")
    if opts.callback and type(opts.callback) == "function" then
      opts.callback(pos)
    else
      print("Selected option:", pos)
    end
    vim.api.nvim_win_close(winid, true)
  end)

  set_keymap("j", sel_next)
  set_keymap("<c-n>", sel_next)
  set_keymap("k", sel_prev)
  set_keymap("<c-p>", sel_prev)

  set_keymap("q", close)
  set_keymap("<c-c>", close)
end

-- [[Entry Menu]]

function M.entry(value, opts)
  local width = opts.width or 100
  local height = opts.height or 1

  local title = "🞂%s ↵ "

  local bufnr, winid = create_window(width, height, {
    title = title:format(opts.title or "Entry"),
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

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(winid, true)
  end, {
    nowait = true,
    buffer = bufnr
  })

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
