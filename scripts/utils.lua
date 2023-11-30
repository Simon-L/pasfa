local stat = require "posix.sys.stat"

return {
    pid_guard = function()
        local st = stat.stat("logs/nginx.pid")
        if st == nil then return true
        else return false end
    end
}