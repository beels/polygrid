local mod = require 'core/mods'

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local ModMenu = {}

function ModMenu:doKey(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

function ModMenu:doEnc(n, d)
  if n == 2 then
  end

  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

function ModMenu:doRedraw()
  screen.clear()

  screen.move(0, 10)
  screen.text(self.name)

  local o = 20

  for i = 1,ModMenu.params.count do
      screen.move(  0, o + 10 * i)
      screen.text(ModMenu.params:get_name(i))
      screen.move(127, o + 10 * i)
      screen.text_right(ModMenu.params:string(i))
  end

  screen.update()
end

function ModMenu:doInit()
    -- on menu entry, ie, if you wanted to start timers
end

function ModMenu:doDeinit()
    -- on menu exit
end

local paramset = require 'core/paramset'

ModMenu.new = function(id, name)
    local m = setmetatable({}, { __index = ModMenu })
    m.key = function(n, z) return m:doKey(n, z) end
    m.enc = function(n, d) return m:doEnc(n, d) end
    m.redraw = function() return m:doRedraw() end
    m.init = function() return m:doInit() end
    m.deinit = function() return m:doDeinit() end
    m.params = paramset.new(id, name)
    m.name = name

    return m
end

return ModMenu
