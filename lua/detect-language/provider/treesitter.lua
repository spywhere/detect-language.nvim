local ts = vim.treesitter
local utils = require('detect-language.utils')

local function count_children(node, level)
  if level == nil then
    level = 1
  end
  if not node then
    return 0
  end

  local count = 1;

  for index=0, node:child_count() - 1 do
    local child = node:child(index)
    count = count + count_children(child, level + 1)
  end

  return count
end

return function (options)
  local M = {}
  local minimum = utils.pick(options, 'minimum', 0)

  M.get_supported_languages = function ()
    local parsers = vim.api.nvim_get_runtime_file('parser/*', true)

    local languages = {}
    for _, parser in ipairs(parsers) do
      local language = string.gsub(parser, '.*[\\/]', '')
      language = string.gsub(language, '[.][^.]*$', '')
      languages[language] = true
    end

    return languages;
  end

  M.analyse = function (code, language)
    local parser = ts.get_string_parser(code, language)

    local trees = parser:parse()
    local count = 1
    for _, tree in ipairs(trees) do
      local root = tree:root()
      local is_valid = not root:has_error() and not root:missing()

      if is_valid then
        count = count + count_children(root)
      end
    end

    if count < minimum then
      return nil
    end
    return count
  end

  return M
end
