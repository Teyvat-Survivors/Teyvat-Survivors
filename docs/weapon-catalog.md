# 基础武器玩法对应

历史名称用于查找 2022 年 10 月 20 日的发售证据。对应项采用项目原创技能、范围、升级和节奏。多种历史反弹条目共用已验证的行为配置。 [历史条目索引](v1.0-item-index.md#武器与奖励)

| 历史条目 | 项目配置 | 已实现玩法 |
| --- | --- | --- |
| Whip | `mist_cut` | 近距离定向斩击，命中后击退 |
| Magic Wand | `wind_blade` | 对最近目标发射，带穿透额度 |
| Knife | `ridge_dart` | 根据玩家当前朝向发射 |
| Axe | `stone_lob` | 抛物线路径，落地结算 |
| Cross | `willow_return` | 直发后追踪玩家回旋，共用命中记录 |
| King Bible | `jade_satellite` | 围绕玩家旋转的周期伤害 |
| Fire Wand | `star_spark` | 按固定种子选择有效目标发射 |
| Garlic | `dew_aura` | 随玩家移动的贴身范围脉冲 |
| Santa Water | `ember_field` | 目标位置生成持续领域 |
| Runetracer | `echo_shard` | 每段扫掠、墙面反射和穿透 |
| Lightning Ring | `sky_needle` | 随机有效目标，蓄时后打击原位置 |
| Pentagram | `horizon_shatter` | 清除场内普通单位，精英扣血，结局敌人免疫，常规掉落 |
| Peachone | `cloud_scout` | 自主巡航体按种子选起始方向 |
| Ebony Wings | `moon_tide` | 与常规卫星错位，延迟高伤脉冲 |
| Phiera Der Tuphello | `prism_cross` | 按朝向布置全周独立弹道 |
| Eight The Sparrow | `willow_twins` | 向身后分角双发，附击退 |
| Gatti Amari | `cloud_scout` | 自主移动、方向切换和间歇命中 |
| Song of Mana | `storm_lane` | 长而窄的定向范围 |
| Shadow Pinion | `trail_mine` | 移动蓄势，停下后在身后布置延迟打击 |
| Clock Lancet | `stillwater_seal` | 短时控制与防连续锁定 |
| Laurel | `stone_ward` | 定期补充限时护盾 |
| Vento Sacro | `step_quake` | 按移动距离触发贴身打击 |
| Bone | `pebble_chain` | 接触后改变方向，继续寻找最近的未命中目标 |
| Cherry Bomb | `blossom_bomb` | 抛投落地后按种子判定溅射 |
| Carréllo | `echo_shard` | 场地边界反弹 |
| Celestial Dusting | `echo_shard` | 有限反弹伤害 |
| La Robba | `stone_lob`、`echo_shard` | 抛投落地与反弹分属两项配置 |
| Greatest Jubilee | `lantern_fanfare` | 首次通过风径试炼终局后解锁的周期庆典脉冲，可从军械箱取得 |
| Bracelet | `needle_ring` | 随机瞄准后产生贯穿齐射 |
| Candybox | 军械守卫宝箱 | 风径试炼稀有掉落，提供有空槽、未持有且未放逐的基础武器候选 |
| Victory Sword | `last_stand` | 生命处于阈值内时增强近身斩击 |
| Flames of Misspell | `ember_breath` | 锁定施法方向的重复扇形脉冲 |

`lua tests/weapon_catalog.lua` 逐级验证本轮新增配置，包括方向、距离、落点、同帧折转、命中次数、触发时序及真实 Run 升级后的两把武器共存。原型与前几批武器继续由 `tests/run.lua`、`tests/weapons.lua`、`tests/combat.lua`、`tests/projectile_families.lua`、`tests/fields.lua`、`tests/support.lua` 回归。角色、配方、终局解锁与具体千星资源由各自任务验证。

风径试炼的军械守卫使用独立掉落。军械箱最多显示三种新武器和金币选项，确认时会重新检查空槽、持有与放逐。继承存档的新局可把 `Profile.unlocks(profile).weapons` 填入 `Run.new` 或 `Run.for_character` 的 `options.weapon_unlocks`。已解锁的灯华齐鸣优先出现在有空槽的军械箱中。Lua 的普通加权升级不会抽出该武器。 `tests/rewards.lua` 验证出生、击杀、选箱、解锁和重开。
