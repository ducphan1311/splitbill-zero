import { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Check, ArrowRight } from 'lucide-react';
import { generateVietQrPayload } from './utils/vietqr';

interface DishItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
  claimedBy: string[]; // guestIds
}

export function App() {
  const [currentGuestId] = useState('guest_nam');
  const [step, setStep] = useState<'claim' | 'settle'>('claim');

  // Dishes matching Figma Screen 03 & 04
  const [dishes, setDishes] = useState<DishItem[]>([
    {
      id: 'dish_1',
      name: 'Lẩu Bò Ba Chỉ',
      price: 350000,
      quantity: 1,
      claimedBy: ['host_duc', 'guest_nam', 'guest_linh'], // Shared 3
    },
    {
      id: 'dish_2',
      name: 'Trà Đào Cam Sả',
      price: 45000,
      quantity: 1,
      claimedBy: ['guest_nam'], // Solo Nam
    },
    {
      id: 'dish_3',
      name: 'Cà Phê Muối',
      price: 35000,
      quantity: 1,
      claimedBy: ['host_duc'], // Claimed by Host
    },
    {
      id: 'dish_4',
      name: 'Nước Suối Lavie',
      price: 15000,
      quantity: 1,
      claimedBy: [], // Unclaimed
    },
  ]);

  const toggleClaimDish = (id: string) => {
    setDishes((prev) =>
      prev.map((dish) => {
        if (dish.id !== id) return dish;
        const hasClaimed = dish.claimedBy.includes(currentGuestId);
        return {
          ...dish,
          claimedBy: hasClaimed
            ? dish.claimedBy.filter((g) => g !== currentGuestId)
            : [...dish.claimedBy, currentGuestId],
        };
      })
    );
  };

  // Math Fair Split Calculation
  const myTotalShare = dishes.reduce((total, dish) => {
    if (dish.claimedBy.includes(currentGuestId)) {
      const share = (dish.price * dish.quantity) / dish.claimedBy.length;
      return total + share;
    }
    return total;
  }, 0);

  // Round up to nearest 1,000 VND
  const roundedTotal = Math.ceil(myTotalShare / 1000) * 1000;

  // VietQR generation
  const qrPayload = generateVietQrPayload({
    bankBin: '970432', // VPBank
    accountNumber: '0395828955',
    amount: roundedTotal > 0 ? roundedTotal : 161600,
    memo: `NAM TRA TIEN LAU VN8842`,
  });

  return (
    <div className="min-h-screen bg-[#080A12] text-white flex flex-col items-center p-4 selection:bg-[#00D9FF] selection:text-black">
      {/* Top Banner Live Indicator */}
      <header className="w-full max-w-md pt-2 pb-4 flex flex-col items-start gap-2">
        <div className="flex items-center justify-between w-full">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#21D487]/15 border border-[#21D487]/40 text-[#21D487] text-xs font-bold tracking-wide">
            <span className="w-2 h-2 rounded-full bg-[#21D487] animate-pulse"></span>
            GUEST PWA • TABLE #VN-8842
          </div>
          <span className="text-xs text-[#9EADC7]">⚡ Syncing Realtime</span>
        </div>

        <h1 className="text-2xl font-bold text-[#FAFAFF] tracking-tight">
          {step === 'claim' ? 'Chọn Món Bạn Đã Dùng' : 'Thanh Toán VietQR Nhanh'}
        </h1>
        <p className="text-sm text-[#9EADC7]">
          {step === 'claim'
            ? 'Chạm để nhận món riêng • Chạm giữ để chia chung với bàn'
            : 'Mở app ngân hàng quét mã hoặc bấm nút chuyển khoản'}
        </p>
      </header>

      {/* Screen 03: Claiming Board */}
      {step === 'claim' && (
        <main className="w-full max-w-md flex flex-col gap-3 pb-28">
          {dishes.map((dish) => {
            const isClaimedByMe = dish.claimedBy.includes(currentGuestId);
            const isShared = dish.claimedBy.length > 1;
            const isClaimedByOthersOnly = !isClaimedByMe && dish.claimedBy.length > 0;

            return (
              <div
                key={dish.id}
                onClick={() => toggleClaimDish(dish.id)}
                className={`p-4 rounded-2xl border transition-all cursor-pointer select-none flex items-center justify-between ${
                  isClaimedByMe
                    ? 'bg-[#121726] border-[#00D9FF] shadow-[0_0_15px_rgba(0,217,255,0.15)]'
                    : isClaimedByOthersOnly
                    ? 'bg-[#121726]/60 border-white/5 opacity-70'
                    : 'bg-[#121726] border-white/10 hover:border-white/20'
                }`}
              >
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-base text-[#FAFAFF]">{dish.name}</span>
                    {isShared && (
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-md bg-[#FAB22E]/20 text-[#FAB22E] border border-[#FAB22E]/40">
                        CHIA {dish.claimedBy.length}
                      </span>
                    )}
                  </div>
                  <span className="text-xs text-[#9EADC7]">
                    {isClaimedByMe && isShared
                      ? `Chia đều ${dish.claimedBy.length} người • ${Math.round(
                          (dish.price * dish.quantity) / dish.claimedBy.length
                        ).toLocaleString('vi-VN')} đ/người`
                      : isClaimedByMe
                      ? 'Chính bạn đã nhận món này'
                      : isClaimedByOthersOnly
                      ? 'Người khác đã chọn'
                      : 'Chưa có ai chọn • Chạm để nhận'}
                  </span>
                </div>

                <div className="flex items-center gap-3">
                  <span className="text-base font-bold text-[#FAB22E]">
                    {(dish.price * dish.quantity).toLocaleString('vi-VN')} đ
                  </span>
                  <div
                    className={`w-6 h-6 rounded-full flex items-center justify-center border transition-all ${
                      isClaimedByMe
                        ? 'bg-[#00D9FF] border-[#00D9FF] text-[#080D14]'
                        : 'border-white/20 text-transparent'
                    }`}
                  >
                    <Check size={14} strokeWidth={3} />
                  </div>
                </div>
              </div>
            );
          })}

          {/* Breakdown summary card */}
          <div className="mt-2 p-4 rounded-2xl bg-[#0E1322] border border-white/10 flex flex-col gap-2">
            <div className="flex justify-between text-xs text-[#9EADC7]">
              <span>Món riêng của bạn</span>
              <span>45.000 đ</span>
            </div>
            <div className="flex justify-between text-xs text-[#9EADC7]">
              <span>Món ăn chung chia sẻ (1/3 Lẩu bò)</span>
              <span>116.666 đ</span>
            </div>
            <div className="border-t border-white/10 pt-2 flex justify-between items-center">
              <span className="text-sm font-semibold text-[#FAFAFF]">Tổng phần bạn cần trả:</span>
              <span className="text-xl font-bold text-[#FAB22E]">
                {roundedTotal.toLocaleString('vi-VN')} đ
              </span>
            </div>
          </div>
        </main>
      )}

      {/* Screen 04: Settlement VietQR */}
      {step === 'settle' && (
        <main className="w-full max-w-md flex flex-col items-center gap-4 pb-28">
          <div className="w-full p-6 rounded-3xl bg-[#121726] border border-white/15 shadow-2xl flex flex-col items-center gap-4">
            <div className="w-full flex justify-between items-center text-xs text-[#9EADC7] border-b border-white/10 pb-3">
              <span>CHỦ BÀN NHẬN TIỀN:</span>
              <span className="font-bold text-[#FAFAFF]">PHAN MINH ĐỨC (VPBANK)</span>
            </div>

            <div className="text-3xl font-extrabold text-[#FAB22E] tracking-tight">
              {roundedTotal.toLocaleString('vi-VN')} đ
            </div>

            {/* QR Frame Container */}
            <div className="p-4 bg-white rounded-2xl border-2 border-[#00D9FF] shadow-[0_0_25px_rgba(0,217,255,0.25)] flex flex-col items-center gap-2">
              <QRCodeSVG value={qrPayload} size={200} level="M" />
              <span className="text-[11px] text-gray-500 font-mono tracking-tighter">
                NAPAS 247 • VIETQR DYNAMIC
              </span>
            </div>

            <div className="w-full p-3 rounded-xl bg-white/5 border border-white/10 flex items-center justify-between text-xs">
              <span className="text-[#9EADC7]">Nội dung CK:</span>
              <span className="font-mono text-[#00D9FF] font-semibold">NAM TRA TIEN LAU VN8842</span>
            </div>

            <p className="text-xs text-center text-[#9EADC7]">
              Hỗ trợ tự động điền số tiền & nội dung trên Vietcombank, Techcombank, VPBank, MB, MoMo...
            </p>
          </div>
        </main>
      )}

      {/* Floating Sticky Bottom Bar */}
      <footer className="fixed bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-[#080A12] via-[#080A12]/95 to-transparent flex justify-center pointer-events-none">
        <div className="w-full max-w-md pointer-events-auto flex flex-col gap-2">
          {step === 'claim' ? (
            <button
              onClick={() => setStep('settle')}
              className="w-full h-14 rounded-full bg-[#00D9FF] text-[#080D14] font-bold text-base flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(0,217,255,0.4)] active:scale-95 transition-all cursor-pointer"
            >
              Xác Nhận & Thanh Toán ({roundedTotal.toLocaleString('vi-VN')} đ)
              <ArrowRight size={18} />
            </button>
          ) : (
            <div className="flex flex-col gap-2 w-full">
              <button
                onClick={() => alert('Đang kích hoạt liên kết mở App Ngân Hàng...')}
                className="w-full h-14 rounded-full bg-[#00D9FF] text-[#080D14] font-bold text-base flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(0,217,255,0.4)] active:scale-95 transition-all cursor-pointer"
              >
                Mở App Ngân Hàng Thanh Toán
                <ArrowRight size={18} />
              </button>
              <button
                onClick={() => setStep('claim')}
                className="w-full h-10 rounded-full border border-white/15 bg-white/5 text-xs text-[#9EADC7] flex items-center justify-center hover:bg-white/10 cursor-pointer"
              >
                ← Quay lại điều chỉnh món
              </button>
            </div>
          )}

          <div className="text-center text-[11px] text-[#21D487] flex items-center justify-center gap-1.5 font-medium">
            <span className="w-1.5 h-1.5 rounded-full bg-[#21D487]"></span>
            Tự động đồng bộ realtime với Host & Bàn ăn
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
