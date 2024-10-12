local memoize = require('lib.memoize')

local chars =  {}

chars['0'] = require('fonts/RobotoMono-Regular.ttf@0,16')
chars['1'] = require('fonts/RobotoMono-Regular.ttf@1,16')
chars['2'] = require('fonts/RobotoMono-Regular.ttf@2,16')
chars['3'] = require('fonts/RobotoMono-Regular.ttf@3,16')
chars['4'] = require('fonts/RobotoMono-Regular.ttf@4,16')
chars['5'] = require('fonts/RobotoMono-Regular.ttf@5,16')
chars['6'] = require('fonts/RobotoMono-Regular.ttf@6,16')
chars['7'] = require('fonts/RobotoMono-Regular.ttf@7,16')
chars['8'] = require('fonts/RobotoMono-Regular.ttf@8,16')
chars['9'] = require('fonts/RobotoMono-Regular.ttf@9,16')

chars['s'] = require('fonts/RobotoMono-Regular.ttf@s,16')
chars['t'] = require('fonts/RobotoMono-Regular.ttf@t,16')
chars['i'] = require('fonts/RobotoMono-Regular.ttf@i,16')
chars['c'] = require('fonts/RobotoMono-Regular.ttf@c,16')
chars['h'] = require('fonts/RobotoMono-Regular.ttf@h,16')
chars['e'] = require('fonts/RobotoMono-Regular.ttf@e,16')
chars['x'] = require('fonts/RobotoMono-Regular.ttf@x,16')

chars['D'] = require('fonts/RobotoMono-Regular.ttf@D,16')
chars['M'] = require('fonts/RobotoMono-Regular.ttf@M,16')
chars['C'] = require('fonts/RobotoMono-Regular.ttf@C,16')

chars['W'] = require('fonts/RobotoMono-Regular.ttf@W,16')
chars['B'] = require('fonts/RobotoMono-Regular.ttf@B,16')

local font = {}

font.createCharImage = memoize.memoize(
  function (char, color)
    local pixels = chars[char]
    local charImage = Image { width = #(pixels[1]), height = #pixels }

    for y, row in ipairs(chars[char]) do
      for x, alpha in ipairs(row) do
        charImage:drawPixel(x - 1, y - 1, Color { red = color.red, green = color.green, blue = color.blue, alpha = 255 - alpha})
      end
    end

    return charImage
  end
)

function font.textImage(text, color)
  local length = string.len(text)
  local height = 0
  local width = 0

  for i = 1, length do
    local char = string.sub(text, i, i)

    if char == ' ' then
      char = '0'
    end

    local pixels = chars[char]

    if #pixels > height then
      height = #pixels
    end

    width = width + #(pixels[1])
  end


  local image = Image { width = width, height = height }
  local offset = 0

  for i = 1, length do
    local char = string.sub(text, i, i)
    local pixels = chars[char]

    if pixels == nil then
      pixels = chars['0']
    else
      image:drawImage(font.createCharImage(char, color), Point(offset, height - #pixels))
    end

    offset = offset + #(pixels[1])
  end

  return image
end

return font
