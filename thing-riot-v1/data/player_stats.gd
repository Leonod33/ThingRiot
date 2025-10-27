# player_stats.gd
class_name PlayerStats
extends Resource

# --- Core stats ---
@export var max_health: int = 6
@export var speed: float = 260.0
@export var attack_power: int = 1
@export var attack_speed: float = 1.0  # seconds between attacks
@export var projectile_count: int = 1
@export var projectile_range: float = 300.0
@export var projectile_size: float = 1.0
@export var knockback_power: float = 140.0

# --- Secondary stats ---
@export_range(0.0, 1.0, 0.01) var defense: float = 0.0
@export var luck: float = 0.0
@export var xp_multiplier: float = 1.0
@export var crown_size_mult: float = 1.0

# Returns true if a property exists on this Resource
func _has_stat(name: String) -> bool:
	for p in get_property_list():
		if p.name == name:
			return true
	return false

func apply_crown_size_percent(percent: float) -> void:
	# percent = 0.20 for +20%
	crown_size_mult *= (1.0 + percent)

# Convenience: add flat or percentage to a stat by name
func modify(stat_name: String, delta: float, is_percent: bool = false) -> void:
	if not _has_stat(stat_name):
		push_warning("Stat '%s' does not exist on PlayerStats" % stat_name)
		return
	var current = get(stat_name)
	if is_percent:
		current += current * delta
	else:
		current += delta
	set(stat_name, current)
