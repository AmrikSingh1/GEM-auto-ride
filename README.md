# 🔋 GEM - Go Extra Mile

![GEM App Mockup](file:///Users/amriksingh/.gemini/antigravity/brain/8212f571-963f-4b1d-a866-774cbe8ed425/gem_app_mockup_1775864485567.png)

**GEM (Go Extra Mile)** is a high-performance, intelligent auto-ride detection and tracking application for Android and iOS. Built with Flutter, it leverages a sophisticated fusion of GPS, Bluetooth, and Activity Recognition to seamlessly detect and record your commutes in the background without manual intervention.

---

## 🚀 Key Features

-   **🤖 Intelligent Auto-Detection**: Uses a custom FSM (Finite State Machine) to detect when a ride starts based on speed, Bluetooth connectivity, and physical activity.
-   **📡 Multi-Sensor Fusion**: Combines GPS data, Bluetooth device connection (vehicle detection), and Activity Recognition for high accuracy.
-   **📍 Background Precision**: Tracks commutes even when the app is in the background or the screen is locked using persistent background services.
-   **📊 Real-time Analytics**: Live speedometer, distance calculation, and duration tracking with a beautiful, responsive UI.
-   **🗺️ Interactive Mapping**: Custom dark-themed Google Maps integration with live route polyline rendering.
-   **🗄️ Offline First**: All commutes are saved locally using **Hive** for high-speed access and offline reliability.
-   **💎 Premium UI/UX**: Crafted with a sleek dark mode, smooth animations (`animate_do`), and a consistent design language.

---

## 🛠️ Tech Stack

-   **Framework**: [Flutter](https://flutter.dev) (SDK: ^3.5.0)
-   **State Management**: [Riverpod 2.0](https://riverpod.dev)
-   **Database**: [Hive](https://docs.hivedb.dev) (Local NoSQL)
-   **Maps**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
-   **Background Processing**: `flutter_background_service`, `workmanager`
-   **Connectivity**: `flutter_blue_plus` (BLE), `flutter_bluetooth_serial`
-   **Sensors**: `geolocator`, `activity_recognition_flutter`

---

## 🏗️ Getting Started

### Prerequisites

-   Flutter SDK installed
-   Google Maps API Key (for map rendering)
-   Physical device (recommended for sensor testing)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone git@github.com:AmrikSingh1/GEM-auto-ride.git
    cd GEM-auto-ride
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run build_runner**:
    (If any Hive models are modified)
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```text
lib/
├── core/             # Core configurations (Theme, Constants, Errors)
├── features/         # Feature-based architecture
│   ├── home/         # Dashboard, Live tracking, Map
│   ├── commutes/     # History and statistics
│   └── vehicles/     # Bluetooth device management
├── services/         # Global services (Location, Background, Permissions)
├── shared/           # Reusable widgets and utilities
└── main.dart         # Entry point & Provider scope
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ for the Go Extra Mile community.
</p>
