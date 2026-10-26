-- ~/.config/nvim/lua/options.lua
-- 基础选项。原 ~/.vimrc 的每一项都保留了，注释里标「改动」的是这次现代化的调整。

local o = vim.opt

-- ── 缩进 ──────────────────────────────────────────────────────────────
o.expandtab   = true    -- 空格代替 Tab                  （原 et）
o.tabstop     = 4       --                              （原 ts=4）
o.softtabstop = 4       --                              （原 sts=4）
o.shiftwidth  = 4       --                              （原 sw=4）
o.cindent     = true    -- C 风格缩进                    （原 cin）
o.shiftround  = true    -- >> << 对齐到 shiftwidth 整数倍 （改动）

-- j1 是 cindent 里唯一管 lambda 的开关（帮助文档写的是 "Java 匿名类"，
-- 但 C++ 的 [&](){ 和 Java 匿名类是同一套语法形状）。不打开的话，
-- cindent 会把 `sort(..., [](int a, int b){` 里的 `(` 当成"还没闭合的括号"，
-- 于是 lambda 体内的行按续行规则缩进（+2*sw），结果是：
--     sort(v.begin(), v.end(), [&](int a, int b){
--             return a < b;        ← 12 空格
--             });                  ← 12 空格
-- 打开 j1 之后恢复成：
--     sort(v.begin(), v.end(), [&](int a, int b){
--         return a < b;            ← 8
--     });                          ← 4
-- v.push_back({1, 2, 3}) 这种初始化列表同理。
o.cinoptions  = 'j1'    -- （改动）

-- 注意：这里不能顺手加 J1。J1（"别把对象声明当成标号"）对 C++ 没用，
-- 副作用是 goto 的标号 `done:` 会被当成普通语句跟着缩进一级。

-- ── 外观 ──────────────────────────────────────────────────────────────
o.number        = true     -- 行号                     （原 nu）
o.cursorline    = true     -- 高亮当前行                （改动）
o.termguicolors = true     -- 24 位真彩色，Windows Terminal 支持 （改动）
o.laststatus    = 3        -- 全局单条状态栏             （改动，原 ls=2 是每个窗口一条）
o.signcolumn    = 'yes'    -- 固定符号列，画面不抖        （改动）
o.scrolloff     = 8        -- 光标上下留 8 行            （改动）
o.sidescrolloff = 8        --                          （改动）
o.wrap          = false    -- 长行不折行                （改动）
o.colorcolumn   = '100'    -- 第 100 列提示线            （改动）

-- 光标形状：nvim 默认是「普通模式 实心方块不闪 / 插入模式 竖线(ver25)」。
-- 而原版 vim 的 guicursor 在终端里其实是空转的 —— vim 的 t_SI / t_EI 为空，
-- 所以它压根不动光标，你看到的是 Windows Terminal 自己的光标（你配的是
-- filledBox，且没关 cursorBlinking = 默认闪烁）。
-- 这里显式写成同样的效果：所有模式都是闪烁的实心方块。
--   想还原 nvim 默认（插入模式竖线）→ 删掉这行
--   想完全交还终端（跟 vim 一模一样，改 WT 设置 nvim 也跟着变）
--     → 改成 vim.opt.guicursor = ''
o.guicursor = 'a:block-blinkwait300-blinkon500-blinkoff500'   -- （改动）
o.pumheight     = 12       -- 补全菜单最多 12 行         （改动）
o.showcmd       = true     -- 右下角显示未完成的命令      （原式默认，显式写出）

-- 折叠：原配置是 fdm=syntax，在有 bits/stdc++.h 的文件上每次输入都要重算语法树，
-- 大模板会明显卡顿。改成手动折叠，需要时 zf 创建、za 开关。
o.foldmethod = 'manual'    --                          （改动，原 fdm=syntax fdl=100）
o.foldlevel  = 99

-- ── 搜索 ──────────────────────────────────────────────────────────────
o.incsearch  = true     -- 边输边跳                     （原 is）
o.hlsearch   = true     -- 高亮全部匹配                  （原 hls）
o.ignorecase = true     -- 忽略大小写                    （改动）
o.smartcase  = true     -- 但含大写字母时区分大小写        （改动）

-- ── 补全 ──────────────────────────────────────────────────────────────
-- fuzzy 是 nvim 0.11+ 的模糊匹配，手写 STL 时比前缀匹配好用很多
o.completeopt = { 'menu', 'menuone', 'noinsert', 'noselect', 'fuzzy' }  -- （改动）
o.wildmode    = 'longest:full,full'   --                              （改动）
o.wildoptions = 'pum'                 --                              （改动）

-- ── 行为 ──────────────────────────────────────────────────────────────
o.mouse       = 'a'      -- 鼠标可用                      （原 mouse=a）
o.autoread    = true     -- 文件被外部改动后自动重载        （原 ar）
o.autochdir   = true     -- cwd 跟随当前文件               （原 acd）
o.belloff     = 'all'    -- 关掉所有响铃                   （原 belloff=all）
o.confirm     = true     -- :q 有未保存改动时弹确认而不是报错 （改动）
o.splitright  = true     -- :vsplit 开在右边               （改动）
o.splitbelow  = true     -- :split 开在下边                （改动）
o.updatetime  = 250      -- 默认 4000，改小让状态刷新及时    （改动）
o.timeoutlen  = 300      -- 默认 1000，leader 之后 0.3 秒内可继续 （改动）
o.jumpoptions = 'view'   -- 跳转保留视图，窗口不跟着滚       （改动）

-- 在注释里按回车 / o 不会自动续上 "//"，写多行注释时按需手动加
o.formatoptions:remove({ 't', 'c', 'r', 'o' })  -- （改动）

-- ── 编码 ──────────────────────────────────────────────────────────────
-- nvim 内部固定 utf-8，原来的 encoding / termencoding 不再需要
o.fileencodings = { 'utf-8', 'gbk', 'gb18030', 'ucs-bom', 'cp936' }  -- 原配置保留

-- ── 持久化 ────────────────────────────────────────────────────────────
o.undofile = true       -- 关掉文件再打开仍可撤销           （原 undofile）
o.undodir  = vim.fn.stdpath('state') .. '/undo'  -- 改用 nvim 自己的 state 目录（改动）

-- ── 剪贴板 ────────────────────────────────────────────────────────────
-- 两条硬约束，解释了下面为什么长这样：
--
-- ① WSL 下没有"nvim 自带又能读 Windows 剪贴板"的东西。
--    · vim.g.clipboard = 'osc52'（原配置那行）只能写不能读：终端一律拒绝
--      OSC52 的查询请求（否则任何网页都能偷读你的剪贴板），而 nvim 的 osc52
--      provider 是先发查询再死等 —— 等 1 秒、打印 "Waiting for OSC52 response
--      from the terminal"、再等 9 秒，然后放弃。这就是"按 p 卡 10 秒"的根因。
--    · 让 nvim 自动探测也不行：nvim 那份 WSL 支持
--      (runtime/autoload/provider/clipboard.vim 的 s:set_clip) 找的是不带扩展名的
--      `clip` / `powershell`，而 WSL 里只认 `clip.exe` / `powershell.exe`，
--      实测 provider#clipboard#Executable() 返回空字符串 —— 等于没有剪贴板后端。
--      顺带一提它自己那份实现走的也是 powershell，下面只是显式写出来。
--    所以读剪贴板必然要起一个 Windows 侧进程，~200ms，省不掉。
--
-- ② 既然读一次要 200ms，就绝不能让它挂在 p 上。
--    o.clipboard = 'unnamedplus' 会让 " 寄存器指向系统剪贴板，于是每一次 put
--    都去问一次 Windows —— 实测 p 每次 193~202ms，按起来一顿一顿的。
--    保持默认（空）时：
--        p / yy        0ms（走 nvim 内部寄存器）
--        "+p / "+y     ~200ms，只在显式要 Windows 剪贴板时才付
--    和 Windows 打交道用 <C-V> / <C-C>（见 keymaps.lua），
--    这也正是原 ~/.vimrc 的行为（老配置里同样没有 unnamedplus）。
local function win_paste()
  local out = vim.fn.system({ 'powershell.exe', '-noprofile', '-command', 'Get-Clipboard -Raw' })
  if vim.v.shell_error ~= 0 then return 0 end   -- 返回 0 = 读失败，Vim 会忽略这次粘贴
  out = out:gsub('\r\n', '\n'):gsub('\r', ''):gsub('\n$', '')  -- 统一行尾 + 去掉尾部换行
  if out == '' then return {} end
  return vim.split(out, '\n', { plain = true })
end

-- 这一段只服务 "+ / * 寄存器，也就是 <C-C> / <C-V>；配置里没有别的 Windows 通道了
vim.g.clipboard = {
  name  = 'wsl(clip.exe 写 + powershell 读)',
  copy  = { ['+'] = 'clip.exe', ['*'] = 'clip.exe' },
  paste = { ['+'] = win_paste,  ['*'] = win_paste },
  -- 不缓存：在 Windows 里复制完立刻回 nvim 粘是最常见的用法，缓存会让你拿到旧内容
  cache_enabled = 0,
}

-- ⚠️ 不要改成 'unnamedplus'。那等于让每一次 p 都去起 powershell，200ms/次。
-- 代价是 y/d 不再自动进 Windows 剪贴板 —— 想要就 <C-C>。
o.clipboard = ''   -- （改动：原来是 unnamedplus）

-- ── 编译 ──────────────────────────────────────────────────────────────
-- F5/F8 只运行（不编译），F9 走 :make + quickfix，两处共用同一套 flags
local CPPFLAGS = '-g -std=c++23 -Wall -Wextra -Wconversion'

-- F9 的 makeprg 走 make：GNU make 自带 %: %.cpp 规则，不用给每道题写 Makefile。
-- 好处是源文件没改动时 make 直接 2ms 返回 "up to date"，省掉一次 ~1.6s 的
-- bits/stdc++.h 重编；改了才编。CXXFLAGS 是命令行变量，不依赖 shell 语法，
-- 所以 fish / bash 下都一样。
-- 注意：<C-F9> 是无条件 -O2 编译（C 用 gcc，C++ 用 g++，不经过 make）—— 它要是也走 make，源文件没改时
-- 会被跳过，结果你计时的是上一次 -O0 的产物，那才是真的坑。
o.makeprg = 'make %:t:r CXXFLAGS="' .. CPPFLAGS .. '"'

-- nvim 自带的 errorformat 匹配 gcc 输出时抓不到错误类型（quickfix 的 type 会是空），
-- 补一条 gcc 的经典规则放在最前面先匹配，这样 F9 才能区分 error 和 warning
-- 注意这里用 vim.o 而不是上面的 vim.opt 代理：vim.opt 取字段得到的是代理对象，
-- 不能直接字符串拼接；vim.o 取到的才是真正的字符串，且赋值等同 :set（全局+当前）
vim.o.errorformat = '%f:%l:%c: %t%*[^:]: %m,' .. vim.o.errorformat

-- ── 配色 ──────────────────────────────────────────────────────────────
vim.cmd.colorscheme('sorbet')   -- nvim 0.12 自带，和你原来的一致
