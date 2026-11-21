-- Offline test double for documented calls. This does not run Miliastra.
local function enumerated(names)
    local result = {}
    for name in names:gmatch("%w+") do result[name] = name end
    return result
end

Enum = {
    Device = enumerated("Mobile KeyboardAndMouse Controller MobileController"),
    KeyEventType = enumerated([[
      KeyboardMoveForwardKeyDown KeyboardMoveForwardKeyUp
      KeyboardMoveBackwardKeyDown KeyboardMoveBackwardKeyUp
      KeyboardMoveLeftKeyDown KeyboardMoveLeftKeyUp
      KeyboardMoveRightKeyDown KeyboardMoveRightKeyUp KeyboardCraftspersonKey1Down
    ]]),
    CursorEventType = enumerated("CursorDown CursorDrag CursorUp CursorEndDrag CursorExit CursorClick")
}

local function makeControl()
    local control = { alive = true, keys = {}, cursors = {}, children = {} }
    function control:GetChild(name) return self.children[name] end
    function control:SetAnchorMin() end
    function control:SetAnchorMax() end
    function control:SetPivot() end
    function control:SetSizeDelta(w, h) self.width, self.height = w, h end
    function control:SetAnchoredPosition(x, y) self.x, self.y = x, y end
    function control:SetActive(active) self.active = active end
    function control:SetVisible(visible) self.visible = visible end
    function control:SetAsLastSibling() end
    function control:AddKeyEventListener(event, handler)
        assert(event and self.keys[event] == nil)
        self.keys[event] = handler
    end
    function control:RemoveKeyEventListener(event, handler)
        assert(self.keys[event] == handler)
        self.keys[event] = nil
    end
    function control:AddCursorEventListener(event, handler)
        assert(event and self.cursors[event] == nil)
        self.cursors[event] = handler
    end
    function control:RemoveCursorEventListener(event, handler)
        assert(self.cursors[event] == handler)
        self.cursors[event] = nil
    end
    return control
end

local root = makeControl()
local region, button, status = makeControl(), makeControl(), makeControl()
root.children.ProbeTouchRegion = region
root.children.ProbeConfirmButton = button
root.children.ProbeStatus = status
local controls = {}
local audioPlaying = false
local device = Enum.Device.KeyboardAndMouse
local canvasAvailable = false
local padX, padY = 0, 0
script = { object = root }
function script:EnableUpdate(enabled) self.updating = enabled end
function script:GetParam(name) return ({ ProbeImagePrefab = 111, ProbeConfirmAudio = 222 })[name] end
game = {
    GetDevice = function() return device end,
    GetUICanvasSize = function() return canvasAvailable and 1280 or 0, 720 end,
    GetControllerLeftStickAxis = function() return padX, padY end,
    PlayAudio2D = function(id)
        assert(id == 222)
        audioPlaying = true
        return 333
    end,
    IsAudioAlive = function(id) return id == 333 and audioPlaying end,
    StopAudio = function(id)
        assert(id == 333 and audioPlaying)
        audioPlaying = false
    end,
    InstantiateClientUIControl = function(prefab, parent)
        assert(prefab == 111 and parent == root)
        local control = makeControl()
        controls[#controls + 1] = control
        return control
    end,
    DestroyClientUIControl = function(control)
        assert(control.alive)
        control.alive = false
    end
}

local function event(id, x, y)
    return { touchId = id, GetUIPos = function() return x, y end }
end

local function worldPosition()
    -- The third control is a landmark at world x=0, y=95.
    return controls[1].x - controls[3].x, controls[1].y - controls[3].y + 95
end

local function close(actual, expected)
    assert(math.abs(actual - expected) < 1e-6, tostring(actual) .. " != " .. tostring(expected))
end

dofile("gil/platform_probe.lua")
OnEnable()
assert(not script.updating)
OnStart()
assert(script.updating)
OnUpdate(0.05)
assert(#controls == 0)
canvasAvailable = true
OnUpdate(0.05)
assert(#controls == 4)
assert(controls[1].width == 38 and controls[3].width == 17)
close(worldPosition(), 0)

assert(root.keys.KeyboardMoveRightKeyDown())
assert(root.keys.KeyboardMoveForwardKeyDown())
OnUpdate(0.1)
local x, y = worldPosition()
close(x, 22 / math.sqrt(2))
close(y, x)
assert(controls[3].x < 0)
root.keys.KeyboardMoveRightKeyUp()
root.keys.KeyboardMoveForwardKeyUp()
OnUpdate(0.1)
close(worldPosition(), x)

device = Enum.Device.Mobile
region.cursors.CursorDown(event(0, 50, 50))
region.cursors.CursorDrag(event(1, 50, 120))
OnUpdate(0.1)
close(worldPosition(), x)
region.cursors.CursorDrag(event(0, 105, 50))
OnUpdate(0.1)
close(worldPosition(), x + 22)
region.cursors.CursorEndDrag(event(0, 105, 50))
OnUpdate(0.1)
close(worldPosition(), x + 22)
button.cursors.CursorClick()
assert(audioPlaying and status.text:find("已确认", 1, true))

device = Enum.Device.Controller
padY = -1
OnUpdate(0.1)
local _, movedY = worldPosition()
close(movedY, y - 22)

OnDisable()
assert(not script.updating and not audioPlaying)
assert(next(root.keys) == nil and next(region.cursors) == nil and next(button.cursors) == nil)
OnEnable()
assert(script.updating and root.keys.KeyboardMoveRightKeyDown and #controls == 4)
OnDestroy()
assert(next(root.keys) == nil and next(region.cursors) == nil)
for _, control in ipairs(controls) do assert(not control.alive) end
print("Miliastra platform probe passed its offline Lua test double")
