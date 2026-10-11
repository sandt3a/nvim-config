-- ~/.config/nvim/lua/plugins.lua
-- 插件管理用 nvim 0.12 内置的 vim.pack，不需要 lazy.nvim / vim-plug。
-- 只需要两个插件，全部在启动时加载，实测启动时间仍在 40ms 以内。
--
-- 首次启动 vim.pack.add 会把它们 clone 到
--   ~/.local/share/nvim/site/pack/core/opt/
-- clone 完成后要 :restart 一次才会进 runtimepath。

vim.pack.add({
  'https://github.com/echasnovski/mini.comment',  -- gcc 注释
  'https://github.com/ibhagwan/fzf-lua',          -- 模糊查找
})

-- 首次启动时插件还没进 runtimepath，require 会失败，所以统一 pcall 包一层
local missing = {}
local function setup(mod, fn)
  local ok, m = pcall(require, mod)
  if ok then fn(m) else missing[#missing + 1] = mod end
  return ok
end

-- 注释：gcc 注释当前行，gc + motion / 可视模式 gc 注释选区
setup('mini.comment', function(m) m.setup() end)

-- 模糊查找：用系统里已有的 rg / fd / fzf / bat，不依赖 node
if setup('fzf-lua', function(m)
  m.setup({
    -- 默认主题就好；想换成 dropdown 风格把下面两行打开
    -- winopts = { height = 0.4, width = 0.8, row = 0.35, preview = { layout = 'vertical' } },
  })
end) then
  local fzf = require('fzf-lua')
  local map = vim.keymap.set
  map('n', '<leader>ff', fzf.files,     { desc = '找文件' })
  map('n', '<leader>fg', fzf.live_grep, { desc = '全仓库搜索' })
  map('n', '<leader>fb', fzf.buffers,   { desc = '切换 buffer' })
  map('n', '<leader>fo', fzf.oldfiles,  { desc = '最近打开' })
  map('n', '<leader>fr', fzf.resume,    { desc = '恢复上次搜索' })
  map('n', '<leader>fh', fzf.help_tags, { desc = '帮助文档' })
end

if #missing > 0 then
  vim.notify(
    '插件尚未加载：' .. table.concat(missing, ', ')
      .. '\n首次启动正在下载，完成后 :restart 即可生效',
    vim.log.levels.WARN
  )
end
