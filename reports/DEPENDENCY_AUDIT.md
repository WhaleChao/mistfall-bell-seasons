# Creator Service 依賴漏洞稽核

結果：**PASS**　｜　59 個第三方 Python 套件　｜　0 個已知漏洞

執行工具：`pip-audit 2.10.1`。首次掃描發現 `pytest 8.4.2` 對應 `PYSEC-2026-1845`，已將測試依賴提高為 `pytest>=9.0.3,<10`；另加入 Starlette 指定的 `httpx2 2.12.0`，消除 TestClient 棄用警告。重新安裝後的最終掃描為零漏洞，15 個 Python 測試亦為零警告通過。

`pixelrpg-creator-service 0.1.0` 是本專案自己的本機套件，不存在於 PyPI，因此工具標示為無法從 PyPI 稽核；其原始碼由本專案測試與 release audit 直接覆蓋。完整機器可讀結果見 `dependency_audit.json`。
