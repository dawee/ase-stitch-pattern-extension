local memoize = require('lib.memoize')

local chars =  {}

chars['0'] = require('fonts/Varela-Regular.ttf@0,16')
chars['1'] = require('fonts/Varela-Regular.ttf@1,16')
chars['2'] = require('fonts/Varela-Regular.ttf@2,16')
chars['3'] = require('fonts/Varela-Regular.ttf@3,16')
chars['4'] = require('fonts/Varela-Regular.ttf@4,16')
chars['5'] = require('fonts/Varela-Regular.ttf@5,16')
chars['6'] = require('fonts/Varela-Regular.ttf@6,16')
chars['7'] = require('fonts/Varela-Regular.ttf@7,16')
chars['8'] = require('fonts/Varela-Regular.ttf@8,16')
chars['9'] = require('fonts/Varela-Regular.ttf@9,16')

local FONT_SIZE = 16

local font = {}

local function _createCharImage(char, color)
  local pixels = chars[char]
  local charImage = Image { width = #(pixels[1]), height = #pixels }

  for y, row in ipairs(chars[char]) do
    for x, value in ipairs(row) do
      if value == 1 then
        charImage:drawPixel(x - 1, y - 1, color)
      end
    end
  end

  return charImage
end

font.createCharImage = memoize.memoize(_createCharImage)

function font.textImage(text, color)
  local length = string.len(text)
  local height = 0
  local width = 0

  for i = 1, length do
    local pixels = chars[string.sub(text, i, i)]

    if #pixels > height then
      height = #pixels
    end

    width = width + #(pixels[1])
  end


  local image = Image { width = width, height = height }
  local offset = 0

  for i = 1, length do
    local pixels = chars[string.sub(text, i, i)]

    image:drawImage(font.createCharImage(string.sub(text, i, i), color), Point(offset, height - #pixels))
    offset = offset + #(pixels[1])
  end

  return image
end

return font
