# Third-party dependency policy

PixelRPG Studio 核心採 MIT License。正式散布允許 MIT、Apache-2.0、BSD、ISC、CC0；GPL 或自訂 EULA 工具只能外部使用，不會與本專案一起打包。

固定相容版本：

| Dependency | Version | License | Bundling |
|---|---:|---|---|
| Godot Engine | 4.7.2 | MIT | 使用者安裝或 portable runtime |
| Dialogue Manager | 4.0.3 | MIT | 選用 adapter dependency |
| QuestSystem | 2.0.2.4_4 | MIT | 選用 adapter dependency |
| GLoot | 3.0.2 | MIT | 選用 adapter dependency |
| Pixelorama | 1.2.1 | MIT | 外部工具，不打包 |
| Ollama | 0.33.2 | MIT | 製作端先決條件，不進入遊戲 |
| Qwen3.5 models | 4B/9B | Apache-2.0 | 使用者下載，不進入遊戲 |
| Qwen3 Embedding | 0.6B | Apache-2.0 | 使用者下載，不進入遊戲 |
| Docling | 2.123.1 | MIT | Creator Service optional extra |
| sqlite-vec | 0.1.9 | MIT | Creator Service optional extra |
| gdUnit4 | 6.2.1 | MIT | 開發／測試用 |

素材自身的授權獨立於程式授權。每個 `AssetRecord` 都必須提供 SPDX 識別碼、自訂授權名稱或 `PROPRIETARY-OWNED`；`UNSPECIFIED` 不得進入正式匯出。

九項原創像素素材於 2026-08-30 使用 OpenAI 內建 imagegen 依本專案原創提示生成：標題主視覺、農場／村莊／洞窟背景、戀愛角色肖像、角色圖集、四方向玩家走路圖集、敵人圖集與動物／產品圖集。每項皆以 `LicenseRef-OpenAI-Generated`、來源、作者標示及實際 SHA-256 登錄於 `data/assets/index.json`；提示明確排除第三方角色、商標、標誌及既有遊戲素材。

Windows 發行檔使用 Godot Engine 4.7.2 MIT 匯出模板。正式 ZIP 會同時附上取自 `4.7.2-stable` 標籤的 `GODOT_ENGINE_LICENSE.txt`，以及列出匯出模板所含第三方元件與個別授權的完整 `GODOT_ENGINE_COPYRIGHT.txt`；兩份原文的 SHA-256 由發行稽核固定驗證。上游來源為 <https://github.com/godotengine/godot/tree/4.7.2-stable>。

Creator Service、Ollama、模型、Docling、sqlite-vec 與測試依賴不包含在遊戲發行包。授權清單是工程合規紀錄，不取代商標、素材權利與商店條款的專業法律審查。
