local lapis = require("lapis")
local app = lapis.Application()
local csrf = require("lapis.csrf")

local os = require"os"
local colors = require("ansicolors")
local inspect = require("inspect")

local pasfa = require "pasfa"

app:enable("etlua")
app.layout = require "views.layout"

app:get("/", function(self)
    return { redirect_to = self:url_for("new") }
end)

function app:handle_404()
    return { status = 404, render = "404" }
end

app:get("/examples", function(self)
    self.examples = pasfa.examples()
    return { render = "examples" }
end)

app:get("new", "/new", function(self)
    self.csrf_token = csrf.generate_token(self)
    self.config = require("lapis.config").get()
    return { render = "new" }
end)

app:post("/paste", function(self)
    if csrf.validate_token(self) == nil then
        return { redirect_to = self:url_for("new") }
    end
    if ((self.params.file.filename ~= "") and (self.params.file.content ~= "")) then
        local pa = pasfa.paste(self.params.file.filename, self.params.file.content, {})
        if pa ~= nil then
            return { redirect_to = "/" .. pa.shortid }
        else
            return { redirect_to = self:url_for("new") }
        end
    elseif ((self.params.name ~= "") and (self.params["code-input"] ~= "")) then
        local pa = pasfa.paste(self.params.name, self.params["code-input"], {})
        if pa ~= nil then
            return { redirect_to = "/" .. pa.shortid }
        else
            return { redirect_to = self:url_for("new") }
        end
    else
        return { redirect_to = self:url_for("new") }
    end
end)

app:get("shortid", "/:shortid", function(self)
    local p = pasfa.get(self.params.shortid)
    if (p == nil) then return app:handle_404() end
    local dsp = self.params.dsp and true or false
    self.content = p.content
    self.name = p.name
    self.dsp = dsp
    self.shortid = p.shortid
    self.ago = require("lapis.util").time_ago_in_words(p.created_at)
    return { render = "paste" }
end)

app:get("/raw/:shortid", function(self)
    local p = pasfa.get(self.params.shortid)
    if (p == nil) then return { status = 404, layout = false } end
    return {p.content, layout = false}
end)

app:get("/admin", function(self)
    if ngx.var.remote_addr ~= "127.0.0.1" then
        return { status = 404, layout = false }
    else
        local paginated = pasfa.Pastes:paginated([[]], 100)
        self.paginated = paginated
        return { render = "admin" }
    end
end)

return app
