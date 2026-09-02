# SDDM Custom Theme Development: blewh-glass

## Project & Goal Overview
Build a production-grade, bug-free, high-performance SDDM Qt6 theme based on Caelestia desktop widget aesthetics, Nothing OS glassmorphism, and Material 3 design principles. Key objectives include:
- Deep frosted glassmorphism with dynamic themed color palettes and soft ambient glow.
- Kinetic 60fps animations with zero jitter, zero sudden jumps, and zero visual flashing.
- Complete user customizability: 9-grid positioning and scale sliders for both Clock and Login containers, toggleable frosted glass background cards, multiple clock and password box styles, dynamic avatar shapes (including Triangle), and seamless button-to-menu morphing transitions.

---

## File & Resource Locations

### Theme & Codebase
- Theme Root: `/home/retro/qylock/themes/blewh-glass/`
- Active Theme Entrypoint: `/home/retro/qylock/themes/blewh-glass/Main.qml`
- Active Theme Config: `/home/retro/qylock/themes/blewh-glass/theme.conf`
- Staging / Safe Edit Copy: `/home/retro/.gemini/antigravity-cli/brain/43df0dc2-a964-4b61-8df5-a3cb252b8a61/scratch/Main.qml`
- SDDM Test Script: `/home/retro/qylock/sddm.sh`
- Test Mode Command: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

### Documentation & Specifications
- Progress Tracker: `/home/retro/retroisticx/ai docs/sddm-customize/progress.md`
- Architecture Specification: `/home/retro/.gemini/antigravity-cli/brain/43df0dc2-a964-4b61-8df5-a3cb252b8a61/docs/superpowers/specs/2026-09-03-full-customization-engine-design.md`
- Implementation Plan: `/home/retro/.gemini/antigravity-cli/brain/43df0dc2-a964-4b61-8df5-a3cb252b8a61/docs/superpowers/plans/2026-09-03-full-customization-engine.md`

### Wallpapers & Media Assets
- Theme Wallpaper: `/home/retro/qylock/themes/blewh-glass/bg.jpg` (symlinked/copied from `blewh56.jpg`)
- Static Wallpapers Directory: `/home/retro/Pictures/Wallpapers/`
- Animated Video Loops Directory: `/home/retro/Pictures/Wallpapers/Animated/` (contains `pingxlm.mp4`)
- User Face Avatar: `/home/retro/.face`

### Installed System Modules & Fonts
- M3Shapes QML Module: `/usr/lib/qt6/qml/M3Shapes/` (provides `MaterialShape` with 35 shapes: Circle, Square, Slanted, Arch, Fan, Arrow, SemiCircle, Oval, Pill, Triangle, Diamond, ClamShell, Pentagon, Gem, Sunny, VerySunny, Cookie4Sided, Cookie6Sided, Cookie7Sided, Cookie9Sided, Cookie12Sided, Ghostish, Clover4Leaf, Clover8Leaf, Burst, SoftBurst, Boom, SoftBoom, Flower, Puffy, PuffyDiamond, PixelCircle, PixelTriangle, Bun, Heart)
- Bundled Fonts: `/home/retro/qylock/themes/blewh-glass/font/` (JetBrainsMono Nerd Font & Google Sans Flex)

### Reference Video Recordings
- `recording_20260902_22-38-24.mp4`: Keyboard & power pill interaction and layout offset issues.
- `recording_20260902_22-41-06.mp4`: Desktop glassy/blurry widgets visual reference.
- `recording_20260902_22-42-31.mp4`: Caelestia lockscreen reference showing smooth password box click bloom and M3 shape typing dots.
- `recording_20260902_22-43-56.mp4`: Animation breakage check.
- `recording_20260902_22-49-39.mp4`: Blur and background testing.
- `recording_20260902_22-56-59.mp4`: Password box text overlap and multi-user/session entry testing.
- `recording_20260902_23-19-43.mp4`: Password box typing jitter and click animation request.
- `recording_20260902_23-44-45.mp4`: Repeater delegate refresh glitch and press bounce frame overflow.
- `recording_20260903_00-33-40.mp4`: Caelestia Desktop Clock settings window demonstrating 9-grid position selection, scale slider, background card toggle, and opacity slider.

---

## User Preferences & Verbatim Directives

### General Rules & Communication
- No emojis in agent messages or documentation.
- Never edit, touch, or alter user configuration or personal PC files outside `/home/retro/qylock/themes/blewh-glass` and documentation.
- Prioritize high visual fidelity, production-grade animations, and clean C++ / QML architecture.

### User Directives Log
1. Keyboard Animation: "the keyboard button should animate into the keyboard bruh do that and ill test others"
2. Power & Layout Interaction: "the lava lamp row height is too much? like thers a lot below now but also look how when power menu opens keyboard buttons fucks up fix that too"
3. Aesthetic Benchmark: "also look how glassy/transparent/blurry like widgets here on my desktop i want the menus and everything to look like this yk"
4. Reference Behavior: "look at the animations on like how it looks when like pressing on the password thing and the password thing and like yeah u get me?? the glassy ness how the animations when putting the passsword looks and the animation when clicking on the password boxx how it looks everything u see is super good"
5. Dynamic Palette Propagation: "the backgroudns of the menus color dont change according to the theme bro fix that and launch again menus and password box buttons etc everything"
6. Test Entries & Text Overlap: "the text overlap on password box lol ... and here look how texts come from like yeah not the button its like ugly u see? also can u add some fake user enteries js so i can test how they look also on the hyprland like yeah tehre too add a fake one pheww so i can test those menues too"
7. Typing & Click Feedback: "the animations when im typing like text entered animations are baddddddddddd BADDDDDDDDDDDDDDDDDDDDD SO BAD and also when i click the pw box like i showed u an animation if u rember idk js make an animation for that if possible"
8. Shape Typing Confirmation: "text animations are using the same shapes that u r using for the pfp so u can make the text box animations with that maybe and yeah"
9. Refresh & Bounce Feedback: "yup wayy better than before but look at the animation is baddddddd like yeah it js looking it refreshes whenever i enter text and also the press bounce aniomation goes beyond as u see"
10. Rectangular Artifact Report: "fix this bro this how the press animations not matching look" (with screenshot showing rectangular scissor clip)
11. Customization Target: "now adding customizebility is the goal: different clock styles first and also changing the scale of the clock like wait let me show u some examples? only take the clock examples oka?"
12. Comprehensive Customization Scope: "like this level of customization the position of clock etc etc and also this level of customization should be there for the like this part too like changing the avatar on top of the box or left side or right side and like also the background customization shapes etc etc and allat and remember to make the menu look nicer and stuff okay? like smooth animations etc etc and also the hyprland like that menu animations are shit and also the user changing animations are also shit u forgot the button to menu transformation smooth animations on those"
13. Background & Triangle Shape: "background card should be able to turn on or off btw and also 2- yup those customization options AND ALSO same customization options as clock like supports top left center middle and middle left center right ... add the trianglur m3 shape too no triangle is there"

---

## Technical Research & Engineering Knowledge

### 1. QML Repeater Lifecycle Bug ("Refreshes on Every Keystroke")
- Root Cause: Binding `Repeater { model: passwordInput.text.length }` in QtQuick caused the QML engine to re-evaluate the entire delegate set on every character change. Delegates were destroyed and re-instantiated, resetting `scale: 0.0` and executing `Component.onCompleted: popAnim.start()` on all existing characters.
- Solution: Pre-allocated static pool of 24 delegates (`model: 24`). Delegates are initialized once during startup and never destroyed. An `isShown` property (`index < text.length`) drives smooth per-character scale (`0.0 -> 1.0`) and width (`0 -> 12px`) transitions with `Easing.OutBack`. Existing characters remain completely stable.

### 2. Press Bounce Frame Overflow
- Root Cause: Adding `scale: boxPressMa.pressed ? 0.985 : 1.0` with `Behavior on scale` containing `overshoot: 1.2` caused the physical frame to expand to 103% upon mouse release, stretching beyond its designated layout boundaries and clipping adjacent elements.
- Solution: Removed frame-level scaling. Kept `passwordBoxRect` at a fixed 1.0 scale and implemented inner luminous bloom feedback.

### 3. Rectangular Scissor Artifact Behind Rounded Pill
- Root Cause: Applying `clip: true` directly to an item with `layer.enabled: true` and `layer.effect: DropShadow` activates OpenGL scissor clipping (`glScissor`), which is strictly axis-aligned rectangular. When an unconstrained circular ripple expanded within this item, it clipped into a sharp rectangle, and `DropShadow` rendered a shadow around the rectangular scissor quad.
- Solution: Removed `clip: true` and oversized circular ripples. Replaced with an inner `Rectangle` with `anchors.fill: parent` and `radius: parent.radius` that animates `pressBloom`. This mathematically confines the highlight to the exact pill contour at all times.

### 4. Caelestia Clock Architecture
- Extracted from `uploaded_media_1788375749668.png` and `recording_20260903_00-33-40.mp4`:
  - Time format: Bold digital glyphs (`00:33`).
  - Divider: Thin vertical glass line `|`.
  - Date format: 3-tier vertical column with uppercase month (`SEPTEMBER`), day number (`03`), and weekday (`Thursday`).
  - Positioning: 9-grid system (`Top Left`, `Top Center`, `Top Right`, `Middle Left`, `Middle Center`, `Middle Right`, `Bottom Left`, `Bottom Center`, `Bottom Right`).
  - Scale: Continuously adjustable from 0.6x to 2.2x.
  - Background: Optional frosted glass rounded card (`radius: 24px`) with opacity slider.

### 5. M3Shapes Module Capabilities
- Verified via `/usr/lib/qt6/qml/M3Shapes/m3shapes.qmltypes`:
  - `MaterialShape.Triangle` is natively supported in the C++ library.
  - Can be added immediately to the avatar shape selector and password dot cycle.

---

## Accomplished Work

1. Core Architecture & Theme Framework:
   - Full SDDM Qt6 compliance with working fallback mock environments.
   - Clean theme structure in `/home/retro/qylock/themes/blewh-glass/`.
   - Google Sans Flex and JetBrainsMono font integration.

2. Glassmorphic Design System:
   - Dynamic `root.accentColor`, `root.glassBg`, `root.glassBorder`, and `root.highlightGlow` across all menus and pills.
   - Smooth palette morphing transitions when switching color presets.

3. Bug Fixes & Refinements:
   - Fixed cursor dot overlapping directly onto the placeholder text.
   - Resolved squashed text during power pill expansion using delayed sequential blossom.
   - Eliminated keyboard button pushback glitch when opening the power menu.
   - Fixed all password dot flickering and jitter using a pre-allocated fixed pool.
   - Fixed rectangular scissor clip artifact by removing `clip: true` and implementing pill-conforming bloom.

4. Mock Testing Infrastructure:
   - Added user switch entries: `retro`, `Astra`, `Lumine`, `Guest Account`.
   - Added desktop session entries: `Hyprland (Wayland)`, `Hyprland (UWSM)`, `Plasma 6`, `GNOME`, `Sway`.

---

## Current Work & Planned Tasks

### Task 1: Add Triangle M3 Shape
- Add `MaterialShape.Triangle` to the avatar shape selection list in the Settings Hub. (Completed and verified)
- Add `MaterialShape.Triangle` to the password dots shape array. (Completed and verified)

### Task 2: Clock Customization System (Completed and Verified)
- Implement 4 Clock Styles: (Completed)
  1. Caelestia Split: Hours:Minutes | vertical divider | 3-tier stacked date (Month, Day, Weekday).
  2. Classic Minimal: Horizontal time with date subtitle below.
  3. Two-Tier Stacked: Giant Hours over Minutes with date pill.
  4. Compact Capsule: Inline time and date in a glass pill.
- Implement 9-Grid Screen Positioning: (Completed)
  - Positions: `Top Left`, `Top Center`, `Top Right`, `Middle Left`, `Middle Center`, `Middle Right`, `Bottom Left`, `Bottom Center`, `Bottom Right`.
  - Transitions: `Behavior on x` and `Behavior on y` with `Easing.OutCubic` (450ms) for smooth kinetic glide.
- Implement Scale Slider (0.6x to 2.2x). (Completed)
- Implement Toggleable Frosted Glass Background Card with opacity control (15% to 85%). (Completed)
- Ensure clock remains optionally visible in the unlocked/login state. (Completed)

### Task 3: Login Container Customization System (Completed and Verified)
- Implement 9-Grid Screen Positioning for Login & Avatar Container with kinetic glide. (Completed)
- Implement Container Scale Slider (0.7x to 1.6x). (Completed)
- Implement Toggleable Frosted Glass Background Card with opacity control. (Completed)
- Implement Avatar Relative Orientation: (Completed)
  - `Right`: Avatar to the right of password box.
  - `Left`: Avatar to the left of password box.
  - `Top Center`: Avatar centered above password box.
  - `Top Left`: Avatar on top-left shoulder of password box.
  - `Top Right`: Avatar on top-right shoulder of password box.
- Implement 4 Password Box Styles: (Completed)
  1. Glass Pill: Full 360-degree rounded pill.
  2. Minimal Underline: Transparent background with glowing bottom border line.
  3. Split Badge: Lock icon in an attached circular glass badge.
  4. Sharp M3 Card: Chamfered rectangular Material 3 card geometry.

### Task 4: Button-to-Menu Morphing Animations (Completed and Verified)
- Morph Session Pill: Expand bottom-left session pill geometry upwards into the session menu card on click, with staggered item fade-in. (Completed)
- Morph Avatar Frame: Expand avatar frame smoothly into user switcher list modal. (Completed)

### Task 5: Caelestia Glass Settings Hub UI (Completed and Verified)
- Redesign the Settings modal into organized glass tabs: (Completed)
  - Tab 1: Clock (Style, 9-Grid Position, Scale Slider, Background Card Toggle & Opacity, Show on Login).
  - Tab 2: Login & Box (9-Grid Position, Scale Slider, Avatar Orientation, Box Style, Background Card Toggle).
  - Tab 3: Avatar (Shape Selector with 11 M3 shapes including Triangle, Live Shape Preview).
  - Tab 4: Themes & Palette (Preset Color Schemes, 12h/24h toggle, Ambient Lava Blobs toggle).
- Verified with qmllint: 0 errors, 0 warnings.
- Verified live with sddm-greeter-qt6 in test mode.
- Synchronized with /home/retro/qylock/themes/blewh-glass/Main.qml.

