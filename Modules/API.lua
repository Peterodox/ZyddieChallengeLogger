local _, addon = ...
local API = addon.API;


local floor = math.floor;
local gsub = string.gsub;
local format = string.format;


do  -- Table
    local function Mixin(object, ...)
        for i = 1, select("#", ...) do
            local mixin = select(i, ...)
            for k, v in pairs(mixin) do
                object[k] = v;
            end
        end
        return object
    end
    API.Mixin = Mixin;

    local function CreateFromMixins(...)
        return Mixin({}, ...)
    end
    API.CreateFromMixins = CreateFromMixins;
end

do  -- Time
    local D_DAYS = D_DAYS or "%d |4Day:Days;";
    local D_HOURS = D_HOURS or "%d |4Hour:Hours;";
    local D_MINUTES = D_MINUTES or "%d |4Minute:Minutes;";
    local D_SECONDS = D_SECONDS or "%d |4Second:Seconds;";

    local DAYS_ABBR = DAYS_ABBR or "%d |4Day:Days;"
    local HOURS_ABBR = HOURS_ABBR or "%d |4Hr:Hr;";
    local MINUTES_ABBR = MINUTES_ABBR or "%d |4Min:Min;";
    local SECONDS_ABBR = SECONDS_ABBR or "%d |4Sec:Sec;";

    local SHOW_HOUR_BELOW_DAYS = 3;
    local SHOW_MINUTE_BELOW_HOURS = 12;
    local SHOW_SECOND_BELOW_MINUTES = 10;

    local function BakePlural(number, singularPlural)
        singularPlural = gsub(singularPlural, ";", "");

        if number > 1 then
            return format(gsub(singularPlural, "|4[^:]*:", ""), number);
        else
            singularPlural = gsub(singularPlural, ":.*", "");
            singularPlural = gsub(singularPlural, "|4", "");
            return format(singularPlural, number);
        end
    end

    local function FormatTime(t, pattern, bakePluralEscapeSequence)
        if bakePluralEscapeSequence then
            return BakePlural(t, pattern);
        else
            return format(pattern, t);
        end
    end

    local function SecondsToTime(seconds, abbreviated, partialTime, bakePluralEscapeSequence)
        --partialTime: Stop processing if the remaining units don't really matter.
        --bakePluralEscapeSequence: Convert EcsapeSequence like "|4Sec:Sec;" to its result so it can be sent to chat

        local timeString = "";
        local isComplete = false;
        local days = 0;
        local hours = 0;
        local minutes = 0;

        if seconds >= 86400 then
            days = floor(seconds / 86400);
            seconds = seconds - days * 86400;

            local dayText = FormatTime(days, (abbreviated and DAYS_ABBR) or D_DAYS, bakePluralEscapeSequence);
            timeString = dayText;

            if partialTime and days >= SHOW_HOUR_BELOW_DAYS then
                isComplete = true;
            end
        end

        if not isComplete then
            hours = floor(seconds / 3600);
            seconds = seconds - hours * 3600;

            if hours > 0 then
                local hourText = FormatTime(hours, (abbreviated and HOURS_ABBR) or D_HOURS, bakePluralEscapeSequence);
                if timeString == "" then
                    timeString = hourText;
                else
                    timeString = timeString.." "..hourText;
                end

                if partialTime and hours >= SHOW_MINUTE_BELOW_HOURS then
                    isComplete = true;
                end
            else
                if timeString ~= "" and partialTime then
                    isComplete = true;
                end
            end
        end

        if partialTime and days > 0 then
            isComplete = true;
        end

        if not isComplete then
            minutes = floor(seconds / 60);
            seconds = seconds - minutes * 60;

            if minutes > 0 then
                local minuteText = FormatTime(minutes, (abbreviated and MINUTES_ABBR) or D_MINUTES, bakePluralEscapeSequence);
                if timeString == "" then
                    timeString = minuteText;
                else
                    timeString = timeString.." "..minuteText;
                end
                if partialTime and minutes >= SHOW_SECOND_BELOW_MINUTES then
                    isComplete = true;
                end
            else
                if timeString ~= "" and partialTime then
                    isComplete = true;
                end
            end
        end

        if (not isComplete) and seconds > 0 then
            seconds = floor(seconds);
            local secondText = FormatTime(seconds, (abbreviated and SECONDS_ABBR) or D_SECONDS, bakePluralEscapeSequence);
            if timeString == "" then
                timeString = secondText;
            else
                timeString = timeString.." "..secondText;
            end
        end

        return timeString
    end
    API.SecondsToTime = SecondsToTime;

    local function SecondsToClock(seconds)
        --Clock: 00:00
        return format("%s:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    end
    API.SecondsToClock = SecondsToClock;
end