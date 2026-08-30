# 公開發行檔乾淨 Windows 驗收

結果：**PASS**　｜　公開 v1.0.3　｜　Windows 11 build 26100

GitHub Actions 使用全新的 `windows-latest` 虛擬機，直接從公開 Release 下載成品，而非使用開發機上的 build。完整工作流程：[Published Release Verification #33295882993](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33295882993)。

- GitHub asset digest、下載 ZIP、`SHA256SUMS.txt` 三者一致。
- ZIP 僅含允許的十個遊戲與法律文件；Godot 4.7.2 授權原文雜湊一致。
- 解壓後 EXE 正常結束，PCK 邊界稽核通過。
- 遊戲執行期間完成 24 次 TCP／UDP 觀測，建立的網路端點為 0。
- EXE／PCK SHA-256 分別為 `c62d32651c07c7cda3c1f71c0bfee9cd065c4f78a0a8cd4ffce94138e64e8773` 與 `2df650987f1795b38016b6bbf13b9ad777d919b6db2c3dd483ddf7c0952953f8`。
- PFX Authenticode 流程在公開 EXE 的隔離複本上完成；測試憑證移除後，正式 EXE 保持原雜湊。

正式 EXE 仍為 `NotSigned`，因為尚未提供受公眾信任的商業程式碼簽章憑證。測試簽章只證明發布管線可用，不冒充受信任簽章。
