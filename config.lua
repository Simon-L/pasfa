local config = require("lapis.config")

config("development", {
  server = "nginx",
  code_cache = "off",
  num_workers = "1",
  sqlite = {
    database = "pasfa.sqlite",
  },
  secret = "correcthorsebatterystaple",
  expiry = {"15", "minutes"},
  interval = {"5", "seconds"},
})
