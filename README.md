# SliTaz Firefox Desktop Live ISO

供 Proxmox VE 使用的輕量 Firefox Live ISO：開機自動取得 DHCP，進入 **SliTaz 桌面**，開啟一般最大化的 Firefox 視窗。保留網址列、工作列、桌面檔案管理器、設定與終端機，並提供繁體中文注音與 fio 測試。

> 實驗版。GitHub Actions 建置成功僅代表 ISO 產生；SliTaz/PVE 上的視窗與 SCIM 注音仍需實機驗收。

## 開機預設

- **Firefox**：開啟 `https://172.22.10.1:8006/`，新視窗**最大化**、不是 kiosk／獨占全螢幕。可以縮小、切換程式、調整網路。關閉 Firefox 後仍停留在桌面。
- **歡迎頁**：以 Firefox Enterprise policies 的 `OverrideFirstRunPage`、`OverridePostUpdatePage` 和使用者設定取消首次啟動、更新提示、預設瀏覽器檢查。
- **中文**：安裝 WenQuanYi Micro Hei 字型、SCIM `ZhuYin`，預設繁體中文注音（大千鍵位），`Ctrl+Space` 中英文切換。不是 RIME 或新酷音；SCIM 與 Firefox XIM 是否能正常交互仍需實機測試。
- **桌面**：Openbox + PCManFM 桌面 + LXPanel，保留應用程式選單；網路以 DHCP 自動取得。Live 的檔案與瀏覽器個人資料在 RAM 中，重新開機消失。
- **fio**：內建固定提交版本的 fio 3.35 靜態執行檔。桌面上的 **Database I/O Test (10 min)** 執行 600 秒、70%/30% 隨機讀寫、8 KiB、最多 750 IOPS；預設只在使用者家目錄的一般檔案內寫入。

PVE 的自簽 HTTPS 憑證警告保持正常，第一次需自行選擇接受；不會關閉憑證驗證機制。

## 下載及 PVE 設定

前往 [GitHub Actions](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/workflows/build.yml) 查看 **Build Live ISO**。成功後在 [Releases](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/releases) 下載 `slitaz-firefox-kiosk-x86_64.iso` 與 `SHA256SUMS`。

建議 PVE 使用 x86_64、2 vCPU、至少 2 GiB RAM（使用 fio 建議 4 GiB）、SeaBIOS、Standard VGA、VirtIO 網卡。此 Live 系統可不配置虛擬磁碟；OVMF 啟動需另外測試，並關閉 Secure Boot。

## fio 10 分鐘資料庫模擬測試

桌面提供 `Database-IO-10min.desktop` 快捷方式及 `Database-IO-10min.sh` 腳本，也可在終端機手動執行：

```sh
fio --version
/usr/local/bin/fio-database-benchmark
# 指定已掛載的檔案系統測試，勿使用 /dev/sdX：
/usr/local/bin/fio-database-benchmark /mnt/test-storage
```

此工作負載使用 `rw=randrw`、`rwmixread=70`、`bs=8k`、`runtime=600`、`time_based`、`size=128M`、`ioengine=sync`、`direct=0`、`fsync=50`、`rate_iops=750`。測試目錄至少要有 256 MiB 可用空間。工作負載建立 `db-benchmark.fio-data` 測試檔，不使用裸裝置；紀錄保存在 `~/fio-results/`。執行完成**不自動刪除測試檔**，方便檢查，需要時可手動刪除。

**注意**：Live ISO 預設家目錄位於 RAM-backed rootfs，因此預設測試量測的是記憶體內的檔案 I/O，**不是** PVE 的底層實體儲存。若要量測實際儲存裝置，必須在系統中掛載可寫入的測試檔案系統，並將目錄傳給腳本。工作負載可能長時間寫入，請勿指向含有重要資料且空間不足的目錄。

## 自訂與建置

編輯 `config/kiosk.conf`：

```sh
START_URL='https://172.22.10.1:8006/'
BROWSER_MODE='normal'
NETWORK_INTERFACE='auto'
DHCP_WAIT_SECONDS=30
```

`normal` 讓 Firefox 最大化但保留桌面；若自行改為 `kiosk` 才會使用 Firefox 的 `--kiosk` 模式。Firefox user.js 複製到 Live 使用者的實際 Profile，並依照 `START_URL` 設定首頁，避免 `/etc/skel` 對已存在使用者無效的問題。

在可丟棄的 Ubuntu 24.04 x86_64 VM 上使用：

```bash
sudo apt-get update
sudo apt-get install -y xorriso cpio xz-utils shellcheck musl-tools
sudo bash scripts/build.sh
```

建置會下載 SliTaz 基底與套件，並從 `axboe/fio` 固定提交 `5a649e2dddc4d8ad163b0cf57f7cea00a2e94a33` 編譯靜態 fio，避免在 Live ISO 安裝完整編譯器。需要 root/chroot/bind mounts。套件庫仍採 rolling cooking，尚不能宣稱位元可重現。

## 驗收

1. ISO 開機取得 VirtIO 網卡 DHCP，LXPanel/桌面圖示存在，Firefox 直接以一般最大化視窗開啟指定 PVE HTTPS 網址，不出現 Firefox 歡迎頁。
2. 能縮小及關閉 Firefox，桌面仍可操作；能進入網路設定、終端機與其他應用。
3. 中文網頁正常顯示，`Ctrl+Space` 切到「Chinese (traditional) — ZhuYin」，使用大千鍵盤輸入「中文測試」。
4. `fio --version` 顯示 3.35，桌面腳本確實執行 600 秒，在指定測試目錄完成 70% 讀／30% 寫，保留結果紀錄。
5. PVE HTTPS 自簽憑證警告正常、可手動接受；如使用 OVMF 額外確認 UEFI。

網路紀錄：`/var/log/kiosk-network.log`；SCIM 紀錄：`~/scim-setup.log`；桌面日誌：`~/desktop.log`、`~/lxpanel.log`。建置前檢查與 PVE 實際操作仍屬不同驗證層次。

## 授權

以官方 SliTaz x86_64 Firefox cooking ISO 為基底，保留 BIOS/UEFI 啟動資訊及套件各自授權。原創程式採 [AGPL-3.0](LICENSE)；參見 [THIRD_PARTY.md](THIRD_PARTY.md)。
