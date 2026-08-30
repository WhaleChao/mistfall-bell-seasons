class_name PixelRPGCalendarSystem
extends RefCounted

signal time_changed(year: int, season: StringName, day: int, minute_of_day: int)
signal day_finished

const DAYS_PER_SEASON := 30
const SEASONS_PER_YEAR := 4
const DAYS_PER_YEAR := DAYS_PER_SEASON * SEASONS_PER_YEAR
const DAY_START_MINUTE := 6 * 60
const DAY_END_MINUTE := 24 * 60
const PLAYABLE_MINUTES := DAY_END_MINUTE - DAY_START_MINUTE
const SEASON_IDS: Array[StringName] = [&"spring", &"summer", &"autumn", &"winter"]
const SEASON_NAMES := {"spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬"}
const SPEED_SECONDS := {"fast": 600.0, "standard": 900.0, "relaxed": 1200.0}

var year := 1
var season_index := 0
var day := 1
var minute_of_day := DAY_START_MINUTE
var speed_mode := "standard"
var paused := false
var _minute_fraction := 0.0


func reset() -> void:
	year = 1
	season_index = 0
	day = 1
	minute_of_day = DAY_START_MINUTE
	speed_mode = "standard"
	paused = false
	_minute_fraction = 0.0


func process(delta: float) -> bool:
	if paused or minute_of_day >= DAY_END_MINUTE:
		return false
	var day_seconds := float(SPEED_SECONDS.get(speed_mode, SPEED_SECONDS.standard))
	_minute_fraction += delta * float(PLAYABLE_MINUTES) / day_seconds
	var whole_minutes := floori(_minute_fraction)
	if whole_minutes <= 0:
		return false
	_minute_fraction -= whole_minutes
	minute_of_day = mini(DAY_END_MINUTE, minute_of_day + whole_minutes)
	time_changed.emit(year, season_id(), day, minute_of_day)
	if minute_of_day >= DAY_END_MINUTE:
		day_finished.emit()
		return true
	return false


func advance_day() -> Dictionary:
	var previous := date_snapshot()
	minute_of_day = DAY_START_MINUTE
	_minute_fraction = 0.0
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season_index += 1
		if season_index >= SEASONS_PER_YEAR:
			season_index = 0
			year += 1
	time_changed.emit(year, season_id(), day, minute_of_day)
	return {"previous": previous, "current": date_snapshot()}


func set_speed(mode: String) -> bool:
	if not SPEED_SECONDS.has(mode):
		return false
	speed_mode = mode
	return true


func cycle_speed() -> String:
	var modes := ["fast", "standard", "relaxed"]
	var current := modes.find(speed_mode)
	speed_mode = modes[(current + 1) % modes.size()]
	return speed_mode


func season_id() -> StringName:
	return SEASON_IDS[clampi(season_index, 0, SEASON_IDS.size() - 1)]


func season_name() -> String:
	return String(SEASON_NAMES.get(String(season_id()), "?"))


func absolute_day() -> int:
	return (year - 1) * DAYS_PER_YEAR + season_index * DAYS_PER_SEASON + day


func time_text() -> String:
	return "%02d:%02d" % [minute_of_day / 60, minute_of_day % 60]


func date_text() -> String:
	return "第 %d 年 %s季 %d 日" % [year, season_name(), day]


func date_snapshot() -> Dictionary:
	return {
		"year": year,
		"season_index": season_index,
		"season": String(season_id()),
		"day": day,
		"minute_of_day": minute_of_day,
		"speed_mode": speed_mode,
	}


func load_data(data: Dictionary) -> void:
	year = maxi(1, int(data.get("year", 1)))
	season_index = clampi(int(data.get("season_index", 0)), 0, SEASONS_PER_YEAR - 1)
	day = clampi(int(data.get("day", 1)), 1, DAYS_PER_SEASON)
	minute_of_day = clampi(int(data.get("minute_of_day", DAY_START_MINUTE)), DAY_START_MINUTE, DAY_END_MINUTE)
	set_speed(String(data.get("speed_mode", "standard")))
	_minute_fraction = 0.0


static func absolute_day_for(target_year: int, target_season_index: int, target_day: int) -> int:
	return (maxi(1, target_year) - 1) * DAYS_PER_YEAR + clampi(target_season_index, 0, 3) * DAYS_PER_SEASON + clampi(target_day, 1, DAYS_PER_SEASON)


static func weather_for(target_year: int, target_season_index: int, target_day: int) -> String:
	var value := posmod(target_year * 7919 + target_season_index * 1543 + target_day * 313, 100)
	match clampi(target_season_index, 0, 3):
		0:
			return "clear" if value < 45 else "rain" if value < 82 else "storm" if value < 92 else "fog"
		1:
			return "clear" if value < 60 else "rain" if value < 84 else "typhoon" if value < 94 else "fog"
		2:
			return "clear" if value < 50 else "rain" if value < 75 else "fog" if value < 94 else "storm"
		_:
			return "clear" if value < 35 else "snow" if value < 80 else "blizzard" if value < 90 else "fog"


static func tomorrow_date(target_year: int, target_season_index: int, target_day: int) -> Dictionary:
	var next_year := target_year
	var next_season := target_season_index
	var next_day := target_day + 1
	if next_day > DAYS_PER_SEASON:
		next_day = 1
		next_season += 1
		if next_season >= SEASONS_PER_YEAR:
			next_season = 0
			next_year += 1
	return {"year": next_year, "season_index": next_season, "day": next_day}


static func forecast_for_tomorrow(target_year: int, target_season_index: int, target_day: int) -> Dictionary:
	var next := tomorrow_date(target_year, target_season_index, target_day)
	var forecast := weather_for(next.year, next.season_index, next.day)
	return {
		"date": next,
		"weather": forecast,
		"warning": forecast in ["typhoon", "blizzard"],
	}
