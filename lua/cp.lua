local M = {}

local TEMPLATE_DIR = vim.fn.expand(vim.g.cp_template_dir or '~/cp-code/template')
local DEFAULT_TPL  = 'multicase'
local CPP_PATTERNS = { '*.cpp', '*.cc', '*.cxx' }
local TEMPLATES    = { 'multicase', 'singlecase' }

local function buf_is_empty(buf)
  return vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
end

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

local function fill_from_template(buf, name)
  local path = TEMPLATE_DIR .. '/' .. name .. '.cpp'
  if vim.fn.filereadable(path) == 0 then return false end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  vim.b[buf].cp_template = name
  return true
end

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

function M.apply_template(name)
  name = name or DEFAULT_TPL
  if not fill_from_template(0, name) then
    vim.notify('Template not found: ' .. TEMPLATE_DIR .. '/' .. name .. '.cpp', vim.log.levels.ERROR)
    return
  end
  M.jump_to_solve()
end

function M.swap_template()
  local buf = vim.api.nvim_get_current_buf()
  local cur    = matched_template(buf) or vim.b[buf].cp_template
  local target = (cur == 'singlecase') and 'multicase' or 'singlecase'

  if vim.bo[buf].modified and not matched_template(buf) then
    local choice = vim.fn.confirm(
      'Buffer has unsaved changes; overwrite with ' .. target .. '.cpp and lose them:',
      '&No \nYes ' .. target)
    if choice ~= 2 then return end
  end

  M.apply_template(target)
end

local function maybe_apply_template(ev)
  local buf = ev.buf

  if vim.api.nvim_buf_get_name(buf):find('/template/', 1, true) then return end

  if vim.bo[buf].buftype ~= '' then return end

  if not buf_is_empty(buf) then return end

  if vim.api.nvim_win_get_buf(0) ~= buf then return end

  if fill_from_template(buf, DEFAULT_TPL) then
    vim.bo[buf].modified = true
    M.jump_to_solve()
  end
end

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
  pattern  = CPP_PATTERNS,
  callback = maybe_apply_template,
  desc     = 'Fill new or empty cpp files with the multicase template and jump to solve',
})

vim.api.nvim_create_user_command('CpTemplate', function(a)
  M.apply_template(a.args ~= '' and a.args or DEFAULT_TPL)
end, {
  nargs    = '?',
  complete = function() return TEMPLATES end,
  desc     = 'Overwrite current buffer with a template (default multicase)',
})

local TERM_HEIGHT = 12
local term = { buf = nil, job = nil }

local function term_alive()
  return term.buf ~= nil
    and vim.api.nvim_buf_is_valid(term.buf)
    and term.job ~= nil
    and vim.fn.jobpid(term.job) > 0
end

local function ensure_term()
  if term_alive() then
    if vim.fn.bufwinid(term.buf) == -1 then
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

  local job = vim.fn.jobstart({ 'bash' }, { term = true })

  term.buf, term.job = buf, job
  vim.bo[buf].bufhidden = 'hide'
  vim.wo.number     = false
  vim.wo.signcolumn = 'no'
  vim.wo.foldcolumn = '0'

  vim.api.nvim_set_current_win(prev)
end

function M.sh(cmd, opts)
  local cwd = vim.fn.shellescape(vim.fn.expand('%:p:h'))

  opts = opts or {}
  ensure_term()

  local win = vim.fn.bufwinid(term.buf)
  if win == -1 then return end

  vim.api.nvim_win_call(win, function() vim.cmd('normal! G') end)

  if opts.focus then
    vim.api.nvim_set_current_win(win)
    vim.cmd('startinsert')
  end

  vim.fn.chansend(term.job, 'cd ' .. cwd .. ' && ' .. cmd .. '\n')
end

local FLAGS_DEBUG  = '-g -std=c++23 -Wall -Wextra -Wconversion'
local FLAGS_FAST   = '-O2 -std=c++23'
local FLAGS_FAST_C = '-O2'

local function stem() return vim.fn.expand('%:t:r') end
local function src()  return vim.fn.expand('%:t')   end

local function compiler()
  return vim.fn.expand('%:e') == 'c' and 'gcc' or 'g++'
end

local function compile(flags)
  return compiler() .. ' ' .. src() .. ' -o ' .. stem() .. ' ' .. flags
end

local function debug_build()
  return string.format('make -B %s CXXFLAGS="%s"', stem(), FLAGS_DEBUG)
end

local function run_with(input)
  local cmd
  if vim.fn.expand('%:e') == 'py' then
    cmd = 'time python3 ' .. src()
  else
    cmd = 'time ./' .. stem()
  end
  if input then cmd = cmd .. ' < ' .. input end
  return cmd
end

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
end

map('<F2>',   function() M.swap_template() end,
    'Switch template (multicase <-> singlecase)')
map('<F5>',   function() M.sh(run_with()) end,
    'Run (C/C++ or Python, no build)')
map('<F8>',   function() M.sh(run_with(stem() .. '.in')) end,
    'Run with same-name .in (C/C++ or Python, no build)')

local function compile_o2()
  local ext = vim.fn.expand('%:e')
  if ext == 'c' then
    M.sh(compile(FLAGS_FAST_C))
  elseif ext == 'cpp' or ext == 'cc' or ext == 'cxx' then
    M.sh(compile(FLAGS_FAST))
  end
end

for _, lhs in ipairs({ '<C-F9>', '<F33>' }) do
  map(lhs, compile_o2, 'Compile with -O2 (gcc for C, g++ for C++)')
end
map('<F10>',  function()
  M.sh(debug_build() .. ' && gdb -q ./' .. stem(), { focus = true })
end, 'Debug with gdb (always rebuild with -g for current symbols)')

map('<F3>',   function() vim.cmd('leftabove vnew ' .. stem() .. '.in') end,
    'Open input file on the left')
map('<F4>',   function() M.sh('python3 ' .. src()) end,
    'Run Python file')

map('<F9>', function()
  local ext = vim.fn.expand('%:e')
  if ext ~= 'cpp' and ext ~= 'cc' and ext ~= 'cxx' then return end
  vim.cmd('cd ' .. vim.fn.fnameescape(vim.fn.expand('%:p:h')))
  vim.cmd('silent make')
  vim.cmd('redraw!')

  local items, has_error = {}, false
  for _, q in ipairs(vim.fn.getqflist()) do
    if q.valid == 1 then
      items[#items + 1] = q
      if q.type == 'e' or q.type == 'E' or q.text:match('^%s*error:') then
        has_error = true
      end
    end
  end
  vim.fn.setqflist({}, 'r', { items = items, title = 'Build' })

  if has_error then
    vim.cmd('copen')
  else
    pcall(vim.cmd, 'cclose')
    vim.notify('Build succeeded' .. (#items > 0 and (' (' .. #items .. ' warning(s))') or ''), vim.log.levels.INFO)
  end
end, 'Build into quickfix (open only on errors)')

return M
