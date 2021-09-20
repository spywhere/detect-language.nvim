local M = {}

M.create = function (list, fn, done, default)
  vim.validate({
    list = { list, 't' },
    fn = { fn, 'c' },
    done = { done, 'c', true }
  })
  local function iter_item(index, accumulator)
    local item = list[index]
    if item == nil then
      if done then
        return done(accumulator, list)
      end
      return
    end

    return fn(
      item,
      function (acc) return iter_item(index + 1, acc) end,
      accumulator
    )
  end

  return function () return iter_item(1, default) end
end

return M
