# P0.5 Implementation Spec — Open Questions Checklist

> File này gom tất cả `[DECIDE BEFORE IMPL]` và `[OPEN QUESTION]` từ `P0_5_IMPLEMENTATION_SPEC_v4.md` thành 1 danh sách duy nhất, đã khử trùng lặp, sắp xếp theo mức ảnh hưởng.
>
> **Mục đích**: user tick 1 trong 2 phương án cho mỗi câu hỏi trước khi bắt đầu implement.
>
> **Cấu trúc mỗi câu hỏi**:
> - Câu hỏi (1 dòng)
> - Ảnh hưởng tới: section/Phase bị ảnh hưởng nếu chọn khác đi
> - Khuyến nghị của spec: nguyên văn từ file spec
> - Vì sao: 1 câu rút gọn
> - Nếu KHÔNG theo khuyến nghị thì sao: hậu quả / việc phải sửa thêm
> - 2 ô tick: theo khuyến nghị / chọn khác (ghi rõ)
>
> **Lưu ý**: Câu hỏi về tên category/SkipReason (Q1) đã được chốt ở §2.2 của v4 — xem lại nếu muốn revisit.

---

## Tier A — Ảnh hưởng nhiều Phase, đụng data model

### Q1. SkipReason: bộ case nào cho 2 loại unverifiable + 1 loại chắc-chắn-not-present? (gộp Q1 + Q5 cũ)
- **Ảnh hưởng tới**: §2.2 SkipReason enum, §2.3 mapping table (line 139 `.unverifiable + n/a → .unverifiable + .unverifiablePlacement`; line 141 `.moved + .notPresented → .movedButNotPresented + .notPresentedOnCurrentScreen`; line 142 `.moved + .unverifiable → .unverifiable + .presentationUnverifiable`), §2.4 conservation rule, §5.5 SkipReason extension, §6.3 displayReason, §7.5 T5 expected, §7.14 T14-fail expected, §14 Open questions #2, Step 3 implementation
- **Khuyến nghị của spec**: **3 case SkipReason**:
  1. `.unverifiablePlacement` — placement-level: `MoveOutcome.unverifiable` (thiếu AX element / setFrame fail state)
  2. `.presentationUnverifiable` — presentation-level: `MoveOutcome.moved` + `PresentationObservation.unverifiable` (isOnCurrentScreen / reResolveWindowID trả nil)
  3. `.notPresentedOnCurrentScreen` — presentation chắc chắn: `MoveOutcome.moved` + `PresentationObservation.notPresented`

  Trong đó case 1 + case 2 **cùng Category `.unverifiable`** (chỉ khác `reason`); case 3 **Category `.movedButNotPresented`** (khác hoàn toàn).
- **Vì sao**: Thành thật về uncertainty (map đúng 3 trạng thái semantic khác nhau của `OnScreenObservationResult` + placement-level unverifiable); banner phân biệt được "placement could not be verified" vs "presentation could not be verified"; tránh nhầm với `.movedButNotPresented` (Category chỉ dành cho khi observation chắc chắn trả `.notPresented`).
- **Nếu KHÔNG theo khuyến nghị thì sao**:
  - Bỏ case 2 (chỉ dùng `.unverifiablePlacement` cho cả 2 loại unverifiable) → displayReason chọn 1 chuỗi chung; mất khả năng phân biệt trong banner
  - Bỏ case 3 (chỉ dùng `.notPresentedOnCurrentScreen`) → phải đổi §2.3 mapping, §6.3 displayReason, test T5/T14 expected; ambiguity giữa "chắc chắn not present" và "không biết" bị che
  - Bỏ cả 2 + 3 → chỉ giữ `.unverifiablePlacement`; mất hoàn toàn thông tin presentation
- [x] Duyệt theo khuyến nghị (3 case như trên)
- [ ] Chọn phương án khác: ___________

### Q2. Observation trả `.unverifiable` map sang Category nào?
- **Ảnh hưởng tới**: §2.3 mapping table (row `.moved + .unverifiable`), §5.4 mapping cell, §7.5 T5 expected, §14 Open questions #3
- **Khuyến nghị của spec**: `.unverifiable` (Category) với reason `.presentationUnverifiable` (SkipReason)
- **Vì sao**: Ta không biết window có present hay không — báo orange "not presented" khi không biết chắc là false-orange
- **Nếu KHÔNG theo khuyến nghị thì sao**: Map sang `.movedButNotPresented` → false-orange; user bị nói "not present" trong khi thực tế chỉ là "không xác minh được"
- [x] Duyệt theo khuyến nghị (.unverifiable)
- [ ] Chọn phương án khác: ___________

### Q3. Re-resolve fail → reason `.presentationUnverifiable` hay `.unverifiablePlacement`?
- **Ảnh hưởng tới**: §4.5 prose, §5.4 mapping cell, §7.14 T14-fail expected, Step 5 implementation
- **Khuyến nghị của spec**: `.presentationUnverifiable` (mới, riêng cho presentation)
- **Vì sao**: Phân biệt 2 loại unverifiable — placement-level (missing element) vs presentation-level (re-resolve fail / CGWindowList fail)
- **Nếu KHÔNG theo khuyến nghị thì sao**: Dùng `.unverifiablePlacement` (đã có) → mất khả năng phân biệt 2 loại; UI banner không biết nên báo "Terminal could not be verified" chung chung
- [x] Duyệt theo khuyến nghị (.presentationUnverifiable)
- [ ] Chọn phương án khác: ___________

---

## Tier B — Ảnh hưởng 1–2 Phase, structural

### Q4. Result model: Option A (2 enum) hay Option B (1 enum tổng hợp)?
- **Ảnh hưởng tới**: §5.1–§5.7 toàn bộ, §14 Open questions #1, Step 2, Step 3, Step 5
- **Khuyến nghị của spec**: Option A — `MoveOutcome` (giữ nguyên) + `PresentationOutcome` (mới) tách riêng
- **Vì sao**: ADR-0008 định nghĩa `MoveOutcome` là "typed result of one placement attempt sequence"; T6 sẽ tự nhiên thêm `MigrationOutcome` mà không phá model
- **Nếu KHÔNG theo khuyến nghị thì sao**: Option B (1 enum `RestorePlacementResult` với associated value) → breaking change với callers (UI, ViewModel, `RestoreIssue`); T6 khó mở rộng
- [x] Duyệt theo khuyến nghị (Option A)
- [ ] Chọn phương án khác: ___________

### Q5. `RestoreSummary.isFullSuccess` có strict hơn không?
- **Ảnh hưởng tới**: §2.5, §5.6, `RestoreSummaryBanner` (line 63, 69 dùng `isFullSuccess` để đổi màu), §7.13 T13, §14 Open questions
- **Khuyến nghị của spec**: yes — `isFullSuccess` phải đồng nghĩa "user nhìn thấy mọi thứ" → thêm điều kiện `movedButNotPresented == 0`
- **Vì sao**: Tránh false-green khi window đã move nhưng không present
- **Nếu KHÔNG theo khuyến nghị thì sao**: `isFullSuccess == true` dù có `.movedButNotPresented` → banner xanh, user nghĩ OK nhưng thực tế 1 window không hiện
- [x] Duyệt theo khuyến nghị (strict)
- [ ] Chọn phương án khác: ___________

### Q6. Detection "đã qua exitFullScreen" cấu trúc nào?
- **Ảnh hưởng tới**: §4.5, Step 5 implementation, chuẩn bị `PreparationResult`
- **Khuyến nghị của spec**: (a) thêm field `exitedFullScreen: Bool` trong `PreparationResult`
- **Vì sao**: Rõ ràng, ít overhead, không tốn lookup thừa
- **Nếu KHÔNG theo khuyến nghị thì sao**:
  - (b) truy vết qua `Prepare` riêng cho fullscreen → phải tách `prepare` thành 2 hàm, sửa caller nhiều chỗ
  - (c) luôn re-resolve trước observation nếu pid còn sống → gọi `reResolveWindowID` thừa cho placement không qua fullscreen
- [x] Duyệt theo khuyến nghị (a — field trong PreparationResult)
- [ ] Chọn phương án khác: ___________

### Q7. Timeout cho observation?
- **Ảnh hưởng tới**: §4.2 bảng quyết định, Step 1 production impl, §14 Open questions #5
- **Khuyến nghị của spec**: KHÔNG cần — `CGWindowListCopyWindowInfo` là sync C API, thường < 5ms
- **Vì sao**: API synchronous, không cần explicit timeout
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm timeout → phức tạp hóa impl vì API không async; phải chạy trên background thread
- [x] Duyệt theo khuyến nghị (không cần timeout)
- [ ] Chọn phương án khác: ___________

### Q8. Heuristic "app chỉ có 1 window → notPresented"?
- **Ảnh hưởng tới**: §3.3 câu 5 (lookup semantics), Step 1 production impl, §14 Open questions (gốc §3.4)
- **Khuyến nghị của spec**: KHÔNG (vì race) — chỉ trả `.unverifiable(reason: .identityNotResolved)`
- **Vì sao**: App có thể tạm thời chỉ có 1 window do đang launch/close window khác
- **Nếu KHÔNG theo khuyến nghị thì sao**: Implement heuristic → false-not-presented do race; lại phải trả `.unverifiable` để an toàn
- [x] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q9. Best-effort `reveal(bundleID:)` cho placement `.movedButNotPresented`?
- **Ảnh hưởng tới**: §4.4, §6.8, §14 Open questions #7
- **Khuyến nghị của spec**: KHÔNG trong P0.5 (chờ live experiment)
- **Vì sao**: (a) chưa có bằng chứng thực nghiệm, (b) có thể gây Space switch bất ngờ, (c) UX tốt hơn khi banner trung thực + user tự switch
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm 1 attempt → có thể gây Space flicker; nếu macOS policy chặn, attempt chỉ là no-op nhưng đã thêm complexity
- [x] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q10. UX chấp nhận "user phải tự switch Space rồi bấm Restore lại"?
- **Ảnh hưởng tới**: §4.4 (phụ thuộc Q9), product UX policy
- **Khuyến nghị của spec**: yes cho P0.5 (P0.5 = detect+report, fix thực sự = T6)
- **Vì sao**: P0.5 scope rõ ràng là report, không phải move; T6 mới giải quyết cross-Space migration
- **Nếu KHÔNG theo khuyến nghị thì sao**: Nếu user không chấp nhận → phải có Q9 = có (thử reveal) hoặc đẩy lên T6 gộp với Q9
- [x] Duyệt theo khuyến nghị (chấp nhận)
- [ ] Chọn phương án khác: ___________

---

## Tier C — Ảnh hưởng UI / option nhỏ

### Q11. Category/SkipReason có cần thêm field `pid` cho banner?
- **Ảnh hưởng tới**: §5.5, §5.6, `RestoreSummary` struct, `RestoreIssue` struct, §14 Open questions
- **Khuyến nghị của spec**: KHÔNG — banner chỉ hiển thị bundleID + reason text
- **Vì sao**: bundleIdentifier đã đủ để người dùng nhận biết app; `pid` là technical detail không cần cho UX
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm `pid` → 1 field thừa trong summary; UI phải render 1 dòng dài hơn
- [x] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q12. Action button "Reveal on this desktop" trong banner?
- **Ảnh hưởng tới**: §6.4 banner UI, `RestoreSummaryBanner.swift`, Step 9
- **Khuyến nghị của spec**: KHÔNG trong P0.5 (giữ simple; T6 mới xử lý action)
- **Vì sao**: Action này cần T6 capability; P0.5 chỉ report
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm button → gọi `launcher.reveal(...)` thủ công khi user click; có thể gây Space flicker tương tự Q9
- [x] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q13. Knob `RestoreOptions.presentationAttempt`?
- **Ảnh hưởng tới**: §4.4, `RestoreOptions` struct (file `WorkspaceRestoring.swift:10`), §14 Open questions #8
- **Khuyến nghị của spec**: KHÔNG trong P0.5 — giữ simple
- **Vì sao**: Thêm knob khi chưa có ít nhất 1 presentation behavior thật là premature
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm enum `presentationAttempt: .none / .bestEffortOnce / .bestEffortPerPlacement` → mở rộng `RestoreOptions`, mở rộng `WorkspaceManager+Restore.swift`, mở rộng test
- [x] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q14. Test T6 (own PID): unit test hay integration test?
- **Ảnh hưởng tới**: §7.6 test design, `MockCurrentScreenVisibilityChecker` mock
- **Khuyến nghị của spec**: 1 unit test mock trả `.unverifiable` cho own PID + 1 integration test chạy 1 lần trong CI
- **Vì sao**: Unit test cover logic; integration test cover production impl với WindowServer thật
- **Nếu KHÔNG theo khuyến nghị thì sao**: Chỉ unit test → không cover production impl; chỉ integration test → khó reproduce deterministic
- [x] Duyệt theo khuyến nghị (cả 2)
- [ ] Chọn phương án khác: ___________

### Q15. Localization: có dùng `Localizable.strings` không?
- **Ảnh hưởng tới**: §6.5 localization key mới, `RestoreSummaryBanner.swift`, `CONTEXT.md` governance
- **Khuyến nghị của spec**: chưa đọc; dùng `LocalizedStringKey` literal (giống hiện tại) nếu chưa có file
- **Vì sao**: Pattern hiện tại đã dùng literal; không cần thay đổi
- **Nếu KHÔNG theo khuyến nghị thì sao**: Nếu project đã có `Localizable.strings` → cần thêm key mới vào file; nếu dùng literal → chỉ code (đã đúng)
- [x] Duyệt theo khuyến nghị (literal; user confirm sau khi đọc)
- [ ] Chọn phương án khác: ___________

### Q16. Test T5 (observation unverifiable) mapping Option A vs B?
- **Ảnh hưởng tới**: §7.5 T5 expected
- **Khuyến nghị của spec**: Option A — `summary.unverifiableCount == 1`, reason `.presentationUnverifiable`
- **Vì sao**: Đồng nhất với Q2
- **Nếu KHÔNG theo khuyến nghị thì sao**: Mâu thuẫn với Q2 — sẽ cần revisit
- [x] Duyệt theo khuyến nghị (Option A)
- [ ] Chọn phương án khác: ___________

---

## Tổng kết

**16 câu hỏi** (đã khử trùng từ 32 chỗ nhắc trong file v4; gộp Q1+Q5 cũ thành 1 Q1 duy nhất):

| Tier | Số câu | Ảnh hưởng |
|---|---|---|
| A (data model) | 3 (Q1, Q2, Q3) | SkipReason / Category / mapping — đụng model nhiều Phase |
| B (structural) | 7 (Q4, Q5, Q6, Q7, Q8, Q9, Q10) | 1–2 Phase, structural |
| C (UI/option) | 6 (Q11, Q12, Q13, Q14, Q15, Q16) | UI / option nhỏ |

**Lệnh user thực hiện khi duyệt**:
- Tick `[ ]` cho từng câu hỏi.
- Nếu chọn khác, ghi rõ phương án vào dòng "Chọn phương án khác: ___________".
- Khi đã tick hết, báo lại cho AI coding để bắt đầu implement theo đúng quyết định.

**Sau khi tick xong**, các câu trả lời sẽ được dùng để:
1. Khóa giá trị cuối trong `P0_5_IMPLEMENTATION_SPEC_v4.md` (sửa các `[DECIDE BEFORE IMPL]` / `[OPEN QUESTION]` còn lại thành giá trị chốt).
2. Hướng dẫn implement Step 1–13 (Phase 9) theo đúng quyết định.

---

## Lịch sử chỉnh sửa

- **v3 (file này) — sửa so với v2**:
  - **Gộp Q1 cũ + Q5 cũ thành Q1 mới duy nhất**: cả 2 hỏi cùng 1 quyết định (SkipReason có `.presentationUnverifiable` riêng hay không) dưới 2 hình thức. Khuyến nghị gộp: **3 case SkipReason** (`.unverifiablePlacement` + `.presentationUnverifiable` + `.notPresentedOnCurrentScreen`); case 1+2 cùng Category `.unverifiable`, case 3 Category `.movedButNotPresented`.
  - **Đánh số lại**: Q6-Q17 cũ → Q5-Q16 (lùi 1). Tổng 17 → 16 câu.
  - **Cập nhật tham chiếu trong text** (regex `Q1[0-7]`) theo mapping 6→5, 7→6, ..., 17→16.
- **v2 — sửa so với v1**:
  - **Q5**: đổi từ "tách `unverifiable` (missing element) + `movedButNotPresented` (presentation nil)" → "tách `unverifiablePlacement` (placement-level) + `presentationUnverifiable` (presentation-level), cả 2 cùng Category `.unverifiable`". Lý do: v1 nhầm lẫn với Q2/Q3 — theo §2.3 mapping + Phase 10 §6, observation trả nil phải map sang `.unverifiable` (không phải `.movedButNotPresented`); `.movedButNotPresented` Category chỉ dành cho khi observation chắc chắn trả `.notPresented`.
  - **Bảng tổng kết**: Tier B 8→7 câu (Q4–Q10), Tier C 6 câu (Q11–Q16), tổng 17→16 câu.
  - **Quét đối chiếu Q1–Q16 với §2.3 mapping + Phase 10 §6**: không còn cặp mâu thuẫn nào. Q1 mới đã gộp Q1 cũ + Q5 cũ thành 1 câu duy nhất về SkipReason (3 case).
