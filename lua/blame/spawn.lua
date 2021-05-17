return function(command)
  local process_done = false
  local stdout_done = false
  local stderr_done = false
  local success = true

  local stdout = {}
  local stderr = {}

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
          table.insert(stdout, l)
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
          table.insert(stderr, l)
        end
        table.insert(stderr, l)
      end
    end
  })
  vim.wait(2000, function()
    return process_done and stdout_done and stderr_done 
  end, 10)

  return stdout, stderr, success
end
