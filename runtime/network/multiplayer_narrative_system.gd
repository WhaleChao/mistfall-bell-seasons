class_name PixelRPGMultiplayerNarrativeSystem
extends RefCounted

const FARM_MODES := ["shared", "private", "competitive"]
const RELATIONSHIP_MODES := ["independent", "competitive"]
const ROMANCE_CANDIDATES := ["mira", "lian", "soren", "yuna"]


static func story_variant(player_count: int, farm_mode: String, relationship_mode: String) -> Dictionary:
	var count := maxi(1, player_count)
	var base: Dictionary
	if count == 1:
		base = {"id":"solo_bell", "title":"獨鐘守望", "intro":"一名旅人獨自聽見霧中的鐘聲。", "objective":"依自己的步調重建農場與四季封印。"}
	elif count == 2:
		base = {"id":"twin_bell_pact", "title":"雙鐘盟約", "intro":"兩名旅人的鐘聲彼此回應，新的選擇也開始分岔。", "objective":"決定共享收成，或以兩座農場證明各自的道路。"}
	elif count <= 4:
		base = {"id":"four_season_chorus", "title":"四季合奏", "intro":"眾人的腳步喚醒四枚封印，村民開始把委託交給整個隊伍。", "objective":"分工照料四季產業，並處理友情、競爭與承諾。"}
	else:
		base = {"id":"mistfall_council", "title":"霧落拓荒議會", "intro":"五名以上旅人讓聚落成為新的拓荒地，資源與人心都需要制度。", "objective":"以議會式共同目標維持聚落，並在排行榜與共享建設間取得平衡。"}
	base["player_count"] = count
	base["farm_branch"] = {
		"shared":"所有玩家共用農地、倉庫與經濟；劇情強調分工與共同承諾。",
		"private":"每名玩家有獨立農場與經濟；劇情會比較不同生活選擇，但不排名。",
		"competitive":"每名玩家有獨立農場與季節積分；劇情加入評鑑、領先與逆轉事件。",
	}.get(farm_mode, "共同農場")
	base["relationship_branch"] = "戀愛候選人的追求者會互相成為情敵；平手時需等待下一次村莊事件決勝。" if relationship_mode == "competitive" and count > 1 else "每名玩家的友情、戀愛與家庭線彼此獨立，不會搶走別人的伴侶。"
	return base


static func farm_leaderboard(player_worlds: Dictionary, player_names: Dictionary) -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for player_key: String in player_worlds:
		var context: Dictionary = player_worlds[player_key]
		var farm: Dictionary = context.get("farm", {})
		var economy: Dictionary = context.get("economy", {})
		var stats: Dictionary = context.get("lifetime_stats", {})
		var score := int(economy.get("total_earned", 0)) + int(stats.get("crops_harvested", 0)) * 25 + int(farm.get("rank", 1)) * 500 + Dictionary(farm.get("plots", {})).size() * 10
		board.append({"player_key":player_key, "name":String(player_names.get(player_key, "旅人")), "score":score, "farm_rank":int(farm.get("rank", 1)), "crops":int(stats.get("crops_harvested", 0))})
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.score) == int(b.score):
			return String(a.name) < String(b.name)
		return int(a.score) > int(b.score)
	)
	for index in range(board.size()):
		board[index]["rank"] = index + 1
	return board


static func romance_board(player_worlds: Dictionary, player_names: Dictionary, npc_id: String) -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for player_key: String in player_worlds:
		var context: Dictionary = player_worlds[player_key]
		var relationship: Dictionary = Dictionary(context.get("relationships", {})).get(npc_id, {})
		var points := int(relationship.get("friendship", 0))
		if points <= 0 and not bool(relationship.get("dating", false)):
			continue
		board.append({"player_key":player_key, "name":String(player_names.get(player_key, "旅人")), "points":points, "hearts":clampi(points / 250, 0, 10), "dating":bool(relationship.get("dating", false))})
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.points) == int(b.points):
			return String(a.name) < String(b.name)
		return int(a.points) > int(b.points)
	)
	for index in range(board.size()):
		board[index]["rank"] = index + 1
		board[index]["tied_for_lead"] = board.size() > 1 and int(board[index].points) == int(board[0].points)
	return board


static func proposal_verdict(player_key: String, npc_id: String, player_worlds: Dictionary, claims: Dictionary, competitive: bool) -> Dictionary:
	if npc_id not in ROMANCE_CANDIDATES:
		return {"ok":false, "message":"這名角色不是戀愛候選人"}
	var context: Dictionary = player_worlds.get(player_key, {})
	var relationship: Dictionary = Dictionary(context.get("relationships", {})).get(npc_id, {})
	if int(relationship.get("friendship", 0)) < 2500 or not bool(relationship.get("dating", false)):
		return {"ok":false, "message":"求婚需要 10 心且已經交往"}
	if not competitive:
		return {"ok":true, "message":"鐘聲見證了你們的婚禮"}
	var claimed_by := String(claims.get(npc_id, ""))
	if not claimed_by.is_empty() and claimed_by != player_key:
		return {"ok":false, "message":"這名角色已與另一位玩家締結婚約"}
	var board := romance_board(player_worlds, {}, npc_id)
	if board.is_empty() or String(board[0].player_key) != player_key:
		return {"ok":false, "message":"競爭追求中，你必須先成為最高好感的追求者"}
	if board.size() > 1 and int(board[0].points) == int(board[1].points):
		return {"ok":false, "message":"追求者好感平手；下一場村莊競賽事件將決定優先求婚權"}
	return {"ok":true, "message":"你在追求競爭中領先，鐘聲接受了這份婚約"}
