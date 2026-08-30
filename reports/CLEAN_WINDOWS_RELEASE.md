# 公開發行檔乾淨 Windows 驗收

結果：**PASS**　｜　公開 v1.1.0　｜　Windows 11 build 26100

GitHub Actions 使用全新的 `windows-latest` 虛擬機，直接從公開 Release 下載成品，而非使用開發機上的 build。完整工作流程：[Published Release Verification #33303339094](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33303339094)。

- GitHub asset digest、下載 ZIP、`SHA256SUMS.txt` 三者一致。
- ZIP 僅含允許的十二個遊戲、伺服器說明與法律文件；Godot 4.7.2 授權原文雜湊一致。
- 解壓後 EXE 正常結束，PCK 邊界稽核通過。
- 遊戲執行期間完成 25 次 TCP／UDP 觀測，建立的網路端點為 0；開發機另從公開下載點完成 15 次零端點交叉觀測。
- ZIP／EXE／PCK SHA-256 分別為 `ac8aa7398d6769f08e77ffce33809530a3398cb723a0d7ac24522e94e87a0b4f`、`0f7a9fc6bde95d9f57338102aaa545b752490ec3f38397a2b1074ae150380d40` 與 `1b165a02118a23c00c35df8cdf39ed9ab444ed28cc1f10e8e2fb7b4f83b6be2e`。
- PFX Authenticode 流程在公開 EXE 的隔離複本上完成；測試憑證移除後，正式 EXE 保持原雜湊。

正式 EXE 仍為 `NotSigned`，因為尚未提供受公眾信任的商業程式碼簽章憑證。測試簽章只證明發布管線可用，不冒充受信任簽章。
