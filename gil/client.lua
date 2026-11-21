-- Official Miliastra client Lua entry. Attach the bundled source to GameRoot.
local Run = require("game.run")
local Stages = require("data.stages")
local Weapons = require("data.weapons")

local stageOptions = {
    { id = "windward", label = "迎风原 · 30 分钟" },
    { id = "moon_reeds", label = "月芦滩 · 8 分钟" },
    { id = "cinder_ridge", label = "余烬峡 · 6 分钟" },
}
local starterIds = { "wind_blade", "frost_pulse", "ember_field" }
local characters = {
    { id = "wind_scout", label = "风庭斥候" },
    { id = "frost_scribe", label = "霜信书记" },
    { id = "ember_courier", label = "炉火信使" },
}
local outcomes = { defeated = "本局结束", finale_defeated = "终局敌人已击败", finale_survived = "成功撑过终局" }
local colors = {
    text = { 243, 244, 235 }, panel = { 22, 35, 48, 230 }, button = { 39, 74, 82, 245 },
    ground = { 108, 146, 152, 150 }, player = { 238, 253, 244 },
    enemy = { 229, 107, 94 }, elite = { 242, 159, 68 }, windup = { 247, 213, 105 },
    boss = { 226, 110, 205 }, shot = { 154, 246, 255 }, field = { 100, 190, 243, 80 },
    xp = { 86, 193, 242 }, coin = { 246, 217, 100 }, healing = { 119, 224, 153 },
    magnet = { 171, 147, 243 }, treasure = { 255, 186, 94 },
    hazard = { 221, 89, 79, 85 }, alert = { 255, 147, 89, 135 },
}
local state
local started = false
local retries = 0
local seed = 0

local function finite(n)
    return type(n) == "number" and n > -math.huge and n < math.huge
end

local function within(n, low, high)
    return math.max(low, math.min(high, n))
end

local function text(label, value)
    if label.value ~= value then
        label.value = value
        label.control.text = value
    end
end

local function visible(control, show)
    if control.visible ~= show then control:SetVisible(show) end
end

local function active(control, show)
    if control.active ~= show then control:SetActive(show) end
end

local function place(control, x, y, width, height)
    control:SetAnchoredPosition(x, y)
    control:SetSizeDelta(width, height)
end

local function createControl(prefab, parent)
    local control = assert(game.InstantiateClientUIControl(prefab, parent), "检查客户端根模板索引")
    control:SetAnchorMin(0.5, 0.5)
    control:SetAnchorMax(0.5, 0.5)
    control:SetPivot(0.5, 0.5)
    return control
end

local function newText(state, panel)
    local control = createControl(state.textPrefab, state.root)
    control:SetActive(true)
    control.fontColor = state.palette.text
    if panel then control.bgColor = state.palette.panel end
    return { control = control }
end

local function listen(state, target, kind, event, callback)
    local add = kind == "key" and target.AddKeyEventListener or target.AddCursorEventListener
    add(target, event, callback)
    state.listeners[#state.listeners + 1] = { target = target, kind = kind, event = event, callback = callback }
end

local function clearInput(state)
    state.keys = {}
    state.touchId = nil
    state.touchX, state.touchY = 0, 0
end

local function unbind(state)
    for _, entry in ipairs(state.listeners) do
        local target = entry.target
        if target.alive then
            local remove = entry.kind == "key" and target.RemoveKeyEventListener or target.RemoveCursorEventListener
            remove(target, entry.event, entry.callback)
        end
    end
    state.listeners = {}
    clearInput(state)
end

local function stopConfirm(state)
    if state.audio and game.IsAudioAlive(state.audio) then game.StopAudio(state.audio) end
    state.audio = nil
end

local function playConfirm(state)
    if state.audioId > 0 then
        stopConfirm(state)
        state.audio = game.PlayAudio2D(state.audioId)
    end
end

local function invalidatePresses(state)
    state.pressGeneration = state.pressGeneration + 1
end

local function menu(state, title, detail, items, action)
    invalidatePresses(state)
    state.action = action
    state.items = items
    state.panel = true
    text(state.title, title)
    text(state.detail, detail)
    visible(state.title.control, true)
    visible(state.detail.control, detail ~= "")
    for index, button in ipairs(state.buttons) do
        local item = items[index]
        active(button.root, item ~= nil)
        if item then text(button.label, item.label) end
    end
end

local function hideMenu(state)
    invalidatePresses(state)
    state.action, state.items, state.panel = nil, {}, false
    visible(state.title.control, false)
    visible(state.detail.control, false)
    for _, button in ipairs(state.buttons) do active(button.root, false) end
end

local function openBattle(state, run)
    state.run = run
    state.screen = "battle"
    state.choice = nil
    clearInput(state)
    hideMenu(state)
    active(state.world, true)
    visible(state.hud.control, true)
end

local function goHome(state)
    state.screen = "home"
    state.run = nil
    active(state.world, false)
    visible(state.hud.control, false)
    menu(state, "提瓦特幸存者", "", { { label = "开始" } }, function()
        state.screen = "stage"
        local options = {}
        for _, item in ipairs(stageOptions) do
            if Stages[item.id] then options[#options + 1] = item end
        end
        options[#options + 1] = { label = "返回" }
        menu(state, "选择关卡", "", options, function(stage)
            if not stage.id then goHome(state) return end
            state.screen = "starter"
            local starters = {}
            if Run.for_character then
                for _, item in ipairs(characters) do starters[#starters + 1] = item end
            else
                for _, id in ipairs(starterIds) do
                    starters[#starters + 1] = { id = id, label = Weapons[id].label }
                end
            end
            starters[#starters + 1] = { label = "返回首页" }
            menu(state, Run.for_character and "选择角色" or "选择初始技能", stage.label, starters, function(starter)
                if not starter.id then goHome(state) return end
                seed = seed % 2147483645 + 1
                local run
                if Run.for_character then
                    run = assert(Run.for_character(starter.id, seed, Stages[stage.id]))
                else
                    run = Run.new(seed, Stages[stage.id], starter.id)
                end
                openBattle(state, run)
            end)
        end)
    end)
end

local function currentChoice(run)
    if run.loot and run.loot.choices then return run.loot.choices, "loot" end
    return run.progress.choices, "progress"
end

local function syncBattle(state)
    local run = state.run
    if not run or state.screen ~= "battle" then return end

    if run.result then
        state.screen = "result"
        clearInput(state)
        active(state.world, false)
        visible(state.hud.control, false)
        local summary = string.format("击败 %d  ·  等级 %d  ·  风砂币 %d",
            run.result.kills, run.result.level, run.result.coins or 0)
        menu(state, outcomes[run.result.outcome] or "本局结束", summary,
            { { id = "restart", label = "再来一局" }, { label = "返回首页" } }, function(item)
                if item.id == "restart" then
                    openBattle(state, Run.restart(run))
                else
                    goHome(state)
                end
            end)
        return
    end

    local choice, kind = currentChoice(run)
    if choice ~= state.choice then
        state.choice = choice
        clearInput(state)
        if choice then
            local items = {}
            for _, option in ipairs(choice.options) do
                items[#items + 1] = { label = option.label, id = option.key or option.id }
            end
            if kind == "progress" and Run.reroll and run.build.remaining.reroll > 0 then
                items[#items + 1] = { label = "重抽", command = Run.reroll }
            end
            if kind == "progress" and Run.skip and run.build.remaining.skip > 0 then
                items[#items + 1] = { label = "跳过", command = Run.skip }
            end
            menu(state, kind == "loot" and "宝箱奖励" or "选择升级", "", items, function(item)
                if item.command then
                    item.command(run, choice.token)
                elseif kind == "loot" then
                    Run.choose_treasure(run, choice.token, item.id)
                else
                    Run.choose(run, choice.token, item.id)
                end
                syncBattle(state)
            end)
        else
            hideMenu(state)
        end
    end

    local seconds = math.floor(run.tick / 60)
    local remaining = math.max(0, math.ceil((run.stage.duration_ticks - run.tick) / 60))
    text(state.hud, string.format("%02d:%02d  ·  生命 %d/%d  ·  等级 %d  ·  击败 %d  ·  %s",
        math.floor(seconds / 60), seconds % 60, math.ceil(run.player.health), math.ceil(run.player.max_health),
        run.progress.level, run.kills, run.terminal_id and "终局" or (remaining .. " 秒后进入终局")))
end

local function dispatch(state, index)
    local item = state.items[index]
    if not item or not state.action or state.actionFrame == state.frame then return false end
    state.actionFrame = state.frame
    playConfirm(state)
    state.action(item)
    return true
end

local function togglePause(state)
    local run = state.run
    if not run or state.screen ~= "battle" or state.choice then return false end
    Run.set_paused(run, not run.paused)
    clearInput(state)
    if run.paused then
        menu(state, "暂停", "", { { id = "resume", label = "继续" }, { label = "返回首页" } }, function(item)
            if item.id == "resume" then togglePause(state) else goHome(state) end
        end)
    else
        hideMenu(state)
    end
    return true
end

local function device(state)
    local current = game.GetDevice()
    if state.device ~= current then
        clearInput(state)
        state.device = current
    end
    return current
end

local function movementOpen(state)
    return state.screen == "battle" and not state.panel
end

local function movement(state)
    local current = device(state)
    if current == Enum.Device.Mobile then return state.touchX, state.touchY end
    if current == Enum.Device.Controller or current == Enum.Device.MobileController then
        local x, y = game.GetControllerLeftStickAxis()
        if finite(x) and finite(y) and x * x + y * y > 0.04 then return x, y end
        return 0, 0
    end
    return (state.keys.right or 0) - (state.keys.left or 0), (state.keys.up or 0) - (state.keys.down or 0)
end

local function bindPress(state, button, available, action)
    local cursor = Enum.CursorEventType
    listen(state, button.hit, "cursor", cursor.CursorDown, function(event)
        if available() then
            button.press = state.pressGeneration
            button.press_id = event and event.touchId
        end
    end)
    listen(state, button.hit, "cursor", cursor.CursorExit, function()
        button.press = nil
    end)
    listen(state, button.hit, "cursor", cursor.CursorClick, function(event)
        local current = button.press == state.pressGeneration and button.press_id == (event and event.touchId)
        button.press = nil
        if current then action() end
    end)
end

local function bindInput(state)
    if #state.listeners > 0 then return end
    local key, cursor = Enum.KeyEventType, Enum.CursorEventType
    local function bindMove(name, down, up)
        listen(state, state.root, "key", down, function()
            if device(state) ~= Enum.Device.KeyboardAndMouse or not movementOpen(state) then return false end
            state.keys[name] = 1
            return true
        end)
        listen(state, state.root, "key", up, function()
            state.keys[name] = 0
            return movementOpen(state)
        end)
    end
    bindMove("up", key.KeyboardMoveForwardKeyDown, key.KeyboardMoveForwardKeyUp)
    bindMove("down", key.KeyboardMoveBackwardKeyDown, key.KeyboardMoveBackwardKeyUp)
    bindMove("left", key.KeyboardMoveLeftKeyDown, key.KeyboardMoveLeftKeyUp)
    bindMove("right", key.KeyboardMoveRightKeyDown, key.KeyboardMoveRightKeyUp)
    for i, button in ipairs(state.buttons) do
        bindPress(state, button, function() return state.items[i] ~= nil end, function() dispatch(state, i) end)
        listen(state, state.root, "key", key["KeyboardCraftspersonKey" .. i .. "Down"], function()
            return dispatch(state, i)
        end)
    end
    listen(state, state.root, "key", key.KeyboardCraftspersonKey10Down, function() return togglePause(state) end)
    bindPress(state, state.pause, function() return movementOpen(state) end, function() togglePause(state) end)
    listen(state, state.touch, "cursor", cursor.CursorDown, function(event)
        if device(state) == Enum.Device.Mobile and movementOpen(state) and state.touchId == nil then
            state.touchId = event.touchId
            state.touchOriginX, state.touchOriginY = event:GetUIPos()
        end
    end)
    listen(state, state.touch, "cursor", cursor.CursorDrag, function(event)
        if state.touchId == nil or event.touchId ~= state.touchId then return end
        local x, y = event:GetUIPos()
        local dx, dy = x - state.touchOriginX, y - state.touchOriginY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance <= 4 then
            state.touchX, state.touchY = 0, 0
        else
            local strength = math.min((distance - 4) / (50 * state.uiScale), 1) / distance
            state.touchX, state.touchY = dx * strength, dy * strength
        end
    end)
    local function release(event)
        if event.touchId == state.touchId then
            state.touchId = nil
            state.touchX, state.touchY = 0, 0
        end
    end
    listen(state, state.touch, "cursor", cursor.CursorUp, release)
    listen(state, state.touch, "cursor", cursor.CursorEndDrag, release)
    listen(state, state.touch, "cursor", cursor.CursorExit, release)
end

local function pool(limit, behind)
    return { limit = limit, count = 0, last = 0, sprites = {}, behind = behind }
end

local function draw(state, pool, x, y, radius, tint)
    local size = math.max(3, radius * 2 * state.worldScale)
    x = (x - state.run.player.x) * state.worldScale
    y = (y - state.run.player.y) * state.worldScale
    if math.abs(x) > (state.width + size) / 2 or math.abs(y) > (state.height + size) / 2 then return end
    if pool.count == pool.limit then
        state.clipped = true
        return
    end
    pool.count = pool.count + 1
    local sprite = pool.sprites[pool.count]
    if not sprite then
        local control = createControl(state.imagePrefab, state.world)
        if pool.behind then control:SetAsFirstSibling() end
        sprite = { control = control }
        pool.sprites[pool.count] = sprite
    end
    if sprite.x ~= x or sprite.y ~= y then
        sprite.control:SetAnchoredPosition(x, y)
        sprite.x, sprite.y = x, y
    end
    if sprite.size ~= size then
        sprite.control:SetSizeDelta(size, size)
        sprite.size = size
    end
    if sprite.tint ~= tint then
        sprite.control.imageColor = state.palette[tint]
        sprite.tint = tint
    end
    active(sprite.control, true)
    visible(sprite.control, true)
end

local function drawWorld(state)
    local run, p = state.run, state.pools
    for _, items in pairs(p) do items.count = 0 end
    state.clipped = false
    local player = run.player
    local grid = 8
    local halfX = state.width / (2 * state.worldScale)
    local halfY = state.height / (2 * state.worldScale)
    for x = grid * math.ceil((player.x - halfX) / grid), player.x + halfX, grid do
        for y = grid * math.ceil((player.y - halfY) / grid), player.y + halfY, grid do
            if x >= run.bounds.min_x and x <= run.bounds.max_x and
                y >= run.bounds.min_y and y <= run.bounds.max_y then
                draw(state, p.ground, x, y, 0.12, "ground")
            end
        end
    end
    for _, feature in ipairs(run.stage_features) do
        if not feature.spent then
            local def = feature.definition
            local tint = def.kind == "healing" and "healing" or
                (feature.next_tick - run.tick <= 30 and "alert" or "hazard")
            draw(state, p.terrain, def.x, def.y, def.radius, tint)
        end
    end
    for _, weapon in ipairs(run.weapon_systems) do
        for _, field in ipairs(weapon.fields) do draw(state, p.fields, field.x, field.y, field.radius, "field") end
        for _, shot in ipairs(weapon.projectiles) do
            draw(state, p.shots, shot.x, shot.y + (shot.height or 0), shot.radius, "shot")
        end
    end
    for _, pickup in ipairs(run.progress.pickups) do draw(state, p.pickups, pickup.x, pickup.y, 0.14, "xp") end
    for _, pickup in ipairs(run.loot.pickups) do
        draw(state, p.pickups, pickup.x, pickup.y, 0.26, state.palette[pickup.kind] and pickup.kind or "coin")
    end
    for _, enemy in ipairs(run.enemies.active) do
        local tint = enemy.isTerminal and "boss" or enemy.motion == "windup" and "windup" or
            enemy.isElite and "elite" or "enemy"
        draw(state, p.enemies, enemy.x, enemy.y, enemy.radius, tint)
    end
    draw(state, p.player, player.x, player.y, player.radius, "player")
    for _, items in pairs(p) do
        for i = items.count + 1, items.last do visible(items.sprites[i].control, false) end
        items.last = items.count
    end
end

local function createButton(state)
    local root = createControl(state.actionPrefab, state.root)
    local label, hit = root:GetChild("Label"), root:GetChild("Hit")
    if not label or not hit then
        game.DestroyClientUIControl(root)
        error("操作模板需要 Label 文本框和 Hit 光标检测区域")
    end
    label.fontColor = state.palette.text
    label.bgColor = state.palette.button
    hit.raycastTarget = true
    return { root = root, label = { control = label }, hit = hit }
end

local function layout(state, width, height)
    state.width, state.height = width, height
    local scale = math.min(width / 1100, height / 660)
    state.uiScale = scale
    state.worldScale = height / 38
    local function textAt(label, x, y, width, height, font)
        label.control.fontSize = math.max(1, math.floor(font * scale))
        place(label.control, x, y, width * scale, height * scale)
    end
    local function buttonAt(button, x, y, width, height)
        place(button.root, x, y, width * scale, height * scale)
        button.label.control.fontSize = math.max(1, math.floor(23 * scale))
    end
    textAt(state.title, 0, 207 * scale, 570, 64, 39)
    textAt(state.detail, 0, 145 * scale, 570, 47, 23)
    textAt(state.hud, 0, height * 0.5 - 34 * scale, 790, 46, 21)
    textAt(state.padText, -width * 0.5 + 128 * scale, -height * 0.5 + 47 * scale, 188, 38, 20)
    textAt(state.budget, 0, -height * 0.5 + 35 * scale, 400, 35, 19)
    for i, button in ipairs(state.buttons) do
        buttonAt(button, 0, (81 - (i - 1) * 55) * scale, 405, 48)
    end
    buttonAt(state.pause, width * 0.5 - 76 * scale, height * 0.5 - 35 * scale, 125, 49)
    place(state.touch, -width * 0.5 + 155 * scale, -height * 0.5 + 153 * scale, 278 * scale, 267 * scale)
end

local function setup(width, height)
    local root = assert(script.object, "将脚本挂载到 GameRoot")
    local client = {
        root = root, world = assert(root:GetChild("World"), "GameRoot 缺少 World"),
        touch = assert(root:GetChild("MoveArea"), "GameRoot 缺少 MoveArea"),
        imagePrefab = script:GetParam("TSImageTemplate"),
        textPrefab = script:GetParam("TSTextTemplate"),
        actionPrefab = script:GetParam("TSActionTemplate"),
        audioId = script:GetParam("TSConfirmAudio") or 0,
        buttons = {}, listeners = {}, palette = {}, frame = 0, pressGeneration = 0,
        pools = {
            ground = pool(160, true), terrain = pool(16, true), fields = pool(36, true),
            shots = pool(96), pickups = pool(96), enemies = pool(300), player = pool(1),
        },
    }
    assert(finite(client.audioId) and client.audioId >= 0, "TSConfirmAudio 必须是已配置的音效 ID 或 0")
    for _, prefab in ipairs({ "imagePrefab", "textPrefab", "actionPrefab" }) do
        assert(finite(client[prefab]) and client[prefab] > 0, "配置脚本的客户端根模板索引")
    end
    for id, channels in pairs(colors) do
        client.palette[id] = Color.FromRGBA(channels[1], channels[2], channels[3], channels[4] or 255)
    end
    root.showCursor = true
    root.disableKeyEventPassthrough = true
    root.disableCursorEventPassthrough = true
    client.touch.raycastTarget = true
    client.buttons[1] = createButton(client)
    client.title = newText(client, true)
    client.detail = newText(client, true)
    client.hud = newText(client, true)
    client.padText = newText(client, true)
    client.budget = newText(client, true)
    text(client.padText, "拖动移动")
    text(client.budget, "部分图元达到显示上限")
    visible(client.budget.control, false)
    for i = 2, 6 do client.buttons[i] = createButton(client) end
    client.pause = createButton(client)
    text(client.pause.label, "暂停")
    layout(client, width, height)
    clearInput(client)
    goHome(client)
    active(client.touch, false)
    active(client.pause.root, false)
    visible(client.padText.control, false)
    bindInput(client)
    return client
end

function OnStart()
    started = true
    script:EnableUpdate(true)
end

function OnEnable()
    if state then bindInput(state) end
    if started then script:EnableUpdate(true) end
end

function OnUpdate(dt)
    local width, height = game.GetUICanvasSize()
    if not finite(width) or not finite(height) or width <= 0 or height <= 0 then
        if state then
            clearInput(state)
        else
            retries = retries + 1
            if retries >= 60 then
                script:EnableUpdate(false)
                error("千星画布未就绪")
            end
        end
        return
    end
    if not state then state = setup(width, height) end
    if width ~= state.width or height ~= state.height then
        clearInput(state)
        invalidatePresses(state)
        layout(state, width, height)
    end
    state.frame = state.frame + 1
    local run = state.run
    local current = device(state)
    if state.screen == "battle" then
        if movementOpen(state) and finite(dt) and dt > 0 then
            local x, y = movement(state)
            Run.update(run, dt, x, y)
            Run.take_events(run)
        end
        syncBattle(state)
        if state.screen == "battle" then drawWorld(state) end
    end
    local mobile = current == Enum.Device.Mobile and movementOpen(state)
    active(state.touch, mobile)
    active(state.pause.root, state.screen == "battle" and not state.panel)
    visible(state.padText.control, mobile)
    visible(state.budget.control, state.screen == "battle" and not state.panel and state.clipped == true)
end

function OnDisable()
    if state then
        invalidatePresses(state)
        unbind(state)
        stopConfirm(state)
    end
    script:EnableUpdate(false)
end

function OnDestroy()
    if not state then return end
    unbind(state)
    stopConfirm(state)
    for _, items in pairs(state.pools) do
        for _, sprite in ipairs(items.sprites) do
            if sprite.control.alive then game.DestroyClientUIControl(sprite.control) end
        end
    end
    for _, name in ipairs({ "title", "detail", "hud", "padText", "budget" }) do
        local control = state[name].control
        if control.alive then game.DestroyClientUIControl(control) end
    end
    for _, button in ipairs(state.buttons) do
        if button.root.alive then game.DestroyClientUIControl(button.root) end
    end
    if state.pause.root.alive then game.DestroyClientUIControl(state.pause.root) end
    state = nil
end
