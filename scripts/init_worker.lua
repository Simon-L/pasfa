local colors = require("ansicolors")
local pasfa = require "pasfa"
local process = require "ngx.process"

local function interval_callback(premature)
    if premature then return end
    print(colors("%{bright yellow underline}Running interval callback: delete_expired()%{reset}"))
    pasfa.delete_expired()
end

if (process.type() == "privileged agent") then
    print(colors("%{bright yellow underline}Registering interval timer every " .. pasfa.interval_date():spanseconds() .. " seconds%{reset}"))
    local ok, err = ngx.timer.every(pasfa.interval_date():spanseconds(), interval_callback)
    if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
    end
end

