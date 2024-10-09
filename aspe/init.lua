local rgbToHsl = require('lib.rgb_to_hsl')
local memoize = require('lib.memoize')

local icons = {
  require("icons/1.png"),
  require("icons/2.png"),
  require("icons/3.png"),
  require("icons/4.png"),
  require("icons/5.png"),
  require("icons/6.png"),
  require("icons/7.png"),
  require("icons/8.png"),
  require("icons/9.png"),
  require("icons/10.png"),
  require("icons/11.png"),
  require("icons/12.png"),
  require("icons/13.png"),
  require("icons/14.png"),
  require("icons/15.png"),
  require("icons/16.png"),
  require("icons/17.png"),
  require("icons/18.png"),
  require("icons/19.png"),
  require("icons/20.png"),
}

local dlg = Dialog {
  title = "Export as stitch pattern",
}

local ICON_SIZE = 16
local TILE_SIZE = 16
local SUFFIX_ICONS_ONLY = '_icons_only'
local SUFFIX_COLORED_ICONS = '_colored_icons'

local COLOR_WHITE = app.pixelColor.rgba(255, 255, 255)
local COLOR_BLACK = app.pixelColor.rgba(0, 0, 0)
local COLOR_LIGHT_GREY = app.pixelColor.rgba(128, 128, 128)
local COLOR_DARK_GREY = app.pixelColor.rgba(64, 64, 64)

local LIGHT_BORDER_WIDTH = 1
local DARK_BORDER_WIDTH = 2

local GRID_CELL_SIZE = 10

local function _createIconImage(icon_index, color)
  local icon = icons[icon_index]
  local icon_image = Image { width = TILE_SIZE, height = TILE_SIZE }

  for y, row in ipairs(icon) do
    for x, value in ipairs(row) do
      if value == 1 then
        icon_image:drawPixel(x + (TILE_SIZE - ICON_SIZE) // 2 - 1, y + (TILE_SIZE - ICON_SIZE) // 2 - 1, color)
      end
    end
  end

  return icon_image
end

local function _createUnicolorImage(color)
  local image = Image { width = TILE_SIZE, height = TILE_SIZE }

  image:clear(Rectangle(0, 0, TILE_SIZE, TILE_SIZE), color)
  return image
end

local function _createLeftBorderImage(width, color)
  local image = Image { width = width, height = TILE_SIZE }

  image:clear(Rectangle(0, 0, width, TILE_SIZE), color)
  return image
end

local function _createTopBorderImage(width, color)
  local image = Image { width = TILE_SIZE, height = width }

  image:clear(Rectangle(0, 0, TILE_SIZE, width), color)
  return image
end


local unicolorImage = memoize.memoize(_createUnicolorImage)
local iconImage = memoize.memoize(_createIconImage)
local leftBorderImage = memoize.memoize(_createLeftBorderImage)
local topBorderImage = memoize.memoize(_createTopBorderImage)


local function tiles()
  local uniqueColorsCount = 0
  local colorsMapping = {}
  local next = app.image:pixels()

  return function ()
    local pixel = next()

    if pixel ~= nil then
      local tile = {}
      tile.pixelValue = pixel()

      if colorsMapping[tile.pixelValue] == nil then
        uniqueColorsCount = uniqueColorsCount + 1
        colorsMapping[tile.pixelValue] = uniqueColorsCount
      end

      tile.x = pixel.x
      tile.y = pixel.y
      tile.iconIndex = colorsMapping[tile.pixelValue]
      tile.leftBorderWidth = LIGHT_BORDER_WIDTH
      tile.leftBorderColor = COLOR_LIGHT_GREY
      tile.topBorderWidth = LIGHT_BORDER_WIDTH
      tile.topBorderColor = COLOR_LIGHT_GREY

      if pixel.x % GRID_CELL_SIZE == 0 then
        tile.leftBorderWidth = DARK_BORDER_WIDTH
        tile.leftBorderColor = COLOR_DARK_GREY
      end

      if pixel.y % GRID_CELL_SIZE == 0 then
        tile.topBorderWidth = DARK_BORDER_WIDTH
        tile.topBorderColor = COLOR_DARK_GREY
      end

      return tile
    end
  end

end


local function exportIconsOnly(filePath)
  local iconsOnlyImage = Image(app.image.width * TILE_SIZE, app.image.height * TILE_SIZE)

  for tile in tiles() do
    iconsOnlyImage:drawImage(unicolorImage(COLOR_WHITE), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    iconsOnlyImage:drawImage(leftBorderImage(tile.leftBorderWidth, tile.leftBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    iconsOnlyImage:drawImage(topBorderImage(tile.topBorderWidth, tile.topBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))

    if app.pixelColor.rgbaA(tile.pixelValue) ~= 0 then
      iconsOnlyImage:drawImage(iconImage(tile.iconIndex, COLOR_BLACK), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    end
  end

  iconsOnlyImage:saveAs(filePath)
end

local function exportColoredIcons(filePath)
  local iconsOnlyImage = Image(app.image.width * TILE_SIZE, app.image.height * TILE_SIZE)

  for tile in tiles() do
    if app.pixelColor.rgbaA(tile.pixelValue) ~= 0 then
      iconsOnlyImage:drawImage(unicolorImage(tile.pixelValue), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    else
      iconsOnlyImage:drawImage(unicolorImage(COLOR_WHITE), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    end

    iconsOnlyImage:drawImage(leftBorderImage(tile.leftBorderWidth, tile.leftBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    iconsOnlyImage:drawImage(topBorderImage(tile.topBorderWidth, tile.topBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))

    if app.pixelColor.rgbaA(tile.pixelValue) ~= 0 then
      local h, s, l = rgbToHsl(app.pixelColor.rgbaR(tile.pixelValue), app.pixelColor.rgbaG(tile.pixelValue), app.pixelColor.rgbaB(tile.pixelValue), app.pixelColor.rgbaA(tile.pixelValue))
      local iconColor = COLOR_BLACK

      if l < 128 then
        iconColor = COLOR_WHITE
      end
      

      iconsOnlyImage:drawImage(iconImage(tile.iconIndex, iconColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    end
  end

  iconsOnlyImage:saveAs(filePath)
end

local function export_all()
  if dlg.data.outputFilePath ~= nil then
    local base_name = app.fs.filePathAndTitle(dlg.data.outputFilePath)
      :gsub(SUFFIX_ICONS_ONLY, '')
      :gsub(SUFFIX_COLORED_ICONS, '')

    exportIconsOnly(base_name .. SUFFIX_ICONS_ONLY .. '.png')
    exportColoredIcons(base_name .. SUFFIX_COLORED_ICONS .. '.png')
  end
end


dlg:file {
  id = "outputFilePath",
  label = "File name",
  save = true,
  open = false,
  filetypes = {"png"},
}

dlg:button{
  id= "export",
  text= "Export",
  onclick = function ()
    export_all()
    dlg:close()
  end
}

dlg:show()