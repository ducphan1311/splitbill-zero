import { useState, useEffect, useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Check, ArrowRight, RefreshCw, ExternalLink, Lock, Users } from 'lucide-react';
import { generateVietQrPayload } from './utils/vietqr';
import { openBankingApp, VIETNAM_POPULAR_BANKS } from './utils/bankLauncher';
import type { TableRoomState, ServerMessage, ClientMessage } from '../../shared/types';

export function App() {
  // Extract roomId dynamically from URL path (/room/:roomId) or query param (?room=...)
  const getInitialRoomId = () => {
    const pathParts = window.location.pathname.split('/').filter(Boolean);
    const roomIndex = pathParts.indexOf('room');
    if (roomIndex !== -1 && pathParts[roomIndex + 1]) {
      return pathParts[roomIndex + 1].toUpperCase();
    }
    const searchParams = new URLSearchParams(window.location.search);
    const queryRoom = searchParams.get('room');
    if (queryRoom) return queryRoom.toUpperCase();

    return 'VN-8842';
  };

  const initialRoomId = getInitialRoomId();

  // Multi-user session storage support: Each browser tab/window has its own identity
  const [guestName, setGuestName] = useState(() => {
    return sessionStorage.getItem(`splitbill_user_${initialRoomId}`) || '';
  });
  const [guestId] = useState(() => {
    let id = sessionStorage.getItem(`splitbill_uid_${initialRoomId}`);
    if (!id) {
      id = `guest_${Math.random().toString(36).substring(2, 9)}`;
      sessionStorage.setItem(`splitbill_uid_${initialRoomId}`, id);
    }
    return id;
  });

  const [inputName, setInputName] = useState('');
  const [step, setStep] = useState<'claim' | 'settle'>('claim');
  const [selectedBank, setSelectedBank] = useState('vpbank');
  const [isConnected, setIsConnected] = useState(false);

  // Live Room State from Realtime Mesh Server
  const [roomState, setRoomState] = useState<TableRoomState>({
    roomId: initialRoomId,
    hostName: 'Phan Minh Đức',
    hostBankBin: '970432', // VPBank
    hostAccountNumber: '0395828955',
    items: [
      { id: 'dish_1', name: 'Lẩu Bò Ba Chỉ', price: 350000, quantity: 1 },
      { id: 'dish_2', name: 'Trà Đào Cam Sả', price: 45000, quantity: 1 },
      { id: 'dish_3', name: 'Cà Phê Muối', price: 35000, quantity: 1 },
      { id: 'dish_4', name: 'Nước Suối Lavie', price: 15000, quantity: 1 },
    ],
    guests: {},
    status: 'OPEN',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  });

  const wsRef = useRef<WebSocket | null>(null);

  // Initial HTTP Fetch to load room snapshot immediately (especially for fresh scanned bills)
  useEffect(() => {
    const defaultHttpUrl = 'https://splitbill-zero-server.onrender.com';
    const httpBase = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
      ? 'http://localhost:3088'
      : (import.meta.env.VITE_SERVER_URL || defaultHttpUrl);

    fetch(`${httpBase}/api/rooms/${initialRoomId}`)
      .then((res) => {
        if (res.ok) return res.json();
        throw new Error('Room not found');
      })
      .then((data: TableRoomState) => {
        if (data && data.roomId) {
          setRoomState(data);
        }
      })
      .catch((err) => {
        console.warn('Initial room fetch failed (fallback to default)', err);
      });
  }, [initialRoomId]);

  // Connect to Bun WebSocket Mesh Gateway once guestName is set
  useEffect(() => {
    if (!guestName) return;

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
        roomId: initialRoomId,
        guestId: guestId,
        guestName: guestName,
      };
      ws.send(JSON.stringify(joinMsg));
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data) as ServerMessage;
        if (msg.type === 'ROOM_STATE' && msg.state) {
          setRoomState((prev) => {
            // CRITICAL: If incoming state has empty items (e.g. transient sync gap), preserve existing loaded items!
            const mergedItems = (msg.state.items && msg.state.items.length > 0)
              ? msg.state.items
              : prev.items;

            return {
              ...msg.state,
              items: mergedItems,
            };
          });
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
  }, [initialRoomId, guestId, guestName]);

  const handleJoinTable = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = inputName.trim();
    if (!trimmed) return;
    sessionStorage.setItem(`splitbill_user_${initialRoomId}`, trimmed);
    setGuestName(trimmed);
  };

  const isRoomLocked = roomState.status === 'LOCKED';

  const toggleClaimDish = (itemId: string) => {
    if (isRoomLocked) return; // Prevent selection when table is locked/frozen!

    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      const claimMsg: ClientMessage = {
        type: 'CLAIM_ITEM',
        roomId: roomState.roomId,
        guestId: guestId,
        itemId,
        action: 'TOGGLE',
      };
      wsRef.current.send(JSON.stringify(claimMsg));
    }

    // Always optimistically update local selection without touching items list!
    setRoomState((prev) => {
      const currentClaimed = prev.guests[guestId]?.claimedItemIds || [];
      const hasClaimed = currentClaimed.includes(itemId);
      return {
        ...prev,
        guests: {
          ...prev.guests,
          [guestId]: {
            guestId: guestId,
            guestName: guestName,
            isHost: false,
            isPaid: false,
            claimedItemIds: hasClaimed
              ? currentClaimed.filter((id) => id !== itemId)
              : [...currentClaimed, itemId],
          },
        },
      };
    });
  };

  // Compute how many guests claimed each dish
  const getItemClaimers = (itemId: string) => {
    return Object.values(roomState.guests || {}).filter((g) => g.claimedItemIds?.includes(itemId));
  };

  // Math Fair Split Calculation for current guest
  const myTotalShare = roomState.items.reduce((total, dish) => {
    const claimers = getItemClaimers(dish.id);
    if (claimers.some((g) => g.guestId === guestId)) {
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
    memo: `${guestName.toUpperCase().replace(/[^A-Z0-9 ]/g, '')} TRA TIEN BAN ${roomState.roomId}`,
  });

  const handleOpenBankApp = () => {
    openBankingApp(qrPayload, selectedBank);
  };

  return (
    <div className="min-h-screen bg-[#080A12] text-white flex flex-col items-center p-4 selection:bg-[#00D9FF] selection:text-black">
      {/* Modal: Guest Name Input if not registered yet */}
      {!guestName ? (
        <div className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-[#121726] border border-[#00D9FF]/40 rounded-3xl p-6 shadow-[0_0_30px_rgba(0,217,255,0.2)] flex flex-col gap-4">
            <div className="flex items-center gap-3 text-[#00D9FF]">
              <div className="p-3 bg-[#00D9FF]/10 rounded-2xl border border-[#00D9FF]/30">
                <Users size={24} />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white">Bàn ăn #{roomState.roomId}</h3>
                <p className="text-xs text-[#9EADC7]">Chủ bàn: {roomState.hostName}</p>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-white/5 border border-white/10 text-xs text-[#9EADC7]">
              👋 Vui lòng nhập tên của bạn để chủ bàn và mọi người cùng thấy danh sách và món bạn chọn theo thời gian thực!
            </div>

            <form onSubmit={handleJoinTable} className="flex flex-col gap-3">
              <div>
                <label className="text-xs text-[#9EADC7] mb-1.5 block">Tên của bạn:</label>
                <input
                  type="text"
                  autoFocus
                  placeholder="Ví dụ: Nam, Linh, Hùng, Trang..."
                  value={inputName}
                  onChange={(e) => setInputName(e.target.value)}
                  className="w-full bg-[#0E1322] border border-white/20 rounded-xl px-4 py-3 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-[#00D9FF]"
                />
              </div>
              <button
                type="submit"
                disabled={!inputName.trim()}
                className="w-full h-12 rounded-xl bg-[#00D9FF] disabled:opacity-40 text-[#080D14] font-bold text-sm flex items-center justify-center gap-2 cursor-pointer shadow-[0_0_15px_rgba(0,217,255,0.3)] transition-all"
              >
                Xác Nhận Tham Gia & Chọn Món
                <ArrowRight size={16} />
              </button>
            </form>
          </div>
        </div>
      ) : null}

      {/* Top Banner Live Indicator */}
      <header className="w-full max-w-md pt-2 pb-4 flex flex-col items-start gap-2">
        <div className="flex items-center justify-between w-full">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#21D487]/15 border border-[#21D487]/40 text-[#21D487] text-xs font-bold tracking-wide">
            <span className={`w-2 h-2 rounded-full ${isConnected ? 'bg-[#21D487] animate-pulse' : 'bg-gray-500'}`}></span>
            BÀN #{roomState.roomId} • {guestName || 'KHÁCH'}
          </div>
          <span className="text-xs text-[#9EADC7] flex items-center gap-1">
            {isConnected ? (
              <>⚡ Realtime Mesh</>
            ) : (
              <span className="flex items-center gap-1 text-amber-400">
                <RefreshCw size={11} className="animate-spin" /> Local Mode
              </span>
            )}
          </span>
        </div>

        {/* Room Lock Alert Banner */}
        {isRoomLocked && (
          <div className="w-full px-3.5 py-2.5 rounded-xl bg-[#FAB22E]/15 border border-[#FAB22E]/40 text-[#FAB22E] flex items-center gap-2.5 text-xs font-semibold">
            <Lock size={15} />
            <span>Host đã khóa bàn! Ma trận chia tiền đã chốt cố định.</span>
          </div>
        )}

        <h1 className="text-2xl font-bold text-[#FAFAFF] tracking-tight">
          {step === 'claim' ? 'Chọn Món Bạn Đã Dùng' : 'Thanh Toán VietQR Nhanh'}
        </h1>
        <p className="text-sm text-[#9EADC7]">
          {step === 'claim'
            ? 'Chạm để nhận món riêng • Món có nhiều người chọn sẽ tự động chia đều'
            : 'Mở app ngân hàng quét mã hoặc bấm nút chuyển khoản'}
        </p>
      </header>

      {/* Screen 03: Claiming Board */}
      {step === 'claim' && (
        <main className="w-full max-w-md flex flex-col gap-3 pb-28">
          {roomState.items.length === 0 ? (
            <div className="p-8 rounded-2xl bg-[#121726] border border-white/10 flex flex-col items-center justify-center text-center gap-3">
              <RefreshCw size={28} className="text-[#00D9FF] animate-spin" />
              <div className="text-sm font-semibold text-white">Đang tải danh sách món từ hóa đơn...</div>
              <p className="text-xs text-[#9EADC7]">
                Nếu vừa quét xong, vui lòng chờ 1-2 giây hoặc chạm nút bên dưới để tải lại dữ liệu.
              </p>
              <button
                onClick={() => {
                  const defaultHttpUrl = 'https://splitbill-zero-server.onrender.com';
                  const httpBase = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
                    ? 'http://localhost:3088'
                    : (import.meta.env.VITE_SERVER_URL || defaultHttpUrl);
                  fetch(`${httpBase}/api/rooms/${initialRoomId}`)
                    .then((r) => r.json())
                    .then((d) => d?.roomId && setRoomState(d));
                }}
                className="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/15 text-xs text-[#00D9FF] border border-[#00D9FF]/30 cursor-pointer"
              >
                🔄 Tải lại món ăn
              </button>
            </div>
          ) : (
            roomState.items.map((dish) => {
              const claimers = getItemClaimers(dish.id);
              const isClaimedByMe = claimers.some((g) => g.guestId === guestId);
              const isShared = claimers.length > 1;
              const isClaimedByOthersOnly = !isClaimedByMe && claimers.length > 0;

              return (
                <div
                  key={dish.id}
                  onClick={() => toggleClaimDish(dish.id)}
                  className={`p-4 rounded-2xl border transition-all select-none flex items-center justify-between ${
                    isRoomLocked ? 'cursor-not-allowed opacity-90' : 'cursor-pointer'
                  } ${
                    isClaimedByMe
                      ? 'bg-[#121726] border-[#00D9FF] shadow-[0_0_15px_rgba(0,217,255,0.15)]'
                      : isClaimedByOthersOnly
                      ? 'bg-[#121726]/60 border-white/5 opacity-70'
                      : 'bg-[#121726] border-white/10 hover:border-white/20'
                  }`}
                >
                  <div className="flex flex-col gap-1.5 flex-1 pr-2">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-semibold text-base text-[#FAFAFF]">{dish.name}</span>
                      {isShared && (
                        <span className="text-[11px] font-bold px-2 py-0.5 rounded-md bg-[#FAB22E]/20 text-[#FAB22E] border border-[#FAB22E]/40">
                          CHIA {claimers.length}
                        </span>
                      )}
                    </div>

                    {/* Claimer Badges */}
                    {claimers.length > 0 && (
                      <div className="flex items-center gap-1.5 flex-wrap">
                        {claimers.map((c) => (
                          <span
                            key={c.guestId}
                            className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${
                              c.guestId === guestId
                                ? 'bg-[#00D9FF]/20 text-[#00D9FF] border border-[#00D9FF]/40'
                                : 'bg-white/10 text-gray-300'
                            }`}
                          >
                            {c.guestId === guestId ? 'Bạn' : c.guestName}
                          </span>
                        ))}
                      </div>
                    )}

                    <span className="text-xs text-[#9EADC7]">
                      {isClaimedByMe && isShared
                        ? `Chia đều ${claimers.length} người • ${Math.round(
                            (dish.price * dish.quantity) / claimers.length
                          ).toLocaleString('vi-VN')} đ/người`
                        : isClaimedByMe
                        ? 'Chính bạn đã nhận món này'
                        : isClaimedByOthersOnly
                        ? `Đang được chọn bởi ${claimers.length} người`
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
            })
          )}

          {/* Breakdown summary card */}
          <div className="mt-2 p-4 rounded-2xl bg-[#0E1322] border border-white/10 flex flex-col gap-2">
            <div className="flex justify-between items-center text-xs text-[#9EADC7]">
              <span>Người đang chọn:</span>
              <span className="text-white font-semibold">{guestName || 'Chưa đăng ký'}</span>
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
              <span className="font-bold text-[#FAFAFF]">{roomState.hostName.toUpperCase()}</span>
            </div>

            <div className="w-full flex justify-between items-center text-xs text-[#9EADC7]">
              <span>STK THỤ HƯỞNG:</span>
              <span className="font-mono font-bold text-[#00D9FF]">{roomState.hostAccountNumber} (BIN: {roomState.hostBankBin})</span>
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
              <span className="font-mono text-[#00D9FF] font-semibold">{guestName.toUpperCase().replace(/[^A-Z0-9 ]/g, '')} TRA TIEN BAN {roomState.roomId}</span>
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
            isRoomLocked ? (
              <button
                onClick={() => setStep('settle')}
                className="w-full h-14 rounded-full bg-[#00D9FF] text-[#080D14] font-bold text-base flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(0,217,255,0.4)] active:scale-95 transition-all cursor-pointer animate-pulse"
              >
                Bàn Đã Chốt! Bấm Để Thanh Toán ({roundedTotal.toLocaleString('vi-VN')} đ)
                <ArrowRight size={18} />
              </button>
            ) : (
              <div className="flex flex-col gap-1.5 w-full">
                <button
                  disabled
                  className="w-full h-14 rounded-full bg-white/10 border border-white/15 text-[#9EADC7] font-semibold text-sm flex items-center justify-center gap-2 cursor-not-allowed opacity-80"
                >
                  <Lock size={16} className="text-[#FAB22E]" />
                  Đang chọn món • Chờ chủ bàn chốt để thanh toán
                </button>
                <div className="text-center text-[11px] text-[#FAB22E] flex items-center justify-center gap-1.5 font-medium">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#FAB22E] animate-ping"></span>
                  Bạn và mọi người đang tự do chọn món. Nút thanh toán sẽ mở khi Host khóa bàn.
                </div>
              </div>
            )
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
                ← Xem lại danh sách món đã chọn
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
