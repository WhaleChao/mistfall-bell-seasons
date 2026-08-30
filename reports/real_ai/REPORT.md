# PixelRPG 真實本機 AI 驗收

結果：**PASS**　｜　24 通過／0 失敗

本測試不使用 `PIXELRPG_MOCK_AI`；Creator Service 綁定 127.0.0.1，透過真實 Ollama、HTTP 與 WebSocket 驗證模型、索引、RAG、結構化草稿、圖片理解及取消。

| 分類 | 項目 | 結果 | 細節 |
|---|---|---:|---|
| 安全 | 缺少工作階段 token 會被拒絕 | 通過 | 401 |
| 服務 | Creator Service 健康檢查 | 通過 | {'service': 'ok', 'project_root': '<isolated-project-root>', 'ollama': True, 'gpu': 'Q8_0', 'index_chunks': 0, 'models': ['qwen3.5:9b', 'qwen3-embedding:0.6b', 'qwen3.5:4b', 'mistral-nemo:12b'], 'warnings': []} |
| 服務 | Ollama 可用且無警告 | 通過 | [] |
| 模型 | 4B 與 9B 模式均可用 | 通過 | {'modes': [{'id': 'quality', 'model': 'qwen3.5:9b', 'vram_estimate_gb': 8.5, 'available': True, 'digest': '6488c96fa5faab64bb65cbd30d4289e20e6130ef535a93ef9a49f42eda893ea7'}, {'id': 'fast', 'model': 'qwen3.5:4b', 'vram_estimate_gb': 5.0, 'available': True, 'digest': '2a654d98e6fba55d452b7043684e9b57a947e393bbffa62485a7aac05ee4eefd'}], 'embedding': {'model': 'qwen3-embedding:0.6b', 'available': True, 'digest': 'ac6da0dfba84a81fdbfbaf330198c33cd77c4cdfc53e8bc50eb581914a15621d'}} |
| 模型 | Qwen3 Embedding 可用 | 通過 | {'model': 'qwen3-embedding:0.6b', 'available': True, 'digest': 'ac6da0dfba84a81fdbfbaf330198c33cd77c4cdfc53e8bc50eb581914a15621d'} |
| 效能 | fast 冷啟動首 token ≤ 30s | 通過 | {'model': 'qwen3.5:4b', 'first_token_seconds': 6.609, 'elapsed_seconds': 7.669, 'eval_count': 71, 'tokens_per_second': 67.16, 'load_seconds': 6.466, 'response_characters': 74} |
| 效能 | fast 暖機首 token ≤ 5s | 通過 | {'model': 'qwen3.5:4b', 'first_token_seconds': 0.122, 'elapsed_seconds': 1.176, 'eval_count': 71, 'tokens_per_second': 67.47, 'load_seconds': 0.019, 'response_characters': 74} |
| 效能 | fast 暖機持續生成 ≥ 8 tokens/s | 通過 | {'model': 'qwen3.5:4b', 'first_token_seconds': 0.122, 'elapsed_seconds': 1.176, 'eval_count': 71, 'tokens_per_second': 67.47, 'load_seconds': 0.019, 'response_characters': 74} |
| 效能 | quality 冷啟動首 token ≤ 30s | 通過 | {'model': 'qwen3.5:9b', 'first_token_seconds': 7.625, 'elapsed_seconds': 8.813, 'eval_count': 54, 'tokens_per_second': 45.51, 'load_seconds': 7.466, 'response_characters': 59} |
| 效能 | quality 暖機首 token ≤ 10s | 通過 | {'model': 'qwen3.5:9b', 'first_token_seconds': 0.113, 'elapsed_seconds': 1.307, 'eval_count': 54, 'tokens_per_second': 45.32, 'load_seconds': 0.002, 'response_characters': 59} |
| 效能 | quality 暖機持續生成 ≥ 8 tokens/s | 通過 | {'model': 'qwen3.5:9b', 'first_token_seconds': 0.113, 'elapsed_seconds': 1.307, 'eval_count': 54, 'tokens_per_second': 45.32, 'load_seconds': 0.002, 'response_characters': 59} |
| 索引 | 真實 embedding 建立文件索引 | 通過 | {'indexed_files': 1, 'unchanged_files': 0, 'chunks': 1, 'warnings': [], 'vector_backend': 'sqlite-vec'} |
| 索引 | 文件索引沒有降級警告 | 通過 | [] |
| 索引 | 相同雜湊採增量略過 | 通過 | {'indexed_files': 0, 'unchanged_files': 1, 'chunks': 0, 'warnings': [], 'vector_backend': 'sqlite-vec'} |
| 驗證 | 無效草稿只回報錯誤 | 通過 | {'valid': False, 'errors': ["$: 'display_name' is a required property", "$: 'category' is a required property", "$: 'description' is a required property", "$: 'stack_limit' is a required property", "$: 'effects' is a required property", "id: 'Bad ID' does not match '^[a-z][a-z0-9_]*$'"], 'warnings': []} |
| 生成 | 4B WebSocket 串流產生合法 DialogueGraph | 通過 | {'done': True, 'draft_valid': True, 'source_count': 1, 'first_token_seconds': 8.467, 'event_types': ['done', 'draft', 'source', 'token', 'warning'], 'warnings': 1, 'errors': [], 'draft_text': '{"schema_version": 1, "id": "mira_warden_request_draft", "title": "米拉與守望者的對話草稿", "start_node": "node_0", "characters": ["hero", "mira"], "nodes": [{"id": "node_0", "type": "line", "speaker": "mira", "text": "晨鐘停了，霧氣又濃了。守望者佔據了鐘塔，它說要保存那些互相矛盾的承諾。", "next": "node_1"}, {"id": "node_1", "type": "line", "speaker" |
| RAG | 草稿先回傳引用來源 | 通過 | 1 |
| 生成 | 草稿包含繁體中文內容 | 通過 |  |
| 生成 | 9B WebSocket 串流完成世界觀問答 | 通過 | {'done': True, 'draft_valid': True, 'source_count': 1, 'first_token_seconds': 13.27, 'event_types': ['done', 'draft', 'source', 'token'], 'warnings': 0, 'errors': [], 'draft_text': '{"answer": "米拉是霧落村的守鐘人，負責維持鐘塔運作。當遺跡守望者甦醒並佔據鐘塔時，米拉無法離開村莊，只能請求拾光者進入遺跡處理狀況。", "citations": ["d09f54642c5681daff93"]}', 'stream_characters': 127} |
| RAG | 品質模式保留來源引用 | 通過 | 1 |
| 圖片 | 4B 真實圖片理解回傳結構化草稿 | 通過 | {'valid': True, 'draft': {'description': '這是一張像素風格的俯視圖，展示了一個寧靜的農場場景。\n\n**建築：**\n- 左上角有一座帶有紫色瓦片屋頂的石砌房屋，屋頂上有一個冒著煙的煙囪。房屋旁邊有木製柵欄、水桶和一個裝滿石頭或木材的箱子。\n- 右上角是一座較大的木製倉庫或穀倉，同樣擁有紫色的瓦片屋頂，前方有一扇雙開門。\n\n**農場：**\n- 畫面中央是一個整齊劃一的農田，由六行六列共三十六塊深褐色的土地組成，目前看起來是空曠的田地。\n\n**池塘：**\n- 左下角有一個藍色的池塘，水面漂浮著幾片睡蓮葉。池塘邊緣有木製柵欄圍繞，旁邊還有一棵開著粉紅色花的樹和一張小木桌。\n\n**洞窟入口：**\n- 右下角是一個由灰色岩石堆砌而成的拱形洞穴入口，內部漆黑一片。\n\n整體環境充滿綠意，佈滿花草與樹木，並有土路蜿蜒穿過。', 'tags': ['像素風', '農場', '石屋', '木屋', '空曠農田', '池塘', '洞穴入口']}, 'confirmed': False} |
| 圖片 | 圖片描述預設不自動確認 | 通過 | False |
| 圖片 | 人工確認後才寫入圖片描述索引 | 通過 | {'confirmed': True, 'path': 'assets/runtime/backgrounds/mistfall_farm_commercial.png', 'indexed_chunks': 1} |
| 串流 | WebSocket 生成可取消 | 通過 | True |

## 效能數據

```json
{
  "models": {
    "modes": [
      {
        "id": "quality",
        "model": "qwen3.5:9b",
        "vram_estimate_gb": 8.5,
        "available": true,
        "digest": "6488c96fa5faab64bb65cbd30d4289e20e6130ef535a93ef9a49f42eda893ea7"
      },
      {
        "id": "fast",
        "model": "qwen3.5:4b",
        "vram_estimate_gb": 5.0,
        "available": true,
        "digest": "2a654d98e6fba55d452b7043684e9b57a947e393bbffa62485a7aac05ee4eefd"
      }
    ],
    "embedding": {
      "model": "qwen3-embedding:0.6b",
      "available": true,
      "digest": "ac6da0dfba84a81fdbfbaf330198c33cd77c4cdfc53e8bc50eb581914a15621d"
    }
  },
  "fast_cold": {
    "model": "qwen3.5:4b",
    "first_token_seconds": 6.609,
    "elapsed_seconds": 7.669,
    "eval_count": 71,
    "tokens_per_second": 67.16,
    "load_seconds": 6.466,
    "response_characters": 74
  },
  "fast_warm": {
    "model": "qwen3.5:4b",
    "first_token_seconds": 0.122,
    "elapsed_seconds": 1.176,
    "eval_count": 71,
    "tokens_per_second": 67.47,
    "load_seconds": 0.019,
    "response_characters": 74
  },
  "quality_cold": {
    "model": "qwen3.5:9b",
    "first_token_seconds": 7.625,
    "elapsed_seconds": 8.813,
    "eval_count": 54,
    "tokens_per_second": 45.51,
    "load_seconds": 7.466,
    "response_characters": 59
  },
  "quality_warm": {
    "model": "qwen3.5:9b",
    "first_token_seconds": 0.113,
    "elapsed_seconds": 1.307,
    "eval_count": 54,
    "tokens_per_second": 45.32,
    "load_seconds": 0.002,
    "response_characters": 59
  },
  "fast_assist": {
    "done": true,
    "draft_valid": true,
    "source_count": 1,
    "first_token_seconds": 8.467,
    "event_types": [
      "done",
      "draft",
      "source",
      "token",
      "warning"
    ],
    "warnings": 1,
    "errors": [],
    "draft_text": "{\"schema_version\": 1, \"id\": \"mira_warden_request_draft\", \"title\": \"米拉與守望者的對話草稿\", \"start_node\": \"node_0\", \"characters\": [\"hero\", \"mira\"], \"nodes\": [{\"id\": \"node_0\", \"type\": \"line\", \"speaker\": \"mira\", \"text\": \"晨鐘停了，霧氣又濃了。守望者佔據了鐘塔，它說要保存那些互相矛盾的承諾。\", \"next\": \"node_1\"}, {\"id\": \"node_1\", \"type\": \"line\", \"speaker\": \"hero\", \"text\": \"我們能進去嗎？魔霧已經凝成史萊姆了。\", \"next\": \"node_2\"}, {\"id\": \"node_2\", \"type\": \"choice\", \"speaker\": \"mira\", \"text\": \"或許吧，但你要小心，它不是為了傷害我們。\", \"options\": [{\"text\": \"我想試試看。\", \"next\": \"node_3\"}, {\"text\": \"我們先退後一步觀察。\", \"next\": \"node_4\"}]}, {\"id\": \"node_3\", \"type\": \"line\", \"speaker\": \"mira\", \"text\": \"好，跟緊我。記住，不要說任何新的承諾，除非你確定它能被兌現。\", \"next\": \"node_5\"}, {\"id\": \"node_4\", \"type\": \"line\", \"speaker\": \"mira\", \"text\": \"觀察是明智的，但時間不多了。霧晶正在凝結，它們會放大我們遺忘的聲音。\", \"next\": \"node_5\"}, {\"id\": \"node_5\", \"type\": \"end\", \"speaker\": \"mira\", \"text\": \"無論你選擇什麼，守望者都在等待承諾的真相。\"}]}",
    "stream_characters": 2346
  },
  "quality_assist": {
    "done": true,
    "draft_valid": true,
    "source_count": 1,
    "first_token_seconds": 13.27,
    "event_types": [
      "done",
      "draft",
      "source",
      "token"
    ],
    "warnings": 0,
    "errors": [],
    "draft_text": "{\"answer\": \"米拉是霧落村的守鐘人，負責維持鐘塔運作。當遺跡守望者甦醒並佔據鐘塔時，米拉無法離開村莊，只能請求拾光者進入遺跡處理狀況。\", \"citations\": [\"d09f54642c5681daff93\"]}",
    "stream_characters": 127
  },
  "image_description": {
    "valid": true,
    "draft": {
      "description": "這是一張像素風格的俯視圖，展示了一個寧靜的農場場景。\n\n**建築：**\n- 左上角有一座帶有紫色瓦片屋頂的石砌房屋，屋頂上有一個冒著煙的煙囪。房屋旁邊有木製柵欄、水桶和一個裝滿石頭或木材的箱子。\n- 右上角是一座較大的木製倉庫或穀倉，同樣擁有紫色的瓦片屋頂，前方有一扇雙開門。\n\n**農場：**\n- 畫面中央是一個整齊劃一的農田，由六行六列共三十六塊深褐色的土地組成，目前看起來是空曠的田地。\n\n**池塘：**\n- 左下角有一個藍色的池塘，水面漂浮著幾片睡蓮葉。池塘邊緣有木製柵欄圍繞，旁邊還有一棵開著粉紅色花的樹和一張小木桌。\n\n**洞窟入口：**\n- 右下角是一個由灰色岩石堆砌而成的拱形洞穴入口，內部漆黑一片。\n\n整體環境充滿綠意，佈滿花草與樹木，並有土路蜿蜒穿過。",
      "tags": [
        "像素風",
        "農場",
        "石屋",
        "木屋",
        "空曠農田",
        "池塘",
        "洞穴入口"
      ]
    },
    "confirmed": false
  }
}
```
