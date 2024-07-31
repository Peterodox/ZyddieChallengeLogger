local addonName, addon = ...

local L = {};       --Locale
local API = {};     --Custom APIs used by this addon
local CallbackRegistry = {};
local ProfileUtil = {};
CallbackRegistry.events = {};
local DB;

addon.L = L;
addon.API = API;
addon.CallbackRegistry = CallbackRegistry;
addon.ProfileUtil = ProfileUtil;


local DefaultValues = {
    --Reserved for future use
};

local function GetDBValue(dbKey)
    return DB[dbKey]
end
addon.GetDBValue = GetDBValue;

local function SetDBValue(dbKey, value)
    DB[dbKey] = value;
    CallbackRegistry:Trigger("SettingChanged."..dbKey, value);
end
addon.SetDBValue = SetDBValue;

local function LoadDatabase()
    ZyddieDB = ZyddieDB or {};
    DB = ZyddieDB;

    local type = type;

    for dbKey, defaultValue in pairs(DefaultValues) do
        if DB[dbKey] == nil or type(DB[dbKey]) ~= type(defaultValue) then
            SetDBValue(dbKey, defaultValue);
        else
            SetDBValue(dbKey, DB[dbKey]);
        end
    end

    DefaultValues = nil;
end


local EL = CreateFrame("Frame");
EL:RegisterEvent("ADDON_LOADED");
EL:RegisterEvent("PLAYER_ENTERING_WORLD");

EL:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            self:UnregisterEvent(event);
            LoadDatabase();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        ProfileUtil:InitPlayerProfile();
        CallbackRegistry:Trigger("PLAYER_ENTERING_WORLD");
    end
end);




local tinsert = table.insert;
local type = type;
local ipairs = ipairs;

--[[
    callbackType:
        1. Function func(owner)
        2. Method owner:func()
--]]

function CallbackRegistry:Register(event, func, owner)
    if not self.events[event] then
        self.events[event] = {};
    end

    local callbackType;

    if type(func) == "string" then
        callbackType = 2;
    else
        callbackType = 1;
    end

    tinsert(self.events[event], {callbackType, func, owner})
end

function CallbackRegistry:Trigger(event, ...)
    if self.events[event] then
        for _, cb in ipairs(self.events[event]) do
            if cb[1] == 1 then
                if cb[3] then
                    cb[2](cb[3], ...);
                else
                    cb[2](...);
                end
            else
                cb[3][cb[2]](cb[3], ...);
            end
        end
    end
end




local UnitGUID = UnitGUID;
local UnitFullName = UnitFullName;
local strsplit = strsplit;

function ProfileUtil:InitPlayerProfile()
    if self.playerDB then return end;

    local _, serverID, playerUID = strsplit("-", UnitGUID("player"));

    if not DB.CharacterData then
        DB.CharacterData = {};
    end

    if not DB.CharacterData[playerUID] then
        DB.CharacterData[playerUID] = {};
    end

    self.playerDB = DB.CharacterData[playerUID];

    local name, realm = UnitFullName("player");
    self.playerDB.Name = name;
    self.playerDB.RealmName = realm;
    self.playerDB.ServerID = serverID;
    self.playerDB.PlayerGUID = playerUID;
end

function ProfileUtil:GetData(field)
    self:InitPlayerProfile();
    return self.playerDB[field]
end

function ProfileUtil:SetData(field, data)
    self:InitPlayerProfile();
    self.playerDB[field] = data;
end

function ProfileUtil:ProcessAllCharcaters(func)
    if not DB.CharacterData then return end;

    for uid, data in pairs(DB.CharacterData) do
        func(uid, data)
    end
end