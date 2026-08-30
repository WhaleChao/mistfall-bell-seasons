# PixelRPG Studio／Creator Service 成品驗收摘要

結果：**PASS**　｜　Godot Studio 57/57　｜　真實 AI 24/24　｜　文件 9/9

## 最終封裝

- 檔案：`PixelRPGCreatorService.exe`
- 大小：390,035,505 bytes（371.97 MiB）
- SHA-256：`0C88759088CDD8A9EE899F9CBB2439A3367053F0E9127913D2A632D43CFC46FC`
- 綁定位址：僅 `127.0.0.1`
- 向量後端：sqlite-vec
- Microsoft Defender：新增偵測 0
- Authenticode：未簽章

## 直接執行證據

| 範圍 | 結果 | 證據 |
|---|---:|---|
| Godot EditorPlugin | 57/57 | 15 個製作頁、16 種資料、7 個長期系統編輯器、UndoRedo、節點圖、真實 AI client 與 16 張 UI 截圖 |
| 真實本機 AI | 24/24 | Qwen3.5 4B／9B、Qwen3 Embedding 0.6B、HTTP／WebSocket、RAG、引用、繁中、圖片、取消與安全 token |
| 封裝文件索引 | 9/9 | TXT、Markdown、CSV、HTML、DOCX、PPTX、XLSX、PDF、PNG；強制索引後增量略過 9/9 |
| 離線文件解析 | 9/9 | 新 Python 子程序強制 HF／Transformers 離線，阻擋非 localhost socket，允許外部連線 0 |
| 依賴供應鏈 | PASS | 138 個依賴、0 個已知漏洞；本專案套件因不在 PyPI 而由原始碼測試覆蓋 |

詳細機器可讀與畫面證據：

- `reports/studio_ui/report.json`、`reports/studio_ui/REPORT.md`
- `reports/real_ai_packaged/report.json`、`reports/real_ai_packaged/REPORT.md`
- `reports/packaged_documents/report.json`、`reports/packaged_documents/REPORT.md`
- `reports/document_formats/report.json`、`reports/document_formats/REPORT.md`
- `reports/dependency_audit.json`、`reports/DEPENDENCY_AUDIT.md`

## 尚需發行者完成

目前沒有受公眾信任的 Windows 程式碼簽章憑證，因此 EXE 仍為 `NotSigned`；另需用實體 XInput 手把做端到端驗收，並由權利人完成法律、商標、商店帳號、分級與稅務程序。這些外部項目不能由自動化測試代替。
