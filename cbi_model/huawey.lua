local fs = require("nixio.fs")local fs = require("nixio.fs")local fs = require("nixio.fs")

map = Map("huawey", "Huawei Configuration", "Configure Huawei router settings.")
map.description = [[
<p>This tool helps to configure settings for various Huawei modem types including Orbit, E5577, E3372, and E5573.</p>
<br>
<p>Tutorial this <a href="https://bit.ly/aryochannel" target="_blank">HERE</a></p>
]]

section = map:section(NamedSection, "settings", "huawey", "Settings")
section.addremove = false
section.anonymous = true

option = section:option(Value, "router_ip", "Router IP")
option.datatype = "ipaddr"
option.default = "192.168.8.1"
option.placeholder = "Input IP Gateway Modem"

option = section:option(Value, "username", "Username")
option.default = "admin"
option.placeholder = "Input Username your Modem"

option = section:option(Value, "password", "Password")
option.password = true
option.default = "admin"
option.placeholder = "Input Password your Modem"

section = map:section(NamedSection, "settings", "huawey", "Telegram")
section.addremove = false
section.anonymous = true

option = section:option(Value, "telegram_token", "Telegram Token")
option.password = true
option.default = ""
option.placeholder = "Telegram BOT Token"

option = section:option(Value, "chat_id", "Chat ID")
option.default = ""
option.placeholder = "Message Chat ID"

option = section:option(Value, "message_thread_id", "Message Thread ID")
option.datatype = "integer"
option.default = 0
option.placeholder = "Message Thread ID Telegram"

section = map:section(NamedSection, "settings", "huawey", "Duration")
section.addremove = false
section.anonymous = true

option = section:option(Value, "lan_off_duration", "Ping Duration (s)")
option.datatype = "uinteger"
option.default = 5
option.placeholder = "Enter Ping Duration in second"


-- Add a button for starting/stopping the service
service_btn = section:option(Button, "_service", "Control Services")
service_btn.inputstyle = "apply"

-- Add a custom title field for service control
status_title = section:option(DummyValue, "_status_title", ".", "")
status_title.rawhtml = true

-- Check if the service is running by checking /etc/rc.local
local function is_service_running()
  local rc_path = "/etc/rc.local"
  local script_line = "/usr/bin/huawei -r"
  return fs.readfile(rc_path) and fs.readfile(rc_path):find(script_line, 1, true)
end

-- Update button text and title based on service status
local function update_status()
  if is_service_running() then
    service_btn.inputtitle = "Stop Service" -- Set the button label dynamically
    service_btn.inputstyle = "remove"
    status_title.value = '<span style="color:green;">Service is Running</span>'
  else
    service_btn.inputtitle = "Start Service" -- Set the button label dynamically
    service_btn.inputstyle = "apply"
    status_title.value = '<span style="color:red;">Service is Stopped</span>'
  end
end

-- Initial status update
update_status()

-- Function for toggling the service
function service_btn.write(self, section)
  local rc_path = "/etc/rc.local"
  local script_line = "/usr/bin/huawei -r"

  if is_service_running() then
    -- Stop the service
    luci.sys.call("huawei -s >/dev/null 2>&1")

    -- Remove the script from /etc/rc.local
    local rc_content = fs.readfile(rc_path)
    if rc_content then
      local new_content = rc_content:gsub(script_line:gsub("%-", "%%-") .. "\n?", "")
      fs.writefile(rc_path, new_content)
    end
  else
    -- Start the service
    luci.sys.call("huawei -r >/dev/null 2>&1 &")

    -- Add the script to /etc/rc.local if not already present
    if not fs.readfile(rc_path):find(script_line, 1, true) then
      fs.writefile(rc_path, fs.readfile(rc_path):gsub("exit 0", script_line .. "\nexit 0"))
    end
  end

  -- Update the status after the service is toggled
  update_status()
end

return map
