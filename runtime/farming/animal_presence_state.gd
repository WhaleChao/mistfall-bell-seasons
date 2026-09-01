class_name PixelRPGAnimalPresenceState
extends Resource

@export var animal_id: StringName
@export var scene_id: StringName = &"mistfall_barn"
@export var stall_index := 0
@export var fed := false
@export var petted := false
@export var product_ready := false


static func scene_for(weather: String, minute_of_day: int) -> StringName:
	var outdoor_weather := weather not in ["rain", "storm", "typhoon", "snow", "blizzard"]
	return &"mistfall_farm" if outdoor_weather and minute_of_day >= 8 * 60 and minute_of_day < 18 * 60 else &"mistfall_barn"
