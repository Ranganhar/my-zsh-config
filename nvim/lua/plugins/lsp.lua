return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      keys = {
        { "K", false },
        {
          "<leader>k",
          vim.lsp.buf.hover,
          desc = "LSP Hover",
        },
      },
    },
  },
}
