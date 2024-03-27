local window = {}

window.create = function(bufnr, win, opts)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
  end

  if not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(bufnr, false, opts)
  end

  vim.wo[win].wrap = true
  vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:Normal"

  return bufnr, win
end

window.buf_del = function(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end

  return -1
end

window.win_del = function(win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end

  return -1
end

-- window.calculate_width = function(width)
--   if width > 1 then
--     return math.floor(width)
--   else
--     return math.floor(width * vim.o.columns)
--   end
-- end
--
-- window.calculate_height = function(height)
--   if type(height) == "string" then
--     error "i'll do this later"
--   elseif height > 1 then
--     return height
--   else
--     return math.floor(height * vim.o.lines)
--   end
-- end
--
-- window.make_win_minimal = function(win)
--   local options = {
--     number = false,
--     relativenumber = false,
--     cursorline = false,
--     cursorcolumn = false,
--     list = false,
--     signcolumn = "auto",
--     wrap = true,
--     winhighlight = "Normal:Normal,FloatBorder:Normal",
--   }
--
--   for key, value in pairs(options) do
--     vim.wo[win][key] = value
--   end
--
--   vim.wo[win].statuscolumn = nil
--   vim.opt_local.fillchars:append { eob = " " }
-- end
--
-- window.make_buf_minimal = function(bufnr)
--   vim.bo[bufnr].buflisted = false
--   vim.bo[bufnr].modified = false
--   vim.bo[bufnr].buftype = "nofile"
-- end

return window
