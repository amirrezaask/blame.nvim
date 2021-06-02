local has_plenary, Job = pcall(require,'plenary.job')
if not has_plenary then
  vim.api.nvim_err_writeln('install nvim-lua/plenary.nvim to use blame.nvim')
  return
end

local blame = {}
__blame_opts = {}
__blame_is_on = false

function blame.clear()
  require'blame.inlayhints'.clear()
end

local function timestamp_to_date(ts)
  return os.date('%Y-%m-%d %H:%M:%S', ts)
end

function blame.blame(buf, lnum)
  -- clear old ones
  require'blame.inlayhints'.clear()
  buf = buf or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]

  local result = Job:new({
    command = "git",
    args = {'blame', '-L', string.format('%d,%d', lnum, lnum), '-p', string.format('%s', filename) },
    cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h"),
  }):sync()

  local message
  local author
  local author_time
  for _, l in ipairs(result) do
    if l:sub(1, 8) == 'summary ' then
      message = l:sub(9, -1)
    end
    if l:sub(1, 7) == 'author ' then
      author = l:sub(8, -1)
    end
    if l:sub(1, 12) == 'author-time ' then
      author_time = timestamp_to_date(l:sub(13, -1))
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
      line = string.format('%s: %s at %s', author, message, author_time),
      hl = __blame_opts.hl or 'Comment'
    }
  end
end

function blame.setup(opts)
  opts = opts or {}
  __blame_opts = opts
  if __blame_opts.always then
    vim.cmd [[
      augroup blame_nvim
        autocmd!
        autocmd CursorMoved,CursorMoved * lua require("blame").blame()
      augroup END
    ]]
  end
end

function blame.off()
  require'blame.inlayhints'.clear()
  vim.cmd [[
    augroup blame_nvim
      autocmd!
    augroup END
  ]]
end

function blame.toggle()
  if __blame_is_on then
    blame.off()
  else
    blame.setup(__blame_opts)
  end
end

vim.cmd [[ command BlameToggle lua require'blame'.toggle() ]]
vim.cmd [[ command BlameOff lua require'blame'.off() ]]
vim.cmd [[ command BlameShow lua require'blame'.blame() ]]
vim.cmd [[ command BlameClear lua require'blame'.clear() ]]
return blame
