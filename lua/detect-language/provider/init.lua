local fn = vim.fn
local api = vim.api
local utils = require('detect-language.utils')
local iter = require('detect-language.utils.iter')
local logger = require('detect-language.utils.logger')
local state = require('detect-language.state')

local private = {}

private.picker = function (picker)
  return function (scores)
    state.set(state.ENABLE)
    state.set_score(scores)
    local best_language = picker.pick(scores)
    if best_language then
      vim.bo.filetype = best_language.language
    else
      logger.inline.info(
        '[Detect-Language] Too many possible languages, try write some code'
      )
    end
  end
end

private.analyse_language = function (provider, code, delay)
  return function (language, continue, scores)
    table.insert(scores, {
      language = language,
      score = provider.analyse(code, language)
    })

    delay(function () return continue(scores) end)
  end
end

private.evaluate = function (self)
  local options = self.options
  local last_line = fn.line('$')

  if utils.some({
    -- buffer still under analysis
    function (buffer)
      return buffer.state == state.ANALYSING or buffer.state == state.DISABLE
    end,
    -- skip non-normal buffer (e.g. terminal)
    function (buffer)
      return buffer.buftype ~= ''
    end,
    -- skip new buffer
    function (buffer)
      return options.disable.new and buffer.name == ''
    end,
    -- skip buffer with no extension
    function (buffer)
      return options.disable.no_extension and buffer.name ~= '' and buffer.extension == ''
    end,
    -- skip buffer with existing file type, that are not under auto detection
    function (buffer)
      return buffer.filetype ~= '' and buffer.state == state.UNSET
    end,
    -- skip big file
    function ()
      return options.max_lines > 0 and last_line > options.max_lines
    end
  }, {
    name = fn.bufname(),
    extension = fn.expand('%:e'),
    buftype = vim.bo.buftype,
    filetype = string.lower(vim.bo.filetype),
    state = state.get()
  }) then
    return
  end

  local lines = api.nvim_buf_get_lines(0, 0, last_line, false)
  local code = table.concat(lines, '\n')

  state.set(state.ANALYSING)
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
        languages = selected_languages,
        max_lines = options.max_lines,
        disable = options.disable
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
