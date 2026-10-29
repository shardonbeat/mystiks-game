extends Resource
class_name FishType

@export var fish_name: String
@export_range(0, 10000, 1) var base_price: int
@export var tint: Color

@export var allowed_areas: Array[String]
@export var requires_rain: bool = false

@export_range(0.2, 3.0, 0.05) var bite_time_avg: float = 1.3
@export_range(0.1, 2.0, 0.05) var bite_time_variance: float = 0.5
@export_range(0.0, 1.0, 0.01) var treasure_chance: float = 0.15

@export_range(0.0, 1.0, 0.01) var difficulty: float = 0.45

enum MovePattern { SMOOTH, DARTY, SINK_RISE, CHAOTIC }
@export var pattern: MovePattern = MovePattern.SMOOTH

@export var is_legendary = false
