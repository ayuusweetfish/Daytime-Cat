local sceneGame = require 'scene_game'

local sceneText
sceneText = function (ty)
  local s = {}

  local strings = {
    [1] = "I'm not like other cats.\nI sleep at night and come out by day.",
    [2] = "So I tell them to leave me alone.\nEvery day I follow their pawprints to them.",
    [3] = "It's not easy, but daylight is enjoyable to me.",
    [4] = "There are a thousand ways to be a cat.\nEnjoying the daytime is one of them.",
    [5] = "Thank you for playing > <",
  }

  local text = love.graphics.newText(
    love.graphics.getFont(),
    strings[ty]
  )

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
    if ty == 3 then
      _G['replaceScene'](sceneGame(1))
    elseif ty ~= #strings then
      _G['replaceScene'](sceneText(ty + 1), 'fadeOrange')
    end
  end

  s.update = function ()
  end

  s.draw = function ()
    love.graphics.clear(1.00, 0.99, 0.93)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.draw(text,
      W * 0.5, H * 0.48, 0, 1, 1,
      text:getWidth() / 2,
      text:getHeight() / 2
    )
  end

  s.destroy = function ()
  end

  return s
end

return sceneText
