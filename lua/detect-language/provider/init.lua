local fn = vim.fn
local api = vim.api
local utils = require('detect-language.utils')
local a = require('detect-language.utils.async')
local logger = require('detect-language.utils.logger')
local state = require('detect-language.state')

local private = {}

private.picker = function (context)
  local picker = context.picker
  return function (scores)
    if context.oneshot then
      state.set(context.buffer.state)
    else
      state.set(state.ENABLE)
    end
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

private.analyse_language = function (context)
  local provider = context.provider
  local code = context.code
  return function (language)
    return function ()
      return a.promise(function (resolve)
        local score = provider.analyse(code, language)

        if score == nil then
          return resolve()
        end

        return resolve({ language = language, score = score })
      end)
    end
  end
end

private.evaluate = function (self, request)
  local options = self.options
  local last_line = fn.line('$')
  local oneshot = utils.pick(request, 'oneshot', false)

  local buffer = {
    name = fn.bufname(),
    extension = fn.expand('%:e'),
    buftype = vim.bo.buftype,
    filetype = string.lower(vim.bo.filetype),
    state = state.get()
  }

  if utils.some({
    -- buffer still under analysis / is disabled
    function (b)
      if b.state == state.ANALYSING then
        if oneshot then
          logger.inline.info(
            '[Detect-Language] Buffer is under analysis, please try again'
          )
        end

        return true
      end

      -- disabled buffer
      return b.state == state.DISABLE and not oneshot
    end,
    -- skip non-normal buffer (e.g. terminal)
    function (b)
      return b.buftype ~= ''
    end,
    -- skip new buffer
    function (b)
      return options.disable.new and b.name == '' and not oneshot
    end,
    -- skip buffer with no extension
    function (b)
      return options.disable.no_extension and
        b.name ~= '' and
        b.extension == '' and
        not oneshot
    end,
    -- skip buffer with existing file type, that are not under auto detection
    function (b)
      return b.filetype ~= '' and b.state == state.UNSET and not oneshot
    end,
    -- skip big file
    function ()
      return options.max_lines > 0 and
        last_line > options.max_lines and
        not oneshot
    end
  }, buffer) then
    return
  end

  local lines = api.nvim_buf_get_lines(0, 0, last_line, false)
  local code = table.concat(lines, '\n')

  local context = {
    oneshot = oneshot,
    buffer = buffer,
    provider = self.provider,
    picker = self.picker,
    code = code
  }
  state.set(state.ANALYSING)

  local promises = vim.tbl_map(
    private.analyse_language(context),
    options.languages
  )

  local delay = function ()
    return a.promise(function (resolve)
      vim.defer_fn(resolve, 0)
    end)
  end

  a.async(function (await)
    local scores = {}

    for _, promise in ipairs(promises) do
      -- give control back to neovim, unblock the main thread a bit
      await(delay())
      local score = await(promise())
      if score then
        table.insert(scores, score)
      end
    end

    return scores
  end)(private.picker(context))
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
