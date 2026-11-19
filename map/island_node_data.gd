class_name IslandNodeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var zone_image: Texture2D
@export_multiline var description: String = ""
@export var coal_cost: int = 10
@export var travel_duration: float = 30.0
@export var connected_islands: Array[String] = []

@export var zone_index: int = 1
