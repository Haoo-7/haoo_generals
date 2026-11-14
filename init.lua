local extension = require "packages.haoo_generals.pkg.haoo_generals"
local tao = require "packages.haoo_generals.pkg.tao"
local langzi = require "packages.haoo_generals.pkg.langzi"
local guozhou = require "packages.haoo_generals.pkg.guozhou"
local wushilin = require "packages.haoo_generals.pkg.wushilin"
local aizhake = require "packages.haoo_generals.pkg.aizhake"
local zengyixiong = require "packages.haoo_generals.pkg.zengyixiong"
require("packages.haoo_generals.guozhou_client")(Client or Fk.Base.ClientBase)
require("packages.haoo_generals.hongkainan_client")(Client or Fk.Base.ClientBase)

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
}

-- Tongqu loads after this package and supplies its own mark translation.
-- Apply the shared canal label after every extension has finished loading.
Fk:addPostLoadFunc(function()
  Fk:loadTranslationTable { ["@@tongqu"] = "渠" }
end)

return { extension, tao, langzi, guozhou, wushilin, aizhake, zengyixiong }
