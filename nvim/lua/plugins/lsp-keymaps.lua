---@diagnostic disable: undefined-global

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "K", false },
            { "<leader>k", vim.lsp.buf.hover, desc = "LSP Hover", has = "hover" },
          },
        },
      },
    },
  },
}
