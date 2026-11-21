local Run = {}

function Run.new(seed)
    if seed == nil then
        seed = 1
    end
    assert(
        type(seed) == "number" and seed >= 1 and seed <= 2147483646 and seed % 1 == 0,
        "run seed must be an integer from 1 to 2147483646"
    )
    return { seed = seed, tick = 0 }
end

return Run
