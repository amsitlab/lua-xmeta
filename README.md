## Xmeta
Yet another lua OOP-like base library.


### Intro
xmeta is an simple base library to use OOP-like paradigm in lua (based on lua metatable).
on xmeta, metatable separated into 2 part.

- __meta-object__ (called class/type) act as instance creator, handling meta-method like `__index`, `__newindex`, etc.. for instance.
- __meta-class__ act as type/class creator, handling meta-method like `__index`, `__newindex`, etc.. for type/class.

if you have miss-understand, see simple code:
```lua
local metatype = {
   __index = rawget,
   __newindex = rawset,
   -- ... other metamethod/metatable
}

local metaobject = {
   new = function(class, ...)
      local self = { ... }
      -- ...
      return setmetatable(self, class)
   end,
   __index = rawget,
   __newindex = rawset,
   -- ... other metamethod/metatable
}
setmetatable(metaobject, metatype)

local foo = metaobject:new()
local bsr = metaobject:new()
local baz = metaobject:new()

```
- metaobject have metatable (metatype)
- foo, bar, baz have metatable (metaobject)

__xmeta__ have base meta-object for creating instance called __xmeta.Object__, also can extended by custom meta-object.
__xmeta.Object__ created by xmeta-builtin meta-class called __xmeta.Type__, but __xmeta.Type__ is also sub-(class/type) of __xmeta.Object__

### Example
To use xmeta, install it before, see: [Install](#Install), and `require` xmeta to your code:
```lua
local xmeta = require "xmeta"
```

xmeta also can act as built in lua __type__ replacement for checking type.
so we can write:
```lua
local type = require "xmeta".Type
assert(type("") == "string")
assert(type(1) == "number")
assert(type({}) == "table")
assert(type(tostring) == "function")

```

How to create class/type (meta-object)?
to creating meta-object we use __xmeta.Type(name: string, base: xmeta.Object, attrs: table)__
eg:
```lua
local xmeta = require "xmeta"
local Object = xmeta.Object
local type = xmeta.Type
local Cursor = type("modname.Cursor", Object, {
   new = Object.new, -- use base constructor
   __index = Object.__index, -- default, it can skip.
   __tostring = Object.__tostring -- default, it can skip.
})

local cursor = Cursor:new() -- also can Cursor()
assert(type(Cursor) == type)
assert(type(cursor) == Cursor)
assert(xmeta.is(Cursor, cursor))
assert(xmeta.is(Object, cursor, true)) -- recursive search
```
**Cursor** is _type/class_ extend of **xmeta.Object**
**Cursor** is meta-table for **cursor**, so we can say:
 > **Cursor** is meta-object of **cursor**
or
 > **Cursor** is type/class of **cursor**


How to Override construction?
```lua

function Cursor:new(attrs)
   -- local super = self.__base__ ---@class xmeta.Object
   local super = xmeta.Object -- explicit (recommended)
   if type(attrs) == "string" then
      attrs = {
         content = attrs,
         pointer = 1,
         longest = attrs:len(),
      }
   end
   --#NOTE: called with '.' not ':'
   return super.new(self, attrs)
end

local cursor = Cursor:new("foo") -- also can call with Cursor("foo")
assert(cursor.__type__ == Cursor)
assert(xmeta(cursor) == Cursor)
assert(cursor.__type__.__name__ == "modname.Cursor")
assert(cursor.content == "foo")

```
for more example see: [tests/](tests/)

--------------------


### Install
- simple
just copy [xmeta/init.lua](lua/xmeta/init.lua) into your project.

- luarocks
For now xmeta not released on luarocks repositories
but we can install with git + luarocks

```sh
git clone https://github.com/amsitlab/lua-xmeta
cd lua-xmeta
luarocks make
```

--------------------
### Available functions
#### xmeta.is(T, obj, recursive=true)
Is **obj** instance of **T** ?
  >- **@param T: xmeta.Object** _meta-object_
  >- **@param obj: xmeta.Object** _meta-object_ instance.
  >- **@param recursive: boolean** search recursively base class.
  >- **@return boolean**
  >eg:
  ```lua
  local o = xmeta.Object:new()
  assert(xmeta.is(xmeta.Object, o))
  ```
  >we can also inject **xmeta.is** function into meta-object (type/class),
  >so we can call **xmeta.is** from type/class.
  >eg:
  ```lua
  local Error = xmeta.Type("Error", xmeta.Object, {
     is = xmeta.is,
     -- new = xmeta.Object.new,
  })
  local level = 2
  local e = Error:new("message", level) -- creating instance
  --#NOTE: called with ':' not '.'
  assert(Error:is(e)) --> same as: xmeta.is(Error, e)
  assert(e[1] == "message")
  assert(e[2] == level)
  ```


#### xmeta.is_based(T1, T2, recursive=true)
Is **T1** based **T2** ?
  >- **@param T1: xmeta.Object** _meta-object_
  >- **@param T2: xmeta.Object** _meta-object_
  >- **@param recursive: boolean** search recursively base class.
  >- **@return boolean**

#### xmeta.pairs(T)
Compatible pairs for each lua version.
  >- **@param T: table|xmeta.Object**

#### xmeta.ipairs(T)
Compatible ipairs for each lua version.
  >- **@param T: table|xmeta.Object**

---------------

### xmeta.Object (default and base of meta-object hirarchy)
#### xmeta.Object:new(...)
creating **xmeta.Object** instance.
  >- **@return xmeta.Object** instance.
  Mostly this method called from sub-(type/class) of **xmeta.Object**
  eg:
  ```lua
  local meta = require "xmeta"
  local SubType = xmeta.Type("SubType", xmeta.Object, {})
  function SubType:new(fields)
     -- local super = self.__base__.new
     local super = xmeta.Object.new --> explicit (recommended)
     assert(type(fields) == "table")
     return super(self, fields)
  end
  local o = SubType:new{ foo = "bar" }
  -- or o = SubType{ foo = "bar" }
  assert(o.foo == "bar")
  assert(xmeta.Type(o) == SubType)
  assert(xmeta.is(SubType, o))
  assert(xmeta.is(xmeta.Object, o)) --recursive search
  assert(xmeta.is(xmeta.Object, o, false --[[no recursive]]) == false)

  ```

#### xmeta.Object:__index(k)
handling field of created instance.
  >- **@param k: any**


