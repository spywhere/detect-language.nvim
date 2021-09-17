local utils = require('detect-language.utils')

-- pick highest score or the first item out of top 3, otherwise don't pick
return function (options)
  local M = {}

  M.pick = function (list)
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

    if same > utils.pick(options, 'top', 3) then
      -- more than top 3, pick nothing
      return nil
    end
    return picked
  end

  return M
end
