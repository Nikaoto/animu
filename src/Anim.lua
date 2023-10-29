local Anim = {
   start_x = 0,
   start_y = 0,
   width = 64,
   height = 64,
   ox = nil,
   oy = nil,
   dir = "horiz",
   frame_count = nil,
   delay = 0.1,
   delay_ms = nil,
   print_debug_info = false,

   sheet_width = nil,
   sheet_height = nil,
   quads = nil,
   current_quad_idx = 1,
   frame_time = nil, -- How long we've been drawing the current frame 
}

function Anim:new(o)
   assert(o and type(o) == "table")
   assert(o.spritesheet)

   local instance = o or {}
   setmetatable(instance, self)
   self.__index = self

   instance:init()
   return instance
end

local function min(a, b)
   return a < b and a or b
end

function Anim:init()
   -- Defaults
   self.sheet_width = self.spritesheet:getWidth()
   self.sheet_height = self.spritesheet:getHeight()
   self.width = min(self.width, self.sheet_width)
   self.height = min(self.height, self.sheet_height)
   if not rawget(self, "delay") and rawget(self, "delay_ms") then
      self.delay = self.delay_ms / 1000
   end
   self.current_quad_idx = 1
   self.frame_time = 0
   self.ox = math.ceil(self.ox or self.width/2)
   self.oy = math.ceil(self.oy or self.height/2)

   if self.dir ~= "horiz" and self.dir ~= "vert" then
      print("Anim: dir can only be \"horiz\" or \"vert\"")
      self.dir = "horiz"
   end

   if self.frame_count < 1 then
      print("Anim: frame_count < 1")
      return nil
   end

   if self.start_x > self.sheet_width then
      print("Anim: start_x > sheet_width")
      return nil
   end

   if self.start_y > self.sheet_height then
      print("Anim: start_y > sheet_width")
      return nil
   end

   local sheet_width = self.sheet_width
   local sheet_height = self.sheet_height

   -- Populate quads array
   self.quads = {}
   local f = 0
   if self.dir == "horiz" then
      for y=self.start_y, sheet_height, self.height do
         for x=self.start_x, sheet_width, self.width do
            if x + self.width <= sheet_width and
               y + self.height <= sheet_height then
               table.insert(self.quads, love.graphics.newQuad(
                  x, y,
                  self.width, self.height,
                  sheet_width, sheet_height
               ))

               f = f + 1
               if f >= self.frame_count then
                  goto finish_iter
               end
            end
         end
      end
   elseif self.dir == "vert" then
      for x=self.start_x, sheet_width, self.width do
         for y=self.start_y, sheet_height, self.height do
            if x + self.width <= sheet_width and
               y + self.height <= sheet_height then
               table.insert(self.quads, love.graphics.newQuad(
                  x, y,
                  self.width, self.height,
                  sheet_width, sheet_height
               ))

               f = f + 1
               if f >= self.frame_count then
                  goto finish_iter
               end
            end
         end
      end
   end

   ::finish_iter::
   if #self.quads < 1 then
      if self.print_debug_info then
         print(inspect(self))
      end
      print("Anim: no quads in animation!")
      return nil
   end
   return self
end

function Anim:update(dt)
   if #self.quads < 1 then
      return
   end
   
   if self.delay <= 0 then
      return
   end

   self.frame_time = self.frame_time + dt
   if self.frame_time > self.delay then
      self.frame_time = self.frame_time - self.delay
      self.current_quad_idx = self.current_quad_idx + 1
      if self.current_quad_idx > #self.quads then
         self.current_quad_idx = 1
      end
   end
end

function Anim:draw(x, y, r, sx, sy)
   if #self.quads < 1 then
      return
   end

   love.graphics.draw(
      self.spritesheet,
      self.quads[self.current_quad_idx],
      x + self.ox,
      y + self.oy,
      r or 0,
      sx or 1,
      sy or 1,
      self.ox,
      self.oy)

   if self.print_debug_info then
      love.graphics.print('frame idx: ' .. self.current_quad_idx, x, y)
      love.graphics.print('\nframe time: ' .. self.frame_time, x, y)
   end
end

function Anim:reset()
   self.current_quad_idx = 1
end

return Anim
