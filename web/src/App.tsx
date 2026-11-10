import { useState, useEffect, useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Check, ArrowRight, RefreshCw, ExternalLink } from 'lucide-react';
import { generateVietQrPayload } from './utils/vietqr';
import { openBankingApp, VIETNAM_POPULAR_BANKS } from './utils/bankLauncher';
import type { TableRoomState, ServerMessage, ClientMessage } from '../../shared/types';

export function App() {
  const [currentGuestId] = useState('guest_nam');
  const [currentGuestName] = useState('Trần Hải Nam');
  const [step, setStep] = useState<'claim' | 'settle'>('claim');
  const [selectedBank, setSelectedBank] = useState('vpbank');
  const [isConnected, setIsConnected] = useState(false);

  // Live Room State from Realtime Mesh Server
  const [roomState, setRoomState] = useState<TableRoomState>({
    roomId: 'VN-8842',
    hostName: 'Phan Minh Đức',
    hostBankBin: '970432', // VPBank
    hostAccountNumber: '0395828955',
    items: [
      { id: 'dish_1', name: 'Lẩu Bò Ba Chỉ', price: 350000, quantity: 1 },
      { id: 'dish_2', name: 'Trà Đào Cam Sả', price: 45000, quantity: 1 },
      { id: 'dish_3', name: 'Cà Phê Muối', price: 35000, quantity: 1 },
      { id: 'dish_4', name: 'Nước Suối Lavie', price: 15000, quantity: 1 },
    ],
    guests: {
      'host_duc': { guestId: 'host_duc', guestName: 'Phan Minh Đức', isHost: true, claimedItemIds: ['dish_1', 'dish_3'], isPaid: true },
      'guest_nam': { guestId: 'guest_nam', guestName: 'Trần Hải Nam', isHost: false, claimedItemIds: ['dish_1', 'dish_2'], isPaid: false },
      'guest_linh': { guestId: 'guest_linh', guestName: 'Nguyễn Thùy Linh', isHost: false, claimedItemIds: ['dish_1'], isPaid: false },
    },
    status: 'OPEN',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  });

  const wsRef = useRef<WebSocket | null>(null);

  // Connect to Bun WebSocket Mesh Gateway
  useEffect(() => {
    // Default to hosted server on Render if not running on local machine
    const defaultWsUrl = 'wss://splitbill-zero-server.onrender.com/ws';
    const wsUrl = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
      ? 'ws://localhost:3088/ws'
      : (import.meta.env.VITE_WS_URL || defaultWsUrl);
    const ws = new WebSocket(wsUrl);
    wsRef.current = ws;

    ws.onopen = () => {
      setIsConnected(true);
      const joinMsg: ClientMessage = {
        type: 'JOIN_ROOM',
        roomId: 'VN-8842',
        guestId: currentGuestId,
        guestName: currentGuestName,
      };
      ws.send(JSON.stringify(joinMsg));
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data) as ServerMessage;
        if (msg.type === 'ROOM_STATE') {
          setRoomState(msg.state);
        }
      } catch (e) {
        console.error('Failed to parse WS msg', e);
      }
    };

    ws.onclose = () => setIsConnected(false);
    ws.onerror = () => setIsConnected(false);

    return () => {
      ws.close();
    };
  }, [currentGuestId, currentGuestName]);

  const toggleClaimDish = (itemId: string) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      const claimMsg: ClientMessage = {
        type: 'CLAIM_ITEM',
        roomId: roomState.roomId,
        guestId: currentGuestId,
        itemId,
        action: 'TOGGLE',
      };
      wsRef.current.send(JSON.stringify(claimMsg));
    } else {
      // Optimistic offline toggle
      setRoomState((prev) => {
        const currentClaimed = prev.guests[currentGuestId]?.claimedItemIds || [];
        const hasClaimed = currentClaimed.includes(itemId);
        return {
          ...prev,
          guests: {
            ...prev.guests,
            [currentGuestId]: {
              guestId: currentGuestId,
              guestName: currentGuestName,
              claimedItemIds: hasClaimed
                ? currentClaimed.filter((id) => id !== itemId)
                : [...currentClaimed, itemId],
            },
          },
        };
      });
    }
  };

  // Compute how many guests claimed each dish
  const getItemClaimers = (itemId: string) => {
    return Object.values(roomState.guests).filter((g) => g.claimedItemIds.includes(itemId));
  };

  // Math Fair Split Calculation for current guest
  const myTotalShare = roomState.items.reduce((total, dish) => {
    const claimers = getItemClaimers(dish.id);
    if (claimers.some((g) => g.guestId === currentGuestId)) {
      const share = (dish.price * dish.quantity) / claimers.length;
      return total + share;
    }
    return total;
  }, 0);

  // Round up to nearest 1,000 VND
  const roundedTotal = Math.ceil(myTotalShare / 1000) * 1000;

  // VietQR generation
  const qrPayload = generateVietQrPayload({
    bankBin: roomState.hostBankBin || '970432', // VPBank
    accountNumber: roomState.hostAccountNumber || '0395828955',
    amount: roundedTotal > 0 ? roundedTotal : 161600,
    memo: `NAM TRA TIEN LAU ${roomState.roomId}`,
  });

  const handleOpenBankApp = () => {
    openBankingApp(qrPayload, selectedBank);
  };

  return (
    <div className="min-h-screen bg-[#080A12] text-white flex flex-col items-center p-4 selection:bg-[#00D9FF] selection:text-black">
      {/* Top Banner Live Indicator */}
      <header className="w-full max-w-md pt-2 pb-4 flex flex-col items-start gap-2">
        <div className="flex items-center justify-between w-full">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#21D487]/15 border border-[#21D487]/40 text-[#21D487] text-xs font-bold tracking-wide">
            <span className={`w-2 h-2 rounded-full ${isConnected ? 'bg-[#21D487] animate-pulse' : 'bg-gray-500'}`}></span>
            GUEST PWA • TABLE #{roomState.roomId}
          </div>
          <span className="text-xs text-[#9EADC7] flex items-center gap-1">
            {isConnected ? (
              <>⚡ Realtime Mesh Active</>
            ) : (
              <span className="flex items-center gap-1 text-amber-400">
                <RefreshCw size={11} className="animate-spin" /> Local Demo Mode
              </span>
            )}
          </span>
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
          {roomState.items.map((dish) => {
            const claimers = getItemClaimers(dish.id);
            const isClaimedByMe = claimers.some((g) => g.guestId === currentGuestId);
            const isShared = claimers.length > 1;
            const isClaimedByOthersOnly = !isClaimedByMe && claimers.length > 0;

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
                        CHIA {claimers.length}
                      </span>
                    )}
                  </div>
                  <span className="text-xs text-[#9EADC7]">
                    {isClaimedByMe && isShared
                      ? `Chia đều ${claimers.length} người • ${Math.round(
                          (dish.price * dish.quantity) / claimers.length
                        ).toLocaleString('vi-VN')} đ/người`
                      : isClaimedByMe
                      ? 'Chính bạn đã nhận món này'
                      : isClaimedByOthersOnly
                      ? `Đã chọn bởi: ${claimers.map((c) => c.guestName).join(', ')}`
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
              <span className="font-bold text-[#FAFAFF]">{roomState.hostName.toUpperCase()} (VPBANK)</span>
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
              <span className="font-mono text-[#00D9FF] font-semibold">NAM TRA TIEN LAU {roomState.roomId}</span>
            </div>

            {/* Select Banking App Deep-link selector */}
            <div className="w-full flex flex-col gap-1.5">
              <label className="text-xs text-[#9EADC7]">Chọn ứng dụng ngân hàng của bạn:</label>
              <select
                value={selectedBank}
                onChange={(e) => setSelectedBank(e.target.value)}
                className="w-full bg-[#0E1322] border border-white/15 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#00D9FF]"
              >
                {Object.entries(VIETNAM_POPULAR_BANKS).map(([key, bank]) => (
                  <option key={key} value={key}>
                    {bank.name}
                  </option>
                ))}
              </select>
            </div>
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
                onClick={handleOpenBankApp}
                className="w-full h-14 rounded-full bg-[#00D9FF] text-[#080D14] font-bold text-base flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(0,217,255,0.4)] active:scale-95 transition-all cursor-pointer"
              >
                Mở {VIETNAM_POPULAR_BANKS[selectedBank]?.name || 'App Ngân Hàng'}
                <ExternalLink size={18} />
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
