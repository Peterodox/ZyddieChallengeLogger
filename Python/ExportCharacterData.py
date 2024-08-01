import os
import datetime
import shutil
import xlsxwriter


# Warcraft path
accountDir = 'E:\\Program Files (x86)\\World of Warcraft\\_retail_\\WTF\\Account'

# Where to save the spreadsheet and the addon data backup
outputPath = 'Z:\\ZyddieExportTest\\'


# Load data from lua to the following Dict
characterData = {}
instanceData = {}       #Pre-sorted in lua


# WoW DBC value set at the bottom
profession = {}
chrRaceName = {}
chrClassName = {}


# Valid Field   ['Name', 'RaceID', 'ClassID', 'ProfessionSkillLine1', 'ProfessionSkillLine2', 'PlayerMoney', 'GuildMoney', 'GuildName']
# Valid Field   ['InstanceName', 'Difficulty', 'Runs', 'TotalSeconds']


# Using readlines()
def readAddonData(filePath):
    file = open(filePath, 'r')
    lines = file.readlines()
    foundStart = False
    lineText = None
    instanceDataIndex = 0

    for line in lines:
        if foundStart:
            lineText = line.strip()
            lineText = lineText.strip(',"')
            if lineText != '{' and lineText != '}':
                dataList = lineText.split(':')
                total = len(dataList)
                if total % 2 == 0:
                    tempDict = {}
                    index = 1
                    while index <= (total - 1):
                        tempDict[dataList[index - 1]] = dataList[index]     #Format is key:value pair
                        index += 2
                    
                    playerName = tempDict.get('Name')
                    if playerName != None:
                        characterData[playerName] = tempDict

                    instanceName = tempDict.get('InstanceName')
                    if instanceName != None:
                        instanceDataIndex = instanceDataIndex + 1
                        instanceData[instanceDataIndex] = tempDict


        else:
            if line.find('ZyddieExport') >= 0:
                foundStart = True
                

def convertCopperToGold(copper):
    if copper:
        return round(int(copper) / 10000)
    else:
        return 0

def convertSecondToMin(seconds):
    if seconds:
        return round(int(seconds) / 60)
    else:
        return 0

def translateValue(v, dbc):
    if v:
        return dbc.get(v)

def readData():
    for entry in os.scandir(accountDir):
        if entry.is_dir():
            if entry.name != 'SavedVariables':
                svFolder = entry.path + '\\SavedVariables'
                svFile = svFolder + '\\ZyddieChallengeLogger.lua'
                if os.path.exists(svFolder) and os.path.exists(svFile):
                    readAddonData(svFile)


headers1 = ['Name', 'Race','Class', 'Level', 'Professions', 'Role', 'Current Gold', 'Guild Name', 'Current Guild Gold']
headers2 = ['Instance Name', 'Mode','Runs', 'Time Per Run (s)', 'Total Time In Instance (s)']

def writeRow(worksheet, row, list, cellFormat):
    for col in range(0, len(list)):
        worksheet.write(row, col, list[col] or '', cellFormat)


def writeData():
    currentTtime = datetime.datetime.now()
    fileName = "PlayerData-{}-{}-{}.xlsx".format(currentTtime.year, currentTtime.month, currentTtime.day)
    workbook = xlsxwriter.Workbook(outputPath + fileName)

    # Player
    sheetPlayer = workbook.add_worksheet('Character')

    cellFormat_Default = workbook.add_format()
    cellFormat_Default.set_align('center')

    cellFormat_Money = workbook.add_format()
    cellFormat_Money.set_num_format('#,##')
    cellFormat_Money.set_align('center')

    colWidth = [16, 24, 16, 16, 32,   16, 24, 24, 24]
    col = 0
    row = 0

    for w in colWidth:
        sheetPlayer.set_column(col, col, w)
        col = col + 1

    writeRow(sheetPlayer, row, headers1, cellFormat_Default)

    charactersList = list(characterData.keys())
    charactersList = sorted(charactersList)

    for charName in charactersList:
        # Basic Info
        data = characterData.get(charName)
        level = data.get('PlayerLevel')
        raceName = translateValue(data.get('RaceID'), chrRaceName)
        className = translateValue(data.get('ClassID'), chrClassName)
        role = ''

        # Profession
        prof1 = data.get('ProfessionSkillLine1')
        prof2 = data.get('ProfessionSkillLine2')
        prof1Name = translateValue(prof1, profession)
        prof2Name = translateValue(prof2, profession)
        profText = ''
        if prof1Name != 'None':
            if prof2Name != 'None':
                profText = prof1Name + '/' + prof2Name
            else:
                profText = prof1Name
        else:
            if prof2Name != 'None':
                profText = prof2Name
            else:
                profText = 'N/A'
        
        # Guild
        guildName = data.get('GuildName')

        # Money
        playerGold = convertCopperToGold(data.get('PlayerMoney'))
        guildGold = convertCopperToGold(data.get('GuildMoney'))

        print(charName, raceName, className, level, profText, role, playerGold, guildName, guildGold)
        tempList = [charName, raceName, className, int(level), profText, role, playerGold, guildName, guildGold]

        row = row + 1
        writeRow(sheetPlayer, row, tempList, cellFormat_Money)


    # Instance
    sheetInstance = workbook.add_worksheet('Instance')

    cellFormat_Clock = workbook.add_format()
    #cellFormat_Clock.set_num_format('#,##')
    cellFormat_Clock.set_align('center')

    colWidth = [32, 32, 16, 32, 32]
    col = 0
    row = 0

    for w in colWidth:
        sheetInstance.set_column(col, col, w)
        col = col + 1

    writeRow(sheetInstance, row, headers2, cellFormat_Default)

    indexList = list(instanceData.keys())
    indexList = sorted(indexList)

    for index in indexList:
        data = instanceData.get(index)
        instanceName = data.get('InstanceName')
        difficultyName = data.get('Difficulty')
        runs = int(data.get('Runs') or 0)
        totalSeconds = int(data.get('TotalSeconds') or 0)
        if runs > 0:
            avgSeconds = round(totalSeconds / runs)
        else:
            avgSeconds = 0
        #totalMins = convertSecondToMin(totalSeconds)

        print(instanceName, difficultyName, runs, avgSeconds, totalSeconds)
        tempList = [instanceName, difficultyName, int(runs), avgSeconds, totalSeconds]

        row = row + 1
        writeRow(sheetInstance, row, tempList, cellFormat_Default)


    #sheetPlayer.autofit()
    #sheetInstance.autofit()
    workbook.close()


def processData():
    readData()
    writeData()
    os.system('pause')
    print("Process Complete")


# WoW DBC
profession = {
    '164': 'Blacksmithing',
    '165': 'Leatherworking',
    '171': 'Alchemy',
    '182': 'Herbalism',
    '186': 'Mining',
    '197': 'Tailoring',
    '202': 'Engineering',
    '333': 'Enchanting',
    '393': 'Skinning',
    '755': 'Jewelcrafting',
    '773': 'Inscription',
    '0'  : 'None',
}

chrRaceName = {
    '1': 'Human',
    '2': 'Orc',
    '3': 'Dwarf',
    '4': 'Night Elf',
    '5': 'Undead',
    '6': 'Tauren',
    '7': 'Gnome',
    '8': 'Troll',
    '9': 'Goblin',
    '10': 'Blood Elf',
    '11': 'Draenei',
    '22': 'Worgen',
    '24': 'Pandaren',
    '25': 'Pandaren',
    '26': 'Pandaren',
    '27': 'Nightborne',
    '28': 'Highmountain Tauren',
    '29': 'Void Elf',
    '30': 'Lightforged Draenei',
    '31': 'Zandalari Troll',
    '32': 'Kul Tiran',
    '33': 'Human',
    '34': 'Dark Iron Dwarf',
    '35': 'Vulpera',
    '36': 'Mag\'har Orc',
    '37': 'Mechagnome',
    '52': 'Dracthyr',
    '70': 'Dracthyr',
    '84': 'Earthen',
    '85': 'Earthen',
    '86': 'Haranir',
}

chrClassName = {
    '1': 'Warrior',
    '2': 'Paladin',
    '3': 'Hunter',
    '4': 'Rogue',
    '5': 'Priest',
    '6': 'Death Knight',
    '7': 'Shaman',
    '8': 'Mage',
    '9': 'Warlock',
    '10': 'Monk',
    '11': 'Druid',
    '12': 'Demon Hunter',
    '13': 'Evoker',
    '14': 'Adventurer',
}


processData()