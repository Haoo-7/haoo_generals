local extension = require "packages.haoo_generals.pkg.haoo_generals"
local tao = require "packages.haoo_generals.pkg.tao"
local langzi = require "packages.haoo_generals.pkg.langzi"
local guozhou = require "packages.haoo_generals.pkg.guozhou"
local wushilin = require "packages.haoo_generals.pkg.wushilin"
require("packages.haoo_generals.guozhou_client")(Client or Fk.Base.ClientBase)

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
}

-- Tongqu may load later and replace the shared canal label.
Fk:addPostLoadFunc(function()
  Fk:loadTranslationTable { ["@@tongqu"] = "渠" }
end)

return { extension, tao, langzi, guozhou, wushilin }
