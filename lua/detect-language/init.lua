local ts = vim.treesitter
local tshealth = require('vim.treesitter.health')
local auto = require('detect-language.utils.auto')

local M = {}

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

-- pick highest score or the first item out of top 3, otherwise don't pick
local function pick_sensible(list)
  local highest = 0
  local picked = nil
  local same = 1

  for _, item in ipairs(list) do
    if item.score > highest then
      highest = item.score
      picked = item
      same = 1
    elseif item.score == highest and highest ~= 0 then
      same = same + 1
    end
  end

  if same > 3 then
    -- more than top 3, pick nothing
    return nil
  end
  return picked
end

local function build_analyser(languages, excludes)
  local A = {}

  A.analyse_language = function (code, language)
    local parser = ts.get_string_parser(code, language)

    local trees = parser:parse()
    local count = 0
    for _, tree in ipairs(trees) do
      local root = tree:root()
      local is_valid = not root:has_error() and not root:missing()

      if is_valid then
        count = count + count_children(root)
      end
    end

    return 1 + count
  end

  A.async_try_languages = function ()
    -- if is not a normal buffer, do nothing
    if vim.bo.buftype ~= '' then
      return
    end

    if A.analysing or excludes[string.lower(vim.bo.filetype)] then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), false)

    -- only process small file
    if vim.tbl_count(lines) > 100 then
      -- print('over the threshold')
      return
    end

    local code = table.concat(lines, '\n')

    local output = {}
    local function analyse_language (index)
      local language = languages[index]
      if not language then
        print(vim.inspect(output))

        local best_language = pick_sensible(output)
        if best_language then
          vim.bo.filetype = best_language.language
        else
          print('too many possible languages, try write some code')
        end
        A.analysing = false
        return
      end

      print('analysing', language)
      table.insert(output, {
        language = language,
        score = A.analyse_language(code, language)
      })

      vim.defer_fn(function () analyse_language(index + 1) end, 10)
    end

    A.analysing = true
    vim.defer_fn(function () analyse_language(1) end, 0)
  end

  -- Setup auto command
  auto.register(
    {
      'InsertLeave', 'TextChanged', 'FileReadPost'
    },
    A.async_try_languages
  )

  return A
end

M.available_languages = function ()
  local parsers = tshealth.list_parsers()

  local languages = {}
  for _, parser in ipairs(parsers) do
    local language = string.gsub(parser, '.*[\\/]', '')
    language = string.gsub(language, '[.][^.]*$', '')
    languages[language] = true
  end

  return languages;
end

M.setup = function (raw_options)
  local options = raw_options or {}

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

  local exclude_filetypes = options.excludes or { 'startify', 'nvimtree' }
  local selected_languages = options.languages or default_languages

  if not selected_languages or vim.tbl_count(selected_languages) == 0 then
    return
  end

  local available_languages = M.available_languages()
  local supported_languages = {}
  for _, language in ipairs(selected_languages) do
    if available_languages[language] then
      table.insert(supported_languages, language)
    end
  end
  local excludes = {}
  for _, filetype in ipairs(exclude_filetypes) do
    excludes[filetype] = true
  end

  return build_analyser(supported_languages, excludes)
end

return M;
