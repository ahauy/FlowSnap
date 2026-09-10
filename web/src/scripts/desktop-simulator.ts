/**
 * Desktop Simulator Controller
 * Implements 3D tilt, pointer dragging with setPointerCapture, multi-window focus,
 * FlowSnap native popover, Windows 11-style top-edge layout picker,
 * and real-time Adaptive Split Divider resizing (EPIC 08).
 */

interface SnapZone {
  left: number;
  top: number;
  width: number;
  height: number;
  label: string;
}

export class DesktopSimulatorController {
  private stageEl: HTMLElement | null = null;
  private frameEl: HTMLElement | null = null;
  private glareEl: HTMLElement | null = null;
  private workspaceEl: HTMLElement | null = null;
  private pickerEl: HTMLElement | null = null;
  private hudPreviewEl: HTMLElement | null = null;
  private hudBadgeEl: HTMLElement | null = null;
  private resetBtnEl: HTMLElement | null = null;
  private clockEl: HTMLElement | null = null;
  private dividerEl: HTMLElement | null = null;

  // Popover Elements
  private popoverTriggerEl: HTMLElement | null = null;
  private popoverEl: HTMLElement | null = null;
  private popoverTargetNameEl: HTMLElement | null = null;

  // Windows State
  private winCodeEl: HTMLElement | null = null;
  private winTermEl: HTMLElement | null = null;
  private activeWindowEl: HTMLElement | null = null;

  // Drag State
  private isDragging = false;
  private currentDragTarget: HTMLElement | null = null;
  private dragStartPointerX = 0;
  private dragStartPointerY = 0;
  private windowStartLeft = 0;
  private windowStartTop = 0;
  private activeZone: SnapZone | null = null;
  private rafId: number | null = null;
  private pendingPointerEvent: PointerEvent | null = null;

  // Divider Drag State (Collinear Resize)
  private isDraggingDivider = false;
  private isSplitMode = false;
  private splitPercent = 50;

  // Concurrency & Z-Index
  private topZIndex = 36;
  private isIntersecting = true;

  // Initial Coordinates
  private readonly initialCodeCoords = {
    left: "8%",
    top: "10%",
    width: "54%",
    height: "70%",
  };
  private readonly initialTermCoords = {
    left: "48%",
    top: "22%",
    width: "46%",
    height: "62%",
  };

  constructor() {
    this.initElements();
    if (!this.frameEl || !this.winCodeEl) return;

    // Mobile / Touch-only Fallback Guard
    const isMobileOrTouch = window.matchMedia(
      "(max-width: 767px), (hover: none) and (pointer: coarse)",
    ).matches;
    if (isMobileOrTouch) {
      this.setupClock();
      return;
    }

    this.activeWindowEl = this.winCodeEl;
    this.bindWindowFocus();
    this.bindDragEvents();
    this.bind3DTilt();
    this.bindPickerZones();
    this.bindQuickChips();
    this.bindPopover();
    this.bindDockApps();
    this.bindTrafficLights();
    this.bindReset();
    this.bindSplitDivider();
    this.setupClock();
    this.setupIntersectionObserver();
  }

  private initElements() {
    this.stageEl = document.getElementById("perspective-stage");
    this.frameEl = document.getElementById("mac-desktop-frame");
    this.glareEl = document.getElementById("bezel-glare");
    this.workspaceEl = document.getElementById("mac-workspace");
    this.pickerEl = document.getElementById("snap-picker");
    this.hudPreviewEl = document.getElementById("hud-snap-preview");
    this.hudBadgeEl = document.getElementById("hud-preview-badge");
    this.resetBtnEl = document.getElementById("simulator-reset-btn");
    this.clockEl = document.getElementById("virtual-clock");
    this.dividerEl = document.getElementById("desktop-split-divider");

    this.popoverTriggerEl = document.getElementById("fs-menubar-trigger");
    this.popoverEl = document.getElementById("fs-menubar-popover");
    this.popoverTargetNameEl = document.getElementById("popover-target-name");

    this.winCodeEl = document.getElementById("mock-window-code");
    this.winTermEl = document.getElementById("mock-window-terminal");
  }

  private focusWindow(win: HTMLElement | null) {
    if (!win) return;
    this.activeWindowEl = win;
    this.topZIndex += 1;
    win.style.zIndex = String(this.topZIndex);

    [this.winCodeEl, this.winTermEl].forEach((w) => {
      if (w) w.classList.toggle("active-window", w === win);
    });

    const winName = win.dataset.windowName || "Window";
    if (this.popoverTargetNameEl) {
      this.popoverTargetNameEl.textContent = winName;
    }
  }

  private bindWindowFocus() {
    [this.winCodeEl, this.winTermEl].forEach((win) => {
      win?.addEventListener("pointerdown", () => this.focusWindow(win));
    });
  }

  private bindDragEvents() {
    const bindHandle = (titlebarId: string, winEl: HTMLElement | null) => {
      const titlebar = document.getElementById(titlebarId);
      if (!titlebar || !winEl || !this.workspaceEl) return;

      titlebar.addEventListener("pointerdown", (e: PointerEvent) => {
        if (e.button !== 0) return;
        this.focusWindow(winEl);
        this.isDragging = true;
        this.currentDragTarget = winEl;
        this.dragStartPointerX = e.clientX;
        this.dragStartPointerY = e.clientY;

        const winRect = winEl.getBoundingClientRect();
        const workspaceRect = this.workspaceEl!.getBoundingClientRect();
        this.windowStartLeft = winRect.left - workspaceRect.left;
        this.windowStartTop = winRect.top - workspaceRect.top;

        titlebar.setPointerCapture(e.pointerId);
        winEl.classList.add("is-dragging");
        this.hideDivider();

        if (this.frameEl) {
          this.frameEl.style.transform = "rotateX(0deg) rotateY(0deg)";
        }
      });

      titlebar.addEventListener("pointermove", (e: PointerEvent) => {
        if (!this.isDragging || this.currentDragTarget !== winEl) return;
        this.pendingPointerEvent = e;
        if (!this.rafId) {
          this.rafId = requestAnimationFrame(() => this.processDragMove());
        }
      });

      const finishDrag = (e: PointerEvent) => {
        if (!this.isDragging || this.currentDragTarget !== winEl) return;
        this.isDragging = false;
        winEl.classList.remove("is-dragging");
        if (this.rafId) {
          cancelAnimationFrame(this.rafId);
          this.rafId = null;
        }
        try {
          titlebar.releasePointerCapture(e.pointerId);
        } catch (_) {}

        if (this.activeZone) {
          this.applySnapZoneWithCompanion(winEl, this.activeZone);
        }
        this.hidePicker();
        this.hideHudPreview();
        this.currentDragTarget = null;
        this.checkAndUpdateSplitMode();
      };

      titlebar.addEventListener("pointerup", finishDrag);
      titlebar.addEventListener("pointercancel", finishDrag);
    };

    bindHandle("titlebar-code", this.winCodeEl);
    bindHandle("titlebar-terminal", this.winTermEl);
  }

  private processDragMove() {
    this.rafId = null;
    const e = this.pendingPointerEvent;
    const win = this.currentDragTarget;
    if (!e || !win || !this.workspaceEl) return;

    const deltaX = e.clientX - this.dragStartPointerX;
    const deltaY = e.clientY - this.dragStartPointerY;
    const workspaceRect = this.workspaceEl.getBoundingClientRect();
    const winRect = win.getBoundingClientRect();

    let newLeft = this.windowStartLeft + deltaX;
    let newTop = this.windowStartTop + deltaY;
    newLeft = Math.max(
      -winRect.width * 0.3,
      Math.min(workspaceRect.width - winRect.width * 0.7, newLeft),
    );
    newTop = Math.max(0, Math.min(workspaceRect.height - 36, newTop));

    win.style.left = `${newLeft}px`;
    win.style.top = `${newTop}px`;

    const cursorY = e.clientY - workspaceRect.top;
    const cursorX = e.clientX - workspaceRect.left;

    if (cursorY <= 36) {
      this.showPicker();
    } else if (cursorY > 110 && !this.activeZone) {
      this.hidePicker();
    }

    const elemUnderCursor = document.elementFromPoint(e.clientX, e.clientY);
    const zoneBtn = elemUnderCursor?.closest(
      ".snap-zone-btn",
    ) as HTMLElement | null;

    if (zoneBtn) {
      document.querySelectorAll<HTMLElement>(".snap-zone-btn").forEach((b) => {
        b.classList.toggle("is-active", b === zoneBtn);
      });
      const left = parseFloat(zoneBtn.dataset.left || "0");
      const top = parseFloat(zoneBtn.dataset.top || "0");
      const width = parseFloat(zoneBtn.dataset.width || "50");
      const height = parseFloat(zoneBtn.dataset.height || "100");
      const label = zoneBtn.dataset.label || "Snapped Zone";
      this.showHudPreview({ left, top, width, height, label });
    } else {
      document
        .querySelectorAll<HTMLElement>(".snap-zone-btn.is-active")
        .forEach((b) => b.classList.remove("is-active"));
      if (cursorY > 50) {
        if (cursorX <= 50) {
          this.showHudPreview({
            left: 0,
            top: 0,
            width: 50,
            height: 100,
            label: "Left 50%",
          });
        } else if (cursorX >= workspaceRect.width - 50) {
          this.showHudPreview({
            left: 50,
            top: 0,
            width: 50,
            height: 100,
            label: "Right 50%",
          });
        } else {
          this.hideHudPreview();
        }
      } else if (cursorY > 36) {
        this.hideHudPreview();
      }
    }
  }

  private showPicker() {
    this.pickerEl?.classList.add("is-visible");
  }

  private hidePicker() {
    this.pickerEl?.classList.remove("is-visible");
    document
      .querySelectorAll<HTMLElement>(".snap-zone-btn.is-active")
      .forEach((b) => b.classList.remove("is-active"));
  }

  private showHudPreview(zone: SnapZone) {
    if (!this.hudPreviewEl) return;
    this.activeZone = zone;
    this.hudPreviewEl.style.left = `${zone.left}%`;
    this.hudPreviewEl.style.top = `${zone.top}%`;
    this.hudPreviewEl.style.width = `${zone.width}%`;
    this.hudPreviewEl.style.height = `${zone.height}%`;
    this.hudPreviewEl.classList.add("is-active");

    if (this.hudBadgeEl) {
      this.hudBadgeEl.textContent = zone.label;
    }
  }

  private hideHudPreview() {
    if (!this.hudPreviewEl) return;
    this.activeZone = null;
    this.hudPreviewEl.classList.remove("is-active");
  }

  private applySnapZone(win: HTMLElement, zone: SnapZone) {
    win.style.left = `${zone.left}%`;
    win.style.top = `${zone.top}%`;
    win.style.width = `${zone.width}%`;
    win.style.height = `${zone.height}%`;
    this.setWindowBadge(win, `Zone: ${zone.label}`);
  }

  private setWindowBadge(win: HTMLElement, label: string) {
    const badgeLabel = win.querySelector<HTMLElement>(".status-label");
    if (badgeLabel) badgeLabel.textContent = label;
  }

  /**
   * Snaps the primary window and automatically tiles the companion window
   * when creating a side-by-side split (50/50, 70/30, 30/70)
   */
  public applySnapZoneWithCompanion(win: HTMLElement, zone: SnapZone) {
    this.applySnapZone(win, zone);

    const companion = win === this.winCodeEl ? this.winTermEl : this.winCodeEl;
    if (!companion || companion.classList.contains("is-hidden")) return;

    // Complementary auto-tile for side-by-side splits
    if (zone.top === 0 && zone.height === 100) {
      if (zone.left === 0 && zone.width === 50) {
        this.applySnapZone(companion, {
          left: 50,
          top: 0,
          width: 50,
          height: 100,
          label: "Right 50%",
        });
      } else if (zone.left === 50 && zone.width === 50) {
        this.applySnapZone(companion, {
          left: 0,
          top: 0,
          width: 50,
          height: 100,
          label: "Left 50%",
        });
      } else if (zone.left === 0 && zone.width === 70) {
        this.applySnapZone(companion, {
          left: 70,
          top: 0,
          width: 30,
          height: 100,
          label: "Right 30%",
        });
      } else if (zone.left === 70 && zone.width === 30) {
        this.applySnapZone(companion, {
          left: 0,
          top: 0,
          width: 70,
          height: 100,
          label: "Left 70%",
        });
      }
    }
    this.checkAndUpdateSplitMode();
  }

  public checkAndUpdateSplitMode() {
    if (!this.winCodeEl || !this.winTermEl) return;
    if (
      this.winCodeEl.classList.contains("is-hidden") ||
      this.winTermEl.classList.contains("is-hidden")
    ) {
      this.hideDivider();
      return;
    }

    const codeLeft = parseFloat(this.winCodeEl.style.left || "0");
    const termLeft = parseFloat(this.winTermEl.style.left || "0");
    const codeWidth = parseFloat(this.winCodeEl.style.width || "0");
    const termWidth = parseFloat(this.winTermEl.style.width || "0");

    // Check if windows are collinear side-by-side filling 100%
    if (
      codeLeft === 0 &&
      Math.abs(codeWidth - termLeft) <= 1 &&
      Math.abs(codeWidth + termWidth - 100) <= 2
    ) {
      this.splitPercent = codeWidth;
      this.showDivider(codeWidth);
    } else if (
      termLeft === 0 &&
      Math.abs(termWidth - codeLeft) <= 1 &&
      Math.abs(termWidth + codeWidth - 100) <= 2
    ) {
      this.splitPercent = termWidth;
      this.showDivider(termWidth);
    } else {
      this.hideDivider();
    }
  }

  public showDivider(percent: number) {
    if (!this.dividerEl) return;
    this.isSplitMode = true;
    this.splitPercent = percent;
    this.dividerEl.style.left = `${percent}%`;
    this.dividerEl.classList.add("is-visible");
    this.dividerEl.setAttribute("aria-hidden", "false");
  }

  public hideDivider() {
    if (!this.dividerEl) return;
    this.isSplitMode = false;
    this.dividerEl.classList.remove("is-visible");
    this.dividerEl.setAttribute("aria-hidden", "true");
  }

  private bindSplitDivider() {
    if (!this.dividerEl || !this.workspaceEl) return;
    const divider = this.dividerEl;
    const workspace = this.workspaceEl;

    divider.addEventListener("pointerdown", (e: PointerEvent) => {
      if (e.button !== 0 || !this.winCodeEl || !this.winTermEl) return;
      this.isDraggingDivider = true;
      divider.setPointerCapture(e.pointerId);
      divider.classList.add("is-dragging");

      this.winCodeEl.style.transition = "none";
      this.winTermEl.style.transition = "none";
      divider.style.transition = "none";
    });

    divider.addEventListener("pointermove", (e: PointerEvent) => {
      if (!this.isDraggingDivider || !this.winCodeEl || !this.winTermEl) return;

      const workspaceRect = workspace.getBoundingClientRect();
      const cursorX = e.clientX - workspaceRect.left;
      let percent = (cursorX / workspaceRect.width) * 100;
      percent = Math.max(20, Math.min(80, percent));
      this.splitPercent = percent;

      const isCodeLeft = parseFloat(this.winCodeEl.style.left || "0") === 0;
      const leftWin = isCodeLeft ? this.winCodeEl : this.winTermEl;
      const rightWin = isCodeLeft ? this.winTermEl : this.winCodeEl;

      leftWin.style.left = "0%";
      leftWin.style.width = `${percent}%`;
      rightWin.style.left = `${percent}%`;
      rightWin.style.width = `${100 - percent}%`;

      divider.style.left = `${percent}%`;

      this.setWindowBadge(leftWin, `Zone: Left ${Math.round(percent)}%`);
      this.setWindowBadge(
        rightWin,
        `Zone: Right ${Math.round(100 - percent)}%`,
      );
    });

    const finishDividerDrag = (e: PointerEvent) => {
      if (!this.isDraggingDivider) return;
      this.isDraggingDivider = false;
      divider.classList.remove("is-dragging");
      try {
        divider.releasePointerCapture(e.pointerId);
      } catch (_) {}

      if (this.winCodeEl) this.winCodeEl.style.transition = "";
      if (this.winTermEl) this.winTermEl.style.transition = "";
      divider.style.transition = "";
    };

    divider.addEventListener("pointerup", finishDividerDrag);
    divider.addEventListener("pointercancel", finishDividerDrag);

    // Double-click resets to 50/50
    divider.addEventListener("dblclick", () => {
      this.applyDualPreset("research");
    });
  }

  private bindPickerZones() {
    document.querySelectorAll<HTMLElement>(".snap-zone-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        const targetWin = this.activeWindowEl || this.winCodeEl;
        if (!targetWin) return;

        const left = parseFloat(btn.dataset.left || "0");
        const top = parseFloat(btn.dataset.top || "0");
        const width = parseFloat(btn.dataset.width || "50");
        const height = parseFloat(btn.dataset.height || "100");
        const label = btn.dataset.label || "Snapped Zone";

        this.applySnapZoneWithCompanion(targetWin, {
          left,
          top,
          width,
          height,
          label,
        });
        this.hidePicker();
        this.hideHudPreview();
      });
    });
  }

  private bind3DTilt() {
    if (!this.stageEl || !this.frameEl) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    this.stageEl.addEventListener("pointermove", (e: PointerEvent) => {
      if (
        this.isDragging ||
        this.isDraggingDivider ||
        !this.isIntersecting ||
        !this.frameEl
      )
        return;

      const rect = this.frameEl.getBoundingClientRect();
      const normX = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      const normY = ((e.clientY - rect.top) / rect.height) * 2 - 1;

      this.frameEl.style.transform = `rotateX(${(-normY * 4.2).toFixed(2)}deg) rotateY(${(normX * 4.2).toFixed(2)}deg)`;

      if (this.glareEl) {
        const glareX = Math.max(0, Math.min(100, (normX + 1) * 50));
        const glareY = Math.max(0, Math.min(100, (normY + 1) * 50));
        this.glareEl.style.background = `radial-gradient(circle at ${glareX}% ${glareY}%, rgba(255, 255, 255, 0.12) 0%, transparent 55%)`;
      }
    });

    this.stageEl.addEventListener("pointerleave", () => {
      if (!this.frameEl) return;
      this.frameEl.style.transform = "rotateX(0deg) rotateY(0deg)";
      if (this.glareEl) {
        this.glareEl.style.background =
          "radial-gradient(circle at 50% 0%, rgba(255, 255, 255, 0.08) 0%, transparent 60%)";
      }
    });
  }

  private bindPopover() {
    const togglePopover = (e: Event) => {
      e.stopPropagation();
      this.popoverEl?.classList.toggle("is-open");
      this.popoverTriggerEl?.classList.toggle("active");
    };

    this.popoverTriggerEl?.addEventListener("click", togglePopover);
    document
      .getElementById("dock-flowsnap")
      ?.addEventListener("click", togglePopover);

    document.addEventListener("click", (e) => {
      if (
        this.popoverEl &&
        !this.popoverEl.contains(e.target as Node) &&
        e.target !== this.popoverTriggerEl
      ) {
        this.popoverEl.classList.remove("is-open");
        this.popoverTriggerEl?.classList.remove("active");
      }
    });

    document
      .querySelectorAll<HTMLButtonElement>("[data-popover-snap]")
      .forEach((btn) => {
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          const targetWin = this.activeWindowEl || this.winCodeEl;
          if (!targetWin) return;

          const action = btn.dataset.popoverSnap;
          switch (action) {
            case "left-50":
              this.applySnapZoneWithCompanion(targetWin, {
                left: 0,
                top: 0,
                width: 50,
                height: 100,
                label: "Left 50%",
              });
              break;
            case "right-50":
              this.applySnapZoneWithCompanion(targetWin, {
                left: 50,
                top: 0,
                width: 50,
                height: 100,
                label: "Right 50%",
              });
              break;
            case "left-70":
              this.applySnapZoneWithCompanion(targetWin, {
                left: 0,
                top: 0,
                width: 70,
                height: 100,
                label: "Left 70%",
              });
              break;
            case "right-30":
              this.applySnapZoneWithCompanion(targetWin, {
                left: 70,
                top: 0,
                width: 30,
                height: 100,
                label: "Right 30%",
              });
              break;
            case "center-50":
              this.applySnapZone(targetWin, {
                left: 25,
                top: 0,
                width: 50,
                height: 100,
                label: "Center 50%",
              });
              this.hideDivider();
              break;
            case "maximize":
              this.applySnapZone(targetWin, {
                left: 0,
                top: 0,
                width: 100,
                height: 100,
                label: "Maximize",
              });
              this.hideDivider();
              break;
          }
          this.popoverEl?.classList.remove("is-open");
        });
      });

    document
      .querySelectorAll<HTMLButtonElement>("[data-popover-preset]")
      .forEach((btn) => {
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          const preset = btn.dataset.popoverPreset;
          this.applyDualPreset(preset || "coding");
          this.popoverEl?.classList.remove("is-open");
        });
      });
  }

  public applyDualPreset(preset: string) {
    if (!this.winCodeEl || !this.winTermEl) return;
    this.winCodeEl.classList.remove("is-hidden");
    this.winTermEl.classList.remove("is-hidden");

    if (preset === "coding") {
      this.applySnapZone(this.winCodeEl, {
        left: 0,
        top: 0,
        width: 70,
        height: 100,
        label: "Left 70%",
      });
      this.applySnapZone(this.winTermEl, {
        left: 70,
        top: 0,
        width: 30,
        height: 100,
        label: "Right 30%",
      });
      this.focusWindow(this.winCodeEl);
      this.showDivider(70);
    } else if (preset === "research") {
      this.applySnapZone(this.winCodeEl, {
        left: 0,
        top: 0,
        width: 50,
        height: 100,
        label: "Left 50%",
      });
      this.applySnapZone(this.winTermEl, {
        left: 50,
        top: 0,
        width: 50,
        height: 100,
        label: "Right 50%",
      });
      this.focusWindow(this.winCodeEl);
      this.showDivider(50);
    }
  }

  private bindQuickChips() {
    document
      .querySelectorAll<HTMLButtonElement>(".chip-btn")
      .forEach((chip) => {
        chip.addEventListener("click", () => {
          const action = chip.dataset.snapAction;
          const targetWin = this.activeWindowEl || this.winCodeEl;

          if (action === "coding-preset") {
            this.applyDualPreset("coding");
          } else if (action === "split-50") {
            this.applyDualPreset("research");
          } else if (targetWin) {
            switch (action) {
              case "left-50":
                this.applySnapZoneWithCompanion(targetWin, {
                  left: 0,
                  top: 0,
                  width: 50,
                  height: 100,
                  label: "Left 50%",
                });
                break;
              case "right-50":
                this.applySnapZoneWithCompanion(targetWin, {
                  left: 50,
                  top: 0,
                  width: 50,
                  height: 100,
                  label: "Right 50%",
                });
                break;
              case "left-70":
                this.applySnapZoneWithCompanion(targetWin, {
                  left: 0,
                  top: 0,
                  width: 70,
                  height: 100,
                  label: "Left 70%",
                });
                break;
            }
          }
        });
      });
  }

  private bindDockApps() {
    const codeDot = document.getElementById("dot-code");
    const termDot = document.getElementById("dot-terminal");

    document.getElementById("dock-vscode")?.addEventListener("click", () => {
      if (!this.winCodeEl) return;
      this.winCodeEl.classList.remove("is-hidden");
      this.focusWindow(this.winCodeEl);
      if (codeDot) codeDot.style.display = "block";
    });

    document.getElementById("dock-terminal")?.addEventListener("click", () => {
      if (!this.winTermEl) return;
      this.winTermEl.classList.remove("is-hidden");
      this.focusWindow(this.winTermEl);
      if (termDot) termDot.style.display = "block";
    });
  }

  private bindTrafficLights() {
    const bindWinLights = (
      win: HTMLElement | null,
      defaultCoords: {
        left: string;
        top: string;
        width: string;
        height: string;
      },
    ) => {
      if (!win) return;
      let isMax = false;

      win
        .querySelectorAll<HTMLButtonElement>("[data-win-action]")
        .forEach((btn) => {
          btn.addEventListener("click", (e) => {
            e.stopPropagation();
            const act = btn.dataset.winAction;
            if (act === "close" || act === "minimize") {
              win.classList.add("is-hidden");
              this.hideDivider();
            } else if (act === "maximize") {
              if (!isMax) {
                this.applySnapZone(win, {
                  left: 0,
                  top: 0,
                  width: 100,
                  height: 100,
                  label: "Maximize",
                });
                isMax = true;
                this.hideDivider();
              } else {
                win.style.left = defaultCoords.left;
                win.style.top = defaultCoords.top;
                win.style.width = defaultCoords.width;
                win.style.height = defaultCoords.height;
                isMax = false;
                this.setWindowBadge(win, "Zone: Free Float");
                this.checkAndUpdateSplitMode();
              }
            }
          });
        });
    };

    bindWinLights(this.winCodeEl, this.initialCodeCoords);
    bindWinLights(this.winTermEl, this.initialTermCoords);
  }

  private bindReset() {
    this.resetBtnEl?.addEventListener("click", () => {
      if (this.winCodeEl) {
        this.winCodeEl.classList.remove("is-hidden");
        this.winCodeEl.style.left = this.initialCodeCoords.left;
        this.winCodeEl.style.top = this.initialCodeCoords.top;
        this.winCodeEl.style.width = this.initialCodeCoords.width;
        this.winCodeEl.style.height = this.initialCodeCoords.height;
        this.setWindowBadge(this.winCodeEl, "Zone: Free Float");
      }

      if (this.winTermEl) {
        this.winTermEl.classList.remove("is-hidden");
        this.winTermEl.style.left = this.initialTermCoords.left;
        this.winTermEl.style.top = this.initialTermCoords.top;
        this.winTermEl.style.width = this.initialTermCoords.width;
        this.winTermEl.style.height = this.initialTermCoords.height;
        this.setWindowBadge(this.winTermEl, "Zone: Free Float");
      }

      this.focusWindow(this.winCodeEl);
      this.hidePicker();
      this.hideHudPreview();
      this.hideDivider();
      this.popoverEl?.classList.remove("is-open");
    });
  }

  private setupClock() {
    const updateClock = () => {
      if (!this.clockEl) return;
      const now = new Date();
      const hours = String(now.getHours()).padStart(2, "0");
      const minutes = String(now.getMinutes()).padStart(2, "0");
      this.clockEl.textContent = `${hours}:${minutes}`;
    };
    updateClock();
    window.setInterval(updateClock, 30000);
  }

  private setupIntersectionObserver() {
    if (!("IntersectionObserver" in window) || !this.frameEl) return;
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          this.isIntersecting = entry.isIntersecting;
        });
      },
      { threshold: 0.1 },
    );
    observer.observe(this.frameEl);
  }
}

// Auto-initialize when mounted
if (typeof document !== "undefined") {
  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      () => new DesktopSimulatorController(),
    );
  } else {
    new DesktopSimulatorController();
  }
}
