local logger = require('detect-language.utils.logger')
local api = vim.api
local fn = vim.fn
local state_name = 'detect_language'
local score_name = 'detect_language_score'

local M = {
  DISABLE = 0,
  ENABLE = 1,
  ANALYSING = 2,
  UNSET = 3
}

M.set = function (state)
  api.nvim_buf_set_var(0, state_name, state)
end

M.get = function ()
  if fn.exists('b:' .. state_name) == 0 then
    return M.UNSET
  end

  return api.nvim_buf_get_var(0, state_name)
end

M.set_score = function (score)
  api.nvim_buf_set_var(0, score_name, vim.inspect(score))
end

M.enable = function ()
  if M.get() == M.ANALYSING then
    logger.inline.info(
    '[Detect-Language] Buffer is under analysis, please try again'
    )
    return
  end
  M.set(M.ENABLE)
  logger.inline.info(
  '[Detect-Language] Auto-detection on buffer is now enabled'
  )
end

M.disable = function ()
  if M.get() == M.ANALYSING then
    logger.inline.info(
    '[Detect-Language] Buffer is under analysis, please try again'
    )
    return
  end
  M.set(M.DISABLE)
  logger.inline.info(
  '[Detect-Language] Auto-detection on buffer is now disabled'
  )
end

M.toggle = function ()
  local state = M.get()
  if state == M.ANALYSING then
    logger.inline.info(
    '[Detect-Language] Buffer is under analysis, please try again'
    )
    return
  elseif state == M.ENABLE then
    M.disable()
  else
    M.enable()
  end
end

return M
