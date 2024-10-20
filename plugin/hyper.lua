vim.api.nvim_create_user_command("Hyper", function(cmd)
  require("hyper.view").show()
end, {})

vim.api.nvim_create_user_command("HyperJump", function(cmd)
  require("hyper.view").jump()
end, {})
