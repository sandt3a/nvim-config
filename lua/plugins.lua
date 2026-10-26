vim.pack.add({
  'https://github.com/echasnovski/mini.comment',
  'https://github.com/ibhagwan/fzf-lua',
})

local missing = {}
local function setup(mod, fn)
  local ok, m = pcall(require, mod)
  if ok then fn(m) else missing[#missing + 1] = mod end
  return ok
end

setup('mini.comment', function(m) m.setup() end)

if setup('fzf-lua', function(m)
  m.setup()
end) then
  local fzf = require('fzf-lua')
  local map = vim.keymap.set
  map('n', '<leader>ff', fzf.files,     { desc = 'Find files' })
  map('n', '<leader>fg', fzf.live_grep, { desc = 'Search in project' })
  map('n', '<leader>fb', fzf.buffers,   { desc = 'Switch buffer' })
  map('n', '<leader>fo', fzf.oldfiles,  { desc = 'Recent files' })
  map('n', '<leader>fr', fzf.resume,    { desc = 'Resume last search' })
  map('n', '<leader>fh', fzf.help_tags, { desc = 'Help tags' })
end

if #missing > 0 then
  vim.notify(
    'Plugins not loaded yet: ' .. table.concat(missing, ', ')
      .. '\nDownloading on first start; run :restart when done',
    vim.log.levels.WARN
  )
end
