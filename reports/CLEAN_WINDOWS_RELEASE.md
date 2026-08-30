# 公開發行檔乾淨 Windows 驗收

結果：**PASS**　｜　公開 v1.1.3　｜　Windows 11 build 26100

GitHub Actions 使用全新的 `windows-latest` 虛擬機，直接從公開 Release 下載成品，而非使用開發機上的 build。完整工作流程：[Published Release Verification #33308048130](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33308048130)。

- GitHub asset digest、下載 ZIP、`SHA256SUMS.txt` 三者一致。
- ZIP 僅含允許的十二個遊戲、伺服器說明與法律文件；Godot 4.7.2 授權原文雜湊一致。
- 解壓後 EXE 正常結束，PCK 邊界稽核通過。
- 遊戲執行期間完成 21 次 TCP／UDP 觀測，建立的網路端點為 0；開發機另從公開下載點完成 14 次零端點交叉觀測。
- ZIP／EXE／PCK SHA-256 分別為 `2dbac74bca36c6b9653aeae2d385d9e2483f9256587b3b609ea08b7673860b2f`、`9d9ec82ed97b29d24c8a48742d3ccf3e983b646038951d3a0ab48faa6d7d0c16` 與 `5690f57d57ad84af892f4be7cd18ae110d8a77a70f43cc05bd4975fb091ff092`。
- main CI、v1.1.3 tag CI 與 Published Release Verification 三條工作流程均成功。
- PFX Authenticode 流程在公開 EXE 的隔離複本上完成；測試憑證移除後，正式 EXE 保持原雜湊。

正式 EXE 仍為 `NotSigned`，因為尚未提供受公眾信任的商業程式碼簽章憑證。測試簽章只證明發布管線可用，不冒充受信任簽章。
