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

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local memoize = {
  _VERSION     = 'memoize v2.0',
  _DESCRIPTION = 'Memoized functions in Lua',
  _URL         = 'https://github.com/kikito/memoize.lua',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2018 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}
-- Inspired by http://stackoverflow.com/questions/129877/how-do-i-write-a-generic-memoize-function

-- Lua 5.3 compatibility
local unpack = unpack or table.unpack

-- private stuff

local function is_callable(f)
  local tf = type(f)
  if tf == 'function' then return true end
  if tf == 'table' then
    local mt = getmetatable(f)
    return type(mt) == 'table' and is_callable(mt.__call)
  end
  return false
end

local function cache_get(cache, params)
  local node = cache
  for i=1, #params do
    node = node.children and node.children[params[i]]
    if not node then return nil end
  end
  return node.results
end

local function cache_put(cache, params, results)
  local node = cache
  local param
  for i=1, #params do
    param = params[i]
    node.children = node.children or {}
    node.children[param] = node.children[param] or {}
    node = node.children[param]
  end
  node.results = results
end

-- public function

function memoize.memoize(f, cache)
  cache = cache or {}

  if not is_callable(f) then
    error(string.format(
            "Only functions and callable tables are memoizable. Received %s (a %s)",
             tostring(f), type(f)))
  end

  return function (...)
    local params = {...}

    local results = cache_get(cache, params)
    if not results then
      results = { f(...) }
      cache_put(cache, params, results)
    end

    return unpack(results)
  end
end

setmetatable(memoize, { __call = function(_, ...) return memoize.memoize(...) end })

--------------------------------------------------------------------------
--------------------------------------------------------------------------


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