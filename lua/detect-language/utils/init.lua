local M = {}

M.pick = function (object, paths, default)
  vim.validate({
    map = { object, 't', true }
  })
  if object == nil then
    return M.pick({}, paths, default)
  end

  local path = paths
  local more = false
  if type(paths) == 'table' then
    path = paths[1]
    table.remove(paths, 1)
    more = not vim.tbl_isempty(paths)
  end

  if object[path] == nil then
    return default
  elseif more then
    return M.pick(object[path], paths, default)
  else
    return object[path]
  end
end

M.to_map = function (list, fill)
  vim.validate({
    list = { list, 't' }
  })
  if fill == nil then
    return M.to_map(list, true)
  end

  local map = {}
  for _, value in ipairs(list) do
    map[value] = fill
  end

  return map
end

M.some = function (list, ...)
  vim.validate({
    list = { list, 't' }
  })

  for _, value in ipairs(list) do
    if value(...) then
      return true
    end
  end

  return false
end

return M
