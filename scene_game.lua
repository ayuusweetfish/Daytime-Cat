local randomPath = require 'randpath'

return function ()
  local s = {}

  local seed = 0

  local camX, camY = 0, 0
  local catX, catY = 0, 0
  local p

  s.press = function (x, y)
    seed = seed + 1
    p = randomPath(seed, 7, 3, 3.5)
    --p = randomPath(seed, 3, 2, 2.5)
    --p = randomPath(seed, 20, 0, 10)
  end
  s.press(0, 0)

  s.move = function (x, y)
  end

  s.release = function (x, y)
  end

  s.update = function ()
  end

  s.draw = function ()
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

  s.destroy = function ()
  end

  return s
end
