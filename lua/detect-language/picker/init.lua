return setmetatable({}, {
  __index = function (_, key)
    return require(string.format('detect-language.picker.%s', key))
  end
})
