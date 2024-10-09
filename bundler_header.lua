local __modules__ = {}
local __defines__ = {}


local function __define__(name, handler)
  __defines__[name] = handler
end

local function __require__(name)
  if __modules__[name] == nil then
    __modules__[name] = __defines__[name]()
  end
  
  return __modules__[name]
end
