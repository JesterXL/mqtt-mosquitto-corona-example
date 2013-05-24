#!/usr/bin/lua
-- ------------------------------------------------------------------------- --
-- mqtt_publish.lua
-- ~~~~~~~~~~~~~~~~
-- Please do not remove the following notices.
-- Copyright (c) 2011-2012 by Geekscape Pty. Ltd.
-- Documentation: http://http://geekscape.github.com/mqtt_lua
-- License: AGPLv3 http://geekscape.org/static/aiko_license.html
-- Version: 0.2 2012-06-01
--
-- Description
-- ~~~~~~~~~~~
-- Publish an MQTT message on the specified topic with an optional last will.
--
-- References
-- ~~~~~~~~~~
-- Lapp Framework: Lua command line parsing
--   http://lua-users.org/wiki/LappFramework
--
-- ToDo
-- ~~~~
-- None, yet.
-- ------------------------------------------------------------------------- --

function is_openwrt()
  return(os.getenv("USER") == "root")  -- Assume logged in as "root" on OpenWRT
end

-- ------------------------------------------------------------------------- --

print("[mqtt_publish v0.2 2012-06-01]")

if (not is_openwrt()) then require("luarocks.require") end
local lapp = require("pl.lapp")

local args = lapp [[
  Publish a message to a specified MQTT topic
  -d,--debug                                Verbose console logging
  -H,--host          (default localhost)    MQTT server hostname
  -i,--id            (default mqtt_pub)     MQTT client identifier
  -m,--message       (string)               Message to be published
  -p,--port          (default 1883)         MQTT server port number
  -t,--topic         (string)               Topic on which to publish
  -w,--will_message  (default .)            Last will and testament message
  -w,--will_qos      (default 0)            Last will and testament QOS
  -w,--will_retain   (default 0)            Last will and testament retention
  -w,--will_topic    (default .)            Last will and testament topic
]]

local MQTT = require("mqtt_library")

if (args.debug) then MQTT.Utility.set_debug(true) end

local mqtt_client = MQTT.client.create(args.host, args.port)

if (args.will_message == "."  or  args.will_topic == ".") then
  mqtt_client:connect(args.id)
else
  mqtt_client:connect(
    args.id, args.will_topic, args.will_qos, args.will_retain, args.will_message
  )
end

mqtt_client:publish(args.topic, args.message)

mqtt_client:destroy()

-- ------------------------------------------------------------------------- --
