import subprocess

html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif; }
  body { background: #0F172A; color: #F8FAFC; width: 1920px; height: 1080px; padding: 36px 50px; display: flex; flex-direction: column; justify-content: space-between; }
  
  /* Header */
  .header { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 1px solid #334155; padding-bottom: 20px; }
  .tag { font-size: 13px; font-weight: 700; color: #38BDF8; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 6px; }
  .title { font-size: 32px; font-weight: 800; color: #FFFFFF; }
  .title span { color: #38BDF8; }
  .desc { font-size: 14px; color: #94A3B8; margin-top: 4px; }
  .figma-badge { background: #1E293B; border: 1px solid #475569; padding: 8px 18px; border-radius: 100px; display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 600; color: #F1F5F9; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: #10B981; }

  /* Screens Gallery (4 Mobile Frames) */
  .screens { display: grid; grid-template-columns: repeat(4, 1fr); gap: 32px; flex: 1; margin: 24px 0; align-items: center; }
  
  .phone-wrap { display: flex; flex-direction: column; align-items: center; }
  .phone-label { font-size: 14px; font-weight: 700; color: #E2E8F0; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }
  .phone-step { width: 22px; height: 22px; border-radius: 50%; background: #38BDF8; color: #0F172A; font-size: 11px; font-weight: 800; display: flex; align-items: center; justify-content: center; }

  /* Mobile Device Mockup */
  .mockup { width: 340px; height: 680px; background: #000000; border: 3px solid #334155; border-radius: 44px; padding: 14px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7); position: relative; overflow: hidden; display: flex; flex-direction: column; }
  .mockup.host { border-color: #0284C7; box-shadow: 0 0 30px rgba(2, 132, 199, 0.25); }
  .mockup.guest { border-color: #10B981; box-shadow: 0 0 30px rgba(16, 185, 129, 0.2); }
  .mockup.settle { border-color: #F59E0B; box-shadow: 0 0 30px rgba(245, 158, 11, 0.2); }

  .notch { width: 120px; height: 24px; background: #000000; border-radius: 0 0 16px 16px; position: absolute; top: 0; left: 50%; transform: translateX(-50%); z-index: 10; }
  .screen-content { background: #0B0F19; border-radius: 32px; width: 100%; height: 100%; overflow: hidden; display: flex; flex-direction: column; padding: 28px 16px 16px 16px; position: relative; }

  /* Screen 1: Camera Scanner */
  .camera-view { background: #1E293B; border-radius: 20px; flex: 1; position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: center; align-items: center; border: 2px dashed #475569; }
  .receipt-paper { background: #F8FAFC; color: #0F172A; width: 220px; padding: 14px; border-radius: 8px; font-family: monospace; font-size: 10px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.4); }
  .box-overlay { border: 2px solid #38BDF8; background: rgba(56, 189, 248, 0.25); border-radius: 4px; padding: 2px 4px; margin: 3px 0; font-weight: bold; }
  .scan-btn { background: #0284C7; color: #fff; font-size: 13px; font-weight: 700; padding: 12px; border-radius: 12px; text-align: center; margin-top: 14px; }

  /* Screen 2: Host Table QR */
  .qr-box { background: #FFFFFF; padding: 16px; border-radius: 20px; display: flex; flex-direction: column; align-items: center; margin: 20px auto; width: 180px; height: 180px; justify-content: center; }
  .qr-pattern { width: 140px; height: 140px; background: repeating-linear-gradient(45deg, #0F172A, #0F172A 8px, #FFFFFF 8px, #FFFFFF 16px); border-radius: 8px; }
  .room-pill { background: #1E293B; border: 1px solid #334155; padding: 8px 14px; border-radius: 100px; text-align: center; font-size: 13px; font-weight: 700; color: #38BDF8; margin-top: 10px; }
  .avatar-row { display: flex; justify-content: center; gap: 8px; margin-top: 14px; }
  .avt { width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; color: #fff; }
  .avt-1 { background: #EF4444; }
  .avt-2 { background: #10B981; }
  .avt-3 { background: #F59E0B; }
  .avt-add { background: #334155; border: 1px dashed #64748B; color: #94A3B8; }

  /* Screen 3: Guest Collaborative Board */
  .dish-item { background: #1E293B; border: 1px solid #334155; border-radius: 12px; padding: 10px 12px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; }
  .dish-item.selected { border-color: #10B981; background: rgba(16, 185, 129, 0.12); }
  .dish-title { font-size: 12px; font-weight: 600; color: #F1F5F9; }
  .dish-price { font-size: 11px; color: #94A3B8; }
  .claim-tag { font-size: 9.5px; padding: 2px 6px; border-radius: 4px; font-weight: 700; }
  .tag-my { background: #10B981; color: #fff; }
  .tag-shared { background: #6366F1; color: #fff; }

  /* Screen 4: Dynamic VietQR Pay */
  .pay-card { background: #1E293B; border: 1px solid #F59E0B; border-radius: 16px; padding: 14px; text-align: center; }
  .pay-amount { font-size: 24px; font-weight: 800; color: #FBBF24; margin: 6px 0; }
  .pay-note { font-size: 11px; color: #94A3B8; background: #0F172A; padding: 4px 8px; border-radius: 6px; display: inline-block; margin-bottom: 12px; }
  .vietqr-box { background: #fff; border-radius: 12px; padding: 12px; width: 160px; height: 160px; margin: 0 auto; display: flex; flex-direction: column; align-items: center; justify-content: center; }
  .napas-logo { font-size: 10px; font-weight: 900; color: #0284C7; letter-spacing: 1px; margin-bottom: 4px; }
  .vietqr-code { width: 120px; height: 120px; background: repeating-linear-gradient(90deg, #0F172A, #0F172A 6px, #FFFFFF 6px, #FFFFFF 12px); border-radius: 4px; }
  .bank-open-btn { background: #F59E0B; color: #0F172A; font-weight: 700; font-size: 12.5px; padding: 12px; border-radius: 12px; text-align: center; margin-top: 12px; }

  /* Footer Specs */
  .footer-specs { background: #111827; border: 1px solid #1E293B; border-radius: 14px; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; }
  .spec-item { display: flex; align-items: center; gap: 12px; }
  .spec-label { font-size: 11px; color: #64748B; text-transform: uppercase; letter-spacing: 1px; }
  .spec-val { font-size: 13.5px; font-weight: 700; color: #E2E8F0; }
</style>
</head>
<body>

  <!-- Header -->
  <div class="header">
    <div>
      <div class="tag">UI/UX Design Specification & Visual Teardown</div>
      <div class="title">⚡ SplitBill Zero: <span>Design System & User Flows</span></div>
      <div class="desc">Engineered for sub-60-second table settlement with zero app installation for dining guests</div>
    </div>
    <div class="figma-badge">
      <div class="dot"></div>
      Figma Design System • Production Ready
    </div>
  </div>

  <!-- 4 Mockups Showcase -->
  <div class="screens">

    <!-- Screen 1 -->
    <div class="phone-wrap">
      <div class="phone-label"><div class="phone-step">1</div> Host Live Camera OCR</div>
      <div class="mockup host">
        <div class="notch"></div>
        <div class="screen-content">
          <div style="font-size: 12px; font-weight: 700; color: #38BDF8; margin-bottom: 8px;">SCANNING RECEIPT...</div>
          <div class="camera-view">
            <div class="receipt-paper">
              <div>*** BILL THANH TOAN ***</div>
              <div class="box-overlay">1. Lau Bo Ba Chi &nbsp;&nbsp;&nbsp;&nbsp; 350,000</div>
              <div class="box-overlay">2. Tra Dao Cam Sa &nbsp;&nbsp;&nbsp;&nbsp; 45,000</div>
              <div class="box-overlay">3. Ca Phe Muoi &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 35,000</div>
              <div class="box-overlay">4. Nuoc Suoi &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 15,000</div>
              <div style="border-top: 1px dashed #64748B; margin-top: 6px; padding-top: 4px;">VAT 8%: 35,600</div>
              <div><b>TONG CONG: 480,600</b></div>
            </div>
          </div>
          <div class="scan-btn">⚡ Tách món &amp; Mở bàn</div>
        </div>
      </div>
    </div>

    <!-- Screen 2 -->
    <div class="phone-wrap">
      <div class="phone-label"><div class="phone-step">2</div> Host Table Join QR</div>
      <div class="mockup host">
        <div class="notch"></div>
        <div class="screen-content">
          <div style="font-size: 14px; font-weight: 700; color: #F8FAFC; text-align: center;">Mời bàn quét tham gia</div>
          <div style="font-size: 11px; color: #94A3B8; text-align: center; margin-top: 2px;">Không cần tải app • Quét bằng Camera / Zalo</div>
          
          <div class="qr-box">
            <div class="qr-pattern"></div>
          </div>

          <div class="room-pill">BÀN ĂN: #VN-8842</div>

          <div style="font-size: 11.5px; color: #94A3B8; text-align: center; margin-top: 16px;">Đã vào bàn (3/4 người):</div>
          <div class="avatar-row">
            <div class="avt avt-1">Đức</div>
            <div class="avt avt-2">Nam</div>
            <div class="avt avt-3">Linh</div>
            <div class="avt avt-add">+</div>
          </div>

          <div class="scan-btn" style="background: #10B981; margin-top: auto;">Bắt đầu nhận món ➔</div>
        </div>
      </div>
    </div>

    <!-- Screen 3 -->
    <div class="phone-wrap">
      <div class="phone-label"><div class="phone-step">3</div> Guest Collaborative Board</div>
      <div class="mockup guest">
        <div class="notch"></div>
        <div class="screen-content">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <div>
              <div style="font-size: 13px; font-weight: 700; color: #10B981;">Chào Nam 👋</div>
              <div style="font-size: 10.5px; color: #94A3B8;">Chạm vào món bạn đã ăn</div>
            </div>
            <div style="background: rgba(16, 185, 129, 0.15); color: #34D399; font-size: 10px; font-weight: 700; padding: 4px 8px; border-radius: 6px;">Web Client</div>
          </div>

          <div class="dish-item selected">
            <div>
              <div class="dish-title">Trà Đào Cam Sả</div>
              <div class="dish-price">45,000 đ</div>
            </div>
            <div class="claim-tag tag-my">Của Nam</div>
          </div>

          <div class="dish-item selected">
            <div>
              <div class="dish-title">Lẩu Bò Ba Chỉ</div>
              <div class="dish-price">350,000 đ (Ăn chung)</div>
            </div>
            <div class="claim-tag tag-shared">Chia 3 người</div>
          </div>

          <div class="dish-item">
            <div>
              <div class="dish-title">Cà Phê Muối</div>
              <div class="dish-price">35,000 đ</div>
            </div>
            <div style="font-size: 10px; color: #EF4444; font-weight: 600;">Linh đã chọn</div>
          </div>

          <div class="dish-item">
            <div>
              <div class="dish-title">Nước Suối Lavie</div>
              <div class="dish-price">15,000 đ</div>
            </div>
            <div style="font-size: 10px; color: #64748B;">Chưa ai nhận</div>
          </div>

          <div class="scan-btn" style="background: #10B981; margin-top: auto;">Xác nhận (161,600 đ) ➔</div>
        </div>
      </div>
    </div>

    <!-- Screen 4 -->
    <div class="phone-wrap">
      <div class="phone-label"><div class="phone-step">4</div> Dynamic VietQR Pay</div>
      <div class="mockup settle">
        <div class="notch"></div>
        <div class="screen-content">
          <div class="pay-card">
            <div style="font-size: 11px; color: #94A3B8; text-transform: uppercase;">Số tiền Nam cần trả:</div>
            <div class="pay-amount">161,600 đ</div>
            <div class="pay-note">Nội dung: <b>NAM TRA TIEN LAU</b></div>

            <div class="vietqr-box">
              <div class="napas-logo">VIETQR • NAPAS 247</div>
              <div class="vietqr-code"></div>
            </div>
          </div>

          <div class="bank-open-btn">🏦 Mở App Ngân hàng thanh toán</div>
          <div style="font-size: 10.5px; color: #64748B; text-align: center; margin-top: 8px;">Tự động điền STK, Số tiền &amp; Lời nhắn</div>
        </div>
      </div>
    </div>

  </div>

  <!-- Specs Footer -->
  <div class="footer-specs">
    <div class="spec-item">
      <div>
        <div class="spec-label">Mobile Host Stack</div>
        <div class="spec-val">Flutter 3.x • Google ML Kit v2 • CameraX</div>
      </div>
    </div>
    <div class="spec-item">
      <div>
        <div class="spec-label">Guest Web Client</div>
        <div class="spec-val">Svelte / PWA • &lt; 250KB • Zero Login</div>
      </div>
    </div>
    <div class="spec-item">
      <div>
        <div class="spec-label">Real-time Mesh</div>
        <div class="spec-val">Supabase Realtime • Latency &lt; 80ms</div>
      </div>
    </div>
    <div class="spec-item">
      <div>
        <div class="spec-label">Fintech Engine</div>
        <div class="spec-val">EMVCo QR Tag Standard • CRC-16 Checksum</div>
      </div>
    </div>
  </div>

</body>
</html>
"""

html_path = "projects/splitbill-zero/docs/design_mockup.html"
img_path = "projects/splitbill-zero/docs/SplitBill_Zero_UI_Showcase.png"

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",
    "--disable-gpu",
    "--window-size=1920,1080",
    f"--screenshot={img_path}",
    html_path
]
subprocess.run(cmd, check=True)
print("Rendered SplitBill_Zero_UI_Showcase.png successfully!")
