# War Room Skills — STATUS

> **Agent／人類接續入口。** 進度與 Phase 邊界以本檔為準；行為細節仍以 `skills/` + 未來 spec 為準。  
> **Date:** 2026-07-22  
> **Design chat:** §1–§4 人點頭；spec-review ✅ Approved；plan Tasks 1–20 **scripts-green**（含 Chunk 6）；S1–S14 手動待跑；hosted web shell＝平行規格軌道

## 〇、一句話

**V0（現況）**＝單倉／少根 locate 雙報告。  
**目標**＝母夾 OS（P1）→ 重裝備本地（P2）→ 雲端 Pro／B（P3）。  
**P1 設計 spec：** [`docs/superpowers/specs/2026-07-22-war-room-os-p1-design.md`](docs/superpowers/specs/2026-07-22-war-room-os-p1-design.md)

**P1 形狀釘死：** skill MD + hub 檔案契約 + 僅三腳本（`assert_gate`／install allowlist／verify degraded-aware）。禁止 FSM 引擎、survey daemon、上傳實作、router binary。

## 一、Phase 地圖

| Phase | 名稱 | 主要解決 | 狀態 |
|-------|------|----------|------|
| **V0** | Locate 儀式 | 症狀→雙報告；pin；硬停；soft CTA 文案 | **已落地** |
| **P1** | 母夾 OS + 薄流水線 | init→orient→CONFIRM→locate；足跡；preview；survey／section-gate；routing B；硬閘門 | **scripts-green**（Tasks 1–20 ✅／Chunk 6 已修）；S1–S14 手動待跑；合併待決 |
| **Web shell** | Hosted `/:locale` + login + SEO 槽 | 與 skills 平行；規格在 SelfAutoBuz；**非** locate 主幹 | **待開 Chat 1（spec/plan only）** |
| **P2** | 重裝備本地 | graphify／等價**全圖**；coverage 閘；long-task + AUTO_DECIDED；更深 service-map | **未開始** |
| **P3** | 雲端 Pro／B | UploadManifest 上傳；加強版結果；Architecture Pass／訂閱 | **未開始**（app scaffold only） |

### P1 vs P2 service-map 線

- **P1**＝RootRef 盤點 + 熱路徑預算（SCAN_PLAN 標記）+ 缺口追問  
- **P2**＝graphify／等價全圖 + 更深 map  

### P1 成功定義（可驗收 YES）

1. 雙報告 `WAR-ROOM-OWNER.md` + `WAR-ROOM-LOCATE.md`  
2. STATUS／RUNS 更新（足跡續跑）  
3. localhost preview：**fail-soft**（失敗不擋 DONE；MD+足跡仍算成功）  
4. soft CTA：站點 TBD **不擋**成功；本地免註冊  
5. 母夾多 repo：SCAN_PLAN → CONFIRM → 再深挖；`assert_gate` 為 locate 前唯一硬閘  
6. RootRef `missing`／`external_ref` + GapQuestion（分析後追問）  
7. 一句話啟用：停在確認閘，不自動深挖  
8. survey 預設 SKIP；MUST 見下方謂詞；`run_id` session ≤1  
9. section-gate-review：≤2 輪、禁遞迴、≤6 agent／節；APPROVE_WITH_CHANGES→checklist  
10. 模型路由 B（L0–L3；slug 可配；禁假裝 L3）  
11. **Mode 驗收：** 預設 `degraded`；無 RunEnvelope dispatch 帳 → 禁 `full`；verify 對假 full＝**FAIL**；`degraded`＝合法成功  

### P1 NON-GOAL

graphify 全圖、coverage 強制、long-task 代決（DECISIONS 可預留 `AUTO_DECIDED` kind，**P1 禁寫入行為**）、雲端上傳行為、100% 證 nested、Backstage IDP、整庫上傳、迷你 runtime。

### P2 成功（薄）／NON-GOAL

- **成功：** 可選全圖產物；coverage 閘可開；long-task 代決 + 交帳  
- **NON-GOAL：** 取代本地雙報告；強迫上雲  

### P3 成功（薄）／NON-GOAL

- **成功：** UploadManifest 上傳單元 → 加強版 UI；付費 Pass  
- **NON-GOAL：** 整母夾 rsync；signup wall 擋本地報告  

### 「100% 證明 nested」

無平台不可竄改收據 → 不當 SLA。P1 只做記帳 + 預設 degraded。

## 二、能力對照（缺口 → Phase）— §3 鎖定

| 問題 | V0 | P1 | P2 | P3 |
|------|----|----|----|-----|
| 單倉 vibing 定位 | YES | YES | YES | YES |
| 非工程雙報告 | YES | YES | YES | YES |
| 母夾多 repo＋確認後深挖 | NO | scripts（assert_gate smoke ✅） | YES | YES |
| 少掛 repo／監控缺口追問 | NO | 待 S1–S14 | YES | YES |
| 足跡／是否處理過 | NO | scripts（hub/RUNS stub） | YES | YES 雲端 |
| 一句話啟用分析 | NO | 待 S1–S14 | YES | YES |
| 本地 preview wow | NO | scripts（fail-soft path ✅） | YES | YES |
| 該時上網對齊先例 | NO | 待 S1–S14 | YES | YES |
| 設計段落自動 3 審 | NO | 待 S1–S14 | YES | YES |
| 模型依難度／額度降級 | NO | 待 S1–S14 | YES | YES |
| 假 full nested 綠燈 | 弱 | scripts ✅ FAIL 假 full | 更強 | 更強 |
| Graphify 級全圖 | NO | NO | YES | YES |
| coverage 強制 | NO | NO | YES | 可接 |
| long-task 代決＋交帳 | NO | NO | YES | 可同步 |
| 註冊看加強版／真·B wow | NO | 僅軟 CTA | 僅軟 CTA | YES |
| 100% 證明 nested | NO | NO | 仍難 | 仍難 |

**P1 做完**＝上表 P1 欄 YES 列（**現況：** scripts-green；S1–S14 manual checklist 後才誠實標 YES）。**P1+P2+P3**＝practically 全表；僅 100% nested 除外。

## 三、穩定介面（schema-only；P1 可 stub）

| 介面 | 最小欄位／規則 |
|------|----------------|
| **RunEnvelope** | `schema_version`, `pipeline_id`, `run_id`, `phase`, artifact 指標, `mode`, survey_refs, gap_ids；**per-run**（非全域 FSM） |
| **CONFIRM** | `confirm_kind=scan_plan`, `subject_ref`, `payload_hash`, timestamp；hash 變→`stale_confirm` |
| **RootRef** | `presence: checked_out\|missing\|external_ref\|submodule` |
| **GapQuestion** | kind（missing_repo\|observability\|owner\|deploy\|contract）, why_blocks_hot_path, owner_action, unanswered? |
| **UploadManifest** | schema_version, path allowlist, redaction, 禁整夾；**P1 不上傳** |
| **DECISIONS** | 預留 `source=human\|auto`／`AUTO_DECIDED`；**P1 禁代決寫入** |

## 四、Survey MUST 謂詞（可判定）

MUST 若且唯若其一：未知部署拓撲且會改假設；關鍵 RootRef=`missing`/`external_ref` 且在 SCAN_PLAN 熱路徑；owner 明示要先例；fresh reviewer 升級。  
**鐵證**＝path + quote（檔案可核）。否則 SKIP。

## 五、情境矩陣 P1（S1–S14）

| ID | 情境 | 行為 |
|----|------|------|
| S1 | 空母夾 | init+orient；無 root 不深挖 |
| S1b | 稍後加 repo | 再 orient；新 SCAN_PLAN；舊 CONFIRM stale |
| S2 | 多 `.git` root | orient→CONFIRM→locate（預算／熱路徑） |
| S3 | vibing 單倉 | **仍要**輕量 SCAN_PLAN+CONFIRM（不跳過閘門） |
| S4 | path 鐵證 | locate；survey SKIP |
| S5 | 缺 deploy/infra | GapQuestion；熱路徑則 MUST 短 survey |
| S6 | 缺監控／DB | 分析後追問 |
| S7 | 一句話 install+分析 | → awaiting_confirm；**不**自動 analyzing |
| S8 | pin 失敗 | 禁 analyzing |
| S9 | 設計 § 過閘 | section-gate；結果=`go_next`（≠ Mode） |
| S10 | skip 上網 | survey SKIP |
| S11 | CONFIRM 後交付 | 雙 MD + RUNS + preview fail-soft + soft CTA |
| S12 | 續跑 | 讀 STATUS/RUNS；不重 init 洗確認 |
| S13 | 拒確認／改 plan | 清／重 CONFIRM；hash 不符禁 analyzing |
| S14 | stale CONFIRM | phase=`stale_confirm`；重 orient／confirm |

**欄位分開：** `RunEnvelope.phase`（含 awaiting_confirm）≠ `Mode`（degraded｜full｜…）≠ section-gate `go_next`。

## 六、設計決策鎖

| 決策 | 選擇 |
|------|------|
| 架構 | 做法 2 |
| Model routing | B |
| Process skills | research-survey-review + section-gate-review |
| section-gate | OS 編排呼叫；不掛死 brainstorming |

### 設計章節進度

| 節 | 狀態 |
|----|------|
| §1 | 鎖＋三審通過 |
| §2 | 修訂鎖＋三審通過 |
| §3 | 人點頭；must_fix 已吸納 |
| §4 | 人點頭 |
| Spec | `docs/superpowers/specs/2026-07-22-war-room-os-p1-design.md`（✅ Approved） |
| Implementation plan | `docs/superpowers/plans/2026-07-22-war-room-os-p1.md`（Tasks 1–20 ✅／Chunk 6；checklist 已落地） |
| Manual checklist | `coverage/p1-manual-checklist.md`（S1–S14 勾選待跑） |

### §3 section-gate 紀錄

| Lens | Agent | Verdict |
|------|-------|---------|
| 產品 | 45ef58a6-dc6d-4d70-933c-662508b3b363 | APPROVE_WITH_CHANGES |
| 工程 | 623a260e-7371-4e7d-abdb-eb974ac03ab9 | APPROVE_WITH_CHANGES |
| 擴展 | 5d03c1b4-0840-4bdd-ac5c-7c93b4a33c72 | APPROVE_WITH_CHANGES |

## 七、§4 草案 — 錯誤／降級／小白路徑

### 小白一句話快樂路徑

1. Cursor 開母資料夾  
2. 「幫我安裝 War Room 然後開始分析」  
3. Agent：install（禁擅自 `--force`）→ 人話列出將掃的 folders＋時間 →「回確認開始」  
4. 用戶：確認  
5. 深挖（可選短 survey；可說跳過上網）→ 雙報告 → 開 localhost preview → 軟 CTA  

### 降級表

| 失敗 | 行為 |
|------|------|
| pin 失敗 | 禁 analyzing；owner 語言恢復 |
| 無 CONFIRM／hash 不符 | assert_gate 硬停 |
| nested 不可用／未派 | Mode=degraded；仍可交雙 MD |
| survey 預算／無模型 | SKIP 或 degraded_model；繼續本地 |
| preview 起不來 | 記 RUNS；不擋 DONE |
| 站點 TBD | CTA「not published yet」 |
| 用戶拒確認 | 停在 awaiting_confirm；可改 plan |

## 八、下一步

1. **合併** `feature/war-room-os-p1`（Chunk 6 已綠）；若 `~/.cursor/skills` 曾被舊 smoke 指到 worktree，合併後重跑 `scripts/install.sh`  
2. 依 `coverage/p1-manual-checklist.md` 跑 S1–S14；全綠後才將能力表 P1 欄標 YES  
3. **平行：** 開 Hosted web shell Chat 1（規格／計劃；Grok 4.5 三審）→ 產出  
   `SelfAutoBuz/docs/superpowers/specs/YYYY-MM-DD-war-room-web-shell-design.md` + plan；**本 repo 不寫 FE/BE**  
4. Web Chat 2＝shell FE；Chat 3＝plan 標出的 API 缺口；Chat 4（可選）＝skills CTA URL 小改  
5. 任何 Phase／成功定義變更 → **先改本 STATUS**

## 九、相關路徑

| 路徑 | 角色 |
|------|------|
| 本 repo | Skills／P1 OS SSOT |
| `docs/superpowers/plans/2026-07-22-war-room-os-p1.md` | P1 + Chunk 6 + web 平行軌道 |
| `../war-room-app` | API／P3；`PRODUCT-LOCKS` |
| `../war-room-web-design` | FE design locks |
| `../SelfAutoBuz/docs/research/war-room/` | research + SEO stack |
| `../SelfAutoBuz/docs/superpowers/specs/*war-room*` | 跨產品 specs |
| `README.md` | 短入口 → 本檔 |
