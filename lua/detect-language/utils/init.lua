local M = {}

M.pick = function (table, path, default)
  if table == nil then
    return M.pick({}, path, default)
  end

  if table[path] == nil then
    return default
  else
    return table[path]
  end
end

M.to_map = function (list, fill)
  if fill == nil then
    return M.to_map(list, true)
  end

  local map = {}
  for _, value in ipairs(list) do
    map[value] = fill
  end

  return map
end

return M
