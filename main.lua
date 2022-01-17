local randomPath = require 'randpath'

local seed = 0

function love.mousepressed()
  seed = seed + 1
  p = randomPath(seed, 7, 3, 3.5)
  --p = randomPath(seed, 3, 2, 2.5)
  --p = randomPath(seed, 20, 0, 10)
end

love.mousepressed()

function love.draw()
  love.graphics.clear(0.98, 0.98, 0.98)
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.setPointSize(4)
  love.graphics.setLineWidth(2)
  local w, h = love.graphics.getDimensions()
  local xscale = math.min(w, h) * 0.4
  local yscale = math.min(w, h) * 0.4
  local ox = w * 0.5
  local oy = h * 0.5
  for i = 1, #p do
    love.graphics.points(ox + p[i].x * xscale, oy + p[i].y * yscale)
  end
  for i = 2, #p do
    love.graphics.line(
      ox + p[i - 1].x * xscale, oy + p[i - 1].y * yscale,
      ox + p[i].x * xscale, oy + p[i].y * yscale)
  end
end
