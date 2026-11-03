# CHANGE LOG

本檔用於不同 AI session 與維護者之間交接：記錄遇到什麼問題、改了哪裡、為什麼改、實際驗證到哪裡，以及哪些方案已撤回或仍只是建議。內容依 GitHub 提交差異與 Actions 原始日誌整理。

- 專案：[pulipulichen/SliTaz-Firefox-Kiosk-ISO](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO)。
- 首次整理日期：2026-11-03；本文時間統一為 Asia/Taipei（UTC+08:00），GitHub 原始日誌時間為 UTC。
- 本次核對的程式基準：[24351e8b2d8267b8bd29dbd919cfa0822c253564](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/24351e8b2d8267b8bd29dbd919cfa0822c253564)。
- 這是狀態快照。後續 session 開始時，先重新讀取 main 與最新 Actions 結果，再依本文定位已嘗試的方案。
- 本次（2026-11-03 文件整理時）的要求是補上紀錄；上一輪僅分析可行性。系統化依賴修復或更換發行版仍待後續指示，不能把本文的建議誤認為已實作。

## 2026-11-03 第 20～23 輪更新

目前可下載 [第 23 輪 ISO 預發行版](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/releases/tag/build-23-1)。以下前期紀錄中的 RIME 方案已由 SCIM 注音表取代。

- 第 20 輪的 6.12.89-slitaz rootfs 有 virtio_net，但沒有 virtio_pci 模組或內建證據。第 21 輪嘗試從三個鏡像保留原核心並補同版本模組，下載均回傳 404。
- 第 22 輪由同一份 cooking 索引更新 linux-lts、已安裝的核心分包與 VirtIO 提供套件，並將對應開機核心放入光碟。6.12.115-slitaz 的 virtio_pci 和 virtio_net 已通過 depmod、modprobe 相依解析。SCIM、注音表及中文字型檔案檢查通過。此輪在整棵目錄覆寫後重播 GRUB 開機資訊時失敗。
- [第 23 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41665277327) 僅替換核心、rootfs、GRUB 設定和 md5sum，成功保留 BIOS 與 UEFI 開機項目並發布 ISO。尚待 PVE 實機驗證 DHCP、Firefox 與 Ctrl+Space 注音輸入。

## 接手摘要（第 15 輪歷史快照）

目前保留 GitHub Actions 與 SliTaz 方案。已完成 RIME 核心編譯的證據來自第 14 輪；該輪在 ibus-rime 的 GLib/GObject 開發依賴檢查停止。最新程式已加入 glib-dev，但第 15 輪在最後查詢時仍執行中。已查閱的第 1～14 輪皆失敗，不能宣稱已有可用 ISO 或已完成 PVE 驗收。

優先處理的問題是「必要的間接依賴下載失敗後，仍繼續安裝主套件及編譯」，而不只是再補一個套件名稱。改為 Debian 精簡 Live ISO 是討論過的替代方案，尚未選定或實作。

## 使用者目標與目前架構

- 在 PVE 從 Live ISO 開機，不需要硬碟；開機取得 DHCP，支援 VirtIO 網卡。
- 自動進入 Firefox，預設開啟 `http://gw/`；normal 模式保留網址列，可自由輸入其他網址。
- `gw` 是 DNS 主機名稱，不是自動替換成 DHCP gateway IP；PVE 管理頁若使用 8006 埠，必須設定完整的 `https://gw:8006/`。
- 必須顯示中文字型，提供 RIME 注音，預設 Ctrl+Space 切換，採大千鍵盤。
- HTTPS 自簽憑證保留瀏覽器正常警告，由使用者接受。
- 以官方 SliTaz x86_64 Firefox cooking ISO 為底；Ubuntu 24.04 runner 負責解包、掛載、呼叫 chroot 與重封裝，RIME 在 SliTaz builder rootfs 內編譯。
- runtime rootfs 與 builder rootfs 分開，編譯器只用於 builder；RIME 相關輸出安裝到 `/opt/rime`。
- 將在 Ubuntu 直接編譯的程式搬入 SliTaz，會涉及函式庫與 ABI 相容性；本文未採用這種替換方式。
- [config/sources.lock.json](config/sources.lock.json) 鎖定基底 ISO 與來源的 SHA256。主要版本為 yaml-cpp 0.6.3、LevelDB 1.22、MARISA 0.2.6、librime 1.8.5、ibus-rime 1.5.0；RIME 資料也固定到指定提交。
- SliTaz cooking 二進位套件庫仍會變動，尚未鎖定為完整套件快照；不能宣稱整份 ISO 已可逐位元重現。
- [目前工作流程](.github/workflows/build.yml) 使用 `ubuntu-24.04`，工作逾時為 90 分鐘；只有建置步驟成功後才以 GitHub Releases 發佈預先版本。

## 2026-11-03 歷次修改與結果

以下依提交順序整理。「該輪失敗」與「該筆修正無效」不是同一件事；若錯誤移到下一階段，會明列已跨過的階段及剩餘限制。

### 21:44:40 — 建立第一版 SliTaz Firefox Live ISO 流程

- 提交：[a4e8ea42](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/a4e8ea42fa5b87a2045ca2ac08e21cde67e1d55a)；[Actions 第 1 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41647095525)。
- 修改位置：`.github/workflows/build.yml`、`scripts/`、`config/`、`README.md`、授權與發佈說明。
- 原因：目標是在 PVE 以 Live ISO 開機後取得 DHCP、顯示中文、直接開啟瀏覽器，並提供 Ctrl+Space 切換的 RIME 注音輸入。
- 實際變更：建立 Ubuntu runner → 解包官方 SliTaz Firefox ISO → 分離 runtime/builder rootfs → 在 SliTaz chroot 編譯 RIME → 檢查成品 → 重封裝 ISO → 發佈 GitHub 預先版本的流程。設定預設網址 `http://gw/`，瀏覽器採保留網址列的 normal 模式。
- 驗證結果：第 1 輪在安裝 `automake` 時停止：`automake-1.16.5-any.tazpkg` 未成功取得，日誌顯示 `Checksum error` 與 `No such file or directory`。沒有完成 ISO 建置。
- 目前採用狀態：基礎架構仍採用；後續逐項修正以下問題。

### 21:51:10 — 以自訂 CMake 配方編譯 MARISA

- 提交：[210f208e](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/210f208e8f4fe2d0a01acb9006d4ccd112a73b00)；[Actions 第 2 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41648072223)。
- 修改位置：`scripts/build-rime.sh`、`scripts/build.sh`；新增 `scripts/marisa-cmake/CMakeLists.txt`。
- 原因：第 1 輪拿不到 automake 套件。鎖定的 marisa-trie v0.2.6 使用 Autotools，不能直接當成附有 CMakeLists.txt 的專案編譯。
- 實際變更：以自訂 CMakeLists.txt 列出 MARISA 所需來源，產生共享函式庫並安裝標頭；移除為這段 Autotools 流程加入的 automake/autoconf/libtool 需求。
- 驗證結果：第 2 輪轉而停在 `Package installation failed: pkg-config`。這一輪還不能證明 MARISA 已成功；第 14 輪完成 librime 編譯，才提供後續流程已跨過此階段的證據。
- 目前採用狀態：保留自訂 MARISA 配方。

### 21:56:08 — 嘗試透過第二個鏡像補裝套件

- 提交：[03ae6758](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/03ae6758819c0c496486b2b1ece2310a9126ea33)；[Actions 第 3 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41648821563)。
- 修改位置：`scripts/build.sh` 的 `install_packages()`。
- 原因：tazpkg 下載失敗後，仍可能沒有可靠地讓整個流程立即失敗；原本主鏡像無法取得 pkg-config，曾懷疑鏡像索引與檔案同步不同步。鏡像同步問題是當時的假設，並非已證實根因。
- 實際變更：依 `/var/lib/tazpkg/installed/<package>` 是否存在判定安裝結果，缺少時切換 Clarkson 鏡像再試。
- 驗證結果：第 3 輪停在 `opencc` 下載／安裝失敗。此提交的 `printf` 格式另有將換行寫成字面跳脫文字的問題，下一筆提交修正。
- 目前採用狀態：此種僅切換 chroot 內鏡像的補救方式，後來被第 7 筆的 runner 端 curl 下載方式取代。

### 21:56:23 — 修正鏡像設定檔的換行

- 提交：[f0db4b38](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/f0db4b38681423e8dfc4568f2336c4949bab0fd8)；[Actions 第 4 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41648855762)。
- 修改位置：`scripts/build.sh`。
- 原因：前一筆提交使用 `printf '%s\\n'`，會輸出字面上的 `\n`，而非正確的行尾換行。
- 實際變更：改用 `printf '%s\n'` 寫入鏡像 URL。
- 驗證結果：第 4 輪仍停在 `pkg-config` 下載／安裝失敗，說明修正換行尚未解決下載問題。
- 目前採用狀態：正確的換行寫法保留；不能把這筆修正視為套件下載已全面正常。

### 21:59:48 — 嘗試改用 Ibiblio 備援鏡像

- 提交：[4cd138bd](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/4cd138bde4d7f41e54cd250b3fd88664922c7e76)；[Actions 第 5 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41649371244)。
- 修改位置：`scripts/build.sh`。
- 原因：Clarkson 備援仍無法讓 tazpkg 取得 pkg-config。
- 實際變更：將補救下載的鏡像改成 `https://distro.ibiblio.org/slitaz/x86_64/cooking/packages/`。
- 驗證結果：第 5 輪仍是 `Package installation failed from all configured mirrors: pkg-config`。單純更換鏡像不足以解決當時問題。
- 目前採用狀態：Ibiblio 後來成為主要鏡像，但這版「只在 chroot 內換鏡像」的實作已被後續方式取代。

### 22:03:20 — 嘗試從鎖定原始碼編譯 pkg-config

- 提交：[32445ed2](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/32445ed2ed6eef04efaaa9ff82352e1f71ede5ff)；[Actions 第 6 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41649942796)。
- 修改位置：`config/sources.lock.json`、`scripts/build.sh`。
- 原因：多個鏡像下的 pkg-config 二進位套件安裝仍失敗，因此嘗試繞過該套件的下載路徑。
- 實際變更：鎖定 pkg-config 0.29.2 tarball 與 SHA256，使用 `./configure --with-internal-glib --prefix=/usr --disable-host-tool` 自行建置；移除先前的單鏡像重試邏輯。
- 驗證結果：第 6 輪先停在另一個套件 `libboost-dev` 安裝失敗，尚未走到 pkg-config 的 configure。問題因此不是只限於 pkg-config 這一個套件。
- 目前採用狀態：原始碼編譯方案已在第 8 筆移除；目前的鎖定檔也不再包含 pkg-config 原始碼項目。

### 22:07:08 — 由 runner 使用 curl 補抓精確套件檔名

- 提交：[f535f195](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/f535f195013755815d86e4a8d978ad12b7a9dbb4)；[Actions 第 7 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41650551559)。
- 修改位置：`scripts/build.sh` 的 `install_packages()`。
- 原因：套件下載失敗涵蓋多個套件，不能只為 pkg-config 增加特例。
- 實際變更：保留 tazpkg 輸出到 `work/tazpkg-<package>.log`；遇到未安裝的直接套件時，從 `Checksum error for "...tazpkg"` 解析檔名，讓 Ubuntu runner 的 curl 依序嘗試 Ibiblio、ICM、Clarkson，下載到 chroot 的 `/tmp` 後再執行 tazpkg install。最終仍檢查直接套件的安裝登錄目錄。
- 驗證結果：第 7 輪已走到 pkg-config 原始碼的 configure，但失敗於 `C preprocessor "/lib/cpp" fails sanity check`；另出現 `/usr/bin/file: not found` 與 cleanup 時 `/dev` busy 的訊息。沒有取得 configure 的完整 config.log，不能逕行斷言其更深層根因。
- 目前採用狀態：runner 端 curl 補抓仍是目前機制；尚未完整處理間接依賴。

### 22:11:27 — 改回安裝 pkg-config 二進位套件

- 提交：[d9d6f8aa](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/d9d6f8aacc37101fc49791995a7055104bcf69bf)；[Actions 第 8 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41651248225)。
- 修改位置：`config/sources.lock.json`、`scripts/build.sh`。
- 原因：runner 端補抓機制已建立，而 pkg-config 自行編譯又引入 configure 問題。
- 實際變更：把 pkg-config 放回 builder 的套件清單，刪除其原始碼鎖定項目及 configure/make 指令，改走共用套件下載補救流程。
- 驗證結果：第 8 輪進入 yaml-cpp 編譯，接著因 `linux/errno.h: No such file or directory` 停止。這提供已跨過 pkg-config 安裝階段的證據，並不代表整個 builder 的開發檔已齊備。
- 目前採用狀態：採用套件版 pkg-config；不要把已撤回的原始碼方案當成目前實作。

### 22:16:23 — 補 Linux API 標頭並切換主要鏡像

- 提交：[0c9eb72d](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/0c9eb72d2e4745a627b8182631823a948916ebc0)；[Actions 第 9 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41652054266)。
- 修改位置：`scripts/build.sh`。
- 原因：第 8 輪的 C/C++ 編譯缺少 `linux/errno.h`；glibc-dev 本身不足以提供所需 Linux API 標頭。
- 實際變更：加入 `linux-api-headers`；主要 tazpkg 鏡像改為 Ibiblio。這裡安裝的是使用者空間編譯所需標頭，沒有重編 Linux kernel。
- 驗證結果：第 9 輪已進入 librime 編譯，改因 `boost/signals2/connection.hpp` 缺少而失敗。
- 目前採用狀態：保留此開發套件與主要鏡像設定。

### 22:20:03 — 補 Boost.Signals2 標頭

- 提交：[19df5602](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/19df5602022638e5349580840c8e77d7102ddce3)；[Actions 第 10 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41652652677)。
- 修改位置：`scripts/build.sh` 的 builder 套件清單。
- 原因：第 9 輪缺少 `boost/signals2/connection.hpp`。不能假設 `libboost-dev` 已包含或已成功補齊所有拆分的 Boost 開發檔。
- 實際變更：明列 `libboost-signals-dev`。
- 驗證結果：第 10 輪改因 `boost/date_time/posix_time/posix_time_types.hpp` 缺少而失敗。
- 目前採用狀態：保留。

### 22:23:11 — 補 Boost.DateTime 標頭

- 提交：[6284385d](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/6284385db95547fe1e7149555bdedc07ad122d0e)；[Actions 第 11 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41653171399)。
- 修改位置：`scripts/build.sh` 的 builder 套件清單。
- 原因：第 10 輪缺少 Boost.DateTime 的 posix_time_types.hpp。
- 實際變更：明列 `libboost-date-time-dev`。
- 驗證結果：第 11 輪改因 `boost/math/special_functions/sign.hpp` 缺少而失敗。
- 目前採用狀態：保留。

### 22:27:01 — 補 Boost.Math 標頭

- 提交：[2379ef8f](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/2379ef8f87ddd2c2923514e3b4ed5c72be54c931)；[Actions 第 12 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41653796336)。
- 修改位置：`scripts/build.sh` 的 builder 套件清單。
- 原因：第 11 輪的 Boost lexical_cast 間接包含 Boost.Math，而所需標頭未齊。
- 實際變更：明列 `libboost-math-dev`。
- 驗證結果：第 12 輪改因 `boost/iostreams/device/array.hpp` 缺少而失敗。
- 目前採用狀態：保留。

### 22:30:58 — 補 Boost.Iostreams 標頭

- 提交：[06316c9b](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/06316c9bd99756850abefc6e26c1ea56668aae06)；[Actions 第 13 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41654444711)。
- 修改位置：`scripts/build.sh` 的 builder 套件清單。
- 原因：第 12 輪缺少 Boost.Iostreams 的 array.hpp。
- 實際變更：明列 `libboost-iostreams-dev`。
- 驗證結果：第 13 輪走到連結 librime 共享函式庫，卻連入非 PIC 的 `libyaml-cpp.a`，出現 `relocation R_X86_64_32 ... can not be used when making a shared object; recompile with -fPIC`。
- 目前採用狀態：保留套件項目；下一筆針對 yaml-cpp 建置選項修正。

### 22:36:38 — 使用 yaml-cpp 真正支援的共享函式庫選項

- 提交：[26f64ff0](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/26f64ff0dd417fc4100a97e89a15afd4a339d71b)；[Actions 第 14 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41655397482)。
- 修改位置：`scripts/build-rime.sh`。
- 原因：yaml-cpp 0.6.3 使用 `YAML_BUILD_SHARED_LIBS` 選項；原先傳入通用的 `BUILD_SHARED_LIBS=ON`，未達成預期的共享函式庫建置。
- 實際變更：將 yaml-cpp 的參數改為 `-DYAML_BUILD_SHARED_LIBS=ON`；LevelDB 的參數維持其既有設定。
- 驗證結果：第 14 輪成功產生並安裝 `/opt/rime/lib/librime.so.1.8.5`，也完成 rime_deployer。接著 ibus-rime 的 configure 因 `Package 'gobject-2.0', required by 'ibus-1.0', not found` 失敗。Validate scripts 成功；Build ISO 失敗；Publish 被跳過。
- 目前採用狀態：共享函式庫修正保留；已驗證 librime 核心編譯跨過前述連結錯誤。完整 ISO 與輸入法操作仍未驗證。

### 22:43:06 — 明列 GLib/GObject 開發檔套件

- 提交：[24351e8b](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/24351e8b2d8267b8bd29dbd919cfa0822c253564)；[Actions 第 15 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41656459179)。
- 修改位置：`scripts/build.sh` 的 builder 套件清單。
- 原因：第 14 輪的 pkg-config 找不到 gobject-2.0。`glibc-dev` 是 C 標準函式庫開發檔，與 GLib/GObject 使用的 `glib-dev` 不同。第 14 輪前段亦曾嘗試把 glib-dev 當成間接依賴下載，但沒有成功。
- 實際變更：在 glibc-dev 之外明列 `glib-dev`，讓它能被直接套件的 curl 補抓機制處理。
- 驗證結果：2026-11-03 22:50:44（Asia/Taipei）查詢時，第 15 輪 API 仍為 `in_progress`，conclusion 為 null。此處只記錄當時狀態；接手者必須重新查詢，不可視為成功。
- 目前採用狀態：已提交，驗證待完成。這次文件整理沒有再次修改該建置邏輯，也沒有重跑工作流程。

## 本次分析：已確認的問題與尚未證實的原因

### 直接停止原因與已成功的部分

[第 14 輪日誌](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41655397482) 已出現 `[100%] Built target rime_deployer`，並安裝 librime.so.1.8.5。接著 ibus-rime 執行 pkg-config 檢查時，出現：

```text
Package 'gobject-2.0', required by 'ibus-1.0', not found
The following required packages were not found:
  - ibus-1.0
```

這次停止點是開發依賴缺漏。前面的 `cmake_minimum_required() should be called prior to ... project()` 是開發警告，沒有直接讓該輪停止；GNU 6.3.0 版本資訊本身也不是該輪的錯誤。

### 套件下載與間接依賴沒有完整驗證

第 14 輪完整 job 日誌中，`Checksum error for` 共出現 122 次；同一套件可重複出現，這不是 122 個不同套件。部分訊息前面緊接著 `md5sum: can't open ... No such file or directory`，因此不能一概當成「下載完成但雜湊不符」，也包含根本沒有成功取得檔案的情形。

具體例子：安裝 libnotify-dev 時，tazpkg 列出缺少 gdk-pixbuf-dev、glib-dev、libgio-dev、dbus-glib-dev，後續下載仍有失敗。主套件成功登錄，不能證明這些間接依賴已安裝完整。

目前 `install_packages()` 的限制：

- `tazpkg get-install ... | tee ... || true` 暫時忽略非零狀態，依賴後面的檢查決定是否停止。
- 最後只檢查直接要求的 `/var/lib/tazpkg/installed/<package>` 目錄，沒有驗證完整依賴集合與必要檔案。
- curl 補抓只在「直接套件尚未登錄」時啟動；主套件已登錄而間接依賴失敗時，可能不會啟動。
- 解析日誌使用第一個 `Checksum error` 檔名，未明確對應每個失敗的依賴；後續修復應檢查這項限制。
- runner 端 curl 補抓後已能讓部分套件安裝繼續前進；但 chroot 內下載失敗究竟是鏡像同步、索引、下載器、TLS、憑證或其他因素，現有證據尚未完整區分。不要直接宣稱其中一項已被證實。

### GitHub Actions 可行性判斷的範圍

目前日誌證明 hosted runner 已執行 sudo、bind mount、chroot 與 librime 編譯。第 14 輪約六分鐘便因依賴缺漏停止，尚未碰到工作流程的 90 分鐘上限；沒有觀察到此次是 OOM、磁碟滿或權限禁止導致失敗。

因此，繼續使用 GitHub Actions 建置有依據；完整建置耗時、尖峰磁碟空間、ISO 開機與輸入法操作仍待驗證。平台提供的資源可參考 [GitHub 官方 runner 說明](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)。

## 待處理建議（以下尚未實作）

1. **先查最新結果。** 重新查詢 [第 15 輪](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41656459179) 及其後續建置；如果已完成，補上結論、第一個實際停止點與新證據，不要沿用本文的執行中快照。
2. **先修套件下載與完整依賴檢查。** 確認必要的間接依賴都能下載、安裝並驗證；失敗時在編譯前停止。依套件庫索引驗證套件身分、架構與校驗碼，不能透過跳過校驗掩蓋問題。
3. **加入編譯前檢查。** 至少在 SliTaz builder 內先執行 `pkg-config --print-errors --exists gobject-2.0 ibus-1.0 libnotify`，並檢查 Linux API、Boost 各模組標頭；GTK 等需求依實際 CMakeLists.txt 補齊。這些檢查目前尚未加進腳本。
4. **固定完整建置輸入。** 除來源 tarball 與 ISO 外，評估固定二進位套件清單、版本、校驗碼及可取得的來源；現有 cooking URL 與套件登錄目錄不是完整可重現建置方案。
5. **維持分層驗證。** 依賴檢查、RIME/IBus 編譯、runtime 函式庫檢查、ISO 封裝、虛擬機開機及互動輸入，分別記錄結果。現有 verify-rootfs.py 以檔案存在性檢查為主，另有 ldd、Python ibus 匯入與 fc-cache 檢查；尚無自動 QEMU 開機驗證。
6. **補開機與 PVE 驗收。** 建議 QEMU 檢查 ISO 開機、VirtIO 網卡、DHCP 與瀏覽器啟動；實際環境的 gw 解析、PVE 自簽憑證操作、中文字型與 Ctrl+Space 輸入「中文測試」仍需驗收。hosted runner 不應直接假設能連到使用者內網的 gw。
7. **保留替代方案供使用者決定。** 若完整依賴機制修復成本過高，可評估 Debian 精簡 Live ISO 與 live-build。Debian 提供現成的 [ibus-rime](https://packages.debian.org/trixie/ibus-rime) 和 [rime-data-bopomofo](https://packages.debian.org/trixie/rime-data-bopomofo)，可降低自行編譯負擔；預期體積會增加，實際需量測。[live-build 套件清單文件](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-package-installation.en.html)。此替代方案尚未實作，現有基底仍是 SliTaz。

## 後續 session 如何更新這份紀錄

每次修改建置邏輯或嘗試修復時，追加「問題／證據 → 修改 → 原因 → 驗證結果 → 採用狀態」，並附 commit 與 Actions 連結。

- 區分「已提出」、「已提交」、「部分階段驗證成功」、「完整建置成功」、「PVE 操作驗收成功」及「已撤回」。
- 修改後若出現不同錯誤，記錄新停止點；不要只寫「仍失敗」而遺失前一項已跨過的證據。
- 不能將執行中或尚未取得結果的 run 記為成功。
- 已撤回的方案保留原因，避免後續 session 不知情地重做 pkg-config 原始碼編譯、僅切換鏡像等已嘗試的路徑。
- 若後續推翻本文分析，保留原始證據及日期，新增更正與新證據。
- 修改前仍應讀目前的 README、工作流程、scripts/build.sh、scripts/build-rime.sh 與 sources.lock.json；本文不取代程式碼。

建議新增紀錄格式：

```markdown
### YYYY-MM-DD HH:mm:ss — 修改目的（Asia/Taipei）

- 提交與 Actions：
- 問題及原始日誌：
- 修改位置：
- 實際變更：
- 為什麼採用：
- 驗證方式及結果：
- 目前採用狀態：
- 尚未驗證或下一步：
```

## 本次文件整理範圍

2026-11-03：回查 main 的提交差異，以及第 1～14 輪失敗日誌，整理以上紀錄並查詢第 15 輪狀態。本次只新增本文件，未實作上述待處理建議，也未觸發建置重跑。文件依現有工作流程的 Markdown paths-ignore 設定，不屬於 push 自動建置的觸發範圍。

### 2026-11-03 23:07 後 — 放棄 RIME 自行編譯，改用 SliTaz 現成 SCIM ZhuYin 套件

- 證據：第 16 輪 [Actions #41658979577](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41658979577)（commit `2806728`）已成功編譯 librime 1.8.5，卻在 ibus-rime CMake 因 `gdk-pixbuf-2.0` 間接依賴缺失失敗。當輪安裝 `libnotify-dev` 時，`gdk-pixbuf-dev` 與 `dbus-glib-dev` 下載失敗，但主套件仍被登記已安裝，導致編譯後段才發現不完整。
- 使用者決定：不再堅持 RIME；優先選能直接安裝、可輸入繁體中文注音的套件。
- 來源查核：SliTaz x86_64 cooking 套件庫列有 `scim`、`scim-tables-base`、`scim-tables-zh`；SCIM 的 `scim-tables-zh` 包含 ZhuYin／ZhuYin-Big 碼表。
- 修改：移除 RIME 自行編譯步驟、來源鎖定與相關設定腳本，改成直接安裝 SCIM/ZhuYin；Firefox 使用 SCIM XIM frontend，保留 Ctrl+Space 及中文顯示；更新說明、授權資訊與驗證條件。
- 根因對應：原本 `install_packages()` 只檢查直接要求的套件，並未追蹤出現在安裝日誌中的 `Missing package`。改成排程處理這些間接依賴，盡可能用 runner 端 curl 從鏡像取得精確套件檔，並檢查每個發現的套件是否已登記安裝；SCIM table engine、ZhuYin 碼表、VirtIO 與字型也加入發佈前檢查。
- 驗證狀態：這是來源碼修改；**仍需 GitHub Actions 確認建置結果與 PVE 內 Firefox 實際注音輸入測試**。不把套件庫中存在套件當成整體已可正常運作。
- 重要限制：SCIM 傳統 ZhuYin 是碼表輸入，非新酷音或 RIME 智慧選字；開機後首次可能仍需在 SCIM 選單挑選 ZhuYin。SliTaz cooking 套件與二進位套件取得仍可能異動。

### 2026-11-03 23:17 後 — 首次 SCIM 版工作流程靜態檢查修正

- 前一版 commit：[`8ab8dc7`](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/commit/8ab8dc705847baa57946b2ce36007d748a1ab148)；[Actions #41662333608](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41662333608)。
- 結果：`Validate scripts` 失敗，ShellCheck SC2066 指向 `for target in "$root"; do`，因只有單一 root，應改成直接判斷 mount，這輪尚未進入 Build ISO。
- 修改：以單次 `if findmnt ... | grep` 取代一元素 for 迴圈；不改變防止殘留掛載被刪除的目的。
- 待驗證：下一輪 Actions 靜態檢查、SliTaz 套件安裝、SCIM table/runtime 與 ISO 封裝。

### 2026-11-03 23:19 後 — SCIM 套件安裝成功，VirtIO PCI 檢查尚待確認

- [Actions #41662508150](https://github.com/pulipulichen/SliTaz-Firefox-Kiosk-ISO/actions/runs/41662508150) 的 Validate scripts 成功；Build ISO 階段已成功安裝 `scim` 1.4.18、`scim-tables-base` 0.5.14.1、`scim-tables-zh` 0.5.14.1 與 `wqy-microhei`；另外解析了 `gtk+`、`wqy-bitmapfont`，共驗證 6 個直接與間接套件。
- 新停止點：`verify-rootfs.py` 要求存在 `virtio_pci.ko`，但 Linux 核心也可能將 `CONFIG_VIRTIO_PCI=y` 直接編入核心而不產生模組檔，僅檢查 .ko 不足以判斷真實支援。
- 修改：允許 `modules.builtin` 或核心設定檔證明 virtio_pci 為內建，且在沒有證據時輸出現有 VirtIO 檔案與配置供定位；仍不會在未知驅動狀態下冒然通過建置。
- 待確認：SliTaz 基底是否提供此內建證據；未完成之前，不把 VirtIO 網卡支援宣稱已驗證。
