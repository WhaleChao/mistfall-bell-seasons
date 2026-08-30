# 公開發行檔乾淨 Windows 驗收

結果：**PASS**　｜　公開 v1.1.2　｜　Windows 11 build 26100

GitHub Actions 使用全新的 `windows-latest` 虛擬機，直接從公開 Release 下載成品，而非使用開發機上的 build。完整工作流程：[Published Release Verification #33306289366](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33306289366)。

- GitHub asset digest、下載 ZIP、`SHA256SUMS.txt` 三者一致。
- ZIP 僅含允許的十二個遊戲、伺服器說明與法律文件；Godot 4.7.2 授權原文雜湊一致。
- 解壓後 EXE 正常結束，PCK 邊界稽核通過。
- 遊戲執行期間完成 21 次 TCP／UDP 觀測，建立的網路端點為 0；開發機另從公開下載點完成 15 次零端點交叉觀測。
- ZIP／EXE／PCK SHA-256 分別為 `6d6118f5e5bfe12778610eb991ec1083a0d3e6656bd0841254a8c191dc74908c`、`a236f29c91091c13c58693558540c63fc5a1115e63f2082717fb1719733f952b` 與 `c632c60cfbb3719a5639ec48133b6d52c97cbac7274004f4cd0b38820f09afa7`。
- PFX Authenticode 流程在公開 EXE 的隔離複本上完成；測試憑證移除後，正式 EXE 保持原雜湊。

正式 EXE 仍為 `NotSigned`，因為尚未提供受公眾信任的商業程式碼簽章憑證。測試簽章只證明發布管線可用，不冒充受信任簽章。
