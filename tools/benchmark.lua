-- Run from the project root: lua tools/benchmark.lua [frames] [seed]
local frames = tonumber(arg[1] or "360")
local seed = tonumber(arg[2] or "21713")
assert(frames and frames >= 1 and frames <= 3600 and frames % 1 == 0, "frames must be 1..3600")
assert(seed and seed >= 1 and seed <= 2147483646 and seed % 1 == 0, "seed must be 1..2147483646")

local CELL = 48
local MAX_ENEMY_RADIUS = 9
local SHOT_RADIUS = 2
local MODULUS = 2147483647
local kinds = {
    { name = "enemies", portion = 0.60, period = 160, extent = 260 },
    { name = "shots", portion = 0.25, period = 24, extent = 180 },
    { name = "pickups", portion = 0.15, period = 48, extent = 200 },
}

local function makeRandom(initial)
    local state = initial
    return function()
        state = (state * 48271) % MODULUS
        return state / MODULUS
    end
end

local function initialize(entity, slot, kind, random)
    local extent = kind.extent
    entity.slot = slot
    entity.x = (random() * 2 - 1) * extent
    entity.y = (random() * 2 - 1) * extent
    entity.radius = MAX_ENEMY_RADIUS - 4 + math.floor(random() * 5)
    entity.speed = 0.7 + random() * 0.9
    local heading = random() * 2 * math.pi
    entity.dx, entity.dy = math.cos(heading), math.sin(heading)
    return entity
end

local function moveToward(entity, x, y, distance)
    local dx, dy = x - entity.x, y - entity.y
    local squared = dx * dx + dy * dy
    if squared <= distance * distance then
        entity.x, entity.y = x, y
    else
        local advance = distance / math.sqrt(squared)
        entity.x, entity.y = entity.x + dx * advance, entity.y + dy * advance
    end
end

local function moveScene(scene, tick, random, reuse, slowEnemies)
    local playerX = 120 * math.cos(tick / 46)
    local playerY = 100 * math.sin(tick / 53)
    local renewals = 0

    for _, kind in ipairs(kinds) do
        local group = scene[kind.name]
        for slot, entity in ipairs(group) do
            if (tick + slot * 13) % kind.period == 0 then
                entity = initialize(reuse and entity or {}, slot, kind, random)
                group[slot] = entity
                renewals = renewals + 1
            end
            if kind.name == "enemies" then
                if not slowEnemies or tick % 2 == 0 then
                    moveToward(entity, playerX, playerY, entity.speed * (slowEnemies and 2 or 1))
                end
            elseif kind.name == "shots" then
                entity.from_x, entity.from_y = entity.x, entity.y
                entity.travel = 7 + entity.speed
                entity.x = entity.x + entity.dx * entity.travel
                entity.y = entity.y + entity.dy * entity.travel
            else
                local dx, dy = playerX - entity.x, playerY - entity.y
                if dx * dx + dy * dy <= 75 * 75 then
                    moveToward(entity, playerX, playerY, 2)
                end
            end
        end
    end
    return renewals
end

local function resetGrid(grid)
    for _, column in pairs(grid) do
        for _, bucket in pairs(column) do
            for i = #bucket, 1, -1 do
                bucket[i] = nil
            end
        end
    end
end

local function indexEnemies(grid, enemies)
    resetGrid(grid)
    for _, enemy in ipairs(enemies) do
        local ix, iy = math.floor(enemy.x / CELL), math.floor(enemy.y / CELL)
        local column = grid[ix]
        if not column then
            column = {}
            grid[ix] = column
        end
        local bucket = column[iy]
        if not bucket then
            bucket = {}
            column[iy] = bucket
        end
        bucket[#bucket + 1] = enemy
    end
end

local function sweptHit(shot, enemy)
    local dx, dy = enemy.x - shot.from_x, enemy.y - shot.from_y
    local position = math.max(0, math.min(shot.travel, dx * shot.dx + dy * shot.dy))
    dx, dy = dx - position * shot.dx, dy - position * shot.dy
    local radius = enemy.radius + SHOT_RADIUS
    return dx * dx + dy * dy <= radius * radius
end

local function checkCandidates(shot, candidates, hits, fingerprint)
    for _, enemy in ipairs(candidates) do
        if sweptHit(shot, enemy) then
            hits = hits + 1
            fingerprint = (fingerprint + shot.slot * 131071 + enemy.slot * 8191
                + shot.slot * enemy.slot * 31) % MODULUS
        end
    end
    return hits, fingerprint
end

local function collide(scene, grid, tick, stagger)
    local checks, hits, fingerprint = 0, 0, 0
    local extent = MAX_ENEMY_RADIUS + SHOT_RADIUS
    for _, shot in ipairs(scene.shots) do
        if not stagger or (shot.slot + tick) % 2 == 0 then
            if grid then
                local left = math.floor((math.min(shot.x, shot.from_x) - extent) / CELL)
                local right = math.floor((math.max(shot.x, shot.from_x) + extent) / CELL)
                local bottom = math.floor((math.min(shot.y, shot.from_y) - extent) / CELL)
                local top = math.floor((math.max(shot.y, shot.from_y) + extent) / CELL)
                for ix = left, right do
                    local column = grid[ix]
                    if column then
                        for iy = bottom, top do
                            local bucket = column[iy]
                            if bucket then
                                checks = checks + #bucket
                                hits, fingerprint = checkCandidates(shot, bucket, hits, fingerprint)
                            end
                        end
                    end
                end
            else
                checks = checks + #scene.enemies
                hits, fingerprint = checkCandidates(shot, scene.enemies, hits, fingerprint)
            end
        end
    end
    return checks, hits, fingerprint
end

local function percentile(sorted, fraction)
    return sorted[math.max(1, math.ceil(#sorted * fraction))]
end

local function measure(size, variant, baseline)
    collectgarbage("collect")
    local random = makeRandom(seed)
    local scene = {}
    for _, kind in ipairs(kinds) do
        local group = {}
        for slot = 1, size * kind.portion do
            group[slot] = initialize({}, slot, kind, random)
        end
        scene[kind.name] = group
    end
    local grid = variant.grid and {} or nil
    local times, frameHits, frameFingerprints = {}, {}, {}
    for i = 1, frames do
        times[i], frameHits[i], frameFingerprints[i] = 0, 0, 0
    end

    collectgarbage("collect")
    local startingMemory = collectgarbage("count")
    local peakMemory = startingMemory
    local hits, checks, renewals, fingerprint, differentFrames = 0, 0, 0, 0, 0
    local moveMs, collisionMs = 0, 0
    for tick = 1, frames do
        local started = os.clock()
        renewals = renewals + moveScene(scene, tick, random, variant.reuse, variant.slow_enemies)
        local moved = os.clock()
        if grid then
            indexEnemies(grid, scene.enemies)
        end
        local stepChecks, stepHits, stepFingerprint = collide(scene, grid, tick, variant.stagger)
        local completed = os.clock()
        times[tick] = (completed - started) * 1000
        moveMs = moveMs + (moved - started) * 1000
        collisionMs = collisionMs + (completed - moved) * 1000
        checks, hits = checks + stepChecks, hits + stepHits
        fingerprint = (fingerprint * 65537 + stepFingerprint + stepHits) % MODULUS
        peakMemory = math.max(peakMemory, collectgarbage("count"))
        frameHits[tick], frameFingerprints[tick] = stepHits, stepFingerprint
        if baseline and (stepHits ~= baseline.hits[tick] or stepFingerprint ~= baseline.fingerprints[tick]) then
            differentFrames = differentFrames + 1
        end
    end

    collectgarbage("collect")
    local retainedMemory = collectgarbage("count")
    table.sort(times)
    return {
        hits = frameHits, fingerprints = frameFingerprints, total_hits = hits,
        checks = checks, renewals = renewals, fingerprint = fingerprint,
        different_frames = differentFrames, move_ms = moveMs, collision_ms = collisionMs,
        p50 = percentile(times, 0.50), p95 = percentile(times, 0.95), max = times[#times],
        peak_delta = peakMemory - startingMemory, gc_after_delta = retainedMemory - startingMemory,
    }
end

local variants = {
    { name = "linear/fresh" },
    { name = "grid/fresh", grid = true, parity = true },
    { name = "grid/pool", grid = true, reuse = true, parity = true },
    { name = "grid/stagger", grid = true, reuse = true, stagger = true },
    { name = "grid/move30", grid = true, reuse = true, slow_enemies = true },
}

print(("%s seed=%d frames=%d sim=%.2fs tick=60Hz cell=%d"):format(_VERSION, seed, frames, frames / 60, CELL))
print("Times are CPU ms per frame; memory is KiB above post-setup GC.")
for _, size in ipairs({ 100, 300, 600 }) do
    local baseline
    print(("\n%d entities: %d enemies + %d shots + %d pickups"):format(size, size * 0.6, size * 0.25, size * 0.15))
    for _, variant in ipairs(variants) do
        local layout = measure(size, variant, baseline)
        baseline = baseline or layout
        if variant.parity then
            assert(layout.different_frames == 0 and layout.fingerprint == baseline.fingerprint, variant.name .. " changed collision results")
        end
        print(("%-13s p50=%6.3f p95=%6.3f max=%6.3f move=%6.3f collision=%6.3f"
            .. " mem_peak=%6.1f mem_gc=%6.1f candidates=%8d hits=%6d delta=%+6d"
            .. " differing=%3d renew=%5d new=%5d fingerprint=%010d"):format(
            variant.name, layout.p50, layout.p95, layout.max, layout.move_ms / frames,
            layout.collision_ms / frames, layout.peak_delta, layout.gc_after_delta,
            layout.checks, layout.total_hits, layout.total_hits - baseline.total_hits,
            layout.different_frames, layout.renewals, variant.reuse and 0 or layout.renewals,
            layout.fingerprint
        ))
    end
end
