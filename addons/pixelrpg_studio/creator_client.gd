@tool
class_name PixelRPGCreatorClient
extends Node

signal status_changed(message: String, connected: bool)
signal event_received(event: Dictionary)

const DEFAULT_URL := "ws://127.0.0.1:8765/api/v1/assist/stream"

var socket := WebSocketPeer.new()
var was_open := false


func connect_service() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return
	socket = WebSocketPeer.new()
	var token := OS.get_environment("PIXELRPG_SESSION_TOKEN")
	if token.is_empty():
		status_changed.emit("缺少 PIXELRPG_SESSION_TOKEN；請用啟動器開啟 Studio。", false)
		return
	var error := socket.connect_to_url("%s?token=%s" % [DEFAULT_URL, token.uri_encode()])
	if error != OK:
		status_changed.emit("無法連接 Creator Service：%s" % error_string(error), false)
		return
	set_process(true)
	status_changed.emit("正在連接本機 Creator Service…", false)


func disconnect_service() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close(1000, "Studio closed")
	was_open = false
	status_changed.emit("Creator Service 已中斷", false)


func request_assist(payload: Dictionary) -> bool:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		status_changed.emit("Creator Service 尚未連線", false)
		return false
	var error := socket.send_text(JSON.stringify(payload))
	if error != OK:
		status_changed.emit("無法送出要求：%s" % error_string(error), false)
		return false
	return true


func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not was_open:
		was_open = true
		status_changed.emit("Creator Service 已連線（localhost）", true)
	while socket.get_available_packet_count() > 0:
		var text := socket.get_packet().get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			event_received.emit(parsed)
	if state == WebSocketPeer.STATE_CLOSED and was_open:
		was_open = false
		status_changed.emit("Creator Service 連線已關閉（%d）" % socket.get_close_code(), false)
		set_process(false)
