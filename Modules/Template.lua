local _, addon = ...
local API = addon.API;

do
    local time = time;
    local floor = math.floor;
    local SecondsToTime = API.SecondsToTime;
    local SecondsToClock = API.SecondsToClock;
    local NUM_INFINITY = 86400;

    local TimerFrameMixin = {};
    --t0:  totalElapsed
    --t1: totalElapsed (between 0 - 1)
    --s1: elapsedSeconds
    --s0: full duration

    function TimerFrameMixin:Init()
        if not self.styleID then
            --Simple Text
            self:Clear();
            self:SetStyle(1);
        end
    end

    function TimerFrameMixin:Clear()
        self:SetScript("OnUpdate", nil);
        self.t0 = 0;
        self.t1 = 0;
        self.s1 = 1;
        self.s0 = 1;
        self.startTime = nil;
        self.DisplayTime(self);
        if not self.alwaysVisible then
            self:Hide();
        end
    end

    function TimerFrameMixin:Calibrate()
        if self.startTime then
            local currentTime = time();
            self.t0 = currentTime - self.startTime;
            self.s1 = self.t0;
            self.DisplayTime(self);
        end
    end

    function TimerFrameMixin:SetTimes(currentSecond, total)
        if currentSecond >= total or total == 0 then
            self:Clear();
        else
            self.t0 = currentSecond;
            self.t1 = 0;
            self.s1 = floor(currentSecond + 0.5);
            self.s0 = total;
            self:SetScript("OnUpdate", self.OnUpdate);
            self.DisplayTime(self);
            self.startTime = time() - currentSecond;
            self:Show();
        end
    end

    function TimerFrameMixin:SetDuration(second)
        self:SetTimes(0, second);
    end

    function TimerFrameMixin:SetEndTime(endTime)
        local t = time();
        self:SetDuration( (t > endTime and (t - endTime)) or 0 );
    end

    function TimerFrameMixin:StartTimer(timeElpased)
        self:SetReverse(false);
        if timeElpased and timeElpased > 0 then
            self:SetTimes(timeElpased, NUM_INFINITY);
        else
            self:SetTimes(0, NUM_INFINITY);
        end
    end

    function TimerFrameMixin:SetReverse(reverse)
        --If reverse, show remaining seconds instead of elpased seconds
        self.isReverse = reverse;
    end

    function TimerFrameMixin:SetAlwaysVisible(alwaysVisible)
        self.alwaysVisible = alwaysVisible;
        if not self.startTime then
            self:Hide();
        end
    end


    function TimerFrameMixin:OnUpdate(elapsed)
        self.t0 = self.t0 + elapsed;
        self.t1 = self.t1 + elapsed;

        if self.t0 >= self.s0 then
            self:Clear();
            return
        end

        if self.t1 > 1 then
            self.t1 = self.t1 - 1;
            self.s1 = self.s1 + 1;
            self.DisplayTime(self);
        end
    end

    function TimerFrameMixin:AbbreviateTimeText(state)
        self.abbreviated = state or false;
    end

    function TimerFrameMixin:DisplayTime()

    end

    function TimerFrameMixin:DisplayTime_SimpleText()
        if self.isReverse then
            self.TimeText:SetText( SecondsToTime(self.s0 - self.s1, self.abbreviated) );
        else
            self.TimeText:SetText( SecondsToTime(self.s1, self.abbreviated) );
        end
    end

    function TimerFrameMixin:DisplayTime_Clock()
        if self.isReverse then
            self.TimeText:SetText( SecondsToClock(self.s0 - self.s1) );
        else
            self.TimeText:SetText( SecondsToClock(self.s1) );
        end
    end

    function TimerFrameMixin:SetStyle(styleID)
        if styleID ~= self.styleID then
            if styleID == 1 then    --Clock 01:30
                self.DisplayTime = self.DisplayTime_Clock;
            else    --Text 1 Min 30 Sec
                styleID = 2;
                self.DisplayTime = self.DisplayTime_SimpleText;
            end

            self.styleID = styleID;
            self.DisplayTime(self);
        end
    end

    function TimerFrameMixin:GetTimeElapsed()
        if self.startTime then
            local currentTime = time();
            return currentTime - self.startTime
        else
            return 0
        end
    end

    local function CreateTimerFrame(parent)
        local f = CreateFrame("Frame", nil, parent);
        f:SetSize(48, 16);

        f.TimeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal", 1);
        f.TimeText:SetJustifyH("CENTER");
        f.TimeText:SetJustifyV("MIDDLE");
        f.TimeText:SetTextColor(1, 1, 1);
        f.TimeText:SetPoint("CENTER", f, "CENTER", 0, 0);

        API.Mixin(f, TimerFrameMixin);
        f:SetScript("OnSizeChanged", f.UpdateMaxBarFillWidth);
        f:SetScript("OnShow", f.Calibrate);
        f:SetAlwaysVisible(false);
        f:Clear();
        f:Init();

        return f
    end
    addon.CreateTimerFrame = CreateTimerFrame;
end