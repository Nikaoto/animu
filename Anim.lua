local Anim = {
   sheet_width = nil,
   sheet_height = nil,
   print_debug_info = false,
   conf = {
      start_x = 0,
      start_y = 0,
      width = 64,
      height = 64,
      ox = nil,
      oy = nil,
      dir = "horiz",
      frame_count = nil,
      delay_ms = 100,
   },
   quads = nil,
   current_quad_idx = 1,
   frame_time = nil, -- How long we've been drawing the current frame 
}

function Anim:new(spritesheet, conf)
   assert(spritesheet)
   assert(conf and type(conf) == "table")

   local o = { spritesheet = spritesheet, conf = conf }
   setmetatable(o.conf, { __index = self.conf })
   setmetatable(o, self)
   self.__index = self

   o:init()
   return o
end

function Anim:init()
   local conf = self.conf

   -- Defaults
   self.current_quad_idx = 1
   self.frame_time = 0
   self.ox = math.ceil(conf.ox or conf.width/2)
   self.oy = math.ceil(conf.oy or conf.height/2)

   if conf.dir ~= "horiz" and conf.dir ~= "vert" then
      print("Anim: dir can only be \"horiz\" or \"vert\"")
      conf.dir = "horiz"
   end

   if conf.frame_count < 1 then
      print("Anim: frame_count < 1")
      return nil
   end

   self.sheet_width = self.spritesheet:getWidth()
   self.sheet_height = self.spritesheet:getHeight()

   if conf.start_x > self.sheet_width then
      print("Anim: start_x > sheet_width")
      return nil
   end

   if conf.start_y > self.sheet_height then
      print("Anim: start_y > sheet_width")
      return nil
   end

   local sheet_width = self.sheet_width
   local sheet_height = self.sheet_height

   -- Populate quads array
   self.quads = {}
   local f = 0
   if conf.dir == "horiz" then
      for y=conf.start_y, sheet_height, conf.height do
         for x=conf.start_x, sheet_width, conf.width do
            if x + conf.width <= sheet_width and
               y + conf.height <= sheet_height then
               table.insert(self.quads, love.graphics.newQuad(
                  x, y,
                  conf.width, conf.height,
                  sheet_width, sheet_height
               ))

               f = f + 1
               if f >= conf.frame_count then
                  goto finish_iter
               end
            end
         end
      end
   elseif conf.dir == "vert" then
      for x=conf.start_x, sheet_width, conf.width do
         for y=conf.start_y, sheet_height, conf.height do
            if x + conf.width <= sheet_width and
               y + conf.height <= sheet_height then
               table.insert(self.quads, love.graphics.newQuad(
                  x, y,
                  conf.width, conf.height,
                  sheet_width, sheet_height
               ))

               f = f + 1
               if f >= conf.frame_count then
                  goto finish_iter
               end
            end
         end
      end
   end

   ::finish_iter::
   if #self.quads < 1 then
      print(inspect(self))
      error("Anim: no quads in animation!")
      return nil
   end
   return self
end

function Anim:update(dt)
   local conf = self.conf
   
   if conf.delay_ms < 1 then
      return
   end

   self.frame_time = self.frame_time + dt * 1000
   if self.frame_time > conf.delay_ms then
      self.current_quad_idx = self.current_quad_idx + 1
      if self.current_quad_idx > #self.quads then
         self.current_quad_idx = 1
      end
      self.frame_time = 0
   end
end

function Anim:draw(x, y, r, sx, sy)
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
