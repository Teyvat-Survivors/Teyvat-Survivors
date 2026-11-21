-- Mount this script on the ProbeRoot client container in the Miliastra editor.
local root
local player
local landmarks = {}
local touchRegion
local confirmButton
local status
local imagePrefab
local confirmAudio
local audioInstance
local started = false
local initialized = false
local canvasWait = 0
local keys = {}
local listeners = {}
local touchId
local touchX, touchY = 0, 0
local originX, originY = 0, 0
local worldX, worldY = 0, 0
local cameraX, cameraY = 0, 0
local previousDevice

local function clearTouch()
    touchId = nil
    touchX, touchY = 0, 0
end

local function clearInput()
    keys = {}
    clearTouch()
end

local function syncDevice()
    local device = game.GetDevice()
    if previousDevice ~= device then
        clearInput()
        previousDevice = device
    end
    return device
end

local function touchStarted(event)
    if syncDevice() == Enum.Device.Mobile and touchId == nil then
        touchId = event.touchId
        originX, originY = event:GetUIPos()
    end
end

local function touchMoved(event)
    if touchId == nil or event.touchId ~= touchId then return end
    local x, y = event:GetUIPos()
    local dx, dy = x - originX, y - originY
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= 5 then
        touchX, touchY = 0, 0
    else
        local strength = math.min((distance - 5) / 50, 1) / distance
        touchX, touchY = dx * strength, dy * strength
    end
end

local function touchEnded(event)
    if touchId ~= nil and event.touchId == touchId then clearTouch() end
end

local function stopAudio()
    if audioInstance then
        if game.IsAudioAlive(audioInstance) then game.StopAudio(audioInstance) end
        audioInstance = nil
    end
end

local function confirm()
    if confirmAudio > 0 then
        stopAudio()
        audioInstance = game.PlayAudio2D(confirmAudio)
        status.text = "已确认，已请求播放音效"
    else
        status.text = "已确认，未配置音效"
    end
end

local function listen(target, kind, event, callback)
    if kind == "key" then
        target:AddKeyEventListener(event, callback)
    else
        target:AddCursorEventListener(event, callback)
    end
    listeners[#listeners + 1] = { target = target, kind = kind, event = event, callback = callback }
end

local function bindKey(key, down, up)
    listen(root, "key", down, function()
        if syncDevice() ~= Enum.Device.KeyboardAndMouse then return false end
        keys[key] = 1
        return true
    end)
    listen(root, "key", up, function()
        if syncDevice() ~= Enum.Device.KeyboardAndMouse then return false end
        keys[key] = 0
        return true
    end)
end

local function attachInput()
    if #listeners > 0 then return end
    local key = Enum.KeyEventType
    bindKey("up", key.KeyboardMoveForwardKeyDown, key.KeyboardMoveForwardKeyUp)
    bindKey("down", key.KeyboardMoveBackwardKeyDown, key.KeyboardMoveBackwardKeyUp)
    bindKey("left", key.KeyboardMoveLeftKeyDown, key.KeyboardMoveLeftKeyUp)
    bindKey("right", key.KeyboardMoveRightKeyDown, key.KeyboardMoveRightKeyUp)
    listen(root, "key", key.KeyboardCraftspersonKey1Down, function()
        confirm()
        return true
    end)

    local cursor = Enum.CursorEventType
    listen(touchRegion, "cursor", cursor.CursorDown, touchStarted)
    listen(touchRegion, "cursor", cursor.CursorDrag, touchMoved)
    listen(touchRegion, "cursor", cursor.CursorUp, touchEnded)
    listen(touchRegion, "cursor", cursor.CursorEndDrag, touchEnded)
    listen(touchRegion, "cursor", cursor.CursorExit, touchEnded)
    listen(confirmButton, "cursor", cursor.CursorClick, confirm)
end

local function detachInput()
    for _, entry in ipairs(listeners) do
        local target = entry.target
        if target.alive then
            if entry.kind == "key" then
                target:RemoveKeyEventListener(entry.event, entry.callback)
            else
                target:RemoveCursorEventListener(entry.event, entry.callback)
            end
        end
    end
    listeners = {}
    clearInput()
end

local function makeImage(size)
    local image = assert(game.InstantiateClientUIControl(imagePrefab, root),
        "ProbeImagePrefab must be the root index of a client image template")
    image:SetAnchorMin(0.5, 0.5)
    image:SetAnchorMax(0.5, 0.5)
    image:SetPivot(0.5, 0.5)
    image:SetSizeDelta(size, size)
    image:SetActive(true)
    image:SetVisible(true)
    return image
end

local function initialize()
    root = assert(script.object, "Attach platform_probe.lua to ProbeRoot")
    touchRegion = assert(root:GetChild("ProbeTouchRegion"), "Missing ProbeTouchRegion")
    confirmButton = assert(root:GetChild("ProbeConfirmButton"), "Missing ProbeConfirmButton")
    status = assert(root:GetChild("ProbeStatus"), "Missing ProbeStatus")
    imagePrefab = script:GetParam("ProbeImagePrefab")
    confirmAudio = script:GetParam("ProbeConfirmAudio") or 0
    assert(type(imagePrefab) == "number" and imagePrefab > 0, "Set the ProbeImagePrefab script variable")
    assert(type(confirmAudio) == "number", "ProbeConfirmAudio must be an integer")
    root.showCursor = true
    touchRegion.raycastTarget = true
    confirmButton.raycastTarget = true
    player = makeImage(38)
    for i = 1, 3 do
        landmarks[i] = { image = makeImage(17), x = (i - 2) * 150, y = 95 }
    end
    player:SetAsLastSibling()
    touchRegion:SetAsLastSibling()
    confirmButton:SetAsLastSibling()
    status.text = "WASD 或触屏拖动 · 点击确认试听"
    initialized = true
    attachInput()
end

local function axis(device)
    if device == Enum.Device.Mobile then return touchX, touchY end
    if device == Enum.Device.Controller or device == Enum.Device.MobileController then
        local x, y = game.GetControllerLeftStickAxis()
        if x * x + y * y > 0.04 then return x, y end
        return 0, 0
    end
    return (keys.right or 0) - (keys.left or 0), (keys.up or 0) - (keys.down or 0)
end

local function bounded(value)
    return math.max(-500, math.min(value, 500))
end

function OnStart()
    started = true
    script:EnableUpdate(true)
end

function OnEnable()
    if initialized then attachInput() end
    if started then script:EnableUpdate(true) end
end

function OnUpdate(dt)
    if not initialized then
        local width, height = game.GetUICanvasSize()
        if not (width > 0 and height > 0 and width < math.huge and height < math.huge) then
            canvasWait = canvasWait + 1
            if canvasWait >= 60 then
                script:EnableUpdate(false)
                error("Miliastra canvas did not become available")
            end
            return
        end
        initialize()
        previousDevice = game.GetDevice()
    end

    if type(dt) ~= "number" or not (dt > 0) then return end
    dt = math.min(dt, 0.1)
    local x, y = axis(syncDevice())
    local length = math.sqrt(x * x + y * y)
    if length > 1 then x, y = x / length, y / length end
    worldX = bounded(worldX + x * 220 * dt)
    worldY = bounded(worldY + y * 220 * dt)
    local follow = math.min(6 * dt, 1)
    cameraX = cameraX + (worldX - cameraX) * follow
    cameraY = cameraY + (worldY - cameraY) * follow
    player:SetAnchoredPosition(worldX - cameraX, worldY - cameraY)
    for _, landmark in ipairs(landmarks) do
        landmark.image:SetAnchoredPosition(landmark.x - cameraX, landmark.y - cameraY)
    end
end

function OnDisable()
    detachInput()
    stopAudio()
    script:EnableUpdate(false)
end

function OnDestroy()
    detachInput()
    stopAudio()
    if player and player.alive then game.DestroyClientUIControl(player) end
    for _, landmark in ipairs(landmarks) do
        if landmark.image.alive then game.DestroyClientUIControl(landmark.image) end
    end
    landmarks = {}
    player = nil
end
