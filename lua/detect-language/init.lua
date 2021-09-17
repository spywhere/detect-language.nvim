local utils = require('detect-language.utils')
local auto = require('detect-language.utils.auto')

local M = {
  provider = require('detect-language.provider'),
  picker = require('detect-language.picker')
}

M.setup = function (options)
  vim.validate({
    options = { options, 't', true }
  })
  if options then
    vim.validate({
      languages = { options.languages, 't', true },
      provider = { options.provider, 'f', true },
      picker = { options.provider, 'f', true },
      events = { options.events, 't', true },
      max_lines = { options.max_lines, 'n', true },
      disable = { options.disable, 't', true }
    })
  end
  if options and options.disable then
    vim.validate({
      new = { options.disable.new, 'b', true },
      no_extension = { options.disable.no_extension, 'b', true }
    })
  end
  local default_languages = {
    'javascript',
    'typescript',
    'tsx',
    'bash',
    'c_sharp',
    'cpp',
    'c',
    'go',
    'graphql',
    'html',
    'java',
    'json5',
    'jsonc',
    'json',
    'lua',
    'php',
    'python',
    'rust',
    'scala',
    'scss',
    'toml',
    'vim',
    'yaml'
  }

  local selected_languages = utils.pick(options, 'languages', default_languages)
  local events = utils.pick(options, 'events', {
    'InsertLeave', 'TextChanged', 'FileReadPost'
  })

  if vim.tbl_isempty(selected_languages) then
    return
  end

  local analyser = M.provider({
    provider = utils.pick(options, 'provider', M.provider.treesitter()),
    picker = utils.pick(options, 'picker', M.picker.sensible()),
    languages = selected_languages,
    max_lines = utils.pick(options, 'max_lines', 100),
    disable = {
      new = utils.pick(options, { 'disable', 'new' }, false),
      no_extension = utils.pick(options, { 'disable', 'no_extension' }, true)
    }
  })

  if not vim.tbl_isempty(events) then
    auto.register(events, analyser.evaluate)
  end
end

return M;
