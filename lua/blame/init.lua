local job = require('plenary.job')
local blame = {}
__blame_opts = {}

function blame.blame(buf, lnum)
  -- clear old ones
  require'blame.inlayhints'.clear()
  buf = buf or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local results = job:new({
    command = 'git',
    args = { 'blame', '-L', string.format('%d,%d', lnum, lnum), '-p', filename}
  }):sync(1000)
  -- local results, success = spawn(string.format('git blame -L %d,%d -p %s', lnum, lnum, filename))
  -- if not success then
  --   return
  -- end
  local message
  local author
  for _, l in ipairs(results) do
    if l:sub(1, 7) == 'summary' then
      message = l:sub(9, -1)
    end
    if l:sub(1, 7) == 'author ' then
      author = l:sub(8, -1)
    end
  end
  local ns = vim.api.nvim_create_namespace(string.format('blame%d', buf))
  local inlay = require('blame.inlayhints').new {
    ns = ns,
    buf = buf
  }
  if message then
    inlay:set {
      prefix = __blame_opts.prefix or '|> ',
      line = string.format('%s: %s', author, message),
      hl = __blame_opts.hl or 'Comment'
    }
  end
end

function blame.setup(opts)
  opts = opts or {}
  __blame_opts = opts
  vim.cmd [[
    augroup blame_nvim
      autocmd!
      autocmd CursorMoved,CursorMoved * lua require("blame").blame()
    augroup END
  ]]
end

function blame.off()
  require'blame.inlayhints'.clear()
  vim.cmd [[
    augroup blame_nvim
      autocmd!
    augroup END
  ]]
end

return blame
