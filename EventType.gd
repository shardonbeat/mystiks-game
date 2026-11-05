extends Resource
class_name EventType

@export var event_name: String
@export var event_description: String

@export var needed_resources: Dictionary  = {
	"coal": 0,
	"energy": 0,
	"money": 0
}
