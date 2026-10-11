-- ~/.config/nvim/lua/cp.lua
-- 算法竞赛相关：新建 cpp 自动填模板并定位到 solve，以及一键编译/运行。
--
-- 编译运行都在底部一个复用的 bash 终端里跑，不是 :! 阻塞式执行，
-- 所以死循环可以直接 Ctrl-C 打断，nvim 本体不会被卡住。

local M = {}

-- 每台电脑在 local.lua 中设置 vim.g.cp_template_dir，模板文件由你自行迁移。
local TEMPLATE_DIR = vim.fn.expand(vim.g.cp_template_dir or '~/cp-code/template')
local DEFAULT_TPL  = 'multicase'                          -- 默认用 multicase.cpp
local CPP_PATTERNS = { '*.cpp', '*.cc', '*.cxx' }
local TEMPLATES    = { 'multicase', 'singlecase' }        -- <F2> 在这两个之间轮换

-- ════════════════════════════════════════════════════════════════════
--  一、模板自动填充
-- ════════════════════════════════════════════════════════════════════

--- buffer 是不是「完全空白」（只有一行空行）
local function buf_is_empty(buf)
  return vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
end

--- 把光标移到 solve 函数体的 '{' 上。
--- 兼容 `void solve()\n{` 和 `void solve() {` 两种排版；
--- 模板被改成别的样子、找不到 solve 时就什么都不做。
function M.jump_to_solve()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local start
  for i, line in ipairs(lines) do
    if line:find('void%s+solve') then
      start = i
      break
    end
  end
  if not start then return end

  for i = start, #lines do
    local col = lines[i]:find('{', 1, true)
    if col then
      vim.api.nvim_win_set_cursor(0, { i, col - 1 })
      return
    end
  end
end

--- 用模板文件的内容替换整个 buffer
local function fill_from_template(buf, name)
  local path = TEMPLATE_DIR .. '/' .. name .. '.cpp'
  if vim.fn.filereadable(path) == 0 then return false end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  vim.b[buf].cp_template = name    -- 记下用的哪个模板，<F2> 靠它决定往哪轮换
  return true
end

--- buffer 内容和哪个模板逐行一致就返回它的名字，改过了则返回 nil。
--- 用内容比对而不是"改没改过"标志位，是因为填完模板本身也算 modified。
local function matched_template(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, name in ipairs(TEMPLATES) do
    local path = TEMPLATE_DIR .. '/' .. name .. '.cpp'
    if vim.fn.filereadable(path) == 1 and vim.deep_equal(lines, vim.fn.readfile(path)) then
      return name
    end
  end
  return nil
end

--- 手动换模板：:CpTemplate 或 :CpTemplate singlecase
function M.apply_template(name)
  name = name or DEFAULT_TPL
  if not fill_from_template(0, name) then
    vim.notify('模板不存在：' .. TEMPLATE_DIR .. '/' .. name .. '.cpp', vim.log.levels.ERROR)
    return
  end
  M.jump_to_solve()
end

--- <F2>：在 multicase / singlecase 之间轮换。
--- 还是原样模板就默默换掉；已经写过东西了则先确认一次，避免一键删掉半道题解。
function M.swap_template()
  local buf = vim.api.nvim_get_current_buf()
  -- 内容还对得上某个模板 → 以它为准；已经改过了 → 退回上次用的那个
  local cur    = matched_template(buf) or vim.b[buf].cp_template
  local target = (cur == 'singlecase') and 'multicase' or 'singlecase'

  if vim.bo[buf].modified and not matched_template(buf) then
    -- confirm() 的默认按钮永远是第一个，所以必须把「取消」放前面：
    -- 否则直接回车（或输入不可用）时会选中"覆盖"，把半道题解一键删掉。
    local choice = vim.fn.confirm(
      'buffer 已改动，覆盖成 ' .. target .. '.cpp 会丢掉这些改动：',
      '&No \nYes ' .. target)
    if choice ~= 2 then return end
  end

  M.apply_template(target)
end

--- 只在「新建」或「空的」cpp 上填模板。
--- 三重保险，保证已经写了内容的题解绝不会被覆盖。
local function maybe_apply_template(ev)
  local buf = ev.buf

  -- 1. 不动 template/ 目录里的模板文件本身
  if vim.api.nvim_buf_get_name(buf):find('/template/', 1, true) then return end
  -- 2. 跳过特殊 buffer（终端、quickfix 等）
  if vim.bo[buf].buftype ~= '' then return end
  -- 3. 有内容就什么都不做
  if not buf_is_empty(buf) then return end

  -- buffer 得显示在当前窗口里，光标才跳得动
  if vim.api.nvim_win_get_buf(0) ~= buf then return end

  if fill_from_template(buf, DEFAULT_TPL) then
    -- 显式标脏：nvim_buf_set_lines 在 BufNewFile 阶段可能不算改动，
    -- 那样 :x 会因为"无改动"而直接退出，文件根本不会创建
    vim.bo[buf].modified = true
    M.jump_to_solve()
  end
end

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
  pattern  = CPP_PATTERNS,
  callback = maybe_apply_template,
  desc     = '新建/空的 cpp 自动填 multicase 模板并定位到 solve',
})

vim.api.nvim_create_user_command('CpTemplate', function(a)
  M.apply_template(a.args ~= '' and a.args or DEFAULT_TPL)
end, {
  nargs    = '?',
  complete = function() return TEMPLATES end,
  desc     = '用模板覆盖当前 buffer（默认 multicase）',
})

-- ════════════════════════════════════════════════════════════════════
--  二、底部终端
-- ════════════════════════════════════════════════════════════════════

local TERM_HEIGHT = 12
local term = { buf = nil, job = nil }

local function term_alive()
  return term.buf ~= nil
    and vim.api.nvim_buf_is_valid(term.buf)
    and term.job ~= nil
    and vim.fn.jobpid(term.job) > 0
end

--- 保证底部有一个活着的终端；被关掉或 shell 退出了就重建
local function ensure_term()
  if term_alive() then
    if vim.fn.bufwinid(term.buf) == -1 then        -- buffer 还在，窗口被关了
      vim.cmd('botright ' .. TERM_HEIGHT .. 'split')
      vim.api.nvim_win_set_buf(0, term.buf)
    end
    return
  end

  if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
  end

  local prev = vim.api.nvim_get_current_win()
  vim.cmd('botright ' .. TERM_HEIGHT .. 'split')

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  -- 固定用 bash：time / && / < 重定向的行为最可预期（fish 语法有差异）
  local job = vim.fn.jobstart({ 'bash' }, { term = true })

  term.buf, term.job = buf, job
  vim.bo[buf].bufhidden = 'hide'                   -- 关窗口不丢这个 shell
  vim.wo.number     = false
  vim.wo.signcolumn = 'no'
  vim.wo.foldcolumn = '0'

  -- 光标留回原来的窗口：按下 F5 只是想在下面看到结果，不是想切走
  vim.api.nvim_set_current_win(prev)
end

--- 在终端里执行一条 shell 命令
--- @param cmd string           要跑的 shell 命令
--- @param opts table|nil       { focus = true } 会把焦点切到终端（gdb 这类交互命令用）
function M.sh(cmd, opts)
  -- 必须在最前面算：% 是跟着窗口走的，下面 ensure_term() 和 opts.focus 都可能把
  -- 当前窗口换成终端，那时候 expand('%:p:h') 拿到的是终端 buffer 的名字
  -- （term://.../bash），cd 过去必然失败。F10 是唯一传 focus 的，之前就踩这个。
  -- 每次先 cd 到当前文件所在目录：./a 和 a.in 都能用相对路径，报错信息也短
  local cwd = vim.fn.shellescape(vim.fn.expand('%:p:h'))

  opts = opts or {}
  ensure_term()

  local win = vim.fn.bufwinid(term.buf)
  if win == -1 then return end

  -- 光标停在终端最后一行，输出来了才会自动跟着滚
  vim.api.nvim_win_call(win, function() vim.cmd('normal! G') end)

  if opts.focus then
    vim.api.nvim_set_current_win(win)
    vim.cmd('startinsert')
  end

  vim.fn.chansend(term.job, 'cd ' .. cwd .. ' && ' .. cmd .. '\n')
end

-- ════════════════════════════════════════════════════════════════════
--  三、编译 & 运行
-- ════════════════════════════════════════════════════════════════════

local FLAGS_DEBUG = '-g -std=c++23 -Wall -Wextra -Wconversion'
local FLAGS_FAST  = '-O2 -std=c++23'

local function stem() return vim.fn.expand('%:t:r') end   -- a.cpp → a
local function src()  return vim.fn.expand('%:t')   end   -- a.cpp → a.cpp

local function compile(flags)
  return 'g++ ' .. src() .. ' -o ' .. stem() .. ' ' .. flags
end

-- F10 用：无条件重编一次带 -g 的。
-- 试过用 readelf 检查调试节来跳过不必要的重编，结果是坑：产物里有调试节、
-- 但源文件已经改过了（写完代码没按 F9 直接按 F10）时会直接跳过，gdb 加载的是
-- 上一次的二进制，断点/行号对不上当前源码，看起来就是"符号不对"。
-- bits/stdc++.h 重编约 2s，换来的一定是对的符号，值。
local function debug_build()
  return string.format('make -B %s CXXFLAGS="%s"', stem(), FLAGS_DEBUG)
end

-- 只运行，不编译：编译是 F9 / <C-F9> 的事，混在一起会把反馈时间拉长
local function run_with(input)
  local cmd = 'time ./' .. stem()
  if input then cmd = cmd .. ' < ' .. input end
  return cmd
end

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
end

map('<F2>',   function() M.swap_template() end,
    '换模板（multicase ⇄ singlecase）')
map('<F5>',   function() M.sh(run_with()) end,
    '运行（底部终端，不编译）')
map('<F8>',   function() M.sh(run_with(stem() .. '.in')) end,
    '读 .in 运行（不编译）')
map('<C-F9>', function() M.sh(compile(FLAGS_FAST)) end,
    '编译 -O2（赛时测速度）')
map('<F10>',  function()
  M.sh(debug_build() .. ' && gdb -q ./' .. stem(), { focus = true })
end, 'gdb 调试（每次都带 -g 重编，保证符号是当前源码的）')
-- 前缀 leftabove 是必须的：options.lua 里开了 splitright，光写 :vnew 会开在右边，
-- 和你原来 vim（默认 nosplitright）的习惯正好相反。只影响 F3，不动全局设置。
map('<F3>',   function() vim.cmd('leftabove vnew ' .. stem() .. '.in') end,
    '在左侧打开输入文件')
map('<F4>',   function() M.sh('python3 ' .. src()) end,
    '运行 python')

-- F9 = :make + quickfix，比原来的 :make 多了自动开关报错面板
map('<F9>', function()
  -- 注意：Lua 正则没有 | 交替，这里必须逐个比，不能写 %. (cpp|cc|cxx)$
  local ext = vim.fn.expand('%:e')
  if ext ~= 'cpp' and ext ~= 'cc' and ext ~= 'cxx' then return end
  vim.cmd('cd ' .. vim.fn.fnameescape(vim.fn.expand('%:p:h')))
  vim.cmd('silent make')
  vim.cmd('redraw!')

  -- gcc 每条诊断后面还会跟一堆源码上下文行，在 quickfix 里是纯噪音。
  -- valid==0 的正是那些续行，丢掉后：12 条 → 只剩真正的 error/warning 3 条。
  local items, has_error = {}, false
  for _, q in ipairs(vim.fn.getqflist()) do
    if q.valid == 1 then
      items[#items + 1] = q
      -- 只在有「错误」时弹面板；-Wconversion 的警告不弹，否则每次都糊一脸。
      -- type 靠 options.lua 里补的 errorformat 拿到，抓不到时退回看文本。
      if q.type == 'e' or q.type == 'E' or q.text:match('^%s*error:') then
        has_error = true
      end
    end
  end
  vim.fn.setqflist({}, 'r', { items = items, title = '编译' })

  if has_error then
    vim.cmd('copen')
  else
    pcall(vim.cmd, 'cclose')
    vim.notify('编译通过' .. (#items > 0 and ('（' .. #items .. ' 条警告）') or ''), vim.log.levels.INFO)
  end
end, '编译到 quickfix（有错才弹面板）')

return M
