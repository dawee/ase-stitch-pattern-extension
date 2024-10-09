local function rgbToHsl(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local b = max + min
  local h = b / 2
  if max == min then return 0, 0, h end
  local s, l = h, h
  local d = max - min
  s = l > .5 and d / (2 - b) or d / b
  if max == r then h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then h = (b - r) / d + 2
  elseif max == b then h = (r - g) / d + 4
  end
  return h * .16667, s, l
end

return rgbToHsl