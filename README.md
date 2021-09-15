# detect-language.nvim

_This plugin still under development, please use at your own risk_

This plugin provide a better language auto-detection to neovim, powered by tree-sitter

## Installation

Install using a plugin manager of your choice, for example

```viml
Plug 'nvim-treesitter/nvim-treesitter'   " not required but recommended
Plug 'spywhere/detect-language.nvim'
```

## Setup

Simply put the following configuration to your .lua config file

```lua
require('detect-language').setup {
  languages = { },  -- list of languages to be auto-detected (must be supported by tree-sitter)
  excludes = { },  -- list of file types to not trigger auto-detection
}
```
