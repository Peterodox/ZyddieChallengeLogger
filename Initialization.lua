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
        CallbackRegistry:Trigger("FIRST_PLAYER_ENTERING_WORLD");
        self:RegisterEvent("PLAYER_LOGOUT");
    elseif event == "PLAYER_LOGOUT" then
        CallbackRegistry:Trigger("PLAYER_LOGOUT");
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




local strsplit = strsplit;
local UnitGUID = UnitGUID;
local UnitFullName = UnitFullName;
local UnitRace = UnitRace;
local UnitClass = UnitClass;

ProfileUtil.FieldValuePrinter = {};

function ProfileUtil:InitPlayerProfile()
    if self.playerDB then return end;

    local unit = "player";
    local _, serverID, playerUID = strsplit("-", UnitGUID("player"));

    if not DB.CharacterData then
        DB.CharacterData = {};
    end

    if not DB.CharacterData[playerUID] then
        DB.CharacterData[playerUID] = {};
    end

    self.playerDB = DB.CharacterData[playerUID];

    local name, realm = UnitFullName(unit);
    local localizedRaceName, englishRaceName, raceID = UnitRace(unit);
    local _, _, classID = UnitClass(unit);

    self.playerDB.Name = name;
    self.playerDB.RealmName = realm;
    self.playerDB.ServerID = serverID;
    self.playerDB.PlayerGUID = playerUID;
    self.playerDB.RaceID = raceID;
    self.playerDB.ClassID = classID;
end

function ProfileUtil:GetData(field)
    self:InitPlayerProfile();
    return self.playerDB[field]
end

function ProfileUtil:SetData(field, data)
    self:InitPlayerProfile();
    self.playerDB[field] = data;

    --debug
    if false then
        if data ~= nil and self.FieldValuePrinter[field] then
            local description = self.FieldValuePrinter[field][1](data);
            if description then
                if self.FieldValuePrinter[field][2] then
                    print(string.format("Save: %s (%s)", field, description))
                else
                    print(string.format("Save: %s %s (%s)", field, data, description))
                end
            end
        end
    end
end

function ProfileUtil:SetInstanceDifficultyName(difficultyID, difficultyName)
    if not difficultyName then return end;

    if not DB.InstanceDifficulty then
        DB.InstanceDifficulty = {};
    end

    DB.InstanceDifficulty[difficultyID] = difficultyName;
end

function ProfileUtil:GetInstanceDifficultyName(difficultyID)
    return (DB.InstanceDifficulty and DB.InstanceDifficulty[difficultyID]) or difficultyID
end

function ProfileUtil:SetInstanceName(instanceID, name)
    if not name then return end;

    if not DB.InstanceName then
        DB.InstanceName = {};
    end
    DB.InstanceName[instanceID] = name;
end

function ProfileUtil:GetInstanceName(instanceID)
    --TEMP
    return (DB.InstanceName and DB.InstanceName[instanceID]) or ("Instance "..instanceID)
end

function ProfileUtil:GetInstanceStats()
    return DB.InstanceStats
end

function ProfileUtil:AddInstanceCounter(instanceID, difficultyID, seconds)
    difficultyID = difficultyID or 0;

    if not DB.InstanceStats then
        DB.InstanceStats = {};
    end

    if not DB.InstanceStats[instanceID] then
        DB.InstanceStats[instanceID] = {};
    end

    if not DB.InstanceStats[instanceID][difficultyID] then
        DB.InstanceStats[instanceID][difficultyID] = {0, 0};    --times, totalSeconds
    end

    local db = DB.InstanceStats[instanceID][difficultyID];
    db[1] = (db[1] or 0) + 1;
    db[2] = (db[2] or 0) + seconds;
end


function ProfileUtil:ProcessAllCharcaters(func, tbl)
    if not DB.CharacterData then return end;

    local index = 0;

    for uid, data in pairs(DB.CharacterData) do
        index = index + 1;
        func(uid, data, index, tbl)
    end
end

local function AddFieldDescription(field, func, muteRawData)
    ProfileUtil.FieldValuePrinter[field] = {func, muteRawData or false};
end
addon.AddFieldDescription = AddFieldDescription;