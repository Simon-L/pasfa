local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types
local inspect = require("inspect")
local stat = require "posix.sys.stat"
local colors = require("ansicolors")

function drop_all()
    schema.drop_table("pasfa_pastes")
    schema.drop_table("pasfa_shortids")
    schema.drop_table("pasfa_meta")
end

function check_db()
    local st = stat.stat("pasfa.sqlite")
    if st == nil then return false
    elseif st.size == 0 then return false
    else return true end
end

function check_tables()
    local res = db.query("SELECT name FROM sqlite_master WHERE name='pasfa_pastes'")
    if #res == 0 then
        return false
    else
        return true
    end
end

print(colors("%{bright red underline}WARNING: THIS SCRIPT WILL DELETE THE DATABASE EFFECTIVELY ERASING ALL DATA%{reset}"))
print(colors("%{bright red underline}TYPE pasfa AND PRESS ENTER TO CONFIRM%{reset}"))
local t = io.read()
if t ~= "pasfa" then
    return
end
print(colors("%{bright red underline}ONE LAST TIME, NO REGRETS? PRESS ENTER TO PROCESS%{reset}"))
io.read()
assert(require"scripts.utils".pid_guard(), "Please stop server before running scripts!")
local cdb = check_db()
local ctbl = check_tables()
print("check_db:", tostring(cdb))
print("check_tables:", tostring(ctbl))
if (cdb and ctbl) then
    print("Dropping")
    drop_all()
end