--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  if n == 2 then
  end

  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()

  local o = 0

  for i = 1,m.params.count do
      screen.move(  0, o + 10 * i)
      screen.text(m.params:get_name(i))
      screen.move(127, o + 10 * i)
      screen.text_right(m.params:string(i))
  end

  screen.update()
end

m.init = function()
    -- on menu entry, ie, if you wanted to start timers

    local paramset = require 'core/paramset'

    m.params = paramset.new("modmenu", "Mod Menu")
    m.params:add_number("a", "num widgets", 3, 7, 5)
    m.params:add_number("b", "num buckets", 12, 24, 18)

    m.haha = "hoho"
end

m.deinit = function()
    -- on menu exit
end

return m
