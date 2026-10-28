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

## 🏗️ System Architecture & Subsystems Specification

The system is architected into 4 decoupled, high-cohesion subsystems adhering to strict clean-architecture boundaries:

![SplitBill Zero System Architecture](docs/SplitBill_Zero_Architecture.png)

*Editable Draw.io source available at: [`docs/SplitBill_Zero_Architecture.drawio`](docs/SplitBill_Zero_Architecture.drawio) (Import into [app.diagrams.net](https://app.diagrams.net))*

### Subsystems Breakdown:
- **Subsystem A (Client Interaction Layer):** Flutter 3.x Host Master Engine & Ultra-lightweight Guest PWA Web Client (< 250KB).
- **Subsystem B (On-Device Ingestion & OCR Engine):** CameraX/AVFoundation streaming buffer, Google ML Kit v2 OCR, 2D Spatial Geometric Clustering ($|\Delta Y| \le 0.5 \times \text{LineHeight}$), and Tax/Surcharge Distributer.
- **Subsystem C (Collaborative Session Mesh):** WebSocket / Supabase Realtime Gateway under topic `room:${roomId}`, in-memory ephemeral store with 2-hour TTL auto-eviction, and Fair-Split Math Matrix.
- **Subsystem D (Banking & Settlement Gateway):** EMVCo QR Tag Synthesizer (NAPAS 247), CRC-16/CCITT-FALSE Checksum Engine (Poly `0x1021`), and Payment Event Reconciliation Listener.

---

## 🔄 End-to-End UML Sequence Diagram

The interaction protocol across the 5 distinct phases from camera ingestion to Napas 24/7 instant settlement:

```mermaid
sequenceDiagram
    autonumber
    actor Host as Table Host (Phan Minh Duc)
    participant App as Mobile Host App (Flutter)
    participant MLKit as Edge OCR (ML Kit v2)
    participant Gateway as Realtime Mesh (Supabase)
    actor Guest as Dining Guest (Nam / Linh)
    participant Web as Guest Mobile Web (PWA)
    participant VietQR as EMVCo VietQR Engine
    participant Bank as Guest Banking App

    Note over Host,App: Phase 1: Receipt Ingestion & Spatial Line Matching
    Host->>App: Points camera at dining receipt
    App->>MLKit: Stream camera frames (YUV420 buffer)
    MLKit-->>App: RecognizedText (Blocks, Lines, BoundingBoxes)
    App->>App: 2D Spatial Clustering (Correlate item name with price)
    App-->>Host: Live bounding box overlay on bill
    Host->>App: Verifies items & taps "Create Room"

    Note over App,Gateway: Phase 2: Session Initialization & Table Broadcast
    App->>Gateway: POST /rooms {roomId, items[], hostBankInfo}
    Gateway-->>App: Room Created (Status: OPEN, TTL: 2 Hours)
    App->>Host: Display Table Joining QR (bill.io/r/VN8842)

    Note over Guest,Web: Phase 3: Zero-Install Participation
    Guest->>App: Scans Table QR with native Camera / Zalo
    Guest->>Web: Opens bill.io/r/VN8842 (No app install, Bundle < 250KB)
    Web->>Gateway: Subscribe to WebSocket channel `room:VN8842`
    Gateway-->>Web: Push initial room snapshot (items[], activeMembers[])
    Guest->>Web: Enters nickname ("Nam")

    Note over Guest,Gateway: Phase 4: Real-Time Collaborative Item Claiming
    Guest->>Web: Taps dish items (Trà Đào: 45k, Lẩu Bò: Shared 3 people)
    Web->>Gateway: Broadcast `item_claimed` {itemId, guestId, isShared}
    Gateway->>Gateway: Calculate Fair Split Matrix (Private + Shared/N + Proportional VAT)
    Gateway-->>Web: Broadcast updated room state to all connected guests
    Gateway-->>App: Sync real-time table dashboard on Host phone

    Note over Guest,Bank: Phase 5: Dynamic VietQR Settlement & Napas 24/7 Transfer
    Guest->>Web: Taps "Confirm & Settle" (Total: 161,600 VND)
    Web->>VietQR: GeneratePayload(HostBIN, HostAcc, 161600, "NAM TRA TIEN LAU")
    VietQR->>VietQR: Synthesize EMVCo TLV string & calculate CRC-16 (Poly 0x1021)
    VietQR-->>Web: Return Dynamic VietQR string & Banking Universal Deep-link
    Web-->>Guest: Render Dynamic VietQR + "Pay via Banking App" button
    Guest->>Bank: Taps button (Auto-fills Recipient, Amount, Reference Note)
    Guest->>Bank: Authenticates biometric payment (FaceID / Fingerprint)
    Bank-->>Host: Money instantly transferred to Host Bank Account
    Guest->>Web: Taps "Confirm Paid"
    Web->>Gateway: Broadcast `payment_completed` {guestId}
    Gateway-->>App: Update guest badge to PAID (Checkmark)
```

---

## 🧠 Algorithmic Pipeline: OCR Spatial Clustering & Line Matching

Raw OCR extracts unstructured text blocks scattered in 2D coordinates. SplitBill Zero utilizes a spatial grouping heuristic to reconstruct receipt tabular geometry:

```mermaid
flowchart TD
    A([Camera Stream: YUV420 Frame]) --> B[Google ML Kit Text Recognition v2]
    B --> C[Extract TextBlocks, Lines & BoundingBoxes]
    
    subgraph Preprocessing [Spatial & Lexical Preprocessing]
        C --> D[Identify Document Vertical Orientation & Angle]
        D --> E[Filter Out Noise Elements: Logo, Address, Date/Time]
    end

    subgraph GeometricMatching [Spatial 2D Geometric Clustering]
        E --> F[Cluster Text Elements by Vertical Band: delta Y &lt;= 0.5 * LineHeight]
        F --> G{Line Contains Numeric Token?}
        G -- Yes --> H[Check Right-Aligned Token with Currency Formats: k, đ, VND, ., ,]
        G -- No --> I[Candidate Multi-line Dish Name]
        I --> J[Merge with vertically adjacent below block if aligned left]
        H --> K[Candidate Price Value Entity]
        J --> L[Pair Name Entity with Right-Aligned Price Entity]
        K --> L
    end

    subgraph BusinessValidation [Financial Reconciliation & Tax Distribution]
        L --> M{Is Subtotal / Total / VAT Tag?}
        M -- Yes: Total Tag --> N[Store as Baseline Target Total]
        M -- Yes: VAT/Service Tag --> O[Compute Tax Percentage or Absolute Surcharge]
        M -- No: Standard Dish --> P[Append to LineItems Collection]
        
        N --> Q[Reconcile: Sum of LineItems vs Target Total]
        O --> Q
        P --> Q
        
        Q --> R{Discrepancy Detected?}
        R -- Yes --> S[Flag Line for Host Manual Confirmation]
        R -- No --> T[Validated Receipt JSON Entity]
    end

    S --> U([Render Verification Screen on Mobile Host])
    T --> U
```

### Mathematical Clustering Formulation:
$$\text{Vertical Closeness Condition:} \quad |Y_{\text{price}} - Y_{\text{item}}| \le \theta_{\text{line\_height}} \times 0.5$$
$$\text{Horizontal Alignment Check:} \quad X_{\text{price}} > X_{\text{item}} \quad (\text{Right-aligned price pattern})$$

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
│   ├── SplitBill_Zero_Architecture.drawio   # Editable enterprise system design diagram
│   ├── SplitBill_Zero_Architecture.png      # High-res architecture export
│   ├── SplitBill_Zero_Sequence_Diagram.png  # Standard UML Sequence Diagram
│   ├── SplitBill_Zero_OCR_Flowchart.png     # Algorithmic spatial matching flowchart
│   └── SplitBill_Zero_UI_Showcase.png       # Production UI/UX spec & design showcase
└── README.md
```

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

## 🎨 Official UI/UX Design System (Figma)

The complete production design file is hosted and maintained on Figma:

* 🔗 **Figma Project File:** [SplitBill Zero UI/UX Specification on Figma](https://www.figma.com/design/o8mIiPoLyks3y0BV7fQ3sw/Untitled?node-id=0-1&p=f&t=XjQc695CtCxboMY7-0)
* **Screen Specifications:** Host Camera Receipt Scanner, Table Room QR, Collaborative Guest PWA, Dynamic VietQR Instant Settle.

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
