local memoize = require('lib.memoize')

local icons = require('aspe.icons')
local font = require('aspe.font')
local colors = require('aspe.colors')

local ICON_SIZE = 16
local TILE_SIZE = 16
local SUFFIX_ICONS_ONLY = '_icons_only'
local SUFFIX_COLORED_ICONS = '_colored_icons'

local LIGHT_BORDER_WIDTH = 1
local DARK_BORDER_WIDTH = 2

local GRID_CELL_SIZE = 10
local GRID_MARGIN = 5

local PAGE_MARGIN_TOP = 60
local PAGE_MARGIN_RIGHT = 160
local PAGE_MARGIN_BOTTOM = 260
local PAGE_MARGIN_LEFT = 160

local LEGEND_MARGIN_WIDTH = 20

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


local iconImage = memoize.memoize(_createIconImage)
local leftBorderImage = memoize.memoize(_createLeftBorderImage)
local topBorderImage = memoize.memoize(_createTopBorderImage)


local function tiles()
  local uniqueColorsCount = 0
  local colorsMapping = {}
  local next = app.image:pixels()

  return function ()
    local pixelHandle = next()

    if pixelHandle ~= nil then
      local tile = {}
      local pixel = pixelHandle()
      local originalColor = colors.pixelToColor(pixel)

      if colorsMapping[pixel] == nil and originalColor.alpha > 0 then
        uniqueColorsCount = uniqueColorsCount + 1
        colorsMapping[pixel] = {
          iconIndex = uniqueColorsCount,
          stitch = colors.findClosestStitchToPixel(pixel)
        }
      end

      if colorsMapping[pixel] ~= nil then
        tile.color = colorsMapping[pixel].stitch.color
        tile.stitchRef = colorsMapping[pixel].stitch.ref
        tile.iconIndex = colorsMapping[pixel].iconIndex
      else
        tile.color = colors.WHITE
        tile.stitchRef = nil
        tile.iconIndex = nil
      end

      tile.xend = pixelHandle.x == app.image.width
      tile.yend = pixelHandle.y == app.image.height
      tile.x = pixelHandle.x
      tile.y = pixelHandle.y
      tile.leftBorderWidth = LIGHT_BORDER_WIDTH
      tile.leftBorderColor = colors.LIGHT_GREY
      tile.topBorderWidth = LIGHT_BORDER_WIDTH
      tile.topBorderColor = colors.LIGHT_GREY

      if pixelHandle.x % GRID_CELL_SIZE == 0 then
        tile.leftBorderWidth = DARK_BORDER_WIDTH
        tile.leftBorderColor = colors.DARK_GREY
      end

      if pixelHandle.y % GRID_CELL_SIZE == 0 then
        tile.topBorderWidth = DARK_BORDER_WIDTH
        tile.topBorderColor = colors.DARK_GREY
      end

      return tile
    end
  end

end

local LEGEND_SLOT_WIDTH = 200
local LEGEND_SLOT_HEIGHT = 32

local function legendSlotImage(iconIndex, count, color, ref)
  local legendSlotImage = Image { width=LEGEND_SLOT_WIDTH, height=LEGEND_SLOT_HEIGHT }
  local colorOutlineImage = Image { width=TILE_SIZE, height=TILE_SIZE }
  local iconOutlineImage = Image { width=TILE_SIZE, height=TILE_SIZE }

  -- legendSlotImage:clear(Rectangle(0, 0, legendSlotImage.width, legendSlotImage.height), colors.LIGHT_GREY)

  colorOutlineImage:clear(Rectangle(0, 0, colorOutlineImage.width, colorOutlineImage.height), colors.DARK_GREY)
  colorOutlineImage:clear(Rectangle(DARK_BORDER_WIDTH, DARK_BORDER_WIDTH, colorOutlineImage.width - DARK_BORDER_WIDTH * 2, colorOutlineImage.height - DARK_BORDER_WIDTH * 2), color)

  iconOutlineImage:clear(Rectangle(0, 0, iconOutlineImage.width, iconOutlineImage.height), colors.DARK_GREY)
  iconOutlineImage:clear(Rectangle(DARK_BORDER_WIDTH, DARK_BORDER_WIDTH, iconOutlineImage.width - DARK_BORDER_WIDTH * 2, iconOutlineImage.height - DARK_BORDER_WIDTH * 2), colors.WHITE)
  iconOutlineImage:drawImage(iconImage(iconIndex, colors.BLACK), Point(0, 0))

  local verticalOffset = (LEGEND_SLOT_HEIGHT - TILE_SIZE) // 2
  local horizontalOffset = verticalOffset

  legendSlotImage:drawImage(colorOutlineImage, Point(horizontalOffset, verticalOffset))

  horizontalOffset = horizontalOffset + colorOutlineImage.width

  legendSlotImage:drawImage(iconOutlineImage,  Point(horizontalOffset, verticalOffset))

  horizontalOffset = horizontalOffset + iconOutlineImage.width + TILE_SIZE // 2

  legendSlotImage:drawImage(font.textImage('x' .. count .. ' DMC ' .. ref, colors.BLACK), Point(horizontalOffset, verticalOffset))

  return legendSlotImage
end

local function legendImage(width, height)
  local outLineImage = Image { width=width, height=height }
  local contentImage = Image { width=width - DARK_BORDER_WIDTH * 2, height=height  - DARK_BORDER_WIDTH * 2}
  local slots = {}

  for tile in tiles() do
    if tile.iconIndex ~= nil then
      if slots[tile.stitchRef] == nil then
        slots[tile.stitchRef] = {
          count = 0,
          color = tile.color,
          iconIndex = tile.iconIndex
        }
      end

      slots[tile.stitchRef].count = slots[tile.stitchRef].count + 1
    end
  end

  outLineImage:clear(Rectangle(0, 0, width, height), colors.DARK_GREY)
  contentImage:clear(Rectangle(0, 0, contentImage.width, contentImage.height), colors.WHITE)


  local verticalOffset = 0
  local horizontalOffset = 0

  for stitchRef, slot in pairs(slots) do
    contentImage:drawImage(legendSlotImage(slot.iconIndex, slot.count, slot.color, stitchRef), Point(horizontalOffset, verticalOffset))
    verticalOffset = verticalOffset + LEGEND_SLOT_HEIGHT

    if verticalOffset + LEGEND_SLOT_HEIGHT > contentImage.height then
      verticalOffset = 0
      horizontalOffset = horizontalOffset + LEGEND_SLOT_WIDTH
    end
  end


  outLineImage:drawImage(contentImage, Point(DARK_BORDER_WIDTH, DARK_BORDER_WIDTH))

  return outLineImage
end


local function writePage(filePath, inputImage)
  local pageWidth = inputImage.width + PAGE_MARGIN_LEFT + PAGE_MARGIN_RIGHT
  local pageHeight = inputImage.height + PAGE_MARGIN_TOP + PAGE_MARGIN_BOTTOM
  local pageImage = Image(pageWidth, pageHeight)

  local gridCols = app.image.width // GRID_CELL_SIZE
  local gridRows = app.image.height // GRID_CELL_SIZE

  pageImage:clear(Rectangle(0, 0, pageWidth, pageHeight), colors.WHITE)
  pageImage:clear(Rectangle(PAGE_MARGIN_LEFT, PAGE_MARGIN_TOP, inputImage.width + DARK_BORDER_WIDTH, inputImage.height + DARK_BORDER_WIDTH), colors.DARK_GREY)

  for i = 1, gridCols do
    local textImg = font.textImage(tostring(i * GRID_CELL_SIZE), colors.BLACK)

    pageImage:drawImage(textImg, Point(PAGE_MARGIN_LEFT + TILE_SIZE * i * GRID_CELL_SIZE - textImg.width / 2, PAGE_MARGIN_TOP - textImg.height - GRID_MARGIN))
    pageImage:drawImage(textImg, Point(PAGE_MARGIN_LEFT + TILE_SIZE * i * GRID_CELL_SIZE - textImg.width / 2, PAGE_MARGIN_TOP + inputImage.height + GRID_MARGIN))
  end

  for i = 1, gridRows do
    local textImg = font.textImage(tostring(i * GRID_CELL_SIZE), colors.BLACK)

    pageImage:drawImage(textImg, Point(PAGE_MARGIN_LEFT - textImg.width - GRID_MARGIN, PAGE_MARGIN_TOP + TILE_SIZE * i * GRID_CELL_SIZE - textImg.height / 2))
    pageImage:drawImage(textImg, Point(PAGE_MARGIN_LEFT + inputImage.width + GRID_MARGIN, PAGE_MARGIN_TOP + TILE_SIZE * i * GRID_CELL_SIZE - textImg.height / 2))
  end

  pageImage:drawImage(inputImage, Point(PAGE_MARGIN_LEFT, PAGE_MARGIN_TOP))


  pageImage:drawImage(legendImage(inputImage.width, PAGE_MARGIN_BOTTOM - LEGEND_MARGIN_WIDTH * 2), Point(PAGE_MARGIN_LEFT, pageHeight - PAGE_MARGIN_BOTTOM + LEGEND_MARGIN_WIDTH))

  pageImage:saveAs(filePath)
end


local function exportIconsOnly(filePath)
  local iconsOnlyImage = Image(app.image.width * TILE_SIZE, app.image.height * TILE_SIZE)
  
  iconsOnlyImage:clear(Rectangle(0, 0, app.image.width * TILE_SIZE, app.image.height * TILE_SIZE), colors.WHITE)

  for tile in tiles() do
    iconsOnlyImage:drawImage(leftBorderImage(tile.leftBorderWidth, tile.leftBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    iconsOnlyImage:drawImage(topBorderImage(tile.topBorderWidth, tile.topBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))

    if tile.iconIndex ~= nil then
      iconsOnlyImage:drawImage(iconImage(tile.iconIndex, colors.BLACK), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    end
  end

  writePage(filePath, iconsOnlyImage)
end

local function exportColoredIcons(filePath)
  local coloredIconsImage = Image(app.image.width * TILE_SIZE, app.image.height * TILE_SIZE)

  coloredIconsImage:clear(Rectangle(0, 0, app.image.width * TILE_SIZE, app.image.height * TILE_SIZE), colors.WHITE)

  for tile in tiles() do
    if tile.iconIndex ~= nil then
      coloredIconsImage:clear(Rectangle(tile.x * TILE_SIZE, tile.y * TILE_SIZE, TILE_SIZE, TILE_SIZE), tile.color)
    end

    coloredIconsImage:drawImage(leftBorderImage(tile.leftBorderWidth, tile.leftBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    coloredIconsImage:drawImage(topBorderImage(tile.topBorderWidth, tile.topBorderColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))

    if tile.iconIndex ~= nil then
      local iconColor = colors.BLACK

      if tile.color.lightness < 0.5 then
        iconColor = colors.WHITE
      end

      coloredIconsImage:drawImage(iconImage(tile.iconIndex, iconColor), Point(tile.x * TILE_SIZE, tile.y * TILE_SIZE))
    end
  end

  writePage(filePath, coloredIconsImage)
end

local function run()
  local dlg = Dialog {
    title = "Export as stitch pattern",
  }

  dlg:file {
    id = "outputFilePath",
    label = "File name",
    save = true,
    open = false,
    filetypes = {"png"},
  }

  dlg:button{
    id= "export",
    text= "Export as stitch pattern",
    onclick = function ()
      if dlg.data.outputFilePath ~= nil then
        local base_name = app.fs.filePathAndTitle(dlg.data.outputFilePath)
          :gsub(SUFFIX_ICONS_ONLY, '')
          :gsub(SUFFIX_COLORED_ICONS, '')

        exportIconsOnly(base_name .. SUFFIX_ICONS_ONLY .. '.png')
        exportColoredIcons(base_name .. SUFFIX_COLORED_ICONS .. '.png')
      end

      dlg:close()
    end
  }

  dlg:show()
end

return {
  run = run
}