local state = require('detect-language.state')
local utils = require('detect-language.utils')
local nvim = require('detect-language.utils.nvim')

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
      provider = { options.provider, 'c', true },
      picker = { options.provider, 'c', true },
      events = { options.events, 't', true },
      commands = { options.commands, 't', true },
      max_lines = { options.max_lines, 'n', true },
      disable = { options.disable, 't', true }
    })

    if options.commands then
      vim.validate({
        prefix = { options.commands.prefix, 's', true },
        toggle = { options.commands.toggle, 'b', true },
        enable = { options.commands.enable, 'b', true },
        disable = { options.commands.disable, 'b', true },
        oneshot = { options.commands.oneshot, 'b', true },
      })
    end
    if options.disable then
      vim.validate({
        new = { options.disable.new, 'b', true },
        no_extension = { options.disable.no_extension, 'b', true }
      })
    end
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
    nvim.auto(events, function () return analyser.evaluate {} end)
  end

  local command_prefix = utils.pick(
    options, { 'commands', 'prefix' }, 'DetectLanguage'
  )

  local commands = {
    toggle = {
      suffix = 'BufToggle',
      fn = function ()
        state.toggle()
      end
    },
    enable = {
      suffix = 'BufEnable',
      fn = function ()
        state.enable()
      end
    },
    disable = {
      suffix = 'BufDisable',
      fn = function ()
        state.disable()
      end
    },
    oneshot = {
      fn = function ()
        analyser.evaluate { oneshot = true }
      end
    }
  }

  if command_prefix ~= '' then
    for key, config in pairs(commands) do
      if utils.pick(options, { 'commands', key }, true) then
        nvim.cmd(command_prefix .. (config.suffix or ''), {
          config.fn
        })
      end
    end
  end
end

return M;
