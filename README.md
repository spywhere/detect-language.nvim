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

## How it works

This plugin simply list all available languages supported by tree-sitter and
iterate through each of the language. The whole document will pass to its
parser and keep record of a number of nodes parsed by tree-sitter. Once all
languages are parsed, it will be picked by the following algorithm...

- Pick the language with highest number of nodes (this typically means proper parsing)
- Only pick if there are less than or equal to 3 languages with the same number of nodes
- Otherwise, nothing is pick

Languages listed in the configuration are order sensitive, to allow prioritization of language ordering.
So if JavaScript comes before TypeScript and both has the same score, JavaScript will be picked.
