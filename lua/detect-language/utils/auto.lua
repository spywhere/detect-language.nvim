local logger = require('detect-language.utils.logger')
local _auto = 'detect-language.utils.auto'
local api = vim.api
local fn = vim.fn
local std = {}
std.count = function ()
  local i = 0
  return function ()
    i = i + 1
    return i
  end
end
std.wrap = function (value)
  if type(value) == 'table' then
    return value
  else
    return { value }
  end
end

local M = {}

local _group = nil
local _callbacks = {}
local increment = std.count()

local remove = function (index, group_name)
  local clear = 'autocmd! ' .. group_name
  _callbacks[index] = nil
  api.nvim_command(clear)
end

M._call = function (index, group_name, ...)
  local kill = function ()
    remove(index, group_name)
  end
  _callbacks[index](M, kill, ...)
end

M.group = function (group_name, group_fn)
  if _group then
    logger.error('still defining autogroup \'' .. _group.name .. '\'')
    return
  end

  local name = group_name
  local group = group_fn
  if group then
    assert(
      type(name) == 'string' or type(name) == 'number',
      'group name must be a string or number'
    )
    assert(type(group) == 'function', 'group must be a function')
  else
    assert(type(name) == 'function', 'group must be a function')
    group = name
    name = nil
  end
  _group = {
    name = name or increment()
  }
  _group.expression = {
    'augroup ' .. _group.name,
    'autocmd!'
  }
  group()
  table.insert(_group.expression, 'augroup END')
  api.nvim_exec(table.concat(_group.expression, '\n'), false)
  _group = nil
end

M.register = function (_events, func, _filter, _modifiers)
  if not _group then
    M.group(
      function ()
        M.register(_events, func, _filter, _modifiers)
      end
    )
    return
  end

  local evnts = std.wrap(_events)
  for event in ipairs(evnts) do
    assert(fn.exists('##' .. event))
  end

  local index = increment()
  local events = table.concat(evnts, ',')
  local filter = table.concat(std.wrap(_filter or '*'), ',')
  local modifiers = table.concat(std.wrap(_modifiers or {}), ' ')
  local call_args = {
    index,
    string.format('%q', _group.name)
  }
  local fn_call = {
    'lua require(\'' .. _auto ..'\')',
    '_call(' .. table.concat(call_args, ', ') .. ')'
  }
  local expression = {
    'autocmd',
    events,
    filter,
    modifiers,
    table.concat(fn_call, '.')
  }
  table.insert(_group.expression, table.concat(expression, ' '))

  _callbacks[index] = func

  return function ()
    remove(index, _group.name)
  end
end

return M
