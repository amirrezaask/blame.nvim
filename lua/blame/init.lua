local blame = {}
__blame_opts = {}

local function spawn(command)
  local process_done = false
  local stdout_done = false
  local stderr_done = false
  local success = true

  local output = {}

  vim.fn.jobstart(command, {
    on_exit = function(_, code, _)
      if code ~= 0 then 
        -- print('process exited with ' .. code)
        success = false
      end
      process_done = true
    end,
    on_stdout = function(_, data, _)
      if data[1] == '' then
        -- EOF
        stdout_done = true
      end
      for _, l in ipairs(data) do
        if l ~= '' then
          table.insert(output, l)
        end
      end
    end,
    on_stderr = function(_, data, _)
       if data[1] == '' then
        -- EOF
        stderr_done = true
      end
      for _, l in ipairs(data) do
        if l ~= '' then
          table.insert(output, l)
        end
        table.insert(output, l)
      end
    end
  })
  vim.wait(2000, function()
    return process_done and stdout_done and stderr_done 
  end, 10)

  return output, success
end

function blame.blame(buf, lnum)
  -- clear old ones
  require'blame.inlayhints'.clear()
  buf = buf or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local results, success = spawn(string.format('git blame -L %d,%d -p %s', lnum, lnum, filename))
  if not success then
    return
  end
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
