local utils = require('detect-language.utils')
local auto = require('detect-language.utils.auto')

local provider = require('detect-language.provider')
local picker = require('detect-language.picker')

local M = {}

M.setup = function (options)
  vim.validate({
    options = { options, 't', true }
  })
  if options then
    vim.validate({
      excludes = { options.excludes, 't', true },
      languages = { options.languages, 't', true },
      provider = { options.provider, 'f', true },
      picker = { options.provider, 'f', true },
      events = { options.events, 't', true },
      max_lines = { options.max_lines, 'n', true }
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

  local exclude_filetypes = utils.pick(options, 'excludes', { 'startify', 'nvimtree' })
  local selected_languages = utils.pick(options, 'languages', default_languages)
  local events = utils.pick(options, 'events', {
    'InsertLeave', 'TextChanged', 'FileReadPost'
  })

  if vim.tbl_isempty(selected_languages) then
    return
  end

  local analyser = provider({
    provider = utils.pick(options, 'provider', provider.treesitter()),
    picker = utils.pick(options, 'picker', picker.sensible()),
    excludes = utils.to_map(exclude_filetypes),
    languages = selected_languages,
    max_lines = utils.pick(options, 'max_lines', 100)
  })

  if not vim.tbl_isempty(events) then
    auto.register(events, analyser.evaluate)
  end
end

return M;
