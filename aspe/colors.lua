local memoize = require('lib.memoize')
local stitches = require('aspe.stitches')

local colors = {}

colors.pixelToColor = memoize.memoize(
  function (pixel)
    return Color {
      r=app.pixelColor.rgbaR(pixel),
      g=app.pixelColor.rgbaG(pixel),
      b=app.pixelColor.rgbaB(pixel),
      a=app.pixelColor.rgbaA(pixel),
    }
  end
)

colors.RED = colors.pixelToColor(app.pixelColor.rgba(255, 0, 0))
colors.WHITE = colors.pixelToColor(app.pixelColor.rgba(255, 255, 255))
colors.BLACK = colors.pixelToColor(app.pixelColor.rgba(0, 0, 0))
colors.LIGHT_GREY = colors.pixelToColor(app.pixelColor.rgba(128, 128, 128))
colors.DARK_GREY = colors.pixelToColor(app.pixelColor.rgba(64, 64, 64))


function colors.distance(colorA, colorB)
  return math.sqrt((colorB.red - colorA.red) ^ 2 + (colorB.green - colorA.green) ^ 2  + (colorB.blue - colorA.blue) ^ 2)
end

local function findClosestStitchToColor(color)
  local minDistance = nil
  local closest = nil

  for ref, stitchColor in pairs(stitches.refs) do
    local distance = colors.distance(color, stitchColor)

    if closest == nil or distance < minDistance then
      minDistance = distance
      closest = {
        color = stitchColor,
        ref = ref
      }
    end
  end

  return closest
end

colors.findClosestStitchToPixel = memoize.memoize(
  function (pixel)
    return findClosestStitchToColor(colors.pixelToColor(pixel))
  end
)

return colors