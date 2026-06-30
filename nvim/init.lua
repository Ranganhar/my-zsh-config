-- ~/.config/nvim/init.lua
 require("config.lazy")

  vim.opt.cursorline = true
  vim.api.nvim_set_hl(0, "CursorLine", {
    bg = "#313640",
  })

