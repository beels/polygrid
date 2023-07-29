--
-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod = require 'core/mods'

--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some x/y values
--

local state = {
  x = 0,
}

local log_prefix = "polygrid"

local function log(s)
    print(log_prefix..": "..s)
end

local fake_grid = {
    real_grid = grid
}

local meta_fake_grid = {}

setmetatable(fake_grid, meta_fake_grid)

-- Grid.add (dev) -- static callback when any grid device is added; user scripts can redefine
-- Grid.remove (dev) -- static callback when any grid device is removed; user scripts can redefine
-- Grid.connect (n) -- create device, returns object with handler and send.
-- Grid.cleanup () -- clear handlers.

meta_fake_grid.__index = function(t, key)
    if key == 'connect' then
        log("'connect' retrieved")
        return function(idx)
            local v = idx and idx or ''
            log("'connect("..v..")' called")

            if idx == nil then
                idx = 1
            end

            local enabled = params:get("polygrid_active")
            if enbled then
              log("Connecting to polygrid")
              if util.file_exists(_path.code.."midigrid") then
                local midigrid = include "midigrid/lib/mg_128"
                return midigrid.connect(idx)
              else
                return t.real_grid.connect(idx)
              end
            end

            log("Connecting to real grid @ index "..idx)

            return t.real_grid.connect(idx)
        end
    end

    return t.real_grid[key]
end

local function init_params()
  params:add_group("MOD - POLYGRID",14)

  params:add_option("polygrid_active", "polygrid active", {"on", "off"}, state.script_active and 1 or 2)
  params:set_action("polygrid_active",
                    function(v)
                      state.script_active = v == 1 and true or false
  end)
end

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("system_post_startup", "polygrid startup", function()
  -- maybe it would be better here to assign the internal value of
  -- `fake_grid.real_grid` as well.

  init_params()

  grid = fake_grid

  state.system_post_startup = true
end)

mod.hook.register("system_pre_shutdown", "polygrid shutdown", function()
  -- maybe it would be better here to assign the internal value of
  -- `fake_grid.real_grid` as well.

  grid = fake_grid.real_grid

  state.system_post_startup = false
end)

mod.hook.register("script_pre_init", "polygrid pre init", function()
  -- tweak global environment here ahead of the script `init()` function being called
end)


--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

-- local m = {}
-- 
-- m.key = function(n, z)
--   if n == 2 and z == 1 then
--     -- return to the mod selection menu
--     mod.menu.exit()
--   end
-- end
-- 
-- m.enc = function(n, d)
--   if n == 2 then
--       local v = state.x + d
--       if v > 0 then
--           state.x = 1
--       else
--           state.x = 0
--       end
--   end
-- 
--   -- tell the menu system to redraw, which in turn calls the mod's menu redraw
--   -- function
--   mod.menu.redraw()
-- end
-- 
-- m.redraw = function()
--   screen.clear()
-- 
--   screen.move(0,6)
--   if state.x > 0 then
--       screen.text("Enabled")
--   else
--       screen.text("Disabled")
--   end
-- 
--   screen.update()
-- end
-- 
-- m.init = function() end -- on menu entry, ie, if you wanted to start timers
-- m.deinit = function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
--mod.menu.register(mod.this_name, m)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api = {}

api.get_state = function()
  return state
end

return api
