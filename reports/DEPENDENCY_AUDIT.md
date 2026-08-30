# Creator Service 依賴漏洞稽核

結果：**PASS**　｜　138 個 Python 依賴　｜　0 個已知漏洞

執行工具：`pip-audit 2.10.1`。掃描環境包含 FastAPI、PyInstaller、Docling 2.123.1、RapidOCR、Torch、OpenCV、Office/PDF 解析與 sqlite-vec 0.1.9 的完整安裝集合。最終掃描為零已知漏洞，16 個 Python 測試通過。

`pixelrpg-creator-service 0.1.0` 是本專案自己的本機套件，不存在於 PyPI，因此工具標示為無法從 PyPI 稽核；其原始碼由本專案測試與 release audit 直接覆蓋。完整機器可讀結果見 `dependency_audit.json`。
