local mod = require 'core/mods'
local fileselect = require 'fileselect'
local textentry = require 'textentry'

local page = nil

local m = {
  pos = 0,
  oldpos = 0,
  group = false,
  groupid = 0,
  alt = false,
  dir_prev = nil,
}

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local ModMenu = {}

local function build_page(params)
  page = {}
  local i = 1
  repeat
    if params:visible(i) then table.insert(page, i) end
    if params:t(i) == params.tGROUP then
      i = i + params:get(i) + 1
    else i = i + 1 end
  until i > params.count
end

local function build_sub(sub, params)
  page = {}
  for i = 1,params:get(sub) do
    if params:visible(i + sub) then
      table.insert(page, i + sub)
    end
  end
end

function ModMenu:doKey(n, z)
  if n==1 and z==1 then
    m.alt = true
  elseif n==1 and z==0 then
    m.alt = false
  else
    local i = page[m.pos+1]
    local t = self.params:t(i)
    if n==2 and z==1 then
      if m.group==true then
        m.group = false
        build_page(self.params)
        m.pos = m.oldpos
      else
        mod.menu.exit()
      end
    elseif n==3 and z==1 then
      if t == self.params.tGROUP then
        build_sub(i, self.params)
        m.group = true
        m.groupid = i
        m.groupname = self.params:string(i)
        m.oldpos = m.pos
        m.pos = 0
      elseif t == self.params.tSEPARATOR then
        local n = m.pos+1
        repeat
          n = n+1
          if n > #page then n = 1 end
        until self.params:t(page[n]) == self.params.tSEPARATOR
        m.pos = n-1
      elseif t == self.params.tFILE then
        fileselect.enter(_path.dust, m.newfile)
        local fparam = self.params:lookup_param(i)
        local dir_prev = fparam.dir or m.dir_prev
        if dir_prev ~= nil then
          fileselect.pushd(dir_prev)
        end
      elseif t == self.params.tTEXT then
        textentry.enter(m.newtext,
                        self.params:get(i),
                        "PARAM: "..self.params:get_name(i))
      elseif t == self.params.tTRIGGER then
        self.params:set(i)
        m.triggered[i] = 2
      elseif t == self.params.tBINARY then
        self.params:delta(i,1)
        if self.params:lookup_param(i).behavior == 'trigger' then
          m.triggered[i] = 2
        else m.on[i] = self.params:get(i) end
      else
        m.fine = true
      end
    elseif n==3 and z==0 then
      m.fine = false
      if t == self.params.tBINARY then
        self.params:delta(i, 0)
        if self.params:lookup_param(i).behavior ~= 'trigger' then
          m.on[i] = self.params:get(i)
        end
      end
    end
  end
  mod.menu.redraw()
end

ModMenu.newfile = function(file)
  if file ~= "cancel" then
    self.params:set(page[m.pos+1],file)
    m.dir_prev = file:match("(.*/)")
    mod.menu.redraw()
  end
end

ModMenu.newtext = function(txt)
  print("SET TEXT: "..txt)
  if txt ~= "cancel" then
    self.params:set(page[m.pos+1],txt)
    mod.menu.redraw()
  end
end

function ModMenu:doEnc(n, d)
  -- normal scroll
  if n==2 and m.alt==false then
    local prev = m.pos
    m.pos = util.clamp(m.pos + d, 0, #page - 1)
    if m.pos ~= prev then mod.menu.redraw() end
  -- jump section
  elseif n==2 and m.alt==true then
    d = d>0 and 1 or -1
    local i = m.pos+1
    repeat
      i = i+d
      if i > #page then i = 1 end
      if i < 1 then i = #page end
    until self.params:t(page[i]) == self.params.tSEPARATOR or i==1
    m.pos = i-1
  -- adjust value
  elseif n==3 and self.params.count > 0 then
    local dx = m.fine and (d/20) or d
    self.params:delta(page[m.pos+1],dx)
    mod.menu.redraw()
  end

  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

function ModMenu:doRedraw()
  screen.clear()

  if m.pos == 0 then
    local n = self.name
    if m.group then n = n .. " / " .. m.groupname end
    screen.level(4)
    screen.move(0,10)
    screen.text(n)
  end
  for i=1,6 do
    if (i > 2 - m.pos) and (i < #page - m.pos + 3) then
      if i==3 then screen.level(15) else screen.level(4) end
      local p = page[i+m.pos-2]
      local t = self.params:t(p)
      if t == self.params.tSEPARATOR then
        screen.move(0,10*i+2.5)
        screen.line_rel(127,0)
        screen.stroke()
        screen.move(63,10*i)
        screen.text_center(self.params:get_name(p))
      elseif t == self.params.tGROUP then
        screen.move(0,10*i)
        screen.text(self.params:get_name(p) .. " >")
      else
        screen.move(0,10*i)
        screen.text(self.params:get_name(p))
        screen.move(127,10*i)
        if t ==  self.params.tTRIGGER then
          if m.triggered[p] and m.triggered[p] > 0 then
            screen.rect(124, 10 * i - 4, 3, 3)
            screen.fill()
          end
        elseif t == self.params.tBINARY then
          fill = m.on[p] or m.triggered[p]
          if fill and fill > 0 then
            screen.rect(124, 10 * i - 4, 3, 3)
            screen.fill()
          end
        else
          screen.text_right(self.params:string(p))
        end
      end
    end
  end
  screen.update()
end

function ModMenu:doInit()
    -- on menu entry, ie, if you wanted to start timers

  if page == nil then build_page(self.params) end
  m.alt = false
  m.fine = false
  m.triggered = {}
  _menu.timer.event = function()
    for k, v in pairs(m.triggered) do
      if v > 0 then m.triggered[k] = v - 1 end
    end
    mod.menu.redraw()
  end
  m.on = {}
  for i,param in ipairs(self.params.params) do
    if param.t == self.params.tBINARY then
        if self.params:lookup_param(i).behavior == 'trigger' then
          m.triggered[i] = 2
        else m.on[i] = self.params:get(i) end
    end
  end
  _menu.timer.time = 0.2
  _menu.timer.count = -1
  _menu.timer:start()
end

function ModMenu:doDeinit()
    -- on menu exit

  _menu.timer:stop()

    page = nil

    m.pos = 0
    m.oldpos = 0
    m.group = false
    m.groupid = 0
    m.alt = false
    m.dir_prev = nil

    if self.exit_hook then
        exit_hook(self)
    end
end

local paramset = require 'core/paramset'

ModMenu.new = function(id, name)
    local this = setmetatable({}, { __index = ModMenu })
    this.key = function(n, z) return this:doKey(n, z) end
    this.enc = function(n, d) return this:doEnc(n, d) end
    this.redraw = function() return this:doRedraw() end
    this.init = function() return this:doInit() end
    this.deinit = function() return this:doDeinit() end
    this.params = paramset.new(id, name)
    this.name = name

    return this
end

return ModMenu
