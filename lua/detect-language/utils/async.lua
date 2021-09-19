-- using JavaScript Promise's analogy
local co = coroutine

local M = {}

local function await_fn(value)
  return co.yield(value)
end

local function process_async(async_generator, resolve)
  vim.validate({
    async_generator = { async_generator, 'f' },
    resolve = { resolve, 'f', true }
  })
  local thread = co.create(async_generator)
  local function process(last_value)
    local _, value = co.resume(thread, last_value)
    local done = co.status(thread) == 'dead'

    if done then
      -- async return raw value
      return (resolve or function () end)(value)
    else
      -- async yield promise
      if type(value) == 'function' then
        return value(process)
      else
        return M.resolve(value)(process)
      end
    end
  end

  return process(await_fn)
end

M.resolve = function (value)
  return function (resolve)
    return resolve(value)
  end
end

M.promise = function (async_fn)
  return M.async(function (await)
    return await(async_fn)
  end)
end

M.async = function (async_generator)
  vim.validate({
    async_generator = { async_generator, 'f' }
  })
  return function (resolve)
    return process_async(async_generator, resolve)
  end
end

return M
