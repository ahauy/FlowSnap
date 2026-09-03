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

### Q1. SkipReason: 1 case hay 2 case?
- **Ảnh hưởng tới**: §2.2 SkipReason enum, §2.3 mapping table, §5.5 SkipReason extension, §6.3 displayReason, §7.5 T5 expected, §7.14 T14-fail expected, §14 Open questions #2, Step 3 implementation
- **Khuyến nghị của spec**: 2 case — `.notPresentedOnCurrentScreen` (chắc chắn not present) + `.presentationUnverifiable` (observation trả `nil`)
- **Vì sao**: Thành thật về uncertainty; map đúng 2 trạng thái semantic khác nhau của `OnScreenObservationResult`
- **Nếu KHÔNG theo khuyến nghị thì sao**: 1 case (chỉ `.notPresentedOnCurrentScreen`) → phải đổi §2.3 mapping, §6.3 displayReason, test T5 expected, test T14-fail expected; ambiguity giữa "chắc chắn not present" và "không biết" bị che
- [ ] Duyệt theo khuyến nghị (2 case)
- [ ] Chọn phương án khác: ___________

### Q2. Observation trả `.unverifiable` map sang Category nào?
- **Ảnh hưởng tới**: §2.3 mapping table (row `.moved + .unverifiable`), §5.4 mapping cell, §7.5 T5 expected, §14 Open questions #3
- **Khuyến nghị của spec**: `.unverifiable` (Category) với reason `.presentationUnverifiable` (SkipReason)
- **Vì sao**: Ta không biết window có present hay không — báo orange "not presented" khi không biết chắc là false-orange
- **Nếu KHÔNG theo khuyến nghị thì sao**: Map sang `.movedButNotPresented` → false-orange; user bị nói "not present" trong khi thực tế chỉ là "không xác minh được"
- [ ] Duyệt theo khuyến nghị (.unverifiable)
- [ ] Chọn phương án khác: ___________

### Q3. Re-resolve fail → reason `.presentationUnverifiable` hay `.unverifiablePlacement`?
- **Ảnh hưởng tới**: §4.5 prose, §5.4 mapping cell, §7.14 T14-fail expected, Step 5 implementation
- **Khuyến nghị của spec**: `.presentationUnverifiable` (mới, riêng cho presentation)
- **Vì sao**: Phân biệt 2 loại unverifiable — placement-level (missing element) vs presentation-level (re-resolve fail / CGWindowList fail)
- **Nếu KHÔNG theo khuyến nghị thì sao**: Dùng `.unverifiablePlacement` (đã có) → mất khả năng phân biệt 2 loại; UI banner không biết nên báo "Terminal could not be verified" chung chung
- [ ] Duyệt theo khuyến nghị (.presentationUnverifiable)
- [ ] Chọn phương án khác: ___________

---

## Tier B — Ảnh hưởng 1–2 Phase, structural

### Q4. Result model: Option A (2 enum) hay Option B (1 enum tổng hợp)?
- **Ảnh hưởng tới**: §5.1–§5.7 toàn bộ, §14 Open questions #1, Step 2, Step 3, Step 5
- **Khuyến nghị của spec**: Option A — `MoveOutcome` (giữ nguyên) + `PresentationOutcome` (mới) tách riêng
- **Vì sao**: ADR-0008 định nghĩa `MoveOutcome` là "typed result of one placement attempt sequence"; T6 sẽ tự nhiên thêm `MigrationOutcome` mà không phá model
- **Nếu KHÔNG theo khuyến nghị thì sao**: Option B (1 enum `RestorePlacementResult` với associated value) → breaking change với callers (UI, ViewModel, `RestoreIssue`); T6 khó mở rộng
- [ ] Duyệt theo khuyến nghị (Option A)
- [ ] Chọn phương án khác: ___________

### Q5. SkipReason: gộp `unverifiablePlacement` chung (a) hay tách thêm `presentationUnverifiable` (b)?
- **Ảnh hưởng tới**: §2.2 SkipReason enum, §2.3 mapping table, §2.4 conservation rule, §5.5 SkipReason extension, §6.3 displayReason, §7.5 T5 expected, §7.14 T14-fail expected, §14 Open questions #2, Step 3 implementation
- **Khuyến nghị của spec**: (b) — tách: `.unverifiablePlacement` (placement-level: thiếu AX element / setFrame thất bại state) + `.presentationUnverifiable` (presentation-level: `isOnCurrentScreen` trả `nil` / `reResolveWindowID` trả `nil`). **Cả 2 vẫn cùng Category `.unverifiable`**, chỉ khác `reason` — khớp với bảng mapping §2.3 (line 139: `.unverifiable + n/a → .unverifiable + .unverifiablePlacement`; line 142: `.moved + .unverifiable → .unverifiable + .presentationUnverifiable`) và Phase 10 §6 (line 988, 990).
- **Vì sao**: Phân biệt được "không đủ AX element" (lỗi phía placement) với "không xác minh được presentation" (lỗi phía WindowServer / lookup); UX banner + test debugging rõ hơn. Tránh nhầm với `.movedButNotPresented` (Category, chỉ dành cho khi observation chắc chắn trả `.notPresented`).
- **Nếu KHÔNG theo khuyến nghị thì sao**: (a) gộp `.unverifiablePlacement` cho cả 2 → displayReason phải chọn 1 chuỗi chung; mất khả năng phân biệt trong banner; người dùng bị nói "Terminal placement could not be verified" trong khi thực tế là "Terminal presentation could not be verified" (khác nghĩa)
- [ ] Duyệt theo khuyến nghị (tách — `(b)`)
- [ ] Chọn phương án khác: ___________

### Q6. `RestoreSummary.isFullSuccess` có strict hơn không?
- **Ảnh hưởng tới**: §2.5, §5.6, `RestoreSummaryBanner` (line 63, 69 dùng `isFullSuccess` để đổi màu), §7.13 T13, §14 Open questions
- **Khuyến nghị của spec**: yes — `isFullSuccess` phải đồng nghĩa "user nhìn thấy mọi thứ" → thêm điều kiện `movedButNotPresented == 0`
- **Vì sao**: Tránh false-green khi window đã move nhưng không present
- **Nếu KHÔNG theo khuyến nghị thì sao**: `isFullSuccess == true` dù có `.movedButNotPresented` → banner xanh, user nghĩ OK nhưng thực tế 1 window không hiện
- [ ] Duyệt theo khuyến nghị (strict)
- [ ] Chọn phương án khác: ___________

### Q7. Detection "đã qua exitFullScreen" cấu trúc nào?
- **Ảnh hưởng tới**: §4.5, Step 5 implementation, chuẩn bị `PreparationResult`
- **Khuyến nghị của spec**: (a) thêm field `exitedFullScreen: Bool` trong `PreparationResult`
- **Vì sao**: Rõ ràng, ít overhead, không tốn lookup thừa
- **Nếu KHÔNG theo khuyến nghị thì sao**:
  - (b) truy vết qua `Prepare` riêng cho fullscreen → phải tách `prepare` thành 2 hàm, sửa caller nhiều chỗ
  - (c) luôn re-resolve trước observation nếu pid còn sống → gọi `reResolveWindowID` thừa cho placement không qua fullscreen
- [ ] Duyệt theo khuyến nghị (a — field trong PreparationResult)
- [ ] Chọn phương án khác: ___________

### Q8. Timeout cho observation?
- **Ảnh hưởng tới**: §4.2 bảng quyết định, Step 1 production impl, §14 Open questions #5
- **Khuyến nghị của spec**: KHÔNG cần — `CGWindowListCopyWindowInfo` là sync C API, thường < 5ms
- **Vì sao**: API synchronous, không cần explicit timeout
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm timeout → phức tạp hóa impl vì API không async; phải chạy trên background thread
- [ ] Duyệt theo khuyến nghị (không cần timeout)
- [ ] Chọn phương án khác: ___________

### Q9. Heuristic "app chỉ có 1 window → notPresented"?
- **Ảnh hưởng tới**: §3.3 câu 5 (lookup semantics), Step 1 production impl, §14 Open questions (gốc §3.4)
- **Khuyến nghị của spec**: KHÔNG (vì race) — chỉ trả `.unverifiable(reason: .identityNotResolved)`
- **Vì sao**: App có thể tạm thời chỉ có 1 window do đang launch/close window khác
- **Nếu KHÔNG theo khuyến nghị thì sao**: Implement heuristic → false-not-presented do race; lại phải trả `.unverifiable` để an toàn
- [ ] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q10. Best-effort `reveal(bundleID:)` cho placement `.movedButNotPresented`?
- **Ảnh hưởng tới**: §4.4, §6.8, §14 Open questions #7
- **Khuyến nghị của spec**: KHÔNG trong P0.5 (chờ live experiment)
- **Vì sao**: (a) chưa có bằng chứng thực nghiệm, (b) có thể gây Space switch bất ngờ, (c) UX tốt hơn khi banner trung thực + user tự switch
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm 1 attempt → có thể gây Space flicker; nếu macOS policy chặn, attempt chỉ là no-op nhưng đã thêm complexity
- [ ] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q11. UX chấp nhận "user phải tự switch Space rồi bấm Restore lại"?
- **Ảnh hưởng tới**: §4.4 (phụ thuộc Q10), product UX policy
- **Khuyến nghị của spec**: yes cho P0.5 (P0.5 = detect+report, fix thực sự = T6)
- **Vì sao**: P0.5 scope rõ ràng là report, không phải move; T6 mới giải quyết cross-Space migration
- **Nếu KHÔNG theo khuyến nghị thì sao**: Nếu user không chấp nhận → phải có Q10 = có (thử reveal) hoặc đẩy lên T6 gộp với Q10
- [ ] Duyệt theo khuyến nghị (chấp nhận)
- [ ] Chọn phương án khác: ___________

---

## Tier C — Ảnh hưởng UI / option nhỏ

### Q12. Category/SkipReason có cần thêm field `pid` cho banner?
- **Ảnh hưởng tới**: §5.5, §5.6, `RestoreSummary` struct, `RestoreIssue` struct, §14 Open questions
- **Khuyến nghị của spec**: KHÔNG — banner chỉ hiển thị bundleID + reason text
- **Vì sao**: bundleIdentifier đã đủ để người dùng nhận biết app; `pid` là technical detail không cần cho UX
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm `pid` → 1 field thừa trong summary; UI phải render 1 dòng dài hơn
- [ ] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q13. Action button "Reveal on this desktop" trong banner?
- **Ảnh hưởng tới**: §6.4 banner UI, `RestoreSummaryBanner.swift`, Step 9
- **Khuyến nghị của spec**: KHÔNG trong P0.5 (giữ simple; T6 mới xử lý action)
- **Vì sao**: Action này cần T6 capability; P0.5 chỉ report
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm button → gọi `launcher.reveal(...)` thủ công khi user click; có thể gây Space flicker tương tự Q10
- [ ] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q14. Knob `RestoreOptions.presentationAttempt`?
- **Ảnh hưởng tới**: §4.4, `RestoreOptions` struct (file `WorkspaceRestoring.swift:10`), §14 Open questions #8
- **Khuyến nghị của spec**: KHÔNG trong P0.5 — giữ simple
- **Vì sao**: Thêm knob khi chưa có ít nhất 1 presentation behavior thật là premature
- **Nếu KHÔNG theo khuyến nghị thì sao**: Thêm enum `presentationAttempt: .none / .bestEffortOnce / .bestEffortPerPlacement` → mở rộng `RestoreOptions`, mở rộng `WorkspaceManager+Restore.swift`, mở rộng test
- [ ] Duyệt theo khuyến nghị (KHÔNG)
- [ ] Chọn phương án khác: ___________

### Q15. Test T6 (own PID): unit test hay integration test?
- **Ảnh hưởng tới**: §7.6 test design, `MockCurrentScreenVisibilityChecker` mock
- **Khuyến nghị của spec**: 1 unit test mock trả `.unverifiable` cho own PID + 1 integration test chạy 1 lần trong CI
- **Vì sao**: Unit test cover logic; integration test cover production impl với WindowServer thật
- **Nếu KHÔNG theo khuyến nghị thì sao**: Chỉ unit test → không cover production impl; chỉ integration test → khó reproduce deterministic
- [ ] Duyệt theo khuyến nghị (cả 2)
- [ ] Chọn phương án khác: ___________

### Q16. Localization: có dùng `Localizable.strings` không?
- **Ảnh hưởng tới**: §6.5 localization key mới, `RestoreSummaryBanner.swift`, `CONTEXT.md` governance
- **Khuyến nghị của spec**: chưa đọc; dùng `LocalizedStringKey` literal (giống hiện tại) nếu chưa có file
- **Vì sao**: Pattern hiện tại đã dùng literal; không cần thay đổi
- **Nếu KHÔNG theo khuyến nghị thì sao**: Nếu project đã có `Localizable.strings` → cần thêm key mới vào file; nếu dùng literal → chỉ code (đã đúng)
- [ ] Duyệt theo khuyến nghị (literal; user confirm sau khi đọc)
- [ ] Chọn phương án khác: ___________

### Q17. Test T5 (observation unverifiable) mapping Option A vs B?
- **Ảnh hưởng tới**: §7.5 T5 expected
- **Khuyến nghị của spec**: Option A — `summary.unverifiableCount == 1`, reason `.presentationUnverifiable`
- **Vì sao**: Đồng nhất với Q2
- **Nếu KHÔNG theo khuyến nghị thì sao**: Mâu thuẫn với Q2 — sẽ cần revisit
- [ ] Duyệt theo khuyến nghị (Option A)
- [ ] Chọn phương án khác: ___________

---

## Tổng kết

**17 câu hỏi** (đã khử trùng từ 32 chỗ nhắc trong file v4):

| Tier | Số câu | Ảnh hưởng |
|---|---|---|
| A (data model) | 3 (Q1, Q2, Q3) | SkipReason / Category / mapping — đụng model nhiều Phase |
| B (structural) | 8 (Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11) | 1–2 Phase, structural |
| C (UI/option) | 6 (Q12, Q13, Q14, Q15, Q16, Q17) | UI / option nhỏ |

**Lệnh user thực hiện khi duyệt**:
- Tick `[ ]` cho từng câu hỏi.
- Nếu chọn khác, ghi rõ phương án vào dòng "Chọn phương án khác: ___________".
- Khi đã tick hết, báo lại cho AI coding để bắt đầu implement theo đúng quyết định.

**Sau khi tick xong**, các câu trả lời sẽ được dùng để:
1. Khóa giá trị cuối trong `P0_5_IMPLEMENTATION_SPEC_v4.md` (sửa các `[DECIDE BEFORE IMPL]` / `[OPEN QUESTION]` còn lại thành giá trị chốt).
2. Hướng dẫn implement Step 1–13 (Phase 9) theo đúng quyết định.

---

## Lịch sử chỉnh sửa

- **v2 (file này) — sửa so với v1**:
  - **Q5**: đổi từ "tách `unverifiable` (missing element) + `movedButNotPresented` (presentation nil)" → "tách `unverifiablePlacement` (placement-level) + `presentationUnverifiable` (presentation-level), cả 2 cùng Category `.unverifiable`". Lý do: v1 nhầm lẫn với Q2/Q3 — theo §2.3 mapping + Phase 10 §6, observation trả nil phải map sang `.unverifiable` (không phải `.movedButNotPresented`); `.movedButNotPresented` Category chỉ dành cho khi observation chắc chắn trả `.notPresented`.
  - **Bảng tổng kết**: Tier B 7→8 câu (Q4–Q11), Tier C 5→6 câu (Q12–Q17), tổng 15→17 câu.
  - **Quét đối chiếu Q1–Q17 với §2.3 mapping + Phase 10 §6**: không còn cặp mâu thuẫn nào khác. Q1 và Q5 gốc nhau (SkipReason 2 case vs SkipReason tách placement/presentation) nhưng **không mâu thuẫn** — chúng hỏi 2 khía cạnh khác nhau.
