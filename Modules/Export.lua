local _, addon = ...
local API = addon.API;
local ProfileUtil = addon.ProfileUtil;


local DELIMITER = ":";

local ValidField = {
    "Name",
    "RealmName",
    "RaceID",
    "ClassID",
    "PlayerLevel",
    "PlayerMoney",
    "GuildName",
    "GuildMoney",
    "ProfessionSkillLine1",
    "ProfessionSkillLine2",
}

local function Join(a, b)
    return a..DELIMITER..b
end

local function ConvertCharacterData(uid, data, index, tbl)
    local s, t;

    for _, key in ipairs(ValidField) do
        if data[key] then
            t = Join(key, data[key]);
            if s then
                s = Join(s, t);
            else
                s = t;
            end
        end
    end

    tbl[index] = s;
end

local function ConvertInstanceData()
    local stats = ProfileUtil:GetInstanceStats();
    if not stats then return end;

    local name, difficulty, runs, totalSeconds, avgSeconds;

    local function SortFunc(l, r)
        return l.name < r.name
    end

    local list = {};
    local n = 0;
    local sort = table.sort;

    for instanceID, instanceData in pairs(stats) do
        n = n + 1;
        name = ProfileUtil:GetInstanceName(instanceID);

        local difficulties = {};
        local m = 0;

        for difficultyID, data in pairs(instanceData) do
            m = m + 1;
            difficulties[m] = difficultyID;
        end

        sort(difficulties);

        list[n] = {
            name = name,
            difficulties = difficulties,
            instanceID = instanceID,
        };
    end

    sort(list, SortFunc);

    local strjoin = strjoin;
    local tbl = {};
    n = 0;
    local instanceName, difficultyName, data;

    for index, v in ipairs(list) do
        instanceName = v.name;
        for _, difficultyID in ipairs(v.difficulties) do
            difficultyName = ProfileUtil:GetInstanceDifficultyName(difficultyID);
            data = stats[v.instanceID][difficultyID];
            n = n + 1;
            tbl[n] = strjoin(DELIMITER, "InstanceName", instanceName, "Difficulty", difficultyName, "Runs", data[1], "TotalSeconds", data[2])
        end
    end

    return tbl
end

local function ExportData()
    local tbl = {};
    ProfileUtil:ProcessAllCharcaters(ConvertCharacterData, tbl);

    local instanceData = ConvertInstanceData();
    if instanceData then
        local i = #tbl;
        for j, v in ipairs(instanceData) do
            tbl[i + j] = v;
        end
    end

    ZyddieExport = tbl;
end

do
    addon.CallbackRegistry:Register("PLAYER_LOGOUT", function()
        ExportData();
    end);
end