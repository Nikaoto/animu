Slab = require 'Slab'
Anim = require("Anim")
inspect = require("inspect")
lfs = require("lfs_ffi")
file = nil
file_attr = nil
get_time = function()
   return math.ceil(love.timer.getTime() * 1000)
end

lg = love.graphics

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
--sprite_border_color = {248/255, 26/255, 248/255, 1}
sprite_border_color = {1, 0, 0, 1}
reload_interval_ms = 700
last_reload_time = nil

function loadImage(path)
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
   spritesheet = loadImage(spritesheet_path)
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
   print("anim_config = {")
   for k, v in pairs_alpha(anim.conf) do
      if type(v) == "number" or type(v) == "string" then
         print("   " .. k .. " = " .. v .. ",")
      end
   end
   print("}")
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
   if last_reload_time + reload_interval_ms <= time then
      last_reload_time = time
      if reload_spritesheet() then
         reload_animation()
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

   Slab.BeginWindow("controls_window", {
      X = lg.getWidth() - 300,
      Title = "Controls",
      ConstrainPosition = true,
      NoSavedSettings = true,
   })
   Slab.Text("- Drag a .txt file to load config")
   Slab.Text("- Drag an image file to load animation")
   Slab.Text("- Scroll wheel/+/-/0 to resize")
   Slab.Text("- Arrow keys to pan")
   Slab.Text("- s to save config")
   Slab.Text("- esc to quit")
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
         print("Saving...")
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
   local new_path = dropped_file:getFilename()
   -- TODO: if the filename is .txt, do loadstring(), otherwise load the image   


   if spritesheet_path ~= new_path then
      spritesheet_path = new_path
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
