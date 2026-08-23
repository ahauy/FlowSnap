# FlowSnap

> **Your Mac. Your Layout. Your Flow.**

FlowSnap là một ứng dụng quản lý cửa sổ dành cho macOS, lấy cảm hứng từ
trải nghiệm Snap Layouts của Windows 11 nhưng được thiết kế theo cách tự
nhiên hơn cho hệ sinh thái Mac.

Mục tiêu của FlowSnap không chỉ là "chia đôi màn hình".

FlowSnap hướng tới việc trở thành một **Workspace & Window Manager cho
macOS**: giúp người dùng sắp xếp cửa sổ nhanh, ghi nhớ cách làm việc,
quản lý nhiều màn hình và quan trọng nhất là giữ cho ứng dụng mới mở **ở
đúng không gian làm việc hiện tại** thay vì làm người dùng bị đưa sang
một Desktop/Space khác ngoài ý muốn.

------------------------------------------------------------------------

# 1. Ý tưởng cốt lõi

Trải nghiệm window management mặc định của macOS có thể khiến người dùng
phải:

-   Tự kéo và resize cửa sổ.
-   Sử dụng Split View.
-   Chuyển qua lại giữa các Spaces.
-   Tự sắp xếp lại cửa sổ mỗi khi bắt đầu một công việc mới.
-   Khó duy trì một bố cục làm việc cố định.
-   Đôi khi bị chuyển sang một Space khác khi mở hoặc kích hoạt ứng
    dụng.

FlowSnap giải quyết vấn đề này bằng một nguyên tắc:

> **Người dùng quyết định cửa sổ ở đâu. FlowSnap lo phần còn lại.**

------------------------------------------------------------------------

# 2. Tầm nhìn sản phẩm

FlowSnap bắt đầu từ một window snapping utility, nhưng mục tiêu dài hạn
là:

> **Biến desktop Mac thành một không gian làm việc có thể điều khiển,
> lưu lại và khôi phục.**

Ví dụ người dùng có một workflow:

``` text
CODING WORKSPACE

┌───────────────────────────────┬───────────────┐
│                               │               │
│            VS Code            │    Chrome     │
│                               │               │
│                               ├───────────────┤
│                               │   Terminal    │
│                               │               │
└───────────────────────────────┴───────────────┘
```

FlowSnap có thể ghi nhớ toàn bộ bố cục này.

Lần sau người dùng chỉ cần:

> **Restore Coding Workspace**

và FlowSnap sẽ cố gắng đưa mọi thứ trở lại đúng vị trí.

------------------------------------------------------------------------

# 3. Những tính năng nổi bật

Đây là phần quan trọng nhất của FlowSnap.

## 3.1. Windows 11-style Snap

Người dùng có thể kéo cửa sổ vào các vùng trên màn hình.

### Trái / phải

``` text
┌───────────────────────┬───────────────────────┐
│                       │                       │
│       VS Code         │        Chrome         │
│                       │                       │
│                       │                       │
└───────────────────────┴───────────────────────┘
```

Kéo cửa sổ sang trái:

> Chiếm 50% màn hình.

Kéo sang phải:

> Chiếm 50% màn hình còn lại.

------------------------------------------------------------------------

# 4. Snap 4 góc

FlowSnap hỗ trợ nhanh:

``` text
┌────────────────┬────────────────┐
│                │                │
│   Top Left     │   Top Right    │
│      25%       │      25%       │
├────────────────┼────────────────┤
│                │                │
│ Bottom Left    │  Bottom Right  │
│      25%       │      25%       │
└────────────────┴────────────────┘
```

Điều này đặc biệt hữu ích khi người dùng có màn hình lớn.

------------------------------------------------------------------------

# 5. Snap Layouts

Đây là một trong những tính năng quan trọng nhất.

Khi người dùng kéo hoặc kích hoạt layout picker, FlowSnap có thể hiển
thị:

``` text
┌───────────────┬───────────────┐
│               │               │
│      50%      │      50%      │
│               │               │
└───────────────┴───────────────┘

┌───────────────────────┬───────┐
│                       │       │
│          70%          │  30%  │
│                       │       │
└───────────────────────┴───────┘

┌──────────┬──────────┬──────────┐
│    A     │    B     │    C     │
└──────────┴──────────┴──────────┘
```

Người dùng chọn layout → FlowSnap tự sắp xếp cửa sổ.

------------------------------------------------------------------------

# 6. Tỷ lệ tùy chỉnh

Không giới hạn ở 50/50.

FlowSnap có thể hỗ trợ:

-   50/50
-   60/40
-   70/30
-   75/25
-   80/20
-   Custom

Ví dụ:

``` text
┌──────────────────────────┬───────────┐
│                          │           │
│          VS Code         │  Browser  │
│                          │           │
│                          │           │
└──────────────────────────┴───────────┘
             70%               30%
```

Người dùng cũng có thể kéo đường phân cách để điều chỉnh.

------------------------------------------------------------------------

# 6.1. ⭐ Kéo đường phân cách chung — Adaptive Multi-Window Resize

Việc "kéo đường phân cách để điều chỉnh" ở mục 6 mới chỉ đúng cho
trường hợp đơn giản: 2 cửa sổ, 1 đường chia. Nhưng với một layout nhiều
cửa sổ như ví dụ ở mục 2:

``` text
┌───────────────────────────────┬───────────────┐
│                               │               │
│            VS Code            │    Chrome     │
│                               │               │
│                               ├───────────────┤
│                               │   Terminal    │
│                               │               │
└───────────────────────────────┴───────────────┘
```

Nếu người dùng kéo **đường phân cách dọc** giữa VS Code và cột bên
phải, thì cả Chrome lẫn Terminal (2 cửa sổ cùng dính vào đường đó) đều
phải resize theo cùng lúc — chứ không phải chỉ VS Code đổi, còn Chrome
và Terminal đứng yên:

``` text
Kéo đường dọc sang phải
        ↓
┌─────────────────────────┬───────────────────┐
│                         │                   │
│         VS Code         │      Chrome       │
│        (rộng hơn)       │                   │
│                         ├───────────────────┤
│                         │      Terminal     │
│                         │                   │
└─────────────────────────┴───────────────────┘
```

Ngược lại, nếu người dùng kéo **đường phân cách ngang** giữa Chrome và
Terminal, chỉ 2 cửa sổ đó thay đổi — VS Code không bị ảnh hưởng, vì
cạnh đó không chạm tới VS Code.

Nói cách khác: **kéo một đường phân cách sẽ resize tất cả cửa sổ có
cạnh nằm trên đường đó**, không phải kéo từng cửa sổ một cách rời rạc.

## Vì sao cần

Đây là hành vi tiêu chuẩn của mọi layout đa cửa sổ tử tế (giống split
pane trong IDE, hoặc các tiling window manager) — thiếu nó, layout
nhiều-hơn-2-cửa-sổ sẽ luôn cảm giác "vỡ": người dùng kéo 1 cửa sổ thì
lộ ra khoảng trống hoặc đè lên cửa sổ khác, phải tự chỉnh tay từng cái.

## Lưu ý kỹ thuật

-   **Cần một Layout Graph, không chỉ danh sách frame rời rạc**: để
    biết "đường phân cách nào đang chạm cửa sổ nào", FlowSnap cần lưu
    layout đang active dưới dạng cấu trúc có quan hệ không gian (ví dụ
    BSP tree hoặc constraint graph giữa các zone), chứ không thể chỉ
    lưu tọa độ (x, y, w, h) độc lập cho từng cửa sổ. Đây là phần mở
    rộng trực tiếp của Layout Engine đã nêu ở mục 5/6, và liên quan
    chặt tới Window Groups (mục 14) và Layout Editor (mục 19).
-   **Chỉ áp dụng cho cửa sổ thuộc cùng 1 layout do FlowSnap quản lý**:
    hai cửa sổ tình cờ nằm sát nhau nhưng không qua Snap/Layout của
    FlowSnap thì không tự động "dính" — tránh hành vi bất ngờ.
-   **Phát hiện cạnh chung (collinear edge detection)**: khi con trỏ
    hover gần 1 cạnh, cần tìm tất cả zone có cạnh trùng phương và
    trùng vị trí với cạnh đó (không chỉ 2 cửa sổ liền kề trực tiếp),
    rồi đổi cursor thành resize-cursor để báo hiệu có thể kéo.
-   **Xử lý T-junction**: như ví dụ trên, cạnh dọc là cạnh chung của
    3 cửa sổ (VS Code với cả Chrome và Terminal) nhưng cạnh ngang chỉ
    là cạnh chung của 2 cửa sổ (Chrome và Terminal). Logic resize phải
    phân biệt đúng "cạnh nào thuộc về những cửa sổ nào" để không resize
    nhầm.
-   **Tôn trọng min-size**: mỗi app có kích thước tối thiểu khác nhau;
    khi kéo, cần giới hạn không cho zone nào nhỏ hơn min-size của app
    bên trong, và dừng đường kéo lại đúng lúc thay vì đè cửa sổ.
-   **Live resize vs resize-on-release**: nên ưu tiên live resize
    (cập nhật liên tục khi kéo, giống IDE) để cảm giác tự nhiên, nhưng
    phải đảm bảo không block main thread và không gọi AX API quá dày
    đặc trong lúc kéo (liên hệ mục 52 — Performance).
-   Tính năng này nên đi cùng **Custom layouts** ở MVP 2 vì cùng dựa
    trên Layout Engine, nhưng phần Layout Graph/collinear-edge có độ
    phức tạp gần với các tính năng ở MVP 3 (Window Groups) — có thể
    coi là cầu nối giữa 2 giai đoạn.

------------------------------------------------------------------------

# 7. Snap Preview

Khi người dùng kéo một cửa sổ tới cạnh màn hình, FlowSnap không lập tức
thay đổi kích thước.

Nó hiển thị preview:

``` text
┌─────────────────────────────────────┐
│                                     │
│ ┌───────────────────┐               │
│ │                   │               │
│ │   Snap Preview    │               │
│ │                   │               │
│ └───────────────────┘               │
│                                     │
└─────────────────────────────────────┘
```

Thả chuột:

> Preview trở thành vị trí thật.

Điều này giúp trải nghiệm giống Windows 11 nhưng vẫn có thể được thiết
kế theo phong cách macOS.

------------------------------------------------------------------------

# 7.1. ⭐ Snap Layout Picker khi kéo lên cạnh trên (Windows 11-style)

Đây là phần mở rộng trực tiếp của Snap Preview (mục 7) và Snap Layouts
(mục 5): thay vì chỉ có 1 vùng preview đơn khi kéo ra cạnh, khi người
dùng kéo cửa sổ chạm tới **cạnh trên cùng màn hình**, FlowSnap hiển thị
hẳn một **Layout Picker** để người dùng kéo-thả trực tiếp vào đúng ô
mong muốn — giống hệt Snap Layouts của Windows 11.

## Hành vi

``` text
Người dùng bắt đầu kéo cửa sổ (giữ title bar)
        ↓
Con trỏ tiến gần cạnh trên cùng màn hình
        ↓
FlowSnap hiện overlay Layout Picker tại đó
        ↓
┌───────────────────────────────────────────┐
│   ┌─────────┬─────────┐  ┌──────┬──────┐   │
│   │   50%   │   50%   │  │  70% │ 30%  │   │
│   └─────────┴─────────┘  └──────┴──────┘   │
│   ┌────┬────┬────┐      ┌────┬────┐        │
│   │ A  │ B  │ C  │      │ TL │ TR │        │
│   └────┴────┴────┘      ├────┼────┤        │
│                         │ BL │ BR │        │
│                         └────┴────┘        │
└───────────────────────────────────────────┘
        ↓
Người dùng kéo tiếp cửa sổ (vẫn đang giữ chuột) vào
một ô cụ thể trong overlay
        ↓
Thả chuột → cửa sổ snap đúng vào ô đó
```

Nếu người dùng **không** thả vào overlay mà tiếp tục kéo ra khỏi vùng
top-edge, overlay biến mất và hành vi quay lại Snap Preview thông
thường (trái / phải / góc — mục 7).

Nếu người dùng thả ngay tại mép trên cùng mà không chọn ô nào cụ thể,
mặc định có thể là **Maximize** (giống hành vi kéo-lên-đỉnh hiện tại
của macOS).

## Vì sao nên có

-   Đây chính là tính năng mà phần lớn người dùng chuyển từ Windows 11
    sang Mac sẽ nhớ và tìm kiếm nhất — Snap Layouts trên Windows 11
    được kích hoạt theo 2 cách: hover vào nút Maximize, hoặc **kéo cửa
    sổ lên cạnh trên**. FlowSnap nên hỗ trợ ít nhất cách thứ hai để
    cảm giác "quen tay" ngay từ đầu.
-   Nó không phải một tính năng tách biệt — nó tận dụng lại đúng
    Layout Engine đã có ở mục 5 (Snap Layouts) và cơ chế preview đã có
    ở mục 7, chỉ thêm một overlay lựa chọn thay vì một preview đơn.

## Lưu ý kỹ thuật

-   **Theo dõi con trỏ khi đang kéo**: cần một global mouse monitor
    (`NSEvent.addGlobalMonitorForEvents` hoặc `CGEventTap`) chạy song
    song với việc theo dõi window đang được kéo qua Accessibility API
    (`kAXWindowMovedNotification` hoặc AX observer), vì tọa độ con
    trỏ và tọa độ khung cửa sổ là hai nguồn khác nhau và không phải
    lúc nào cũng đồng bộ 1:1.
-   **Ngưỡng kích hoạt (threshold)**: chỉ hiện overlay khi con trỏ ở
    trong một dải mỏng sát cạnh trên (vài px) và giữ trạng thái đó
    trong một khoảng thời gian ngắn, để tránh flash/nháy khi người
    dùng chỉ lướt ngang qua top edge.
-   **Overlay là NSPanel riêng**: non-activating, luôn nổi trên cùng,
    không cướp focus của cửa sổ đang kéo; cần multi-monitor aware để
    hiện đúng trên màn hình đang chứa con trỏ (liên hệ mục 16 — Multi-
    Monitor).
-   **Zone hit-testing**: khi thả chuột trong lúc overlay đang hiện,
    cần xác định tọa độ thả rơi vào ô nào trong overlay rồi áp layout
    tương ứng — logic này dùng lại được Layout Engine ở mục 5/6.
-   **App có custom title bar** (Chrome, VS Code, Slack, Discord...):
    một số app không expose title bar chuẩn qua Accessibility API,
    nên việc bắt "bắt đầu kéo cửa sổ" đôi khi cần dựa vào theo dõi
    frame thay đổi của window thay vì bắt mouse-down trực tiếp trên
    title bar. Đây là rủi ro tương tự đã ghi ở mục 54 (Accessibility).
-   **Animation**: nên fade + scale nhẹ khi hiện/ẩn overlay để giống
    cảm giác macOS hơn là hiệu ứng thô của Windows.

Về roadmap, tính năng này phù hợp đưa vào **MVP 2 — Snap Experience**
(mục 48) cùng với Drag-to-snap và Snap Preview, vì nó dùng chung hạ
tầng kéo-thả và Layout Engine đã có ở giai đoạn đó.

------------------------------------------------------------------------

# 8. Global Keyboard Shortcuts

FlowSnap phải đặc biệt nhanh đối với người dùng power-user.

Ví dụ:

``` text
⌃⌥←     Snap Left
⌃⌥→     Snap Right
⌃⌥↑     Maximize
⌃⌥↓     Restore

⌃⌥1     Top Left
⌃⌥2     Top Right
⌃⌥3     Bottom Left
⌃⌥4     Bottom Right
```

Về sau người dùng có thể tự cấu hình.

Ví dụ:

``` text
My Shortcut

⌘⌥L → Snap Left
⌘⌥R → Snap Right
```

------------------------------------------------------------------------

# 9. ⭐ Tính năng đặc biệt: App mới luôn ở Workspace hiện tại

Đây là một trong những tính năng **quan trọng nhất của FlowSnap**, xuất
phát trực tiếp từ nhu cầu của người dùng.

## Vấn đề

Người dùng đang làm việc:

``` text
Desktop / Space hiện tại

┌──────────────────────┬───────────────────┐
│                      │                   │
│       VS Code        │      Chrome       │
│                      │                   │
└──────────────────────┴───────────────────┘
```

Sau đó mở Telegram.

Người dùng mong muốn:

``` text
CÙNG SPACE

┌──────────────────────┬───────────────────┐
│                      │      Chrome       │
│       VS Code        │ ┌───────────────┐ │
│                      │ │   Telegram    │ │
│                      │ │               │ │
└──────────────────────┴─┴───────────────┴─┘
```

Không muốn:

``` text
SPACE 1                    SPACE 2

VS Code + Chrome            Telegram
```

Tức là:

> **Mở app mới không đồng nghĩa với việc tạo hoặc chuyển sang một không
> gian làm việc mới.**

------------------------------------------------------------------------

# 10. Window Policy

FlowSnap sẽ có hệ thống Window Policy.

Ví dụ:

``` text
Chrome      → Current Space
VS Code     → Current Space
Terminal    → Current Space
Telegram    → Floating
Spotify     → Remember Position
```

Các policy có thể gồm:

``` text
Current Space
Current Display
Floating
Remember Position
Assigned Layout
Assigned Workspace
```

Mặc định:

> **Current Space + Current Display**

Tuy nhiên, hành vi liên quan đến Spaces phải tuân theo những gì macOS
cho phép thông qua public APIs.

FlowSnap không nên phụ thuộc vào private/undocumented APIs chỉ để ép một
hành vi mà macOS không hỗ trợ chính thức.

------------------------------------------------------------------------

# 11. ⭐ Smart Window Stack

Một cửa sổ mới có thể xuất hiện phía trên các cửa sổ hiện tại mà không
phá vỡ layout.

Ví dụ:

``` text
VS Code
Chrome
Terminal
```

Mở Slack:

``` text
VS Code
Chrome
Terminal
     ↓
   Slack
```

Slack được đưa lên foreground.

Đóng Slack:

``` text
VS Code
Chrome
Terminal
```

Bố cục cũ vẫn tồn tại.

Mục tiêu là:

> **App mới xuất hiện trên workflow hiện tại, không phá workflow hiện
> tại.**

------------------------------------------------------------------------

# 12. ⭐ Per-App Behavior

FlowSnap có thể nhớ hành vi riêng cho từng ứng dụng.

Ví dụ:

``` text
VS Code
→ Current Space
→ 60% width

Chrome
→ Current Space
→ 25% width

Terminal
→ Current Space
→ 15% width

Telegram
→ Floating

Spotify
→ Remember Position
```

Người dùng có thể chỉnh sửa từ Settings.

------------------------------------------------------------------------

# 13. ⭐ Workspace Presets

Người dùng có thể tạo:

``` text
💻 Coding
🎨 Design
📚 Research
💼 Work
🎬 Editing
```

Ví dụ:

## Coding

``` text
VS Code     → 60%
Chrome      → 25%
Terminal    → 15%
```

## Research

``` text
Browser 1   → 50%
Browser 2   → 25%
Notes       → 25%
```

Một shortcut có thể khôi phục workspace.

``` text
⌃⌥C

Restore Coding Workspace
```

------------------------------------------------------------------------

# 14. ⭐ Window Groups

Một group có thể chứa:

``` text
Coding Group

- VS Code
- Chrome
- Terminal
```

FlowSnap có thể:

``` text
Restore Coding Group
```

và tự tìm các cửa sổ tương ứng.

------------------------------------------------------------------------

# 15. ⭐ Save Current Layout

Người dùng có thể đang có:

``` text
VS Code      60%
Chrome       25%
Terminal     15%
```

Sau đó:

> Save Layout → Coding

FlowSnap lưu lại cấu trúc.

Lần sau:

> Restore Coding

Không cần sắp xếp lại thủ công.

------------------------------------------------------------------------

# 16. ⭐ Multi-Monitor

FlowSnap phải hỗ trợ nhiều màn hình ngay từ kiến trúc ban đầu.

Ví dụ:

``` text
MacBook Display                  External Monitor

┌───────────────────────┐        ┌───────────────────────┐
│                       │        │                       │
│       VS Code         │        │       Slack           │
│                       │        │                       │
├────────────┬──────────┤        │                       │
│ Terminal   │ Chrome   │        └───────────────────────┘
└────────────┴──────────┘
```

FlowSnap phải hiểu:

-   Monitor nào đang chứa focused window.
-   Độ phân giải.
-   Retina scaling.
-   Portrait display.
-   Vị trí tương đối giữa các monitor.
-   Dock/Menu Bar.
-   Monitor được kết nối/ngắt kết nối.

------------------------------------------------------------------------

# 17. ⭐ Display-Aware Snap

Khi người dùng nhấn:

``` text
⌃⌥←
```

FlowSnap không đơn giản dùng màn hình chính.

Nó phải:

``` text
Focused Window
      ↓
Window Center
      ↓
Display chứa Window
      ↓
Display Visible Frame
      ↓
Snap
```

Điều này làm cho multi-monitor hoạt động tự nhiên.

------------------------------------------------------------------------

# 18. ⭐ Smart Layout Gap

Người dùng có thể chọn:

``` text
Window Gap

0 px
4 px
8 px
12 px
16 px
```

Ví dụ:

``` text
┌──────────────┐  ┌──────────────┐
│              │  │              │
│   VS Code    │  │    Chrome    │
│              │  │              │
└──────────────┘  └──────────────┘
```

Điều này giúp desktop nhìn gọn và chuyên nghiệp hơn.

------------------------------------------------------------------------

# 19. ⭐ Layout Editor

Về sau FlowSnap có thể có một Layout Editor trực quan.

Người dùng kéo các zone:

``` text
┌───────────────────────────────┐
│               │               │
│               │       B       │
│       A       ├───────────────┤
│               │       C       │
│               │               │
└───────────────────────────────┘
```

Sau đó:

> Save as "My Coding Layout"

Không cần code để tạo layout.

------------------------------------------------------------------------

# 20. ⭐ Future: Start a Workflow

Đây là hướng phát triển dài hạn.

Ví dụ:

``` text
Start Coding
```

FlowSnap có thể:

``` text
Open VS Code
Open Terminal
Open Chrome
Restore Coding Workspace
Arrange windows
```

Hoặc:

``` text
Start Research
```

→ mở các ứng dụng cần thiết và bố trí chúng.

Lúc này FlowSnap không còn chỉ là:

> Window Snapper

mà trở thành:

> **Workspace Operating Layer cho macOS.**

------------------------------------------------------------------------

# 21. Trải nghiệm người dùng tổng thể

FlowSnap nên có cảm giác:

``` text
Mở Mac
   ↓
Mở ứng dụng
   ↓
Ứng dụng xuất hiện đúng nơi
   ↓
Kéo → Snap
   ↓
Shortcut → Arrange
   ↓
Save Workspace
   ↓
Lần sau Restore
```

Người dùng không cần suy nghĩ:

> "Cửa sổ này phải đặt ở đâu?"

FlowSnap xử lý phần đó.

------------------------------------------------------------------------

# 22. Giao diện Menu Bar

FlowSnap nên là một ứng dụng nhẹ chạy trên Menu Bar.

Ví dụ:

``` text
┌──────────────────────────────┐
│ FlowSnap                     │
├──────────────────────────────┤
│ Snap                         │
│ Layouts                      │
│ Workspaces                   │
│ Groups                       │
├──────────────────────────────┤
│ 💻 Coding                    │
│ 🎨 Design                    │
│ 📚 Research                  │
├──────────────────────────────┤
│ Settings...                  │
│ Quit FlowSnap                │
└──────────────────────────────┘
```

Không cần mở một cửa sổ ứng dụng lớn để sử dụng những chức năng cơ bản.

------------------------------------------------------------------------

# 23. Tư duy sản phẩm

FlowSnap nên được xây dựng theo ba tầng:

## Tầng 1 --- Snap

``` text
Move
Resize
Snap
```

## Tầng 2 --- Arrange

``` text
Layouts
Groups
Multi-monitor
Hotkeys
```

## Tầng 3 --- Flow

``` text
Policies
Workspaces
Automation
App behavior
```

Điều này tạo ra hướng phát triển rõ ràng:

``` text
Window Manager
       ↓
Workspace Manager
       ↓
Workflow Manager
```

------------------------------------------------------------------------

# 24. Kiến trúc kỹ thuật

Sau khi xác định rõ trải nghiệm sản phẩm, kiến trúc kỹ thuật được thiết
kế như sau.

``` text
                         FlowSnap
                             │
             ┌───────────────┴───────────────┐
             │                               │
         SwiftUI                         AppKit
       Settings / UI                  Menu / Panels
             │                               │
             └───────────────┬───────────────┘
                             │
                     Command Dispatcher
                             │
       ┌─────────────────────┼──────────────────────┐
       │                     │                      │
       ▼                     ▼                      ▼
 Window Policy          Snap/Layout           Workspace
   Manager                 Engine               Manager
       │                     │                      │
       └─────────────────────┼──────────────────────┘
                             │
                       Window Manager
                             │
                  ┌──────────┴──────────┐
                  │                     │
          Accessibility Service    Display Manager
                  │                     │
                  ▼                     ▼
              AXUIElement           NSScreen
                  │
                  ▼
              macOS Windows
```

------------------------------------------------------------------------

# 25. Công nghệ

  Thành phần              Công nghệ
  ----------------------- ------------------------------------
  Language                Swift
  UI                      SwiftUI
  Window integration      AppKit
  Window control          Accessibility API
  Global cursor tracking  CGEventTap (Input Monitoring)
  Application lifecycle   NSWorkspace
  Display management      NSScreen / Core Graphics
  Snap preview            NSPanel + AppKit/CALayer (overlay)
  Global hotkeys          KeyboardShortcuts (Sindre Sorhus)
  Persistence             UserDefaults + Codable
  Concurrency             Swift Concurrency
  Architecture            Service-oriented Core + SwiftUI UI
  Auto-update             Sparkle (EdDSA-signed appcast)
  Distribution            Developer ID + Notarization (direct)
  CI/CD                   GitHub Actions + Fastlane

Nguyên tắc:

> **SwiftUI quản lý giao diện. AppKit tích hợp với macOS. Core quản lý
> logic. Accessibility API điều khiển cửa sổ.**

------------------------------------------------------------------------

# 25.1. ⭐ Quyết định: Direct Distribution

FlowSnap sẽ phân phối **trực tiếp** (Developer ID + Notarization),
không qua Mac App Store.

## Lý do

-   Không bị giới hạn bởi App Sandbox và Apple Review khi cần các
    hành vi "nhạy cảm" như điều khiển cửa sổ ứng dụng khác, theo dõi
    con trỏ toàn cục (`CGEventTap`) để phục vụ Snap Layout Picker
    (mục 7.1) và Adaptive Multi-Window Resize (mục 6.1).
-   Toàn quyền kiểm soát tốc độ release — không phụ thuộc thời gian
    duyệt của App Store, quan trọng với một sản phẩm mà trải nghiệm
    (độ mượt khi kéo, độ chính xác snap) cần lặp nhanh dựa trên phản
    hồi người dùng.
-   Phù hợp với nhóm người dùng mục tiêu: power-user, người quen dùng
    Homebrew/terminal — nhóm này vốn quen tải app trực tiếp từ
    website hoặc qua Homebrew Cask hơn là tìm trên App Store.

## Đánh đổi cần chấp nhận

-   Phải tự xây dựng **niềm tin** với người dùng (không có "được Apple
    duyệt" làm bảo chứng) — cần website rõ ràng, changelog minh bạch,
    có thể mã nguồn mở một phần để tăng độ tin cậy (giống Rectangle).
-   Phải tự làm auto-update (Sparkle) thay vì dùng cơ chế update sẵn
    có của App Store.
-   Nếu về sau muốn thu phí, không có sẵn StoreKit/IAP — cần tự tích
    hợp một bên xử lý thanh toán + license (VD Paddle, Gumroad,
    LemonSqueezy) và logic license validation trong app.

## Yêu cầu hạ tầng cụ thể

``` text
1. Apple Developer Program membership
        ↓
2. Developer ID Application certificate (ký .app)
        ↓
3. Hardened Runtime bật, KHÔNG bật App Sandbox
   (cần toàn quyền AXUIElement + CGEventTap liên-process)
        ↓
4. Build → Code sign → xcrun notarytool submit
        ↓
5. Staple notarization ticket vào .app
        ↓
6. Đóng gói .dmg (drag-to-Applications)
        ↓
7. Upload lên GitHub Release / website riêng
        ↓
8. Cập nhật appcast.xml (Sparkle) → user nhận update
```

Cân nhắc thêm **Homebrew Cask** (`brew install --cask flowsnap`) như
một kênh phân phối phụ — rất phù hợp với nhóm người dùng mục tiêu và
gần như miễn phí về công sức duy trì.

## Ảnh hưởng tới luồng xin quyền (liên hệ mục 29)

Vì không qua App Store, người dùng tải file "lạ" từ internet — Gatekeeper
sẽ kiểm tra chữ ký + notarization ticket trước khi cho chạy; nếu thiếu
bước notarize, app sẽ bị báo "damaged" hoặc bị chặn hoàn toàn. Notarization
phải là bước bắt buộc trong CI/CD trước khi phát hành bất kỳ bản nào,
kể cả bản beta gửi tay.

Ngoài ra, vì cần `CGEventTap` để theo dõi con trỏ real-time (không chỉ
Accessibility notification), người dùng sẽ phải cấp **hai quyền riêng
biệt**: Accessibility **và** Input Monitoring. Luồng onboarding (mục
29) cần mở rộng để xin cả hai, giải thích rõ lý do cho từng quyền —
đây là bước dễ mất người dùng nhất nếu làm không rõ ràng, đặc biệt khi
không có mô tả sẵn từ App Store để "bảo chứng" cho app.

------------------------------------------------------------------------

# 26. Domain Models

## ManagedWindow

``` swift
struct ManagedWindow: Identifiable, Hashable {
    let id: CGWindowID
    let pid: pid_t
    let bundleIdentifier: String?
    let title: String

    var frame: CGRect
    var isMinimized: Bool
}
```

## Display

``` swift
struct Display: Identifiable {
    let id: CGDirectDisplayID
    let frame: CGRect
    let visibleFrame: CGRect
    let scaleFactor: CGFloat
}
```

## Layout

``` swift
struct Layout: Identifiable, Codable {
    let id: UUID
    var name: String
    var zones: [LayoutZone]
}
```

## LayoutZone

``` swift
struct LayoutZone: Codable, Hashable {
    let id: UUID

    // Normalized coordinates: 0...1
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}
```

------------------------------------------------------------------------

# 27. Window Manager

WindowManager là thành phần duy nhất nên trực tiếp thao tác với các cửa
sổ được quản lý.

``` swift
protocol WindowManaging {
    func focusedWindow() -> ManagedWindow?

    func move(
        _ window: ManagedWindow,
        to frame: CGRect
    ) async throws

    func focus(
        _ window: ManagedWindow
    ) async throws

    func minimize(
        _ window: ManagedWindow
    ) async throws
}
```

------------------------------------------------------------------------

# 28. Accessibility Service

Tách toàn bộ Apple Accessibility API ra khỏi Core.

``` swift
protocol AccessibilityService {
    func focusedWindow() -> AXUIElement?

    func windows(of pid: pid_t) -> [AXUIElement]

    func frame(of window: AXUIElement) -> CGRect?

    func setFrame(
        _ frame: CGRect,
        for window: AXUIElement
    ) throws

    func raise(_ window: AXUIElement) throws
}
```

Luồng:

``` text
WindowManager
      ↓
AccessibilityService
      ↓
AXUIElement
      ↓
Application Window
```

------------------------------------------------------------------------

# 29. Accessibility & Input Monitoring Permission

FlowSnap cần **hai** permission riêng biệt, không chỉ một:

``` text
Accessibility        → điều khiển cửa sổ ứng dụng khác (AXUIElement)
Input Monitoring     → theo dõi con trỏ toàn cục qua CGEventTap
                        (phục vụ mục 6.1 Adaptive Resize,
                         mục 7.1 Snap Layout Picker)
```

Đây là 2 TCC permission độc lập trong System Settings — cấp cái này
không tự động cấp cái kia. FlowSnap cần xin cả hai và giải thích rõ lý
do cho từng cái, vì với direct distribution (mục 25.1) không có mô tả
sẵn từ App Store để "bảo chứng" cho các quyền này.

Luồng:

``` text
FlowSnap
   ↓
AXIsProcessTrusted()  +  IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
   ↓
Permission(s) missing?
   ↓
Hiện onboarding, giải thích lý do cần từng quyền
   ↓
Open System Settings (đúng pane tương ứng)
   ↓
User enables FlowSnap
   ↓
Re-check (app cần tự poll hoặc lắng nghe khi quay lại foreground,
vì macOS không báo event khi user cấp quyền xong)
```

Logic permission nên được tách riêng, và tách rõ 2 loại quyền để có
thể test/mock độc lập:

``` swift
protocol AccessibilityPermissionProvider {
    var isTrusted: Bool { get }

    func requestPermission()
}

protocol InputMonitoringPermissionProvider {
    var isAuthorized: Bool { get }

    func requestPermission()
}
```

------------------------------------------------------------------------

# 30. Layout Engine

Layout Engine không được phụ thuộc vào AppKit hoặc Accessibility API.

``` swift
protocol LayoutCalculating {
    func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout
    ) -> [CGWindowID: CGRect]
}
```

Input:

``` text
Layout
Display visible frame
Windows
```

Output:

``` text
Window ID → CGRect
```

Điều này giúp Layout Engine dễ dàng unit test.

------------------------------------------------------------------------

# 31. Snap Engine

Snap Engine xác định người dùng muốn snap vào đâu.

``` swift
enum SnapTarget {
    case left
    case right
    case top
    case bottom

    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    case maximize
    case layout(Layout)
}
```

Luồng:

``` text
Mouse / Hotkey
      ↓
SnapEngine
      ↓
SnapTarget
      ↓
LayoutEngine
      ↓
WindowManager
```

------------------------------------------------------------------------

# 32. Snap Preview

Preview được xây dựng bằng AppKit:

``` text
NSPanel
   ↓
NSHostingView
   ↓
SwiftUI SnapPreviewView
```

AppKit chịu trách nhiệm về window/overlay.

SwiftUI chịu trách nhiệm render giao diện.

------------------------------------------------------------------------

# 33. Display Manager

``` swift
protocol DisplayManaging {
    var displays: [Display] { get }

    func display(
        containing point: CGPoint
    ) -> Display?

    func display(
        containing window: ManagedWindow
    ) -> Display?
}
```

FlowSnap nên sử dụng `visibleFrame` để tính vùng làm việc thực tế.

------------------------------------------------------------------------

# 34. Global Hotkey Manager

``` swift
protocol GlobalHotkeyManaging {
    func register(
        _ shortcut: Shortcut,
        action: HotkeyAction
    )

    func unregisterAll()
}
```

Hotkey không gọi trực tiếp WindowManager.

Luồng:

``` text
GlobalHotkeyManager
        ↓
HotkeyAction
        ↓
CommandDispatcher
        ↓
SnapEngine / WorkspaceManager
```

------------------------------------------------------------------------

# 35. Command Dispatcher

``` swift
enum WindowCommand {
    case snap(SnapTarget)
    case maximize
    case restore
    case moveToDisplay(Display.ID)
    case restoreWorkspace(UUID)
}
```

Mọi input đều có thể trở thành command:

``` text
Keyboard
Menu Bar
Settings
Automation
CLI (future)
       ↓
Command
       ↓
CommandDispatcher
```

------------------------------------------------------------------------

# 36. Application Observer

FlowSnap cần theo dõi vòng đời ứng dụng.

``` text
NSWorkspace
     ↓
ApplicationObserver
     ↓
application launched
     ↓
wait for window
     ↓
WindowPolicyManager
```

Không nên cố di chuyển cửa sổ ngay lập tức khi app vừa launch vì cửa sổ
có thể chưa được tạo.

------------------------------------------------------------------------

# 37. Window Policy Manager

``` swift
enum WindowPolicy {
    case currentSpace
    case currentDisplay
    case floating
    case rememberPosition
    case assignedLayout(UUID)
    case assignedWorkspace(UUID)
}
```

Đây là module chịu trách nhiệm hiện thực hóa ý tưởng:

> **App mới mở phải xuất hiện trong workflow hiện tại thay vì phá
> workflow hiện tại.**

------------------------------------------------------------------------

# 38. Workspace Manager

``` swift
struct Workspace: Codable, Identifiable {
    let id: UUID
    var name: String
    var layouts: [WindowPlacement]
}
```

``` swift
struct WindowPlacement: Codable {
    var bundleIdentifier: String
    var zoneID: UUID
}
```

Workspace lưu **ý định bố trí**, không lưu pixel cố định.

------------------------------------------------------------------------

# 39. Window Registry

``` swift
actor WindowRegistry {
    private var windows: [CGWindowID: ManagedWindow] = [:]

    func update(_ window: ManagedWindow) {
        windows[window.id] = window
    }

    func remove(_ id: CGWindowID) {
        windows.removeValue(forKey: id)
    }
}
```

Dùng `actor` để quản lý state bất đồng bộ an toàn.

------------------------------------------------------------------------

# 40. Event System

FlowSnap sẽ có nhiều nguồn event:

``` swift
enum WindowEvent {
    case windowCreated(ManagedWindow)
    case windowClosed(CGWindowID)
    case windowMoved(CGWindowID)

    case applicationLaunched(pid_t)
    case applicationTerminated(pid_t)

    case displayConfigurationChanged
    case activeSpaceChanged
}
```

Các service giao tiếp thông qua event thay vì phụ thuộc trực tiếp vào
nhau.

------------------------------------------------------------------------

# 41. SwiftUI và AppKit

## SwiftUI

Dùng cho:

-   Settings.
-   Layout Editor.
-   Workspace Editor.
-   Application Rules.
-   Shortcut Settings.
-   Menu Bar UI.

## AppKit

Dùng cho:

-   Window integration.
-   NSPanel.
-   Snap Preview.
-   macOS application lifecycle.
-   Window overlays.
-   Low-level macOS behavior.

Nguyên tắc:

> **SwiftUI = Product UI**
>
> **AppKit = macOS Window Integration**

------------------------------------------------------------------------

# 42. Project Structure

``` text
FlowSnap/
│
├── App/
│   ├── FlowSnapApp.swift
│   ├── AppDelegate.swift
│   └── AppDependencies.swift
│
├── Domain/
│   ├── Window/
│   │   ├── ManagedWindow.swift
│   │   └── WindowPolicy.swift
│   │
│   ├── Layout/
│   │   ├── Layout.swift
│   │   └── LayoutZone.swift
│   │
│   ├── Display/
│   │   └── Display.swift
│   │
│   └── Workspace/
│       ├── Workspace.swift
│       └── WindowPlacement.swift
│
├── Core/
│   ├── Window/
│   │   ├── WindowManager.swift
│   │   └── WindowRegistry.swift
│   │
│   ├── Layout/
│   │   ├── LayoutEngine.swift
│   │   ├── SnapEngine.swift
│   │   └── SnapDetector.swift
│   │
│   ├── Workspace/
│   │   └── WorkspaceManager.swift
│   │
│   ├── Policy/
│   │   └── WindowPolicyManager.swift
│   │
│   ├── Commands/
│   │   └── CommandDispatcher.swift
│   │
│   └── Events/
│       └── EventBus.swift
│
├── Infrastructure/
│   ├── Accessibility/
│   │   ├── AXAccessibilityService.swift
│   │   └── AXError.swift
│   │
│   ├── macOS/
│   │   ├── WorkspaceObserver.swift
│   │   ├── DisplayManager.swift
│   │   └── SpaceObserver.swift
│   │
│   └── Hotkeys/
│       └── GlobalHotkeyManager.swift
│
├── UI/
│   ├── MenuBar/
│   │   └── MenuBarView.swift
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── GeneralSettingsView.swift
│   │   ├── ShortcutSettingsView.swift
│   │   └── ApplicationRulesView.swift
│   │
│   └── SnapPreview/
│       ├── SnapPreviewPanel.swift
│       └── SnapPreviewView.swift
│
└── Persistence/
    ├── PreferencesStore.swift
    └── WorkspaceStore.swift
```

------------------------------------------------------------------------

# 43. Kiến trúc dependency

Quy tắc quan trọng:

``` text
UI
 ↓
Core
 ↓
Infrastructure
 ↓
Apple APIs
```

Không làm:

``` text
LayoutEngine
 ↓
NSScreen
```

và cũng không làm:

``` text
SwiftUI View
 ↓
AXUIElement
```

Thay vào đó:

``` text
DisplayManager
 ↓
Display
 ↓
LayoutEngine
```

và:

``` text
SwiftUI
 ↓
ViewModel
 ↓
Core
 ↓
AccessibilityService
```

------------------------------------------------------------------------

# 44. Concurrency

FlowSnap là ứng dụng event-driven.

Nên sử dụng Swift Concurrency:

``` text
MainActor
   ├── SwiftUI
   ├── AppKit UI
   └── Snap Preview

Actors / Services
   ├── WindowRegistry
   ├── ApplicationObserver
   └── WorkspaceManager
```

Không block Main Thread khi xử lý các event hoặc scan window.

------------------------------------------------------------------------

# 45. Persistence

MVP:

``` text
UserDefaults
    ├── General Settings
    ├── Hotkeys
    ├── App Policies
    └── UI Preferences

Application Support/FlowSnap/
    ├── layouts.json
    └── workspaces.json
```

SwiftData chỉ nên được cân nhắc khi dữ liệu trở nên phức tạp hơn.

------------------------------------------------------------------------

# 46. MVP Roadmap

## MVP 0 --- Technical Spike

Không làm UI đẹp.

Chỉ cần:

``` text
✓ Accessibility permission
✓ Find focused window
✓ Read window frame
✓ Find current display
✓ Move window
✓ Resize window
```

Test:

``` text
⌃⌥←
→ Focused Window sang trái 50%

⌃⌥→
→ Focused Window sang phải 50%
```

Nếu phần này chưa ổn định thì chưa nên xây các tính năng cao hơn.

------------------------------------------------------------------------

# 47. MVP 1 --- Basic FlowSnap

``` text
✓ Accessibility
✓ Focused window
✓ Left/right snap
✓ Four-corner snap
✓ Maximize
✓ Restore
✓ Global hotkeys
✓ Multi-monitor
✓ Menu Bar
✓ Settings
```

Sau MVP này, FlowSnap đã là một window manager hữu dụng.

------------------------------------------------------------------------

# 48. MVP 2 --- Snap Experience

``` text
✓ Drag-to-snap
✓ Snap preview
✓ Snap Layout Picker (kéo lên cạnh trên)
✓ 50/50
✓ 60/40
✓ 70/30
✓ Custom layouts
✓ Adaptive multi-window resize (shared divider)
✓ Window gaps
✓ Custom shortcuts
```

Đây là giai đoạn FlowSnap bắt đầu có trải nghiệm giống một sản phẩm hoàn
chỉnh.

------------------------------------------------------------------------

# 49. MVP 3 --- FlowSnap Differentiators

``` text
✓ Application launch detection
✓ Current Space policy
✓ Current Display policy
✓ Per-app rules
✓ Window Groups
✓ Workspace save/restore
✓ Workspace presets
```

Đây là giai đoạn tạo ra sự khác biệt lớn với các ứng dụng window manager
đơn thuần.

------------------------------------------------------------------------

# 50. Spaces --- Technical Risk

Spaces là phần cần đặc biệt cẩn thận.

FlowSnap có thể quan sát trạng thái Space và xây dựng logic xoay quanh
current working context, nhưng macOS không cung cấp một public API đơn
giản để ứng dụng bên thứ ba tùy ý làm:

``` swift
moveWindowToSpace(window, space)
```

với toàn quyền kiểm soát.

Vì vậy:

> **Không phụ thuộc vào private/undocumented APIs.**

Thiết kế abstraction:

``` swift
protocol SpaceManaging {
    func currentContext() -> SpaceContext
    func observeSpaceChanges()
}
```

Sau đó triển khai những hành vi có thể thực hiện ổn định bằng public
APIs.

Mục tiêu sản phẩm vẫn là:

> **Giữ người dùng trong workflow hiện tại và không chủ động phá vỡ
> Space của họ.**

------------------------------------------------------------------------

# 51. Testing

## Unit Tests

Tập trung mạnh vào Layout Engine:

``` text
1440 × 900
50/50

A = 720 × 900
B = 720 × 900
```

Test:

-   50/50.
-   60/40.
-   70/30.
-   Four corners.
-   Gaps.
-   4K.
-   Retina.
-   Portrait.
-   Multiple displays.

## Integration Tests

Test:

-   Accessibility.
-   Window movement.
-   Window focus.
-   Application launch.
-   Multiple monitors.
-   Display changes.

## Compatibility Testing

Các ứng dụng cần test:

-   Safari.
-   Chrome.
-   Finder.
-   Terminal.
-   VS Code.
-   Slack.
-   Discord.
-   Figma.

------------------------------------------------------------------------

# 52. Performance

FlowSnap phải có cảm giác gần như tức thời.

Mục tiêu:

``` text
Hotkey
   ↓
Command
   ↓
Calculate
   ↓
Move
```

Không nên:

-   Poll toàn bộ windows liên tục.
-   Scan mọi ứng dụng liên tục.
-   Block Main Thread.
-   Re-render SwiftUI không cần thiết.

Ưu tiên event-driven architecture.

------------------------------------------------------------------------

# 53. Window Classification

Không phải cửa sổ nào cũng nên snap.

Về sau có thể phân loại:

``` swift
enum WindowKind {
    case normal
    case dialog
    case sheet
    case utility
    case fullscreen
    case unknown
}
```

Snap Engine mặc định chỉ nên xử lý `.normal`.

Điều này tránh làm ảnh hưởng tới dialog, sheet hoặc system UI.

------------------------------------------------------------------------

# 54. Technical Risks

Các phần có rủi ro cao nhất:

## Accessibility

Mỗi ứng dụng có thể expose Accessibility UI khác nhau.

## Spaces

Public API có giới hạn.

## Application launch timing

App có thể launch trước khi window tồn tại.

## Multi-monitor coordinates

Mỗi display có thể khác:

-   Resolution.
-   Scale.
-   Orientation.
-   Position.

## Special windows

Một số window không thể hoặc không nên resize/move.

------------------------------------------------------------------------

# 55. Development Order

``` text
1. Tạo macOS app
        ↓
2. Accessibility permission
        ↓
3. Detect focused window
        ↓
4. Read window frame
        ↓
5. Detect current display
        ↓
6. Move / resize window
        ↓
7. Layout Engine
        ↓
8. Left / Right Snap
        ↓
9. Global Hotkeys
        ↓
10. Four-corner Snap
        ↓
11. Multi-monitor
        ↓
12. Menu Bar
        ↓
13. Drag-to-Snap
        ↓
14. Snap Preview
        ↓
15. Custom Layouts
        ↓
16. Application Observer
        ↓
17. Window Policy Manager
        ↓
18. Workspaces
        ↓
19. Window Groups
        ↓
20. Advanced Space behavior
```

------------------------------------------------------------------------

# 56. FlowSnap Lab

Trước khi xây UI hoàn chỉnh, nên tạo một target/test application:

``` text
FlowSnap Lab

┌─────────────────────────────────────┐
│ Accessibility:       ✓              │
│ Focused App:         Chrome         │
│ Focused Window:      Google         │
│ Window Frame:        1200 × 800     │
│ Current Display:     MacBook        │
│                                     │
│ [ Snap Left ] [ Snap Right ]        │
│ [ Maximize ]  [ Restore ]           │
│                                     │
│ [ Test Launch Detection ]           │
└─────────────────────────────────────┘
```

Mục tiêu:

1.  Detect focused window.
2.  Read window frame.
3.  Identify monitor.
4.  Move window.
5.  Resize window.
6.  Detect application launch.

Khi FlowSnap Lab hoạt động ổn định, mới chuyển sang UI sản phẩm.

------------------------------------------------------------------------

# 57. Vision dài hạn

FlowSnap có thể phát triển theo:

``` text
                    FlowSnap
                       │
                       ▼
                Window Manager
                       │
                       ▼
               Workspace Manager
                       │
                       ▼
               Workflow Manager
                       │
                       ▼
              Personal Workspace OS
```

Cuối cùng, FlowSnap không chỉ trả lời:

> "Cửa sổ này nằm ở đâu?"

mà trả lời:

> **"Tôi đang làm việc gì và Mac của tôi nên được bố trí như thế nào để
> hỗ trợ công việc đó?"**

------------------------------------------------------------------------

# 58. Product Statement

> **FlowSnap is a native macOS window and workspace manager that brings
> fast, flexible snapping to Mac while keeping users in control of their
> current workspace.**

Hoặc phiên bản ngắn:

> **FlowSnap --- Your Mac. Your Layout. Your Flow.**

------------------------------------------------------------------------

# 59. Kết luận

FlowSnap nên được xây dựng theo thứ tự:

``` text
TRẢI NGHIỆM
    ↓
TÍNH NĂNG
    ↓
WORKSPACE CONCEPT
    ↓
WINDOW POLICY
    ↓
KIẾN TRÚC
    ↓
IMPLEMENTATION
```

Chứ không nên bắt đầu bằng việc xây một hệ thống kỹ thuật phức tạp mà
chưa xác định rõ trải nghiệm người dùng.

Điểm khác biệt lớn nhất của FlowSnap không phải chỉ là:

> "Chia màn hình giống Windows 11."

Mà là:

> **"Mac hiểu cách bạn muốn làm việc."**

Ba trụ cột của sản phẩm:

``` text
┌───────────────────────────────────────────┐
│                                           │
│                 FlowSnap                  │
│                                           │
│       SNAP          ARRANGE        FLOW   │
│                                           │
│    Snap nhanh      Layouts        Policies│
│    Hotkeys         Workspaces     Automation
│    Preview         Groups         App Rules│
│    Multi-monitor   Restore        Current Space
│                                           │
└───────────────────────────────────────────┘
```

Và tính năng mang tính biểu tượng của FlowSnap:

> **Khi tôi mở một ứng dụng mới, hãy đưa nó vào workflow hiện tại của
> tôi --- đừng bắt tôi đi tìm nó ở một Space khác.**

Đó là nền tảng để FlowSnap khác biệt với một ứng dụng window snapping
thông thường.
