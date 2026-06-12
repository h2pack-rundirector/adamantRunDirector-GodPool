package.path = "./?.lua;./?/init.lua;" .. package.path

require("tests/TestUtils")
require("tests/TestLogic")

local lu = require("luaunit")
os.exit(lu.LuaUnit.run())
