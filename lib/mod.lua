--
-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod = require 'core/mods'
local script = require 'core/script'
local modmenu = require 'polygrid/modmenu'

local log_prefix = "polygrid"
local data_directory = _path.data.."polygrid"
local state_file = data_directory.."state"
local log_file = data_directory.."log"

--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some x/y values
--

local grid_sizes = { "64", "128", "256" }

local state = {
  mod_active = false,
  grid_size = 2
}

local function log(s)
  print(log_prefix..": "..s)
  local f = io.open(log_file, "a+")
  if f then
      f:write(s.."\n")
      f:close()
  end
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

            if state.mod_active then
              log("Connecting to polygrid")
              if util.file_exists(_path.code.."midigrid") then
                local midigrid = include "midigrid/lib/midigrid"
                midigrid:init(grid_sizes[state.grid_size])
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
  params:add_group("MOD - POLYGRID",2)

  params:add_option("polygrid_active", "polygrid active",
                    {"on", "off"},
                    state.mod_active and 1 or 2)
  params:set_action("polygrid_active",
                    function(v)
                      state.mod_active = v == 1 and true or false
  end)

  params:add_option("polygrid_size", "polygrid size",
                    grid_sizes,
                    state.grid_size)
  params:set_action("polygrid_size",
                    function(v)
                      state.grid_size = v
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

  -- The menu won't appear unless it is initialized in `script.clear` but I
  -- have no idea why.  Is it because the param hierarchy does not exist until
  -- the script context is initialized, and that happens in `script.clear`?

  log("starting up")

  local t
  local error
  t, error = tab.load(state_file)

  if not error then
      state.mod_active = t.mod_active
      state.grid_size  = t.grid_size
  else
      log("Could not load polygrid state: " .. error)
  end

  -- why put init_params in script.clear?  In order to force the params to
  -- the top of the menu, I think.  Also maybe to ensure that the params
  -- are available outside of scripts.

  local script_clear = script.clear
  script.clear = function()
      script_clear()
      init_params()
  end

  grid = fake_grid

  state.system_post_startup = true
end)

mod.hook.register("system_pre_shutdown", "polygrid shutdown", function()
  -- note that none of this code is run unless the user chooses SYSTEM>SLEEP
  -- from the menu, so this is strictly code for dealiing with powering down
  -- the device.
  --
  -- that means the code here is effectively useless.

  state.system_post_startup = false

  -- maybe it would be better here to assign the internal value of
  -- `fake_grid.real_grid` as well.

  grid = fake_grid.real_grid

  log("shutting down")
end)

mod.hook.register("script_pre_init", "polygrid pre init", function()
  -- tweak global environment here ahead of the script `init()` function being
  -- called
end)

mod.hook.register("script_post_cleanup", "polygrid post cleanup", function()
  log("saving polygrid state")

  if not util.file_exists(data_directory) then
    os.execute("mkdir -p " .. data_directory)
  end

  local t
  local error
  t, error = tab.save(state, state_file)

  if error then
      log("Could not save polygrid state: " .. error)
  end
end)

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m = modmenu.new("polygridmenu", "Polygrid")
m.params:add_number("a", "num widgets", 3, 7, 5)
m.params:add_number("b", "num buckets", 12, 24, 18)

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)
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
