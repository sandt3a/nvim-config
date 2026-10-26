local map = vim.keymap.set

map('n', '<C-A>', 'ggVG', { desc = 'Select all', silent = true })
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight', silent = true })

map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

map('v', '<C-C>', '"+y', { desc = 'Copy to Windows clipboard' })
map({ 'n', 'v' }, '<C-V>', '"+P', { desc = 'Paste from Windows clipboard (~200ms)' })
