Slab = require 'Slab'
Anim = require("Anim")
inspect = require("inspect")
lfs = require("lfs_ffi")
utf8 = require("utf8")
get_time = function()
   return math.ceil(love.timer.getTime() * 1000)
end

lg = love.graphics

show_help = true
file = nil
file_attr = nil
spritesheet_path = "spritesheet.png"
spritesheet = nil
anim = nil
anim_config = {
   start_x = 0,
   start_y = 0,
   width = 72,
   height = 128,
   dir = "horiz",
   frame_count = 2,
   delay_ms = 300,
}
anim_x = 0
anim_y = 0
anim_sx = 1
anim_sy = 1
camera_x = 0
camera_y = 0
camera_speed = 300
background_color = {55/255,70/255,73/255, 1}
sprite_background_color = {0.6, 0.6, 0.6, 1}
sprite_border_color = {1, 0, 0, 1}
reload_interval_ms = 700
last_reload_time = nil
reloading_started = false

-- Return dirname, basename of path
function dir_base_name(path)
   local p = path:gsub("\\", "/")
                 :gsub("/$", "")

   local last_slash = p:match(".*/")
   local dirname = ""
   local basename = ""

   if not last_slash then
      dirname = last_slash

      local off = utf8.len(last_slash)
      basename = p:sub(utf8.offset(p, off + 1))
   else
      basename = p
   end
   return dirname, basename
end

-- Get file extension from path
function ext(path)
  return path:match("%.[^.]*$")
end

function unix_path(path)
   return path:gsub("\\", "/")
end

-- Serialize variable
function ser(varname)
   local value = _G[varname]
   local v
   if type(value) == "boolean" then
      v = (value and "true" or "false")
   elseif type(value) == "string" then
      v = "\"" .. value .. "\""
   elseif type(value) == "number" then
      v = tostring(value)
   elseif type(value) == "table" then
      v = inspect(value)
   end
   return string.format("%s = %s\n", varname, v)
end

function pairs_alpha(t, f)
   local a = {}
   for n in pairs(t) do table.insert(a, n) end
   table.sort(a, f)
   local i = 0
   local iter = function ()
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
   end
   return iter
end

function load_image(path)
   -- Read image data
   file = assert(io.open(path, "rb"))
   local buf = file:read("*a")
   file:close()

   love.filesystem.createDirectory("animu_temp")

   -- Write image data to temp.file
   local new_path = love.filesystem.getSaveDirectory().."/animu_temp/temp.file"
   file = assert(io.open(new_path, "w+b"))
   file:write(buf)
   file:flush()
   file:close()

   return lg.newImage("animu_temp/temp.file")
end

function init_spritesheet()
   last_reload_time = get_time()
   file_attr = lfs.attributes(spritesheet_path)
   spritesheet = lg.newImage(spritesheet_path)
   spritesheet:setFilter("nearest", "nearest")
end

function reload_spritesheet()
   -- Check if modified
   local new_attr = lfs.attributes(spritesheet_path)
   if file_attr and new_attr.modification <= file_attr.modification then
      return false
   end

   -- Update
   file_attr = new_attr
   spritesheet = load_image(spritesheet_path)
   spritesheet:setFilter("nearest", "nearest")
   return true
end

function reload_animation()
   local conf
   if anim and anim.conf then
      conf = anim.conf
   else
      conf = anim_config
   end

   anim = Anim:new(spritesheet, conf)
end

function save_config()
   local config_path = spritesheet_path .. ".animu.txt"

   local file = io.open(config_path, "w+")
   file:write("-- " .. config_path .. "\n")
   file:write("-- " .. os.date() .. "\n")

   -- Serialize anim_config
   file:write("anim_config = {\n")
   for k, v in pairs_alpha(anim.conf) do
      local t = type(v)
      if t == "number" or t == "string" or t == "boolean" then
         local val = tostring(v)
         if t == "string" then
            val = "\"" .. val .. "\""
         elseif t == "boolean" then
            val = val and "true" or "false"
         end
         file:write("   " .. k .. " = " .. val .. ",\n")
      end
   end
   file:write("}\n")

   -- Write other values
   file:write(ser("show_help"))
   file:write(ser("reloading_started"))
   file:write(ser("spritesheet_path"))
   file:write(ser("anim_x"))
   file:write(ser("anim_y"))
   file:write(ser("anim_sx"))
   file:write(ser("anim_sy"))
   file:write(ser("camera_x"))
   file:write(ser("camera_y"))
   file:write(ser("camera_speed"))
   file:write(ser("background_color"))
   file:write(ser("sprite_background_color"))
   file:write(ser("sprite_border_color"))

   file:close()

   print("Saved to " .. config_path)
end

function love.load(args)
   lg.setBackgroundColor(background_color)
   love.window.setTitle("animu - animation preview tool")
   love.window.setDisplaySleepEnabled(true)
   love.window.setMode(800, 600, {
      resizable = true,
      minwidth = 200,
      minheight = 200,
   })

   init_spritesheet()
   reload_animation()

   Slab.Initialize(args)
end

function SlabNumberInput(name, num)
   local minus = Slab.Button("-", { W = 18 })

   Slab.SameLine()
   local inp = Slab.Input(name, {
      W = 100,
      Text = tostring(num),
      ReturnOnText = false,
      NumbersOnly = true,
      NoDrag = true,
   })

   Slab.SameLine()
   local plus = Slab.Button("+", { W = 18 })

   return minus, inp, plus
end

local input_focused = false
local mouse_down = false
local void_hovered = false
function love.update(dt)
   local time = get_time()
   if reloading_started then
      if last_reload_time + reload_interval_ms <= time then
         last_reload_time = time
         if reload_spritesheet() then
            reload_animation()
         end
      end
   end

   void_hovered = Slab.IsVoidHovered()
   input_focused = false
   Slab.Update(dt)

   anim_x = (lg.getWidth() - anim.conf.width)/2
   anim_y = (lg.getHeight() - anim.conf.height)/2

   -- Camera controls
   if not input_focused then
      if love.keyboard.isDown("left") then
         camera_x = camera_x - camera_speed * dt
      elseif love.keyboard.isDown("right") then
         camera_x = camera_x + camera_speed * dt
      end
      if love.keyboard.isDown("up") then
         camera_y = camera_y - camera_speed * dt
      elseif love.keyboard.isDown("down") then
         camera_y = camera_y + camera_speed * dt
      end
   end
   --mouse_down = love.mouse.isDown(1, 2, 3) and Slab.IsVoidHovered()

   anim:update(dt)

   Slab.BeginWindow('config_window', {
      X = 10, Y = 10,
      Title = "Configuration",
      ConstrainPosition = true,
      NoSavedSettings = true,
      W = 260,
      AllowResize = true,
      AutoSizeWindow = false,
      AutoSizeWindowW = false,
      AutoSizeWindowH = true,
   })

   -- Print spritesheet info
   Slab.Text("Sheet path: " .. spritesheet_path)
   Slab.Text("Sheet width: " .. anim.sheet_width)
   Slab.Text("Sheet height: " .. anim.sheet_height)

   -- Print config
   for k, v in pairs_alpha(anim.conf) do
      local input_name = k .. "_input"
      Slab.Text(k .. ": ")
      Slab.SameLine()
      if type(v) == "number" then
         local minus, inp, plus = SlabNumberInput(input_name, v)
         if inp then
            anim.conf[k] = tonumber(Slab.GetInputText())
            anim:init()
         end
         if minus then
            anim.conf[k] = anim.conf[k] - 1
            anim:init()
         end
         if plus then
            anim.conf[k] = anim.conf[k] + 1
            anim:init()
         end
      else
         local inp = Slab.Input(input_name, {
            Text = tostring(v),
            ReturnOnText = false,
            NumbersOnly = false,
         })
         if inp then
            anim.conf[k] = Slab.GetInputText()
            anim:init()
         end
      end

      input_focused = input_focused or Slab.IsInputFocused(input_name)
   end

   Slab.Text("")
   Slab.EndWindow()

   show_help = Slab.BeginWindow("controls_window", {
      X = lg.getWidth() - 290,
      Y = 10,
      IsOpen = show_help,
      Title = "Help",
      ConstrainPosition = true,
      NoSavedSettings = true,
   })
   Slab.Text("- Drag a .txt file to load config")
   Slab.Text("- Drag an image file to load animation")
   Slab.Text("- Scroll wheel/+/-/0 to resize")
   Slab.Text("- Arrow keys and mouse drag to pan")
   Slab.Text("- s/Ctrl+s to save config")
   Slab.Text("- esc to quit")
   Slab.Text("- If a dragged image doesn't show up,")
   Slab.Text("  adjust the width/height in animu")
   Slab.EndWindow()
end

function love.draw()
   -- Draw animation background
   lg.setColor(sprite_background_color)
   lg.rectangle(
      "fill",
      camera_x + anim_x - (anim_sx-1) * 0.5 * anim.conf.width,
      camera_y + anim_y - (anim_sy-1) * 0.5 * anim.conf.height,
      anim.conf.width * anim_sx,
      anim.conf.height * anim_sy
   )
   -- Draw animation
   lg.setColor(1, 1, 1, 1)
   anim:draw(camera_x + anim_x, camera_y + anim_y, 0, anim_sx, anim_sy)

   -- Draw animation border
   lg.setColor(sprite_border_color)
   lg.rectangle(
      "line",
      camera_x + anim_x - (anim_sx-1) * 0.5 * anim.conf.width,
      camera_y + anim_y - (anim_sy-1) * 0.5 * anim.conf.height,
      anim.conf.width * anim_sx,
      anim.conf.height * anim_sy
   )

   -- Draw UI
   lg.setColor(1, 1, 1, 1)
   Slab.Draw()
end

function love.keypressed(key)
   if not input_focused then
      if key == "escape" then
         love.event.quit()
      end
   
      if key == "s" then
         save_config()
      end
   
      if key == "0" then
         anim_sx = 1
         anim_sy = 1
      end
   
      if key == "=" then
         anim_sx = math.floor(anim_sx) + 1
         anim_sy = anim_sx
      end
   
      if key == "-" then
         anim_sx = math.floor(anim_sx) - 1
         anim_sy = anim_sx
      end
   end
end

function love.filedropped(dropped_file)
   reloading_started = true
   local new_path = dropped_file:getFilename()

   if ext(new_path) == ".txt" then
      dofile(new_path)
      anim.conf = anim_config
      if reloading_started then
         reload_spritesheet()
      end
      reload_animation()
      return
   end

   if spritesheet_path ~= new_path then
      spritesheet_path = unix_path(new_path)
      file_attr = nil
      file = nil
      reload_spritesheet()
      reload_animation()
      return
   end

   if spritesheet_path == new_path then
      if reload_spritesheet() then
         reload_animation()
      end
      return
   end
end

function love.wheelmoved(x, y)
   if not input_focused and void_hovered then
      local sum = (x + y)/5
      anim_sy = anim_sy + sum
      anim_sx = anim_sy
   end
end

function love.mousepressed()
   mouse_down = Slab.IsVoidHovered()
end

function love.mousereleased()
   mouse_down = false
end

function love.mousemoved(x, y, dx, dy)
   if mouse_down and not input_focused and void_hovered then
      camera_x = camera_x + dx
      camera_y = camera_y + dy
   end
end
