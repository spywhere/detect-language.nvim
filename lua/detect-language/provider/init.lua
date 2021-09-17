local fn = vim.fn
local api = vim.api
local iter = require('detect-language.utils.iter')
local logger = require('detect-language.utils.logger')

local private = {}

private.picker = function (picker)
  return function (scores)
    logger.debug('score ' .. vim.inspect(scores))
    local best_language = picker.pick(scores)
    if best_language then
      vim.bo.filetype = best_language.language
    else
      logger.info(
        '[Detect-Language] Too many possible languages, try write some code'
      )
    end
  end
end

private.analyse_language = function (provider, code, delay)
  return function (language, continue, scores)
    logger.debug('analysing ' .. language)
    table.insert(scores, {
      language = language,
      score = provider.analyse(code, language)
    })

    delay(function () return continue(scores) end)
  end
end

private.evaluate = function (self)
  -- skip non-normal buffer (e.g. terminal)
  if vim.bo.buftype ~= '' then
    return
  end

  local options = self.options

  -- skip excluded file types
  if options.excludes[string.lower(vim.bo.filetype)] then
    return
  end

  local last_line = fn.line('$')
  -- skip big file
  if options.max_lines > 0 and last_line > options.max_lines then
    return
  end

  local lines = api.nvim_buf_get_lines(0, 0, last_line, false)
  local code = table.concat(lines, '\n')

  logger.debug('--------')
  vim.defer_fn(iter.create(
    options.languages,
    private.analyse_language(
      self.provider,
      code,
      function (callback) vim.defer_fn(callback, 10) end
    ),
    private.picker(self.picker),
    {}
  ), 0)
end

local analyser = setmetatable({}, {
  __call = function (self, provider, picker, options)
    self.provider = provider
    self.picker = picker
    self.options = options

    return self
  end,
  __index = function (self, key)
    vim.validate({
      key = { key, 's' }
    })

    local value = private[key]
    if type(value) == 'function' then
      return function (...) return value(self, ...) end
    else
      return nil
    end
  end
})

return setmetatable({}, {
  -- build analyser from provider
  __call = function (_, options)
    local provider = options.provider
    local picker = options.picker
    local supported_languages = provider.get_supported_languages()
    local selected_languages = vim.tbl_filter(
      function (language) return supported_languages[language] end,
      options.languages
    )

    return analyser(
      provider,
      picker,
      {
        excludes = options.excludes,
        languages = selected_languages,
        max_lines = options.max_lines
      }
    )
  end,
  __index = function (_, key)
    vim.validate({
      key = { key, 's' }
    })
    return require(string.format('detect-language.provider.%s', key))
  end
})
