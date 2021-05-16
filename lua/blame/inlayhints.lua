local inlayhints = {}
local _mt = {}
__INLAY_HINTS_STATE = {}
_mt.__index = _mt

--@param opts
--@param opts.name name for ns group
--@param opts.buf buffer to set virtual_text in, sets to the current one if not provided
--@param opts.ns namespace to use for virtual_text, one is going to be created with given opts.name if not provided
function inlayhints.new(opts)
  opts = opts or {}
  opts.buf = opts.buf or vim.api.nvim_get_current_buf()
  opts.ns = vim.api.nvim_create_namespace(opts.name or 'INLAY_HINT')
  __INLAY_HINTS_STATE[opts.buf] = opts
  return setmetatable(opts, _mt)
end

--@param opts.line: line to set in virtual_text
function _mt:set(opts)
  assert(opts, 'pass opts')
  opts.lnum = opts.lnum or vim.api.nvim_win_get_cursor(0)[1] - 1
  local lines = {}
  table.insert(lines, {(opts.prefix or self.prefix or '> ') .. tostring(opts.line), opts.hl or 'Comment'})
  vim.api.nvim_buf_set_virtual_text(self.buf, self.ns, opts.lnum, lines, {})
  vim.cmd [[ redraw! ]]
end

function _mt:clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, self.ns, 0, -1)
end

function inlayhints.for_buf(buf)
  if __INLAY_HINTS_STATE[buf] then return __INLAY_HINTS_STATE[buf] end
  __INLAY_HINTS_STATE[buf] = inlayhints.new({
    buf = buf,
    name = string.format('inlays for %d', buf)
  })
  return __INLAY_HINTS_STATE[buf]
end

function inlayhints.clear()
  local buf = vim.api.nvim_get_current_buf()
  if __INLAY_HINTS_STATE[buf] then
    __INLAY_HINTS_STATE[buf]:clear(buf)
  end
end

return inlayhints

