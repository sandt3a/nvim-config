if vim.fn.has('nvim-0.12') == 0 then
  error('This config requires Neovim 0.12+ (vim.pack and sorbet)')
end

local local_config = vim.fn.stdpath('config') .. '/local.lua'
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('options')
require('cp')
require('plugins')
require('keymaps')
