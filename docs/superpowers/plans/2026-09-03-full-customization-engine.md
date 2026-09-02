# Full Customization Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement comprehensive customization for the blewh-glass theme, including 9-grid dynamic positioning for Clock and Login, multiple Clock styles, Avatar orientations, Password Box styles, Triangle M3 shape, and button-to-menu morphing animations.

**Architecture:** Extend `scratch/Main.qml` with dedicated component controllers and models, verify syntax with test mode, and deploy to `themes/blewh-glass/Main.qml`.

**Tech Stack:** Qt 6 QML, QtQuick, Qt5Compat.GraphicalEffects, SDDM Greeter Qt6.

**Spec:** `/home/retro/.gemini/antigravity-cli/brain/43df0dc2-a964-4b61-8df5-a3cb252b8a61/docs/superpowers/specs/2026-09-03-full-customization-engine-design.md`

## Global Constraints
- Do not edit or touch personal configuration or outside directories. Only edit files inside `/home/retro/qylock/themes/blewh-glass` and `/home/retro/.gemini/antigravity-cli/brain/43df0dc2-a964-4b61-8df5-a3cb252b8a61/scratch/`.
- No emojis in any agent communication or user-facing messages.

---

### Task 1: Add Triangle M3 Shape and Expand MaterialShape Collection
**Files:**
- Modify: `scratch/Main.qml`
- Test: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

- [ ] **Step 1: Check MaterialShape enum and path definitions**
- [ ] **Step 2: Add Triangle shape to MaterialShape enum, shape paths, and avatar selection**
- [ ] **Step 3: Verify syntax in test mode**

### Task 2: Implement Clock Customization System with 9-Grid & Caelestia Split Style
**Files:**
- Modify: `scratch/Main.qml`
- Test: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

- [ ] **Step 1: Implement Clock styles (Caelestia Split, Minimal, Two-Tier, Capsule)**
- [ ] **Step 2: Add 9-grid positioning function with smooth Behavior on x and y**
- [ ] **Step 3: Add toggleable frosted glass background card with opacity slider**
- [ ] **Step 4: Add scale property for clock (0.6x to 2.2x)**
- [ ] **Step 5: Verify syntax in test mode**

### Task 3: Implement Login Container 9-Grid, Avatar Orientations, and Box Styles
**Files:**
- Modify: `scratch/Main.qml`
- Test: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

- [ ] **Step 1: Implement 9-grid positioning for the login & avatar container with Behavior on x/y**
- [ ] **Step 2: Implement Avatar relative orientation (Right, Left, Top Center, Top Left, Top Right)**
- [ ] **Step 3: Implement Password Box styles (Glass Pill, Minimal Underline, Split-Badge, Sharp M3 Card)**
- [ ] **Step 4: Add container scale control and toggleable frosted glass card**
- [ ] **Step 5: Verify syntax in test mode**

### Task 4: Implement Button-to-Menu Morphing Animations
**Files:**
- Modify: `scratch/Main.qml`
- Test: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

- [ ] **Step 1: Morph bottom-left session pill geometry upwards into the session menu**
- [ ] **Step 2: Morph avatar frame smoothly into the user switcher menu**
- [ ] **Step 3: Verify smooth 60fps transitions and staggered reveals**

### Task 5: Build Caelestia-Inspired Glass Settings Hub UI
**Files:**
- Modify: `scratch/Main.qml`
- Deploy: `cp scratch/Main.qml themes/blewh-glass/Main.qml`
- Test: `sddm-greeter-qt6 --test-mode --theme /home/retro/qylock/themes/blewh-glass`

- [ ] **Step 1: Build categorized tabbed settings window (Clock, Login, Avatar, Themes)**
- [ ] **Step 2: Connect all controls, toggles, steppers, and sliders**
- [ ] **Step 3: Deploy to theme and run test mode for live verification**
