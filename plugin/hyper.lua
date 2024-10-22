vim.api.nvim_create_user_command("Hyper", function(cmd)
  require("hyper.drive").open()
end, {})

vim.api.nvim_create_user_command("HyperJump", function(cmd)
  require("hyper.drive").jump()
end, {})
