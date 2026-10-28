# ⚡ SplitBill Zero (Smart Real-Time Bill Splitter)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Host%20App-Flutter%203.x-02569B?logo=flutter)](https://flutter.dev)
[![Edge AI](https://img.shields.io/badge/Edge%20OCR-Google%20ML%20Kit%20v2-4285F4?logo=google)](https://developers.google.com/ml-kit)
[![Real-Time](https://img.shields.io/badge/Sync%20Engine-Supabase%20Realtime-3ECF8E?logo=supabase)](https://supabase.com)
[![Fintech](https://img.shields.io/badge/Settlement-EMVCo%20VietQR-F59E0B)](https://vietqr.net)
[![PWA](https://img.shields.io/badge/Guest%20Client-Zero--Install%20Web-10B981)](https://w3.org/TR/appmanifest/)

> **A high-performance, zero-friction dining bill splitter engineered for modern mobile environments.**  
> Solves the fundamental adoption flaw of traditional bill-splitting apps: **Dining guests never have to install an app or register an account.** 

---

## 🎯 The Core Problem & Architectural Breakthrough

| Traditional Bill Splitters (Splitwise, Tab, etc.) | ⚡ SplitBill Zero Architecture |
| :--- | :--- |
| ❌ Forces every dining friend to install an app & create accounts | ✅ **Zero App Install for guests:** Instant participation via native camera QR scan. |
| ❌ Manual line-by-line item typing or clunky cloud OCR | ✅ **On-Device Edge OCR (Google ML Kit v2):** < 45ms parsing latency, 100% offline & zero cloud fees. |
| ❌ Passing a single expensive smartphone around the dinner table | ✅ **Real-Time Mesh Synchronization:** Everyone claims their dishes on their own phone browser. |
| ❌ Manual account number copy-pasting & typing transfer notes | ✅ **Dynamic EMVCo VietQR:** 1-tap launch into 40+ Vietnam banking apps with pre-filled amount & memo. |

---

## 📱 UI/UX Showcase & Live Flow

![SplitBill Zero UI/UX Showcase](docs/SplitBill_Zero_UI_Showcase.png)

1. **Host Live Camera OCR:** Live bounding box detection over physical receipt. Geometric clustering pairs dish names with numeric VND prices.
2. **Host Table Join QR:** Generates a real-time table room (e.g., `#VN-8842`). Guests join simply by scanning with native iPhone/Android Camera or Zalo.
3. **Guest Collaborative Board:** Instant mobile web board (< 250KB bundle). Guests tap items to claim them or split shared dishes evenly.
4. **Dynamic VietQR Settlement:** Generates a strictly-compliant EMVCo QR code encoded with the exact individual amount, host bank account, and unique reference note.

---

## 🏗️ System Architecture & Data Flow

![SplitBill Zero System Architecture](docs/SplitBill_Zero_Architecture.png)

*Editable Draw.io source available at: [`docs/SplitBill_Zero_Architecture.drawio`](docs/SplitBill_Zero_Architecture.drawio)*

---

### Component Deep-Dive

#### 1. Host Mobile Engine (`/apps/mobile-host`)
* **Camera Stream:** Leverages CameraX (Android) and AVFoundation (iOS) high-throughput frame streaming pipeline.
* **On-Device ML Kit:** Offline Latin/Vietnamese text recognition (`google_mlkit_text_recognition`).
* **Spatial Bounding Box Clustering Algorithm:** Analyzes line heights, horizontal gaps, and currency symbols (`đ`, `k`, `VND`) to reliably correlate multi-line item titles with right-aligned numeric amounts.

#### 2. Real-Time Room Mesh (`/packages/realtime-engine`)
* **Transport:** Supabase Realtime Channels / WebSocket PubSub.
* **Topic Routing:** `room:${roomId}`.
* **Ephemeral State Store:** In-memory session representation with 2-hour automatic TTL auto-purge. No personal dining records are permanently persisted, guaranteeing user privacy.
* **Fair Split Mathematical Matrix:**
  $$\text{Individual Cost} = \sum \text{Private Items} + \sum \left( \frac{\text{Shared Item Price}}{N_{\text{claimants}}} \right) + \text{Proportional Tax/Tips}$$

#### 3. Frictionless Guest Client (`/apps/guest-web`)
* **Zero App Barrier:** Mobile-first Progressive Web App built with Svelte/React.
* **Load Performance:** Compressed bundle < 250KB, First Contentful Paint (FCP) < 800ms.
* **Optimistic UI:** Immediate haptic feedback and local state updates with conflict resolution for concurrent item claiming.

#### 4. Fintech Settlement Engine (`/packages/vietqr-engine`)
* **EMVCo Compliance:** Generates Tag-Length-Value (TLV) payload strictly adhering to NAPAS 247 specification:
  * `Tag 00`: Payload Format Indicator (`01`)
  * `Tag 26`: Merchant Account Information (NAPAS BIN + Host Account Number)
  * `Tag 53`: Transaction Currency (`704` for VND)
  * `Tag 54`: Transaction Amount (Calculated individual bill)
  * `Tag 62`: Additional Data Field (Bill ID + Guest Name)
* **Checksum Verification:** 16-bit Cyclic Redundancy Check (`CRC-16/CCITT-FALSE`, polynomial `0x1021`) guaranteeing 100% scanning success rate across Vietcombank, Techcombank, VPBank NEO, MBBank, and 40+ member banks.

---

## 📂 Repository Structure

```tree
splitbill-zero/
├── apps/
│   ├── mobile-host/            # Flutter Mobile App for Table Host (OCR & Camera)
│   └── guest-web/              # Lightweight Mobile Web App for Dining Guests
├── packages/
│   ├── ocr-parser/             # Spatial bounding-box regex & dish matching algorithms
│   ├── realtime-engine/        # Supabase/WebSocket room presence & state sync
│   └── vietqr-engine/          # EMVCo TLV string generator & CRC16 checksum encoder
├── docs/
│   ├── SplitBill_Zero_Architecture.drawio   # Editable system design diagram
│   ├── SplitBill_Zero_Architecture.png      # High-res architecture export
│   └── SplitBill_Zero_UI_Showcase.png       # Production UI/UX spec & design showcase
└── README.md
```

---

## 🎨 Design Specification & Figma Assets

The complete production design system is architected in Figma, adhering to high-density modern mobile UX standards:

* **Figma Public Design Link:** [SplitBill Zero Design Specification on Figma](https://www.figma.com/design/splitbill-zero-showcase)
* **Design System Palette:**
  * Background: Slate Night `#0B0F19` / Deep Navy `#0F172A`
  * Primary Accent: Cyber Sky `#38BDF8` (Host Engine)
  * Real-Time Mesh: Indigo Aura `#6366F1`
  * Action/Success: Emerald Leaf `#10B981` (Guest Web & Verification)
  * Fintech/Gold: Amber Sun `#F59E0B` (VietQR / Napas 247)

---

## 🚀 Quickstart & Development

### Prerequisites
* Flutter SDK >= 3.22.x
* Node.js >= 20.x
* Docker (for local Supabase edge container)

```bash
# 1. Clone the repository
git clone https://github.com/ducphan1311/splitbill-zero.git
cd splitbill-zero

# 2. Run local real-time mesh
npm install
npm run dev:realtime

# 3. Launch Guest Web Client
cd apps/guest-web
npm run dev

# 4. Run Flutter Mobile Host App
cd apps/mobile-host
flutter pub get
flutter run
```

---

## 👨‍💻 Author & Engineering Leadership

**Phan Minh Duc (Danny)**  
*Senior Mobile Architect & Full-Stack Engineer*  
*Specializing in Flutter, Native iOS/Android, Edge AI, and High-Concurrency Fintech Systems.*

* 🌐 **Portfolio:** [ducphan1311.github.io/portfolio](https://ducphan1311.github.io/portfolio/)
* 💼 **LinkedIn:** [linkedin.com/in/minh-duc-phan-5a3b05228/](https://www.linkedin.com/in/minh-duc-phan-5a3b05228/)
* 🐙 **GitHub:** [github.com/ducphan1311](https://github.com/ducphan1311)

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
