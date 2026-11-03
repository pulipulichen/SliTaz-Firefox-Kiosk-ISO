# SliTaz Firefox Kiosk ISO

供 Proxmox VE 使用的 Firefox Live ISO：開機取得 DHCP、自動登入、開啟
`http://gw/`，保留網址列供自由瀏覽。包含中文字型與 RIME 注音輸入法。

> 實驗版：建置通過後才會發佈預先版本；仍需完成 PVE 圖形介面及中文輸入驗收。

## 下載

到 [Actions](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/workflows/build.yml)
執行 **Build Live ISO → Run workflow**。程式變更推送到 main 也會自動建置。
成功後到 [Releases](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/releases)
下載 `slitaz-firefox-kiosk-x86_64.iso`，以 SHA256SUMS 驗證。
另附 RIME 原始碼、套件清單與來源鎖定檔。

## PVE 設定

- x86_64；建議 2 vCPU、2 GB RAM 起，較多分頁可給 4 GB。
- 不需硬碟，掛上 ISO 並設為第一開機順位。
- 先用 SeaBIOS。保留上游 UEFI 結構；OVMF 測試時關閉 Secure Boot。
- 網卡選 VirtIO，接到提供 DHCP、DNS 且能解析 gw 的 bridge。
- 顯示使用 Standard VGA，以 PVE noVNC 操作。
- Ctrl+Space 切換 RIME 注音，採大千鍵盤；首次部署字典可能稍候數秒。
- HTTPS 自簽憑證保留正常警告，手動接受即可。

`gw` 是 DNS 名稱，不會自動改成 DHCP 預設閘道 IP。預設 `http://gw/`；
若要連 PVE 管理頁，請修改完整網址，例如 `https://gw:8006/` 再重新建置。

## 自訂

編輯 `config/kiosk.conf`：

```sh
START_URL='http://gw/'
BROWSER_MODE='normal'
NETWORK_INTERFACE='auto'
DHCP_WAIT_SECONDS=30
```

normal 保留網址列，kiosk 為全螢幕。網卡也可指定 eth0 等名稱。
關閉 Firefox 後會重新開啟。瀏覽紀錄、登入資訊與 RIME 詞庫均存 RAM，重開機清空。
Live 使用者是上游的 tux；這是管理用 Live 系統，未實施公共展示機的權限封鎖。

## 本機建置

使用可丟棄的 Ubuntu 24.04 x86_64 VM，至少 2 CPU、4 GB RAM、10 GB 空間：

```bash
sudo apt-get update
sudo apt-get install -y xorriso cpio xz-utils python3
sudo bash scripts/build.sh
```

輸出在 dist/。需要 root、chroot、bind mount，請用專用建置 VM。
runtime 與 compiler 使用不同 rootfs，成品不包含編譯器。
若 rolling ISO 更新導致 SHA256 不同，先檢查上游變動再更新鎖定檔。
套件庫仍會隨 cooking 更新，尚非完整位元可重現建置。

## 驗收

1. 從 ISO 開機，免登入，Firefox 開啟設定網址且有網址列。
2. VirtIO 網卡取得 DHCP 位址、路由與 DNS，gw 能解析。
3. 中文網頁與候選字正常顯示，沒有方框。
4. 點文字欄位，Ctrl+Space 切注音並送出「中文測試」，再按回英文。
5. 可輸入其他網址，接受測試用 HTTPS 自簽憑證警告。
6. 關閉 Firefox 可重開；VM 重啟後不保留瀏覽與登入資訊。
7. 使用 OVMF 時另測 UEFI 開機。

網路記錄：`/var/log/kiosk-network.log`；輸入法設定記錄：`~/ibus-setup.log`。
建置缺少 VirtIO、GTK3 IBus 模組、RIME 字典、CJK 字型或函式庫時停止，不發佈缺件 ISO。

## 技術與授權

以官方 x86_64 Firefox cooking ISO 為基底，保留 kernel、Xorg、BIOS/UEFI 結構。
套件庫沒有 RIME，故在 SliTaz chroot 編譯 librime 與 ibus-rime；
注音資料固定到相容歷史版本，避免最新資料要求更高版本引擎。

原創程式採現有 [AGPL-3.0](LICENSE)；ISO 各元件保留原授權，見
[THIRD_PARTY.md](THIRD_PARTY.md)。
