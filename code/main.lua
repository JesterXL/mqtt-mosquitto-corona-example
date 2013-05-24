
json = require "json"

function callback(
  topic,    -- string
  payload)  -- string

  -- print("omg")
  -- print("mqtt_test:callback(): " .. topic .. ": " .. payload)
  local json = json.decode(payload)
  if json.name == "create" then
    createBall(json.id)
  elseif json.name == "move" then
    moveBall(json.id, json.x, json.y)
  elseif json.name == "destroy" then
    destroyBall(json.id)
  end

  if (payload == "quit") then running = false end
end



-- ------------------------------------------------------------------------- --

function is_openwrt()
  return(os.getenv("USER") == "root")  -- Assume logged in as "root" on OpenWRT
end

-- ------------------------------------------------------------------------- --

print("[mqtt_test v0.2 2012-06-01]")

if (not is_openwrt()) then require("luarocks.require") end
local lapp = require("pl.lapp")

-- local args = lapp [[
--   Test Lua MQTT client library
--   -d,--debug                         Verbose console logging
--   -i,--id       (default mqtt_test)  MQTT client identifier
--   -p,--port     (default 1883)       MQTT server port number
--   -s,--topic_s  (default test/2)     Subscribe topic
--   -t,--topic_p  (default test/1)     Publish topic
--   <host>        (default localhost)  MQTT server hostname
-- ]]

local args = {
  debug=false,
  id="mqtt_test" .. tostring(math.round(math.random() * 9999)),
  port=1883,
  topic_s="test/2",
  topic_p="test/2",
  host="localhost"
}


local MQTT = require("mqtt_library")

if (args.debug) then MQTT.Utility.set_debug(true) end

local mqtt_client = MQTT.client.create(args.host, args.port, callback)

mqtt_client:connect(args.id)

local jsonStr = json.encode({name = "create", id=args.id})
mqtt_client:publish(args.topic_p, jsonStr)
mqtt_client:subscribe({ args.topic_s })


local error_message = nil
local running = true

function tick()
  if mqtt_client.connected then
    local error_message = mqtt_client:handler()
    
    -- if (error_message == nil) then
    --     mqtt_client:publish(args.topic_p, "*** Lua test message ***")
    --     -- socket.sleep(1.0)  -- seconds
    -- end

    if (error_message ~= nil) then
      print("error_message:", error_message)
      mqtt_client:unsubscribe({ args.topic_s })
      mqtt_client:destroy()
    end
  end
end
timer.performWithDelay( 1000, tick, 0)


-- while (error_message == nil and running) do
--   error_message = mqtt_client:handler()

--   if (error_message == nil) then
--     mqtt_client:publish(args.topic_p, "*** Lua test message ***")
--     socket.sleep(1.0)  -- seconds
--   end
-- end

-- if (error_message == nil) then
--   mqtt_client:unsubscribe({ args.topic_s })
--   mqtt_client:destroy()
-- else
--   print(error_message)
-- end

-- ------------------------------------------------------------------------- --

local balls = {}
function createBall(id)
  local ball = display.newGroup()
  local circle = display.newCircle(0, 0, 60)
  ball:insert(circle)
  local field = display.newText(ball, tostring(id), 0, 0, system.nativeFont, 11)
  field:setTextColor(255, 255, 255)
  ball.id = id
  balls[id] = ball
  local color
  if id == args.id then
    color = {255, 0, 0, 100}
    function ball:touch(e)
      if e.phase == "began" then
        display.getCurrentStage():setFocus(self)
        self.x0 = e.x - self.x
        self.y0 = e.y - self.y
      elseif e.phase == "moved" then
        self.x = e.x - self.x0
        self.y = e.y - self.y0
      elseif e.phase == "ended" then
        display.getCurrentStage():setFocus( nil )
      end
      if e.phase == "moved" or e.phase == "ended" then
        local jsonStr = json.encode({name="move", x=self.x, y=self.y, id=args.id})
        mqtt_client:publish(args.topic_p, jsonStr)
      end
      return true
    end
    ball:addEventListener("touch", ball)
  else
    color = {0, 0, 255, 100}
  end
  circle:setFillColor(unpack(color))
  ball.x = 40
  ball.y = 40
  return ball
end

function moveBall(id, x, y)
  if id == args.id then return false end
  local ball = balls[id]
  if ball == nil then
    -- print("couldn't find ball for id: ", id)
    ball = createBall(id)
  end
  ball.x = x
  ball.y = y
end

function destroyBall(id)
  local ball = balls[id]
  ball:removeSelf()
  balls[id] = nil
end

createBall(args.id)