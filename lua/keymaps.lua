-- ~/.config/nvim/lua/keymaps.lua
-- 通用快捷键。竞赛的编译/运行键在 lua/cp.lua 里。

local map = vim.keymap.set

-- ── 编辑 ──────────────────────────────────────────────────────────────
map('n', '<C-A>', 'ggVG', { desc = '全选', silent = true })   -- 原配置保留
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = '清除搜索高亮', silent = true })

-- ── 窗口切换 ──────────────────────────────────────────────────────────
map('n', '<C-h>', '<C-w>h', { desc = '切到左窗口' })
map('n', '<C-j>', '<C-w>j', { desc = '切到下窗口' })
map('n', '<C-k>', '<C-w>k', { desc = '切到上窗口' })
map('n', '<C-l>', '<C-w>l', { desc = '切到右窗口' })

-- ── 剪贴板 ────────────────────────────────────────────────────────────
-- 和 Windows 交互只有这两个键，别的路径一律不碰系统剪贴板。
-- y/d/p 走 nvim 内部寄存器，0ms；带 "+ 才去起 powershell（~200ms，WSL 下绕不开，
-- 原因见 options.lua）。复制整份文件就是 <C-A>（= ggVG）再 <C-C>。
map('v', '<C-C>', '"+y', { desc = '复制到 Windows 剪贴板' })
map({ 'n', 'v' }, '<C-V>', '"+P', { desc = '从 Windows 剪贴板粘贴（~200ms）' })
