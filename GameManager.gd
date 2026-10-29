extends Node

enum IslandNation { FLUCTANTIA, TROPICANTIA, INSECANTIA, CAELUMANTIA, ANIMANTIA }

var coal: int = 100
var energy: int = 100
var money: int = 100
var food: int = 50

var is_on_boat: bool = true
var is_on_route: bool = false

var equipped_mystik: Dictionary = {
	"name": "Mystik Pez",
	"nation": IslandNation.FLUCTANTIA,
	"uses_left": 3,
	"max_uses": 3
}

signal resources_changed

func modify_resources(c: int, e: int, m: int, f: int):
	coal = max(0, coal + c)
	energy = max(0, energy + e)
	money = max(0, money + m)
	food = max(0, food + f)
	emit_signal("resources_changed")
