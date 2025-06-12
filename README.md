
# 📱 Swift Scanning App

An iOS scanning application built with Swift that supports 3D scanning using either:

- **Apple Sensor** (using the **front-facing TrueDepth camera**)
- **Structure Sensor**

Users can choose their preferred scanning method from the **Settings** screen. After scanning, the app displays the mesh model and allows further interactions.

---

## 🧾 Overview

This app allows users to perform 3D scanning using two different types of sensors and view the scanned model in an interactive viewer.

- 🔍 **Apple Sensor** (via front camera / TrueDepth)
- 📦 **Structure Sensor**
- 📺 Mesh viewer post-scan
- ⚙️ Settings to choose the preferred sensor

---

## 🛠 Architecture

### 1. Sensor Selection

- **Default Sensor**: Apple Sensor (Front-facing camera)
- **Customizable**: Users can switch between Apple and Structure Sensor from the **Settings** screen.
- The preference determines which scanning view is launched.

### 2. Main View Controllers

| Class Name                    | Role                                                 |
|------------------------------|------------------------------------------------------|
| `ViewController.swift`       | Scanning with Apple Sensor (Front Camera - TrueDepth)|
| `StructureViewController.swift` | Scanning with Structure Sensor                     |
| `MeshViewController.swift`   | Displays scanned mesh model and provides actions     |
| `SettingsViewController.swift` | Allows the user to choose their preferred sensor   |

Each scanner uses its own dedicated screen and class.

### 3. Scanned Model Viewer

After the scan is complete from either sensor:
- The app **navigates to `MeshViewController`**
- It displays the scanned 3D mesh
- Users can **view, rotate, zoom, and perform custom actions** on the mesh

---

## 📂 File Summary

| File                        | Purpose                                         |
|-----------------------------|-------------------------------------------------|
| `ViewController.swift`       | Apple Sensor scanning using front-facing camera |
| `StructureViewController.swift` | Structure Sensor scanning logic            |
| `MeshViewController.swift`   | Display scanned mesh and perform actions        |
| `SettingsViewController.swift` | Allow sensor preference selection             |
