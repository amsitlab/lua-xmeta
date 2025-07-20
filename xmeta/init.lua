
---@diagnostic disable: redefined-local
---@alias xmeta.todo fun(obj: xmeta.Object)

local error = error
local string = string
local format = string.format
local tonumber = tonumber
local os = os
local getenv = os and os.getenv
local _VERSION = _VERSION
local _, MIN_VERSION = _VERSION:match("Lua%s+(%d)%.(%d)")
MIN_VERSION = tonumber(MIN_VERSION)
local XMETA_STRICT_TODO = getenv and getenv('XMETA_STRICT_TODO')

---@type xmeta.todo
local todo = function (_)
end
if XMETA_STRICT_TODO then
  --{{{
  local debug = debug
  local getinfo = debug and debug.getinfo
  if getinfo then
    todo = function (obj)
      local __type__ = obj
      local __kind__ = obj.__kind__
      local type_name = obj.__name__
      if __kind__ == 'object' then
        __type__ = obj.__type__
         type_name = __type__.__name__
       end
      local field_name = getinfo(1, 'n').name or '<unknown>'
      if not __type__[field_name] then
        field_name = '__invoke'
      end
      error(format('Attempt to call [todo] method %s.%s', type_name, field_name))
    end
  end
  --}}}
end

local mode_key = { __mode = 'k' }
NAMES = setmetatable({}, mode_key)
BASES = setmetatable({}, mode_key)
local READONLY = {
  __base__ = true,
  __kind__ = true,
  __name__ = true,
  __type__ = true,
}


---@generic T: xmeta.Object
---@param name string
---@param base? T
---@param t table
---@return T t
local function init(name, base, t)
  NAMES[t] = name
  BASES[t] = base
  if not base then return t end
  t.__index = t.__index or base.__index
  t.__newindex = t.__newindex or base.__newindex or rawset
  t.__tostring = t.__tostring or base.__tostring
  t.__call = t.__call or base.__call
  t.__pairs = t.__pairs or base.__pairs
  t.__ipairs = t.__ipairs or base.__ipairs
  t.__eq = t.__eq or base.__eq
  t.__add = t.__add or base.__add
  t.__sub = t.__sub or base.__sub
  t.__mul = t.__mul or base.__mul
  t.__div = t.__div or base.__div
  t.__pow = t.__pow or base.__pow
  t.__mod = t.__mod or base.__mod

  return t
end

---The base type of the type hirarchy
---@class xmeta.Object: table
---@field __type__ xmeta.Object
---@field __name__? string
---@field __base__? xmeta.Object
---@field __kind__ string
---@field protected __invoke fun(self: xmeta.Object, ...): any
local Object do
-- {{{

  ---@class xmeta.Object
  Object = init('xmeta.Object', nil, {
    new = todo,
    __new = todo,
    __invoke = todo,
    __index = todo,
    __call = todo,
    __tostring = todo,
  })


  ---@protected
  function Object:__index(k)
    if k == '__kind__' then
      return 'object'
    end
    local meta = getmetatable(self)
    if k == '__type__' then return meta end
    local v = rawget(self, k)
    if v then return v end
    v = meta[k]
    if v then return v end
  end

  ---@protected
  function Object:__newindex(k, v)
    local ro = READONLY
    if ro[k] then
      local error = error
      local f = format
      local t = self.__kind__ == "type" and self or self.__type__
      local n = t.__name__
      error(f("Attempt to assign read-only field: %s.%s",n, k), 2)
    end
    local rawset = self['__set'] or rawset
    return rawset(self, k, v)
  end


  ---@protected
  function Object.__tostring(self)
    local __kind__ = self.__kind__
    local __type__ = self.__type__
    local __name__ = self.__name__
    local of = ' '
    if __kind__ == 'object' then
      __name__ = __type__.__name__
      of = ' of '
    end
    return format('<%s%s%s>', __kind__, of, __name__)
  end

  ---@protected
  function Object:__call(...)
    local kind = self.__kind__
    local invoke = self.new
    local typename = self.__name__
    if kind == 'object' then
      typename = self.__type__.__name__
      invoke = self.__invoke
    end
    if type(invoke) ~= "function" then
      error(format('Attemp to invoke %s', typename))
    end
    return invoke(self, ...)
  end

  ---@protected
  ---@generic T: xmeta.Object
  ---@param self T
  ---@return T
  function Object.new(self, ...)

    local instance = {...}
    local n = #instance
    if n == 1 and type(instance[1]) == 'table' then
      instance = instance[1]
    end

    return setmetatable(instance, self)
  end


-- }}}
end

---@class xmeta.Type: xmeta.Object
local Type = init('xmeta.Type', Object, {
  new = todo,
  __index = todo,
  __newindex = todo,
  __tostring = Object.__tostring,
  __call = Object.__call,
})

---@protected
function Type:__index(k)
  if k == '__kind__' then return 'type' end
  if k == '__name__' then return NAMES[self] end
  local meta = getmetatable(self)
  if k == '__type__' then return meta end
  local base = BASES[self]
  if k == '__base__' then return base end

  local v = rawget(self, k)
  if v then return v end
  if not base then return end
  v = base[k]
  if v then return v end
end

---@protected
Type.__newindex = Object.__newindex

---@protected
---@generic O: xmeta.Object, T: xmeta.Type
---@param self T
---@param val any|`O`
---@return O
function Type.new(self, val, base, defs)
  if not(base or defs) then
    local type = _G.type
    local t = type(val)
    if t ~= "table" then
      return t
    end
    local mt = getmetatable(val)
    if not mt then return t end
    return mt.__type__ or t
  end

  local name = val
  ---@diagnostic disable-next-line: undefined-field
  base = base or self.__base__
  defs = init(name, base, defs or {})

  return setmetatable(defs, self)
end


---@class xmeta.Type
Type = setmetatable(Type --[[@as table]], Type --[[@as table]])
setmetatable(Object, Type --[[@as table]])

---@class xmeta
local xmeta
-- {{{
local pairs = _G.pairs
local ipairs = _G.ipairs
xmeta = init("xmeta", Type, {
  is = todo,
  is_based = todo,
  pairs = pairs,
  ipairs = ipairs,
  len = todo,
  todo = todo,
  Type = false,
  Object = false,
})

---Is `T1` based on `T2`?
---@generic T1: xmeta.Object, T2: xmeta.Object
---@param T1 T1
---@param T2 T2
---@param recursive? boolean default: **true**
---@return boolean
function xmeta.is_based(T1, T2, recursive)
  local self = T1 ---@class xmeta.Object
  local root = T2 ---@class xmeta.Object
  if self.__kind__ ~= "type" or root.__kind__ ~= "type" then
    return false
  end
  local base = BASES[self]
  if not base then return false end
  if base == root then return true end
  if recursive ~= false then
    repeat
      base = BASES[base]
      if base == root then return true end
    until base == nil
  end
  return false
end

---Is `self` type of `obj` ?
---@param self xmeta.Object kind: type
---@param obj xmeta.Object kind: object
function xmeta.is(self, obj, recursive)
  local is_based = xmeta.is_based
  local self_t = type(self)
  local obj_t = type(obj)
  if not(self_t == "table" and obj_t == "table") then
    return false
  end
  if self.__kind__ ~= "type" or obj.__kind__ ~= "object" then
    return false
  end
  local __type__ = obj.__type__
  if self == __type__ then return true end
  if recursive ~= false then
    return is_based(__type__, self, recursive)
  end
  return false
end

---Counting table length
---@param val table
---@return number n default: 0
function xmeta.len(val)
  local type = type
  local t = type(val)
  if t ~= "table" then
    error("attemp to call length with value of" .. t, 2)
  end
  local mt = getmetatable(val)
  if not mt then return #val end
  local __len = mt.__len
  if type(__len) ~= "function" then return #val end
  return mt.__len(val) or 0
end

if MIN_VERSION == 1 then
  ---@version 5.1, jit
  ---@param val table
  function xmeta.pairs(val)
    local pairs = pairs
    local type = type
    local t = type(val)
    if t ~= "table" then
      return pairs(val)
    end
    local mt = getmetatable(val)
    if not mt then return pairs(val) end
    local __pairs = mt.__pairs
    if type(__pairs) ~= "function" then
      return pairs(val)
    end
    return __pairs(val)
  end
end

if MIN_VERSION == 1 or MIN_VERSION == 4 then
  ---@version 5.1, jit, 5.4
  ---@param val table
  function xmeta.ipairs(val)
    local ipairs = ipairs
    local type = type
    local t = type(val)
    if t ~= "table" then
      return ipairs(val)
    end
    local mt = getmetatable(val)
    if not mt then return ipairs(val) end
    local __ipairs = mt.__ipairs
    if type(__ipairs) ~= "function" then
      return ipairs(val)
    end
    return __ipairs(val)
  end
end
---@generic T: xmeta.Object
---@alias xmeta.type T

xmeta.todo = todo
---@class xmeta.Type
---@overload fun(name: string, base: xmeta.Object, defs?: table): xmeta.type
---@overload fun(val: any): type
xmeta.Type = Type
---@class xmeta.Object
xmeta.Object = Object
-- }}}
setmetatable(xmeta, Type)
return xmeta
