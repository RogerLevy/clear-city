extends Node

## Global enemy class definitions
## Usage: enemies.get_stats("enemy7__pentagon") returns { hp=10, atk=20, bounty=50 }

var active_stats: EnemyStatsSet  ## Set by Stage node on scene load

var _data := {
    "enemy7__pentagon": { hp = 1, atk = 30, bounty = 10 },
    "enemy4__quadraton": { hp = 1, atk = 30, bounty = 30 },
    "enemy2__elderbeak": { hp = 2, atk = 30, bounty = 30 },
    "enemy_angel": { hp = 10, atk = 100, bounty = 50 },
    #"enemy_billy": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_blyxalon": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_bryson": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_ding_dong": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_dolly": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_doris": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_ganglion": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_gumpus": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_helmaton": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_jollyboy": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_jug_jug": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_kuta": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_nyxalon": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_ogulus": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_saton": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_shmoundabout": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_shrim": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_spintor": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_stanex": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_tanjer": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_viper": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_waffil": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_zdo": { hp = 10, atk = 10, bounty = 10 },
    #"enemy_zib_zob": { hp = 10, atk = 10, bounty = 10 },
}

## Default stats for enemies not in the dictionary
var _default := { hp = 10, atk = 10, bounty = 10 }

func get_stats(enemy_class: String) -> Dictionary:
    if active_stats and active_stats.stats.has(enemy_class):
        return active_stats.stats[enemy_class]
    return _data.get(enemy_class, _default)

func get_hp(enemy_class: String) -> int:
    return get_stats(enemy_class).hp

func get_atk(enemy_class: String) -> int:
    return get_stats(enemy_class).atk

func get_bounty(enemy_class: String) -> int:
    return get_stats(enemy_class).bounty
