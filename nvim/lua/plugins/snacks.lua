return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true, -- 显示 .gitignore / .env / .github 等隐藏文件
        ignored = true, -- 显示被 .gitignore 忽略的文件
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
          files = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
