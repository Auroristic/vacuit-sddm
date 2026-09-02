# Full Customization Engine Specification

## Overview
Comprehensive customization system for the blewh-glass theme, providing dynamic 9-grid positioning with kinetic physics for the clock and login container, multiple clock styles (including Caelestia Split), avatar relative orientations, password box aesthetic styles, additional M3 shapes including Triangle, and production-grade button-to-menu morphing transitions for the session picker and user switcher.

## 1. 9-Grid Positioning Engine
Both Clock and Login/Avatar Container will be positioned dynamically via a 9-grid system:
- Positions:
  - Top Left
  - Top Center
  - Top Right
  - Middle Left
  - Middle Center
  - Middle Right
  - Bottom Left
  - Bottom Center
  - Bottom Right
- Transitions:
  - Behavior on x and Behavior on y with Easing.OutCubic (450ms) for smooth glide animation on change.
  - Safe margins: 40px screen padding and clearance from bottom controls.

## 2. Clock Customization Engine
- Styles:
  1. Caelestia Split: Hours:Minutes on left, vertical divider line, 3-tier stacked date on right (Month caps, Day number, Weekday).
  2. Classic Minimal: Clean horizontal time with date subtitle below.
  3. Two-Tier Stacked: Giant Hours stacked over Minutes with date beside.
  4. Compact Capsule: Time and date unified in a single glass pill.
- Scale Slider: 0.6x to 2.2x.
- Frosted Glass Card: Toggleable on/off, with opacity slider (15% to 85%).

## 3. Login and Avatar Customization Engine
- Container Position: 9-grid picker with smooth glide physics.
- Container Scale: 0.7x to 1.6x.
- Frosted Glass Card: Toggleable on/off with opacity slider.
- Avatar Relative Orientation:
  - Right: Avatar to the right of the password box.
  - Left: Avatar to the left of the password box.
  - Top Center: Avatar centered above the password box.
  - Top Left: Avatar on the top-left shoulder of the password box.
  - Top Right: Avatar on the top-right shoulder of the password box.
- Password Box Styles:
  1. Glass Pill: Rounded pill shape with neon accent border.
  2. Minimal Underline: Transparent background with glowing accent bottom line.
  3. Attached Split-Badge: Circular glass badge for lock icon connected to pill.
  4. Sharp M3 Card: Angular geometry with subtle chamfers.
- M3 Shapes:
  - Add MaterialShape.Triangle.
  - Full set: Triangle, Cookie 9-Sided, ClamShell, Sunny, Very Sunny, Cookie 4-Sided, Heart, Diamond, Circle, Square.

## 4. Button-to-Menu Morphing Animations
- Session Button to Session Menu:
  - Bottom-left session pill geometry expands upwards into the session menu card upon clicking.
  - Session items fade in with a staggered glide.
- Avatar Frame to User Switcher:
  - Clicking the avatar expands the frame directly into the user selection list modal.

## 5. Caelestia Glass Settings Hub
- Organized into tabs:
  - Clock: Style, Position, Scale, Card toggle & Opacity.
  - Login: Position, Scale, Avatar orientation, Box Style, Card toggle & Opacity.
  - Avatar: Shape picker (with Triangle), Border glow.
  - Palette: Themed color presets.
