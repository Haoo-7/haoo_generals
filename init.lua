local extensions = require "packages.haoo_generals.pkg.haoo_generals"
require("packages.haoo_generals.guozhou_client")(Client or Fk.Base.ClientBase)
if Client then
  require("packages.haoo_generals.hongkainan_client")(Client)
end

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
}

-- Tongqu loads after this package and supplies its own mark translation.
-- Apply the shared canal label after every extension has finished loading.
Fk:addPostLoadFunc(function()
  Fk:loadTranslationTable { ["@@tongqu"] = "渠" }
end)

return { extensions[1], extensions[2] }
