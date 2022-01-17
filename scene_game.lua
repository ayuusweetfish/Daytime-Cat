local randomPath = require 'randpath'
local sp = require 'spacepart'
local spPartition = sp.partition
local spVicinity = sp.vicinity

local pawImage = love.graphics.newImage('res/paw.png')
local pawW, pawH = pawImage:getDimensions()

return function ()
  local s = {}
  local W, H = W, H

  -- Generate path
  local seed = 0
  local p = randomPath(seed, 7, 3, 3.5)
  --p = randomPath(seed, 3, 2, 2.5)
  --p = randomPath(seed, 20, 0, 10)
  local scale = math.min(W, H) * 4
  for i = 1, #p do
    p[i].x = p[i].x * scale
    p[i].y = p[i].y * scale
  end

  -- Paws
  local paws = {}
  local addPaw = function (x, y, angle, flip)
    paws[#paws + 1] = {
      x = x, y = y, angle = angle,
      flip = flip,
    }
  end

  for i = 1, #p - 1, 2 do
    -- Draw a paw
    local isLeft = (i % 4 == 1)
    local dx = p[i + 1].x - p[i].x
    local dy = p[i + 1].y - p[i].y
    local angle = math.pi / 2 + math.atan2(dy, dx)
    local nx, ny = dy * 0.7, -dx * 0.7
    addPaw(
      p[i].x + (isLeft and nx or -nx),
      p[i].y + (isLeft and ny or -ny),
      angle, isLeft
    )
  end
  -- On-track paws lookup table
  local spTrackPaws = spPartition(paws)

  love.math.setRandomSeed(333152)
  local x = love.math.random()
  local y = love.math.random()
  for i = 1, 5000 do
    x = (x + 2^0.5) % 1
    y = (y + 3^0.5) % 1
    local x1 = x + love.math.random() * 0.01
    local y1 = y + love.math.random() * 0.01
    local x2 = (x1 * 2 - 1) * scale
    local y2 = (y1 * 2 - 1) * scale
    if not spVicinity(spTrackPaws, 30, x2, y2) then
      addPaw(
        x2, y2,
        love.math.random() * math.pi * 2,
        love.math.random() < 0.5
      )
    end
  end

  local camX, camY = 0, 0
  local catX, catY = 0, 0

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
  end

  s.update = function ()
    -- Move cat
    local moveX, moveY = 0, 0
    if love.keyboard.isDown('w', 'up') then moveY = moveY - 1 end
    if love.keyboard.isDown('s', 'down') then moveY = moveY + 1 end
    if love.keyboard.isDown('a', 'left') then moveX = moveX - 1 end
    if love.keyboard.isDown('d', 'right') then moveX = moveX + 1 end
    if moveX ~= 0 or moveY ~= 0 then
      local v = 1.5 / (moveX^2 + moveY^2)^0.5
      catX = catX + v * moveX
      catY = catY + v * moveY
    end

    -- Move camera
    local dx = catX - camX
    local dy = catY - camY
    local dsq = dx^2 + dy^2
    if dsq >= 0.1 then
      camX = camX + dx * 0.05
      camY = camY + dy * 0.05
    else
      camX, camY = catX, catY
    end
  end

  s.draw = function ()
    love.graphics.clear(0.98, 0.98, 0.98)
    love.graphics.setColor(1, 1, 1)
    local ox = W * 0.5 - camX
    local oy = H * 0.5 - camY
    for i = 1, #paws do
      local p = paws[i]
      love.graphics.draw(pawImage,
        ox + p.x, oy + p.y, p.angle,
        p.flip and -0.6 or 0.6, 0.6,
        pawW / 2, pawH / 2
      )
    end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(2)
  --[[
    for i = 1, #p do
      love.graphics.points(ox + p[i].x, oy + p[i].y)
    end
    for i = 2, #p do
      love.graphics.line(
        ox + p[i - 1].x, oy + p[i - 1].y,
        ox + p[i].x, oy + p[i].y)
    end
  ]]
    love.graphics.points(ox + catX, oy + catY)
  end

  s.destroy = function ()
  end

  return s
end
