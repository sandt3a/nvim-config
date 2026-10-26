local o = vim.opt

o.expandtab   = true
o.tabstop     = 4
o.softtabstop = 4
o.shiftwidth  = 4
o.cindent     = true
o.shiftround  = true

o.cinoptions  = 'j1'

o.number        = true
o.cursorline    = true
o.termguicolors = true
o.laststatus    = 3
o.signcolumn    = 'yes'
o.scrolloff     = 8
o.sidescrolloff = 8
o.wrap          = false
o.colorcolumn   = '100'

o.guicursor = 'a:block-blinkwait300-blinkon500-blinkoff500'
o.pumheight     = 12
o.showcmd       = true

o.foldmethod = 'manual'
o.foldlevel  = 99

o.incsearch  = true
o.hlsearch   = true
o.ignorecase = true
o.smartcase  = true

o.completeopt = { 'menu', 'menuone', 'noinsert', 'noselect', 'fuzzy' }
o.wildmode    = 'longest:full,full'
o.wildoptions = 'pum'

o.mouse       = 'a'
o.autoread    = true
o.autochdir   = true
o.belloff     = 'all'
o.confirm     = true
o.splitright  = true
o.splitbelow  = true
o.updatetime  = 250
o.timeoutlen  = 300
o.jumpoptions = 'view'

o.formatoptions:remove({ 't', 'c', 'r', 'o' })

o.fileencodings = { 'utf-8', 'gbk', 'gb18030', 'ucs-bom', 'cp936' }

o.undofile = true
o.undodir  = vim.fn.stdpath('state') .. '/undo'

local function win_paste()
  local out = vim.fn.system({ 'powershell.exe', '-noprofile', '-command', 'Get-Clipboard -Raw' })
  if vim.v.shell_error ~= 0 then return 0 end
  out = out:gsub('\r\n', '\n'):gsub('\r', ''):gsub('\n$', '')
  if out == '' then return {} end
  return vim.split(out, '\n', { plain = true })
end

vim.g.clipboard = {
  name  = 'wsl(clip.exe write + powershell read)',
  copy  = { ['+'] = 'clip.exe', ['*'] = 'clip.exe' },
  paste = { ['+'] = win_paste,  ['*'] = win_paste },
  cache_enabled = 0,

}

o.clipboard = ''

local CPPFLAGS = '-g -std=c++23 -Wall -Wextra -Wconversion'

o.makeprg = 'make %:t:r CXXFLAGS="' .. CPPFLAGS .. '"'

vim.o.errorformat = '%f:%l:%c: %t%*[^:]: %m,' .. vim.o.errorformat

vim.cmd.colorscheme('sorbet')
