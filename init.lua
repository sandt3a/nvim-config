-- ~/.config/nvim/init.lua
-- 现代 Vim 配置（算法竞赛向）。原 ~/.vimrc 仍然保留，vanilla vim 不受影响。
--
-- 目录结构：
--   lua/options.lua   基础选项
--   lua/keymaps.lua   通用快捷键
--   lua/cp.lua        模板自动填充 + 一键编译运行
--   lua/plugins.lua   用内置 vim.pack 装的两个插件
--   local.lua         本机路径配置（可选，不纳入 Git，见 local.lua.example）

if vim.fn.has('nvim-0.12') == 0 then
  error('此配置需要 Neovim 0.12 或更新版本（使用 vim.pack 和 sorbet）')
end

-- 在加载 cp.lua 前读取本机模板路径；没有 local.lua 时沿用原来的默认路径。
local local_config = vim.fn.stdpath('config') .. '/local.lua'
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end

-- leader 必须在插件加载前设好（mini.nvim / fzf-lua 会在 setup 时读它）
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('options')
require('cp')
require('plugins')
require('keymaps')
