local _, addon = ...
local API = addon.API;
local ProfileUtil = addon.ProfileUtil;


local IsInInstance = IsInInstance;
local GetInstanceInfo = GetInstanceInfo;
local time = time;
local format = string.format;


local RESTART_TIMER_THRESHOLD = 600;    --Support continuing counting after /reload If currentTime - lastEnterTime exceed this value, restart timer


local EL = CreateFrame("Frame");
local TimerFrame;


function EL:IsInDungeonOrRaid()
    local inInstance, instanceType = IsInInstance();
    if inInstance and instanceType == "party" or instanceType == "raid" then
        return true
    end
    return false
end

function EL:OnEnterInstance()
    local data = self.instanceData;
    print(format("Entered %s: %s (%s)", data.instanceID, data.name, data.difficultyName));
    self:StartTimer();
end

function EL:StartTimer()
    if not TimerFrame then
        local parent = UIParent;
        TimerFrame = addon.CreateTimerFrame(parent);
        TimerFrame:SetPoint("TOP", parent, "TOP", 0, -8);
        TimerFrame:SetAlpha(0.5);
    end

    local currentTime = time();
    local secondPassed = 0;
    local enterTime = ProfileUtil:GetData("LastInstanceEnterTime");
    local lastInstanceID = ProfileUtil:GetData("LastInstanceID");

    if enterTime and lastInstanceID and lastInstanceID == self.lastInstanceID then
        secondPassed = currentTime - enterTime;
        if secondPassed > RESTART_TIMER_THRESHOLD then
            enterTime = currentTime;
            secondPassed = 0;
        end
    end

    enterTime = enterTime or currentTime;

    self.enterTime = enterTime;
    TimerFrame:StartTimer(secondPassed);

    ProfileUtil:SetData("LastInstanceEnterTime", enterTime);
    ProfileUtil:SetData("LastInstanceID", self.lastInstanceID);
end

function EL:OnLeaveInstance()
    local duration;
    if self.enterTime then
        duration = time() - self.enterTime;
    end

    local instanceID = self.lastInstanceID;
    self.lastInstanceID = nil;

    local data = self.instanceData;
    if data then
        if duration then
            print(format("Left %s: %s (%s) after %s (%s s)", data.instanceID, data.name, data.difficultyName, API.SecondsToTime(duration), duration));
            ProfileUtil:AddInstanceCounter(instanceID, data.difficultyID, duration);
        else
            print(format("Left %s: %s (%s) after unknown time", data.instanceID, data.name, data.difficultyName));
        end

        self.instanceData = nil;
    end

    if TimerFrame then
        TimerFrame:Clear();
    end

    ProfileUtil:SetData("LastInstanceEnterTime", nil);
    ProfileUtil:SetData("LastInstanceID", nil);
end

function EL:UpdateInstanceStatus()
    if self:IsInDungeonOrRaid() then
        local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID = GetInstanceInfo();

        if self.lastInstanceID and instanceID ~= self.lastInstanceID then
            self:OnLeaveInstance();
        end

        self.lastInstanceID = instanceID;

        self.instanceData = {
            name = name,
            type = instanceType,
            difficultyID = difficultyID,
            difficultyName = difficultyName,
            instanceID = instanceID,
        };

        ProfileUtil:SetInstanceName(instanceID, name);
        ProfileUtil:SetInstanceDifficultyName(difficultyID, difficultyName);

        self:OnEnterInstance();
    else
        if self.lastInstanceID then
            self:OnLeaveInstance();
        end
    end
end

function EL:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t >= 0 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        self:UpdateInstanceStatus();
    end
end

function EL:RequestUpdate(delay)
    if not self.t then
        self.t = 0;
    end

    delay = (delay and -delay) or 0;
    if delay < self.t then
        self.t = delay;
    end

    self:SetScript("OnUpdate", self.OnUpdate);
end

function EL:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:RequestUpdate(0.5);
    end
end

function EL:Enable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:SetScript("OnEvent", self.OnEvent);
end
EL:Enable();


do
    function EL:RAID_INSTANCE_WELCOME(instanceName, resetTime, locked, extended)

    end

    function EL:DAILY_RESET_INSTANCE_WELCOME(instanceName, resetTime, locked, extended)

    end
end