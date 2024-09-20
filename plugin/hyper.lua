local View = require "hyper.view"

vim.api.nvim_create_user_command("Hyper", function(cmd)
  View.show()
end, {})

vim.api.nvim_create_user_command("HyperJump", function(cmd)
  View.jump()
end, {})
