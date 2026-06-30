---@diagnostic disable: undefined-global
vim.keymap.set("n", "<C-n>", "<cmd>nohlsearch<CR>", {
  noremap = true,
  silent = true,
})
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "J", "5j", opts)
vim.keymap.set("n", "K", "5k", opts)
vim.keymap.set("n", "H", "^", opts)
vim.keymap.set("n", "L", "g_", opts)
vim.keymap.set("n", "E", "3e", opts)
vim.keymap.set("n", "B", "3b", opts)

-- =========================
-- Insert 模式：单步移动
-- =========================
vim.keymap.set("i", "<C-h>", "<Left>", opts)
vim.keymap.set("i", "<C-j>", "<Down>", opts)
vim.keymap.set("i", "<C-k>", "<Up>", opts)
vim.keymap.set("i", "<C-l>", "<Right>", opts)

-- =========================
-- Visual 模式：单步扩展/移动选区
-- =========================
vim.keymap.set("x", "<C-h>", "h", opts)
vim.keymap.set("x", "<C-j>", "j", opts)
vim.keymap.set("x", "<C-k>", "k", opts)
vim.keymap.set("x", "<C-l>", "l", opts)

-- =========================
-- Insert 模式：快速移动 5 格
-- =========================
vim.keymap.set("i", "<A-h>", "<C-o>5h", opts)
vim.keymap.set("i", "<A-j>", "<C-o>5j", opts)
vim.keymap.set("i", "<A-k>", "<C-o>5k", opts)
vim.keymap.set("i", "<A-l>", "<C-o>5l", opts)

-- =========================
-- Visual 模式：快速扩展/移动选区 5 格
-- =========================
vim.keymap.set("x", "<A-h>", "5h", opts)
vim.keymap.set("x", "<A-j>", "5j", opts)
vim.keymap.set("x", "<A-k>", "5k", opts)
vim.keymap.set("x", "<A-l>", "5l", opts)

-- =========================
-- Insert 模式：按 word 移动
-- =========================
vim.keymap.set("i", "<A-e>", "<C-o>e", opts)
vim.keymap.set("i", "<A-b>", "<C-o>b", opts)

vim.keymap.set("i", "<A-S-e>", "<C-o>3e", opts)
vim.keymap.set("i", "<A-S-b>", "<C-o>3b", opts)

-- =========================
-- Visual 模式：按 word 扩展/移动选区
-- =========================
vim.keymap.set("x", "<A-e>", "e", opts)
vim.keymap.set("x", "<A-b>", "b", opts)

vim.keymap.set("x", "<A-S-e>", "3e", opts)
vim.keymap.set("x", "<A-S-b>", "3b", opts)
