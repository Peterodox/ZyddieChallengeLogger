local _, addon = ...
local API = addon.API;
local ProfileUtil = addon.ProfileUtil;


local function SetExportString()
    ZyddieExport = {};
end


local ValidField = {
    "Name",
    "RealmName",
}

local function ConvertCharacterData(uid, data)
    for _, key in ipairs(data) do
        if data[key] then
            print(data[key]);
        end
    end
end