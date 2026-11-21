local Data = require("data.journal")
local Stages = require("data.stages")
local Weapons = require("data.weapons")
local Roster = require("data.characters")

local Journal = {}
local characterIds, achievementIds = {}, {}
for _, character in ipairs(Roster) do
    characterIds[character.id] = true
end
for _, milestone in ipairs(Data.milestones) do
    achievementIds[milestone.id] = true
end

local function copySet(source)
    local copy = {}
    for id in pairs(source) do
        copy[id] = true
    end
    return copy
end

local function validSet(value, catalogue)
    if type(value) ~= "table" then
        return false
    end
    for id, collected in pairs(value) do
        if not catalogue[id] or collected ~= true then
            return false
        end
    end
    return true
end

local function loadSet(saved, catalogue)
    if saved == nil then
        return {}
    end
    assert(validSet(saved, catalogue), "invalid saved discovery set")
    return copySet(saved)
end

local function evaluate(journal, completedRuns, wonStage)
    local weaponCount = 0
    for _ in pairs(journal.collection.weapons) do
        weaponCount = weaponCount + 1
    end
    local earned = journal.earned
    for _, milestone in ipairs(Data.milestones) do
        if (not milestone.completed_runs or completedRuns >= milestone.completed_runs)
            and (not milestone.win_stage or wonStage == milestone.win_stage)
            and (not milestone.requires or earned[milestone.requires])
            and (not milestone.discovered_weapons or weaponCount >= milestone.discovered_weapons) then
            earned[milestone.id] = true
        end
    end
end

function Journal.load(saved, completedRuns)
    if saved == nil then saved = {} end
    assert(type(saved) == "table", "invalid saved journal")
    local collection = saved.collection
    if collection == nil then collection = {} end
    assert(type(collection) == "table", "invalid saved collection")
    local journal = {
        earned = loadSet(saved.earned, achievementIds),
        collection = {
            stages = loadSet(collection.stages, Stages),
            characters = loadSet(collection.characters, characterIds),
            weapons = loadSet(collection.weapons, Weapons),
        },
    }
    -- Older snapshots still have a completed-run count.
    evaluate(journal, completedRuns)
    return journal
end

function Journal.collection(journal)
    return {
        stages = copySet(journal.collection.stages),
        characters = copySet(journal.collection.characters),
        weapons = copySet(journal.collection.weapons),
    }
end

function Journal.export(journal)
    return { earned = copySet(journal.earned), collection = Journal.collection(journal) }
end

function Journal.achievements(journal)
    local result = {}
    for index, milestone in ipairs(Data.milestones) do
        result[index] = { id = milestone.id, label = milestone.label, earned = journal.earned[milestone.id] == true }
    end
    return result
end

function Journal.unlocks(journal)
    local flags = { stages = copySet(Data.starting_stages), characters = {}, perks = {} }
    for _, milestone in ipairs(Data.milestones) do
        if journal.earned[milestone.id] then
            for kind, grants in pairs(milestone.grants) do
                for id in pairs(grants) do
                    flags[kind][id] = true
                end
            end
        end
    end
    return flags
end

function Journal.valid_result(result)
    return (result.stage == nil or type(result.stage) == "string")
        and (result.character == nil or type(result.character) == "string")
        and (result.weapons == nil or validSet(result.weapons, Weapons))
end

function Journal.credit(journal, result, completedRuns, won)
    local collection = journal.collection
    if Stages[result.stage] then
        collection.stages[result.stage] = true
    end
    if characterIds[result.character] then
        collection.characters[result.character] = true
    end
    for id in pairs(result.weapons or {}) do
        collection.weapons[id] = true
    end
    evaluate(journal, completedRuns, won and result.stage or nil)
end

return Journal
