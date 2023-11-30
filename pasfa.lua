local db = require("lapis.db")
local schema = require("lapis.db.schema")
local Model = require("lapis.db.model").Model
local to_json = require("lapis.util").to_json
local from_json = require("lapis.util").from_json
local types = schema.types
local colors = require("ansicolors")
local stringx = require("pl.stringx")
local config = require("lapis.config").get()

local date = require"date"
local inspect = require("inspect")
local utf8 = require 'lua-utf8'
local Sqids = require("sqids")
local sqids = Sqids.new({
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    minLength = 4
})

local Pastes, Pastes_mt = Model:extend("pasfa_pastes", {primary_key="pid"})
local Shortids, Shortids_mt = Model:extend("pasfa_shortids", {primary_key="shortid"})
local Meta, Meta_mt = Model:extend("pasfa_meta", {primary_key="key"})

local remove_all_metatables = function(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
end

function Pastes_mt:dump()
  print(inspect(self))
end

function Pastes_mt:print()
  print("pid:", self.pid)
  print("shortid:", self.shortid)
  print("name:", self.name)
  print("content:", self.content)
  print("created_at:", self.created_at)
  print("meta:", self.meta)
end

local config_to_date
config_to_date = function (field)
    if (stringx.startswith(field[2], "hour")) then
        return date({hour = field[1]})
    elseif (stringx.startswith(field[2], "day")) then
        return date({day = field[1]})
    elseif (stringx.startswith(field[2], "minute")) then
        return date({min = field[1]})
    elseif (stringx.startswith(field[2], "sec")) then
        return date({sec = field[1]})
    end
end

local expiry_date
expiry_date = function ()
    return config_to_date(config.expiry)
end

local interval_date
interval_date = function ()
    return config_to_date(config.interval)
end

local delete_paste
delete_paste = function (pid)
    local pa = Pastes:find(pid)
    if pa == nil then return end
    pa:delete()
    Shortids:find(pa.shortid):delete()
    print("Deleted " .. pid)
end

local examples_pids
examples_pids = function()
    local ex = Meta:find("examples_pids")
    local pids = from_json(ex.value)
    return pids[1], pids[2]
end

local libraries_pids
libraries_pids = function()
    local ex = Meta:find("libraries_pids")
    local pids = from_json(ex.value)
    return pids[1], pids[2]
end

local examples
examples = function ()
    local first, last = examples_pids()
    local res1 = db.query("SELECT * FROM pasfa_pastes WHERE ((pid > ?) AND (pid < ?))", first, last)
    for i,e in ipairs(res1) do
        e.meta = from_json(e.meta)
        e.category = stringx.join(' / ', e.meta.category)
    end
    return res1
end

local libraries
libraries = function ()
    local first, last = libraries_pids()
    local res1 = db.query("SELECT * FROM pasfa_pastes WHERE ((pid > ?) AND (pid < ?))", first, last)
    for i,e in ipairs(res1) do
        e.meta = from_json(e.meta)
    end
    return res1
end


local is_expired
is_expired = function (_date)
    local d = date.diff(_date, date(true)):spanminutes()
    print("remaining " .. string.format("%2.2f", math.max(0.0, d)) .. " minutes", " | now: ", tostring(date(true)), " target: ", tostring(_date), " ", (d < 0.0 and "will expire" or "still living"))
    return d < 0.0
end

local delete_expired
delete_expired = function ()
    local _, last = examples_pids()
    local res1 = Pastes:select("WHERE (pid > ?)", last)
    for i,pa in ipairs(res1) do
        if from_json(pa.meta).expiry ~= "eternal" then
            local expired = is_expired(date(pa.expires_at))
            if expired then delete_paste(pa.pid) end
        end
    end
end

local get
get = function (shortid)
    local short = Shortids:find(shortid)
    if (short == nil) then
        return nil
    end
    return Pastes:find(short.pid)
end

local paste
paste = function(name, content, meta)
    local req = "SELECT (1000 * unixepoch('subsecond')) as ms, datetime('now') as datetime;"
    local res = db.query(req)
    local ms = tonumber(res[1].ms)
    local datetime = res[1].datetime
    local expires_at = (meta.expiry == "eternal") and "eternal" or tostring(date(datetime) + expiry_date())
    
    local shortid_int = bit.band(ms, 0xffff) -- 16bits
    local shortid = sqids:encode({shortid_int})
    -- print("pid:", "n/a", "| shortid:", shortid, "| name:", name, "| content:", string.sub(content, 1, 16).."...", "| created_at:", datetime, "| meta:", inspect(meta, {depth=1, newline='', indent="", process=remove_all_metatables}))
    -- print("shortid:", shortid, "| pid (foreignkey): n/a")
    local pa = Pastes:create({
        shortid = shortid,
        name = name,
        content = content,
        created_at = datetime,
        expires_at = expires_at,
        meta = to_json(meta)
    })
    local short = Shortids:create({
        shortid = pa.shortid,
        pid = pa.pid
    })
    assert(short.shortid == pa.shortid)
    return pa
end

return {
    Pastes = Pastes,
    Shortids = Shortids,
    Meta = Meta,
    expiry_date = expiry_date,
    interval_date = interval_date,
    is_expired = is_expired,
    get = get,
    paste = paste,
    examples_pids = examples_pids,
    libraries_pids = libraries_pids,
    examples = examples,
    libraries = libraries,
    to_json = to_json,
    from_json = from_json,
    delete_paste = delete_paste,
    delete_expired = delete_expired,
}