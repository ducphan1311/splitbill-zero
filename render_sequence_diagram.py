import subprocess

# Mermaid Sequence Diagram & System Architecture rendered via Mermaid CDN in headless browser

html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  body { background: #0B0F19; color: #E2E8F0; padding: 40px; width: 1920px; }
  .header { margin-bottom: 24px; border-bottom: 2px solid #1E293B; padding-bottom: 16px; }
  .tag { font-size: 13px; font-weight: 700; color: #38BDF8; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 6px; }
  .title { font-size: 30px; font-weight: 800; color: #FFFFFF; }
  .title span { color: #38BDF8; }
  .desc { font-size: 14px; color: #94A3B8; margin-top: 4px; }
  .diagram-box { background: #111827; border: 1px solid #1F2937; border-radius: 14px; padding: 28px; }
  .mermaid { display: flex; justify-content: center; }
</style>
<script>
  mermaid.initialize({
    startOnLoad: true,
    theme: 'dark',
    themeVariables: {
      darkMode: true,
      background: '#111827',
      primaryColor: '#1E293B',
      primaryTextColor: '#F8FAFC',
      primaryBorderColor: '#38BDF8',
      lineColor: '#64748B',
      secondaryColor: '#1E293B',
      tertiaryColor: '#0F172A',
      noteBkgColor: '#1E293B',
      noteTextColor: '#38BDF8',
      noteBorderColor: '#38BDF8',
      actorBkg: '#1E293B',
      actorBorder: '#38BDF8',
      actorTextColor: '#FFFFFF',
      signalColor: '#E2E8F0',
      signalTextColor: '#E2E8F0',
      activationBkgColor: '#0284C7',
      activationBorderColor: '#38BDF8'
    }
  });
</script>
</head>
<body>
  <div class="header">
    <div class="tag">Standard UML Specification</div>
    <div class="title">⚡ SplitBill Zero: <span>End-to-End UML Sequence Diagram</span></div>
    <div class="desc">Deterministic 5-phase protocol: Receipt Ingestion ➔ Session Mesh ➔ Zero-Install Claiming ➔ Dynamic VietQR ➔ Instant Settlement</div>
  </div>
  <div class="diagram-box">
    <div class="mermaid">
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
    App-->>Host: Live AR bounding box overlay on physical bill
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
    Gateway-->>App: Update guest badge to PAID (Green checkmark)
    </div>
  </div>
</body>
</html>
"""

with open("projects/splitbill-zero/docs/sequence_diagram.html", "w", encoding="utf-8") as f:
    f.write(html_content)

print("Saved sequence_diagram.html")
