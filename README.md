# SliTaz Firefox Desktop Live ISO

供 Proxmox VE 使用的輕量 Firefox Live ISO：開機優先嘗試 DHCP（最多 10 秒），失敗就使用靜態 IP 備援，進入 **SliTaz 桌面**，開啟一般最大化的 Firefox 視窗。保留網址列、工作列、桌面檔案管理器、設定與終端機，並提供繁體中文注音與 fio 測試。

> 實驗版。GitHub Actions 建置成功僅代表 ISO 產生；SliTaz/PVE 上的視窗與 SCIM 注音仍需實機驗收。

## 開機預設

- **Firefox**：開啟 `https://172.22.10.1:8006/`，新視窗**最大化**、不是 kiosk／獨占全螢幕。可以縮小、切換程式、調整網路。關閉 Firefox 後仍停留在桌面。
- **歡迎頁**：以 Firefox Enterprise policies 的 `OverrideFirstRunPage`、`OverridePostUpdatePage` 和使用者設定取消首次啟動、更新提示、預設瀏覽器檢查。
- **中文**：安裝 WenQuanYi Micro Hei 字型、SCIM `ZhuYin`，預設繁體中文注音（大千鍵位），`Ctrl+Space` 中英文切換。不是 RIME 或新酷音；SCIM 與 Firefox XIM 是否能正常交互仍需實機測試。
- **桌面**：Openbox + PCManFM 桌面 + LXPanel，保留應用程式選單；網路優先使用 DHCP，逾時就套用靜態 IP 備援，且不再重試 DHCP。Live 的檔案與瀏覽器個人資料在 RAM 中，重新開機消失。
- **fio**：內建含 `libaio` 的 fio 3.35 靜態執行檔，桌面提供 **Database 4K R70 W30 (10 min)** 與 **Database 4K R50 W50 (10 min)**。兩組都直接對專用裸磁碟 `/dev/sda` 做破壞性隨機讀寫，手動執行並確認後才開始。

PVE 的自簽 HTTPS 憑證警告保持正常，第一次需自行選擇接受；不會關閉憑證驗證機制。

## 下載及 PVE 設定

前往 [GitHub Actions](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/workflows/build.yml) 查看 **Build Live ISO**。成功後在 [Releases](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/releases) 下載 `slitaz-firefox-kiosk-x86_64.iso` 與 `SHA256SUMS`。

建議 PVE 使用 x86_64、2 vCPU、至少 2 GiB RAM（使用 fio 建議 4 GiB）、SeaBIOS、Standard VGA、VirtIO 網卡。此 Live 系統可不配置虛擬磁碟；OVMF 啟動需另外測試，並關閉 Secure Boot。

## Red Hat 風格 fio 資料庫 I/O 基準測試（裸磁碟）

本專案以 [Red Hat Ceph Storage Performance Benchmark](https://docs.redhat.com/en/documentation/red_hat_ceph_storage/9/html/administration_guide/ceph-performance-benchmark) 作為 4K、Linux AIO、Direct I/O、Queue Depth 的實作參考，依使用需求調整為 70/30 和 50/50 混合讀寫。所有選項以 [fio 官方文件](https://fio.readthedocs.io/en/latest/fio_doc.html) 為準。這是自訂混合 I/O 測試，並非 Red Hat 認證測試或完整資料庫交易模擬。

**警告：這兩個測試直接覆寫 `/dev/sda`，會破壞分割表、檔案系統與現有資料。只可用於特別配置、內容可完全刪除的虛擬測試磁碟。**

- 在 PVE 以 VirtIO SCSI 掛載**專用測試磁碟**，確認 SliTaz 識別為 `/dev/sda`；VirtIO Block 可能是 `/dev/vda`，腳本不會自動改寫別的磁碟。
- 桌面可手動點擊 **Database 4K R70 W30 (10 min)** 或 **Database 4K R50 W50 (10 min)**，也可透過終端機執行下列命令：

```sh
# root 登入後執行；一般 tux 帳號啟動時會先要求 su 認證
/usr/local/bin/fio-db-r70-w30.sh
/usr/local/bin/fio-db-r50-w50.sh
```

共用設定：`filename=/dev/sda`、`rw=randrw`、`bs=4k`、`ioengine=libaio`、`direct=1`、`iodepth=32`、`numjobs=1`、`size=100%`、`ramp_time=60`、`runtime=600`、`time_based=1`、`group_reporting=1`。第一組 `rwmixread=70`，第二組 `rwmixread=50`。正式量測每次 600 秒，另外加 60 秒暖機。報表包含讀、寫 IOPS、頻寬、平均與百分位延遲（P50/P95/P99/P99.9）。

**執行安全檢查**：偵測真正的 /dev/sda block device、唯讀旗標、磁碟容量、系統掛載點（比對 kernel major:minor）、Swap、device holders，且必須以互動終端機輸入精確的 `ERASE /dev/sda`。檢查通過不代表磁碟資料一定安全；確認測試硬碟身分是操作者責任。禁止無人值守執行。

結果儲存在 `/tmp/fio-results/`，Live ISO 重啟後消失，請先將紀錄移出。此測試**沒有整碟事前寫滿（Preconditioning）**，因此結果不能直接宣稱符合 SNIA 穩態測試方法。兩組應在相同虛擬磁碟、儲存設定和初始條件下比較。

`fio` 由 GitHub Actions 在 Alpine musl 環境中靜態編譯，明確安裝 `libaio-dev`，編譯後會確認 Linux AIO engine，並執行小型 libaio I/O smoke test；若不支援則停止 ISO 發佈。

## 自訂與建置

編輯 `config/kiosk.conf`：

```sh
START_URL='https://172.22.10.1:8006/'
BROWSER_MODE='normal'
NETWORK_INTERFACE='auto'
DHCP_WAIT_SECONDS=10
FALLBACK_IP='192.168.0.6'
FALLBACK_NETMASK='255.255.255.0'
FALLBACK_GATEWAY='192.168.0.1'
FALLBACK_DNS='192.168.0.1'
```

開機最多等待 DHCP 10 秒。DHCP 成功時採用伺服器發放的 IP、Gateway、DNS，並保留租約續租程序；失敗時改用 SliTaz 官方預設的固定 IP `192.168.0.6/24`、Gateway/DNS `192.168.0.1`，不再重試 DHCP。**注意：此備援網段不等於 PVE 網址 `172.22.10.1` 的網段**。若需在無 DHCP 的 172.22.10.0 網段存取 PVE，請先依現場狀況修改 `FALLBACK_*` 設定，避免 IP 衝突。本專案修改前並沒有明確設定固定 IP，只有 DHCP；上述預設值沿用 SliTaz 原始設定而非假設已有的 PVE 靜態設定。網路狀態記錄在 `/var/run/kiosk-network.status`、`/var/log/kiosk-network.log`；Firefox 會等待成功取得 DHCP 或備援設定完成（另有逾時保護）。

`normal` 讓 Firefox 最大化但保留桌面；若自行改為 `kiosk` 才會使用 Firefox 的 `--kiosk` 模式。Firefox user.js 複製到 Live 使用者的實際 Profile，並依照 `START_URL` 設定首頁，避免 `/etc/skel` 對已存在使用者無效的問題。

在可丟棄且已安裝 Docker Engine 的 Ubuntu 24.04 x86_64 VM 上使用：

```bash
sudo apt-get update
sudo apt-get install -y xorriso cpio xz-utils shellcheck
sudo bash scripts/build.sh
```

建置會下載 SliTaz 基底與套件，並從 `axboe/fio` 固定提交 `5a649e2dddc4d8ad163b0cf57f7cea00a2e94a33` 由 Alpine Docker 容器編譯含 libaio 的靜態 fio，避免在 Live ISO 安裝完整編譯器。需要 root/chroot/bind mounts。套件庫仍採 rolling cooking，尚不能宣稱位元可重現。

## 驗收

1. 分別測試有 DHCP 和沒有 DHCP 的 VirtIO 網路：前者取得 DHCP，後者最多約 10 秒後改用備援 IP 且不再嘗試 DHCP；檢查 `/var/run/kiosk-network.status`。LXPanel/桌面圖示存在，Firefox 直接以一般最大化視窗開啟指定 PVE HTTPS 網址，不出現 Firefox 歡迎頁。
2. 能縮小及關閉 Firefox，桌面仍可操作；能進入網路設定、終端機與其他應用。
3. 中文網頁正常顯示，`Ctrl+Space` 切到「Chinese (traditional) — ZhuYin」，使用大千鍵盤輸入「中文測試」。
4. `fio --version` 顯示 3.35，`fio --enghelp=libaio` 有效；確認專用 `/dev/sda` 無掛載與重要資料，兩個桌面腳本均能要求確認後完成 60 秒暖機 + 600 秒測試，結果保留在 `/tmp/fio-results/`。
5. PVE HTTPS 自簽憑證警告正常、可手動接受；如使用 OVMF 額外確認 UEFI。

網路紀錄：`/var/log/kiosk-network.log`；SCIM 紀錄：`~/scim-setup.log`；桌面日誌：`~/desktop.log`、`~/lxpanel.log`。建置前檢查與 PVE 實際操作仍屬不同驗證層次。

## 授權

以官方 SliTaz x86_64 Firefox cooking ISO 為基底，保留 BIOS/UEFI 啟動資訊及套件各自授權。原創程式採 [AGPL-3.0](LICENSE)；參見 [THIRD_PARTY.md](THIRD_PARTY.md)。
