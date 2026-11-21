-- Desktop test double for Miliastra controls, with the actual deterministic game core.
local globals = { "Enum", "Color", "script", "game", "OnStart", "OnEnable", "OnUpdate", "OnDisable", "OnDestroy" }
local previousGlobals = {}
for _, name in ipairs(globals) do previousGlobals[name] = _G[name] end

local bundle = arg[2] == "bundle"
local invalidActionTemplate = arg[2] == "invalid-template"
local invalidTextTemplate = arg[2] == "invalid-text"
local Run = require("game.run")
local stages = require("data.stages")
local oldStage = stages.windward
local quickStage = {
    id = "windward", duration_ticks = 65, terminal_kind = "test_boss", terminal_timeout_ticks = 72,
    waves = {
        capacity = 5, spawnDistance = 0, despawnDistance = 15, contactIntervalTicks = 30,
        types = {
            elite = { radius = 0.6, speed = 0, health = 1, contactDamage = 0, elite = true, xp = 60 },
            test_boss = { radius = 1, speed = 0, health = 1000, contactDamage = 0 },
        },
        spawns = { { tick = 1, kind = "elite", count = 1 } },
    },
}

local live
local oldNew, oldRestart, oldCharacter = Run.new, Run.restart, Run.for_character
local function remember(start)
    return function(...)
        live = assert(start(...))
        return live
    end
end
if not bundle then
    stages.windward = quickStage
    Run.new, Run.restart = remember(oldNew), remember(oldRestart)
    if oldCharacter then Run.for_character = remember(oldCharacter) end
end

local function restore()
    stages.windward = oldStage
    Run.new, Run.restart, Run.for_character = oldNew, oldRestart, oldCharacter
    for _, name in ipairs(globals) do _G[name] = previousGlobals[name] end
end

local enumKey = {
    "KeyboardMoveForwardKeyDown", "KeyboardMoveForwardKeyUp", "KeyboardMoveBackwardKeyDown",
    "KeyboardMoveBackwardKeyUp", "KeyboardMoveLeftKeyDown", "KeyboardMoveLeftKeyUp",
    "KeyboardMoveRightKeyDown", "KeyboardMoveRightKeyUp",
}
for i = 1, 10 do enumKey[#enumKey + 1] = "KeyboardCraftspersonKey" .. i .. "Down" end
local function enum(names)
    local results = {}
    for _, name in ipairs(names) do results[name] = name end
    return results
end
Enum = {
    Device = enum({ "Mobile", "KeyboardAndMouse", "Controller", "MobileController" }),
    KeyEventType = enum(enumKey),
    CursorEventType = enum({ "CursorClick", "CursorDown", "CursorDrag", "CursorUp", "CursorEndDrag", "CursorExit" }),
}
Color = { FromRGBA = function(r, g, b, a) return ((r * 256 + g) * 256 + b) * 256 + a end }

local function control(kind, parent)
    local node = {
        kind = kind, parent = parent, active = true, visible = true, alive = true,
        child = {}, keys = {}, cursors = {}, instances = {},
    }
    function node:GetChild(name) return self.child[name] end
    function node:SetAnchorMin() end
    function node:SetAnchorMax() end
    function node:SetPivot() end
    function node:SetAsFirstSibling() end
    function node:SetAnchoredPosition(x, y) self.x, self.y = x, y end
    function node:SetSizeDelta(w, h) self.width, self.height = w, h end
    function node:SetActive(value) self.active = value end
    function node:SetVisible(value) self.visible = value end
    function node:AddKeyEventListener(event, callback)
        assert(event and not self.keys[event])
        self.keys[event] = callback
    end
    function node:RemoveKeyEventListener(event, callback)
        assert(self.keys[event] == callback)
        self.keys[event] = nil
    end
    function node:AddCursorEventListener(event, callback)
        assert(self.kind == "area" and event and not self.cursors[event])
        self.cursors[event] = callback
    end
    function node:RemoveCursorEventListener(event, callback)
        assert(self.cursors[event] == callback)
        self.cursors[event] = nil
    end
    if parent then parent.instances[#parent.instances + 1] = node end
    return node
end

local root = control("root")
local world, touch = control("world", root), control("area", root)
root.child.World = world
root.child.MoveArea = touch
local rendered = {}
local device = Enum.Device.KeyboardAndMouse
local sWidth, sHeight = 0, 0
local playing
local prefabs = { TSImageTemplate = 100, TSTextTemplate = 101, TSActionTemplate = 102, TSConfirmAudio = 103 }
script = { object = root }
function script:EnableUpdate(enabled) self.updating = enabled end
function script:GetParam(name) return assert(prefabs[name]) end
game = {
    GetUICanvasSize = function() return sWidth, sHeight end,
    GetDevice = function() return device end,
    GetControllerLeftStickAxis = function() return 0, 0 end,
    PlayAudio2D = function(id)
        assert(id == 103)
        playing = true
        return id * 2
    end,
    IsAudioAlive = function(id) return id == 206 and playing end,
    StopAudio = function(id)
        assert(id == 206 and playing)
        playing = false
    end,
    InstantiateClientUIControl = function(id, parent)
        if id == 101 and invalidTextTemplate then return nil end
        local kinds = { [100] = "image", [101] = "text", [102] = "button" }
        local node = control(assert(kinds[id]), parent)
        rendered[#rendered + 1] = node
        if id == 102 then
            if not invalidActionTemplate then node.child.Label = control("text", node) end
            node.child.Hit = control("area", node)
        end
        return node
    end,
    DestroyClientUIControl = function(node)
        assert(node.alive)
        node.alive = false
    end,
}

local function excerpt(query)
    for _, node in ipairs(rendered) do
        if node.kind == "text" and node.visible and node.text and node.text:find(query, 1, true) then
            return node
        end
    end
end

local function actionButton(label)
    for _, node in ipairs(rendered) do
        if node.kind == "button" and node.active and node.child.Label.text:find(label, 1, true) then
            return node.child.Hit
        end
    end
    error("button unavailable: " .. label)
end

local function action(label)
    local hit = actionButton(label)
    hit.cursors.CursorDown()
    hit.cursors.CursorClick()
end

local function touchEvent(id, x, y)
    return { touchId = id, GetUIPos = function() return x, y end }
end

dofile(arg[1] or "gil/client.lua")
if invalidActionTemplate or invalidTextTemplate then
    sWidth, sHeight = 1260, 720
    OnStart()
    local success, reason = pcall(OnUpdate, Run.step_seconds)
    local expected = invalidActionTemplate and "Label" or "根模板索引"
    assert(not success and reason:find(expected, 1, true) and not script.updating)
    OnDestroy()
    for _, node in ipairs(rendered) do assert(not node.alive) end
    restore()
    print("Invalid Miliastra template left no instantiated controls")
    return
end
OnEnable()
OnStart()
assert(script.updating)
OnUpdate(Run.step_seconds)
assert(#rendered == 0)
sWidth, sHeight = 1260, 720
OnUpdate(Run.step_seconds)
assert(excerpt("提瓦特幸存者") and not world.active)
local previousMenuButton = actionButton("开始")
previousMenuButton.cursors.CursorDown()
assert(root.keys.KeyboardCraftspersonKey1Down())
OnUpdate(0)
previousMenuButton.cursors.CursorClick()
assert(excerpt("选择关卡") and playing, "a delayed click does not choose a new menu's first option")
assert(root.keys.KeyboardCraftspersonKey1Down())
assert(excerpt(oldCharacter and "选择角色" or "选择初始技能"))
OnUpdate(0)
action(oldCharacter and "风庭斥候" or "风刃")
if bundle then
    assert(world.active)
    for _ = 1, 9 do OnUpdate(0.25) end
    assert(excerpt("00:02") and excerpt("生命"))
    assert(root.keys.KeyboardMoveRightKeyDown())
    OnUpdate(0.25)
    root.keys.KeyboardMoveRightKeyUp()
    local enemyColor = Color.FromRGBA(229, 107, 94, 255)
    local enemies = 0
    for _, node in ipairs(world.instances) do
        if node.visible and node.imageColor == enemyColor then enemies = enemies + 1 end
    end
    assert(enemies > 0, "packaged Lua renders scheduled combat enemies")
    OnDisable()
    OnDestroy()
    for _, node in ipairs(rendered) do assert(not node.alive) end
    restore()
    print("Miliastra bundled script initialized the real stage and rendered scheduled combat")
    return
end
assert(live and live.tick == 0 and world.active)
for _ = 1, 25 do
    OnUpdate(Run.step_seconds)
    if live.loot.choices then break end
end
assert(excerpt("宝箱奖励") and live.loot.choices)
action("领取风砂币")
assert(live.loot.coins > 0)
OnUpdate(Run.step_seconds)
assert(excerpt("选择升级") and live.progress.choices)
local first = assert(live.progress.choices.options[1].label)
action(first)
for _ = 1, 35 do
    OnUpdate(Run.step_seconds)
    if not live.progress.choices then break end
    action(live.progress.choices.options[1].label)
end
assert(not live.progress.choices and excerpt("生命") and not excerpt("选择升级"))
assert(world.active and #world.instances > 0)

OnUpdate(0)
local px, py = live.player.x, live.player.y
assert(root.keys.KeyboardMoveRightKeyDown())
OnUpdate(Run.step_seconds)
root.keys.KeyboardMoveRightKeyUp()
assert(live.player.x > px)
assert(root.keys.KeyboardCraftspersonKey10Down())
assert(excerpt("暂停"))
local paused = live.tick
OnUpdate(0.25)
assert(live.tick == paused)
action("继续")
OnUpdate(0)

device = Enum.Device.Mobile
OnUpdate(0)
assert(touch.active and excerpt("拖动移动"))
touch.cursors.CursorDown(touchEvent(0, 60, 50))
touch.cursors.CursorDrag(touchEvent(1, 60, 100))
OnUpdate(Run.step_seconds)
assert(live.player.y == py)
touch.cursors.CursorDrag(touchEvent(0, 60, 100))
OnUpdate(Run.step_seconds)
assert(live.player.y > py)
py = live.player.y
sWidth, sHeight = 720, 1260
OnUpdate(Run.step_seconds)
assert(live.player.y == py, "reflow cancels a drag in the old canvas coordinates")
touch.cursors.CursorDrag(touchEvent(0, 60, 100))
OnUpdate(Run.step_seconds)
assert(live.player.y == py, "a cancelled touch cannot move the player")
touch.cursors.CursorEndDrag(touchEvent(0, 60, 100))
sWidth, sHeight = 1260, 720
OnUpdate(0)

local previous = live.enemies.active
live.enemies.active = {}
for i = 1, 320 do
    live.enemies.active[i] = { x = live.player.x, y = live.player.y, radius = 0.5 }
end
OnUpdate(0)
assert(excerpt("部分图元达到显示上限"))
local count = 0
for _, node in ipairs(world.instances) do
    if node.visible and node.imageColor == Color.FromRGBA(229, 107, 94, 255) then count = count + 1 end
end
assert(count == 300)
live.enemies.active = previous
OnUpdate(0)
assert(not excerpt("部分图元达到显示上限"))

for _ = 1, 200 do
    OnUpdate(Run.step_seconds)
    if live.result then break end
end
assert(live.result and excerpt("成功撑过终局") and not world.active)
local oldRun = live
OnUpdate(0)
action("再来一局")
assert(live ~= oldRun and live.tick == 0 and not live.result and world.active)
OnDisable()
assert(not script.updating and not playing and next(root.keys) == nil and next(touch.cursors) == nil)
OnEnable()
assert(script.updating and root.keys.KeyboardMoveRightKeyDown ~= nil)
OnDestroy()
for _, node in ipairs(rendered) do assert(not node.alive) end
assert(next(root.keys) == nil)
restore()

print("Miliastra offline double + native Lua core: menu, movement, levels, treasure, render caps, finish, restart passed")
