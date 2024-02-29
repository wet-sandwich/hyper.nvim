local M = {}

setmetatable(M, {
  __call = function(_, ...)
    return M.new(...)
  end,
})

function M.new(...)
  local self = setmetatable({}, { __index = M })
  return self:init()
end

function M:init(opts)
  local w = vim.o.columns
  local h = vim.o.lines
  local mh = 40
  local mv = 5

  self.opts = vim.deepcopy(opts)

  self.win_opts = {
    style = "minimal",
    relative = "editor",
    width = w - 2*mh,
    height = h - 2*mv,
    row = mv,
    col = mh,
    border = "rounded",
    title = self.opts.title,
    title_pos = self.opts.title_pos,
    noautocmd = self.opts.noautocmd,
  }

  self:mount()
  self:on_key("q", self.close, "close window", "all")
  return self
end

function M:mount()
  if self:buf_valid() then
    self.buf = self.buf
  else
    self.buf = vim.api.nvim_create_buf(false, true)
  end

  self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)
end

function M:on_key(key, fn, desc, mode)
  vim.keymap.set("n", key, function()
    local current_mode = self.state.get_state("mode")
    mode = mode == nil and "main" or mode
    if current_mode == mode or mode == "all" then
      fn(self)
    end
  end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
end

function M:close()
  local buf = self.buf
  local win = self.win

  self.win = nil
  vim.schedule(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

function M:buf_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function M:focus()
  vim.api.nvim_set_current_win(self.win)

  if vim.v.vim_did_enter ~= 1 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if self.win and vim.api.nvim_win_is_valid(self.win) then
          pcall(vim.api.nvim_set_current_win, self.win)
        end
        return true
      end,
    })
  end
end

return M
