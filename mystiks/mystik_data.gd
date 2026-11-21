class_name MystikData
extends Resource

enum AbilityType {
	CURRENT_SURGE,
	WIND_SHIELD
}

@export var id: String = ""
@export var mystik_name: String = "Mystik"
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var nation: GameManager.IslandNation = GameManager.IslandNation.FLUCTANTIA 

@export_group("Habilidad Activa")
@export var ability_type: AbilityType = AbilityType.CURRENT_SURGE
@export var ability_name: String = ""
@export var max_uses: int = 3
@export var cooldown_seconds: float = 12.0
@export var power_value: float = 10.0

func get_ability_name() -> String:
	if not ability_name.is_empty():
		return ability_name
		
	match ability_type:
		AbilityType.CURRENT_SURGE:
			return "Impulso de Corriente"
		AbilityType.WIND_SHIELD:
			return "Escudo de Viento"
			
	return "Sin habilidad"
