# detect-language.nvim

_This plugin still under development_

This plugin provide a better language auto-detection to neovim, powered by tree-sitter

![demo](https://user-images.githubusercontent.com/1087399/133861833-9e221aca-0a9e-471a-8501-31893e3a3596.gif)

## Installation

Install using a plugin manager of your choice, for example

```viml
Plug 'nvim-treesitter/nvim-treesitter'   " not required but recommended
Plug 'spywhere/detect-language.nvim'
```

## Setup

Simply put the following configuration to your .lua config file

```lua
require('detect-language').setup {}
```

The following configuration is defaults included with this plugin

```lua
local detect_language = require('detect-language')
detect_language.setup {
  -- list of languages to be auto-detected (must be supported by tree-sitter)
  languages = {
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
  },
  -- auto-detection analyser
  provider = detect_language.provider.treesitter {
    -- minimum score to be considered as candidate languages
    minimum = 0
  },
  -- language picker
  picker = detect_language.picker.sensible {
    -- pick when there is less than or equal to this number of suitable languages
    top = 3
  },
  -- autocmd events to trigger auto-detection
  events = { 'InsertLeave', 'TextChanged', 'FileReadPost' },
  -- command configurations
  commands = {
    -- Prefix for command (set to empty will disable all commands)
    prefix = 'DetectLanguage',
    -- Enable buffer toggle command (suffixed with 'BufToggle')
    toggle = true,
    -- Enable buffer enable command (suffixed with 'BufEnable')
    enable = true,
    -- Enable buffer disable command (suffixed with 'BufDisable')
    disable = true,
    -- Enable manual trigger for auto-detection command (no suffix)
    oneshot = true
  },
  -- disable auto-detection for buffer over this number of lines (set to 0 for no limit)
  max_lines = 100,
  -- fine-grain setup
  disable = {
    -- disable auto-detection on new buffer
    new = false,
    -- disable auto-detection on buffer with no extension
    no_extension = true
  }
}
```

Languages listed in the configuration are order sensitive, to allow prioritization of language ordering.
So if JavaScript comes before TypeScript and both has the same score, JavaScript will be picked.

## Analyser

### Treesitter

Language analyser powered by tree-sitter

```lua
require('detect-language').provider.treesitter {}
```

## Picker

### Sensible

A sensible language picker using the algorithm explained below

```lua
require('detect-language').picker.sensible {
  -- allow up to this number of the same score, otherwise will not pick
  top = 3
}
```

#### Algorithm

- Pick the language with highest score
- Keep track of languages with the same highest score
- Pick the first language if there are less than or equal to `n` number of languages with highest score
- Otherwise, nothing is pick

## How it works

This plugin simply list all available languages supported by the specific provider,
then it will iterate through each of the language. The whole document will pass
to its provider's analyser and keep record of the score produced. Once all the
languages are paresed, all scores will be submitted to the picker to select the
suitable language.
