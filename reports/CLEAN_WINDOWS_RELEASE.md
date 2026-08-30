# 公開發行檔乾淨 Windows 驗收

結果：**PASS**　｜　公開 v1.0.4　｜　Windows 11 build 26100

GitHub Actions 使用全新的 `windows-latest` 虛擬機，直接從公開 Release 下載成品，而非使用開發機上的 build。完整工作流程：[Published Release Verification #33299304050](https://github.com/WhaleChao/mistfall-bell-seasons/actions/runs/33299304050)。

- GitHub asset digest、下載 ZIP、`SHA256SUMS.txt` 三者一致。
- ZIP 僅含允許的十個遊戲與法律文件；Godot 4.7.2 授權原文雜湊一致。
- 解壓後 EXE 正常結束，PCK 邊界稽核通過。
- 遊戲執行期間完成 24 次 TCP／UDP 觀測，建立的網路端點為 0；開發機另從公開下載點完成 14 次零端點交叉觀測。
- ZIP／EXE／PCK SHA-256 分別為 `d636ce5dbd9fd6ea19d74b84f9044f78c757152be09595668dbe9177f37b1d43`、`996f6585d22a84747a28a87c4ff0bfbd13777a6047f171d0777dc990592970b2` 與 `bcf3b224fb5257df2bc53b01dad0bd328b84cc7650f710943370124735b193af`。
- PFX Authenticode 流程在公開 EXE 的隔離複本上完成；測試憑證移除後，正式 EXE 保持原雜湊。

正式 EXE 仍為 `NotSigned`，因為尚未提供受公眾信任的商業程式碼簽章憑證。測試簽章只證明發布管線可用，不冒充受信任簽章。
