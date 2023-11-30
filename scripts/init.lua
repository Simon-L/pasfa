local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types
local to_json = require("lapis.util").to_json
local from_json = require("lapis.util").from_json

local inspect = require("inspect")
local stat = require "posix.sys.stat"
local dir = require("pl.dir")
local path = require("pl.path")
local file = require("pl.file")
local stringx = require("pl.stringx")

local pasfa = require "pasfa"
local paste = pasfa.paste

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

function init_tables()
    schema.create_table("pasfa_pastes", {
        { "pid", types.integer },
        { "name", types.text },
        { "content", types.text },
        { "created_at", types.text },
        { "expires_at", types.text },
        { "shortid", types.text },
        { "meta", types.text },
        "PRIMARY KEY (pid)"
    })
    schema.create_table("pasfa_shortids", {
        { "shortid", types.text },
        { "pid", types.integer },
        "PRIMARY KEY (shortid)",
        "FOREIGN KEY(pid) REFERENCES pasfa_pastes(pid)"
    })
    schema.create_table("pasfa_meta", {
        { "key", types.text },
        { "value", types.integer },
        "PRIMARY KEY (key)"
    })
    local pa = pasfa.Pastes:create({
        pid = 13370000,
        shortid = "init",
        name = "init",
        content = "init",
        created_at = "init",
        expires_at = "init",
        meta = "init"
    })
end

function paste_libraries(lib_path)
    local files = dir.getallfiles(lib_path, "*.lib")
    local pa
    for i,v in ipairs(files) do
        local f = path.basename(v)
        local content = file.read(v)
        pa = paste(f, content, {category={"library"}, expiry="eternal"})
    end
    return pa
end

function paste_examples(ex_path)
    local files = dir.getallfiles(ex_path, "*.dsp")
    local pa
    for i,v in ipairs(files) do
        local f = path.basename(v)
        local content = file.read(v)
        local cat = path.relpath(path.dirname(v), ex_path)
        cat = stringx.split(cat, '/')
        pa = paste(f, content, {category=cat, expiry="eternal"})
    end
    return pa
end

assert(require"scripts.utils".pid_guard(), "Please stop server before running scripts!")
local cdb = check_db()
local ctbl = check_tables()
print("check_db:", tostring(cdb))
print("check_tables:", tostring(ctbl))
if arg[1] == nil then
    print("usage: resty scripts/init.lua [path to faust repo]\nMake sure you also cloned the submodules")
end
if (not cdb or not ctbl) then
    print("Initializing")
    init_tables()
    local lib_0 = 13370001
    local pa = paste_libraries(arg[1] .. "/libraries")
    local lib_end = pa.pid
    local ex_0 = lib_end + 1
    pa = paste_examples(arg[1] .. "/examples")
    local ex_end = pa.pid
    print("libraries ", lib_0, " to ", lib_end)
    print("examples ", ex_0, " to ", ex_end)
    pasfa.Meta:create({
        key = "libraries_pids",
        value = to_json({lib_0, lib_end })
    })
    pasfa.Meta:create({
        key = "examples_pids",
        value = to_json({ex_0, ex_end })
    })
    local a, b = pasfa.examples_pids()
    print(a, "   ", b)
end