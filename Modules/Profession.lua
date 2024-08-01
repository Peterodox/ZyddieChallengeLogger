local _, addon = ...
local API = addon.API;
local ProfileUtil = addon.ProfileUtil;


local FIELD_PROF1 = "ProfessionSkillLine1";
local FIELD_PROF2 = "ProfessionSkillLine2";
local UNLEARNED_PROF_ID = 0;

local select = select;
local GetProfessions = GetProfessions;
local GetProfessionInfo = GetProfessionInfo;


local EL = CreateFrame("Frame");

local function GetPrimarySkillLineID(index)
    local prof = select(index, GetProfessions());
    local skillLine;
    if prof then
        skillLine = select(7, GetProfessionInfo(prof));
    end
    return skillLine or UNLEARNED_PROF_ID
end

function EL:SaveProfessionInfo()
    local skillLine1 = GetPrimarySkillLineID(1);
    local skillLine2 = GetPrimarySkillLineID(2);

    if skillLine1 > skillLine2 then
        local temp = skillLine1;
        skillLine1 = skillLine2
        skillLine2 = temp;
    end

    if skillLine1 ~= self.skillLine1 then
        self.skillLine1 = skillLine1;
        ProfileUtil:SetData(FIELD_PROF1, skillLine1);
    end

    if skillLine2 ~= self.skillLine2 then
        self.skillLine2 = skillLine2;
        ProfileUtil:SetData(FIELD_PROF2, skillLine2);
    end
end

function EL:OnUpdate(elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.2 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);
        EL:SaveProfessionInfo();
    end
end

function EL:OnEvent(event, ...)
    if event == "SKILL_LINES_CHANGED" then
        self.t = 0;
        self:SetScript("OnUpdate", self.OnUpdate);
    end
end

function EL:Enable()
    self:RegisterEvent("SKILL_LINES_CHANGED");
    EL:SetScript("OnEvent", EL.OnEvent);
end


do
    addon.CallbackRegistry:Register("FIRST_PLAYER_ENTERING_WORLD", function()
        EL:Enable();
        EL:SaveProfessionInfo();
    end);

    local function Debug_SkillLineName(skillLineID)
        local name = C_TradeSkillUI.GetTradeSkillDisplayName(skillLineID);
        return name
    end

    addon.AddFieldDescription(FIELD_PROF1, Debug_SkillLineName);
    addon.AddFieldDescription(FIELD_PROF2, Debug_SkillLineName);
end