Slab = require 'Slab'
Anim = require("Anim")
inspect = require("inspect")

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

function reload_spritesheet()
   -- TODO: if hash(fs.read(spritesheet_path)) == oldhash then return end
   spritesheet = lg.newImage(spritesheet_path)
   spritesheet:setFilter("nearest", "nearest")
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

   reload_spritesheet()
   reload_animation()

   Slab.Initialize(args)
end

function SlabNumberInput(name, num)
   local minus = Slab.Button("-", { W = 18 })

   Slab.SameLine()
   local inp = Slab.Input(name, {
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
function love.update(dt)
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
   mouse_down = love.mouse.isDown(1, 2, 3)

   anim:update(dt)

   Slab.BeginWindow('config_window', {
      X = 10, Y = 10,
      Title = "Configuration",
      ConstrainPosition = true,
      NoSavedSettings = true,
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
   spritesheet_path = dropped_file:getFilename()
   reload_spritesheet()
   reload_animation()
   -- TODO: if the filename is .txt, do loadstring(), otherwise load the image
end

function love.wheelmoved(x, y)
   local sum = (x + y)/5
   anim_sy = anim_sy + sum
   anim_sx = anim_sy
end

function love.mousemoved(x, y, dx, dy)
   if mouse_down and not input_focused then
      camera_x = camera_x + dx
      camera_y = camera_y + dy
   end
end
