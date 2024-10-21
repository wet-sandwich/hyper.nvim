vim.api.nvim_create_user_command("Hyper", function(cmd)
  require("hyper.core").open()
end, {})

vim.api.nvim_create_user_command("HyperJump", function(cmd)
  require("hyper.core").jump()
end, {})
