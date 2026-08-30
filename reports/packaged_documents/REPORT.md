# PixelRPG 封裝版文件與索引驗收

結果：**PASS**　｜　9 種格式　｜　52 次連線取樣　｜　外部連線 0

| 檢查 | 結果 |
|---|---|
| service_health | 通過 |
| localhost_only_listener | 通過 |
| forced_indexed_all_formats | 通過 |
| forced_chunks_present | 通過 |
| forced_without_warnings | 通過 |
| sqlite_vec_active | 通過 |
| incremental_skipped_all | 通過 |
| health_reports_index | 通過 |
| no_external_connections | 通過 |

- 強制索引：9 個檔案／9 個片段
- 增量索引：9 個未變更檔案
- 向量後端：sqlite-vec
- EXE SHA-256：0C88759088CDD8A9EE899F9CBB2439A3367053F0E9127913D2A632D43CFC46FC
