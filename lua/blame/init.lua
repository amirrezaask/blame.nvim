local blame = {}

local function tohex(s)
  local R = {}
  for i = 1, #s do
    R[#R+1] = string.format("%02X", s:byte(i))
  end
  return table.concat(R)
end

__AUTOCMD_REGISTRY = {}
--@param opts[1] event
--@param opts[2] filter
--@param opts[3] function or expression
local function autocmd(opts)
 local function get_expression(f)
    if type(f) == 'string' then return f end
    if type(f) == 'function' then
      __AUTOCMD_REGISTRY[tohex(opts[1] .. opts[2])] = function()
        f()
      end
      return string.format('lua __AUTOCMD_REGISTRY["%s"]()', tohex(opts[1]..opts[2]))
    end
  end
  vim.cmd(string.format('autocmd %s %s %s', opts[1], opts[2], get_expression(opts[3])))
end


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
  require'amirrezaask.inlayhints'.clear()
  buf = buf or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local results, success = spawn(string.format('git blame -L %d,%d -p %s', lnum, lnum, filename))
  if not success then
    return
  end
  local message
  for _, l in ipairs(results) do
    if l:sub(1, 7) == 'summary' then
      message = l:sub(9, -1)
    end
  end
  local ns = vim.api.nvim_create_namespace(string.format('blame%d', buf))
  local inlay = require('amirrezaask.inlayhints').new {
    ns = ns,
    buf = buf
  }
  if message then
    inlay:set {
      prefix = 'Git: ',
      line = message,
      hl = 'Comment'
    }
  end
end

function blame.setup(opts)
  autocmd {
    "CursorMovedI,CursorMoved",
    '*',
    blame.blame
  }
end

return blame
