local _, addon = ...
local API = addon.API;
local ProfileUtil = addon.ProfileUtil;


local FIELD_PLAYER_MONEY = "PlayerMoney";
local FIELD_GUILD_MONEY = "GuildMoney";     --Stored in guild instead of player?
local FIELD_PLAYER_LEVEL = "PlayerLevel";
local FIELD_GUILD_NAME = "GuildName";


local GetMoney = GetMoney;
local GetGuildBankMoney = GetGuildBankMoney;
local UnitLevel = UnitLevel;
local GetGuildInfo = GetGuildInfo;
local IsInGuild = IsInGuild;


local GUILD_EVENTS = {
    GUILDBANK_UPDATE_MONEY = true,
    GUILDBANKFRAME_OPENED = true,
    GUILDBANKFRAME_CLOSED = true,
};


local EL = CreateFrame("Frame");

function EL:SavePlayerMoney()
    local copper = GetMoney();
    if copper ~= self.lastPlayerMoney then
        self.lastPlayerMoney = copper;
        ProfileUtil:SetData(FIELD_PLAYER_MONEY, copper);
    end
end

function EL:SaveGuildMoney()
    local copper = GetGuildBankMoney();
    if copper ~= self.lastGuildMoney then
        self.lastGuildMoney = copper;
        ProfileUtil:SetData(FIELD_GUILD_MONEY, copper);
    end
end

function EL:SavePlayerlevel()
    local level = UnitLevel("player");
    if (not self.playerLevel) or level > self.playerLevel then
        self.playerLevel = level;
        ProfileUtil:SetData(FIELD_PLAYER_LEVEL, level);
    end
end

function EL:SaveGuildName()
    if IsInGuild() then
        local guildName = GetGuildInfo("player");
        ProfileUtil:SetData(FIELD_GUILD_NAME, guildName);
    end
end

function EL:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.5 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);

        if self.playerMoneyDirty then
            self.playerMoneyDirty = nil;
            self:SavePlayerMoney();
        end

        if self.guildMoneyDirty then
            self.guildMoneyDirty = nil;
            self:SaveGuildMoney();
        end

        if self.playerLevelDirty then
            self.playerLevelDirty = nil;
            self:SavePlayerlevel();
        end

        if self.guildStatusDirty then
            self.guildStatusDirty = nil;
            self:SaveGuildName();
        end
    end
end

function EL:OnEvent(event, ...)
    self.t = 0;
    if event == "PLAYER_MONEY" then
        self.playerMoneyDirty = true;
    elseif event == "PLAYER_LEVEL_UP" then
        self.playerLevelDirty = true;
    else
        self.guildMoneyDirty = true;
    end
    self:SetScript("OnUpdate", self.OnUpdate);
end

function EL:Enable()
    self:RegisterEvent("PLAYER_MONEY");
    self:RegisterEvent("PLAYER_LEVEL_UP");

    for event in pairs(GUILD_EVENTS) do
        self:RegisterEvent(event);
    end

    self:SetScript("OnEvent", self.OnEvent);
end


do
    addon.CallbackRegistry:Register("FIRST_PLAYER_ENTERING_WORLD", function()
        EL:Enable();
        EL:SavePlayerMoney();
        EL:SavePlayerlevel();
    end);


    addon.AddFieldDescription(FIELD_PLAYER_MONEY, API.FormatMoney, true);
    addon.AddFieldDescription(FIELD_GUILD_MONEY, API.FormatMoney, true);
end