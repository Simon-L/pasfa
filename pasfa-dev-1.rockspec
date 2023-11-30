package = "pasfa"
version = "dev-1"

source = {
  url = "git@github.com:Simon-L/pasfa.git"
}

description = {
  summary = "Lapis Application",
  homepage = "",
  license = "MIT"
}

dependencies = {
  "lua ~> 5.1",
  "lapis == 1.16.0",
  "ansicolors == 1.0.2-3",
  "date == 2.2.1-1",
  "inspect == 3.1.3-0",
  "lsqlite3 == 0.9.5-1",
  "luaposix == 36.2.1-1",
  "luautf8 == 0.1.5-2",
  "penlight == 1.13.1-1",
  "sqids-lua == 0.1-6",
}

build = {
  type = "none"
}
