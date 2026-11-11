import type { TableRoomState, ClientMessage, ServerMessage } from '../shared/types';
import { syncRoomToSupabase, fetchRoomFromSupabase } from './supabase';
import { performReceiptOcr } from './ocrEngine';

const PORT = Number(process.env.PORT) || 3088;

// In-memory Ephemeral Room Store with 2-hour TTL auto-cleanup
const rooms = new Map<string, TableRoomState>();

// Pre-seed room #VN-8842 for immediate zero-config testing
rooms.set('VN-8842', {
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
    'host_duc': {
      guestId: 'host_duc',
      guestName: 'Phan Minh Đức',
      isHost: true,
      claimedItemIds: ['dish_1', 'dish_3'],
      isPaid: true,
    },
    'guest_nam': {
      guestId: 'guest_nam',
      guestName: 'Trần Hải Nam',
      isHost: false,
      claimedItemIds: ['dish_1', 'dish_2'],
      isPaid: false,
    },
    'guest_linh': {
      guestId: 'guest_linh',
      guestName: 'Nguyễn Thùy Linh',
      isHost: false,
      claimedItemIds: ['dish_1'],
      isPaid: false,
    },
  },
  status: 'OPEN',
  createdAt: Date.now(),
  updatedAt: Date.now(),
});

interface WebSocketData {
  roomId?: string;
  guestId?: string;
}

const server = Bun.serve<WebSocketData>({
  port: PORT,
  async fetch(req, server) {
    const url = new URL(req.url);

    // CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({ status: 'ok', activeRooms: rooms.size, timestamp: Date.now() }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    // OCR Ingestion Endpoint (Accepts multipart/form-data or binary image)
    if (url.pathname === '/api/ocr' && req.method === 'POST') {
      try {
        const contentType = req.headers.get('content-type') || '';
        let imageBuffer: Buffer;

        if (contentType.includes('multipart/form-data')) {
          const formData = await req.formData();
          const file = formData.get('image') as File | null;
          if (!file) throw new Error('No image file provided');
          imageBuffer = Buffer.from(await file.arrayBuffer());
        } else {
          imageBuffer = Buffer.from(await req.arrayBuffer());
        }

        const items = await performReceiptOcr(imageBuffer);
        return new Response(JSON.stringify({ success: true, count: items.length, items }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      }
    }

    // HTTP API: Create Room from Host App
    if (url.pathname === '/api/rooms' && req.method === 'POST') {
      try {
        const body = await req.json();
        const roomId = (body.roomId || `VN-${Math.floor(1000 + Math.random() * 9000)}`).toUpperCase();
        
        const newRoom: TableRoomState = {
          roomId,
          hostName: body.hostName || 'Chủ Bàn',
          hostBankBin: body.hostBankBin || '970432',
          hostAccountNumber: body.hostAccountNumber || '0395828955',
          items: body.items || [],
          guests: {
            'host': {
              guestId: 'host',
              guestName: body.hostName || 'Chủ Bàn',
              isHost: true,
              claimedItemIds: [],
              isPaid: true,
            }
          },
          status: 'OPEN',
          createdAt: Date.now(),
          updatedAt: Date.now(),
        };

        rooms.set(roomId, newRoom);
        await syncRoomToSupabase(newRoom);

        return new Response(JSON.stringify({ success: true, room: newRoom }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      }
    }

    // HTTP API: Lock Room & Freeze Split Matrix
    if (url.pathname.match(/^\/api\/rooms\/[^\/]+\/lock$/) && req.method === 'POST') {
      try {
        const parts = url.pathname.split('/');
        const roomId = parts[3].toUpperCase();
        let room = rooms.get(roomId);
        if (!room) {
          const dbRoom = await fetchRoomFromSupabase(roomId);
          if (dbRoom) {
            room = dbRoom;
            rooms.set(roomId, room);
          }
        }

        if (!room) {
          return new Response(JSON.stringify({ error: 'Room not found' }), {
            status: 404,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
          });
        }

        room.status = 'LOCKED';
        room.updatedAt = Date.now();
        rooms.set(roomId, room);

        // Broadcast realtime to all guests in the room
        const stateMsg: ServerMessage = { type: 'ROOM_STATE', state: room };
        server.publish(`room:${roomId}`, JSON.stringify(stateMsg));
        syncRoomToSupabase(room);

        return new Response(JSON.stringify({ success: true, room }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      }
    }

    // HTTP Room state snapshot endpoint
    if (url.pathname.startsWith('/api/rooms/')) {
      const roomId = url.pathname.split('/').pop()?.toUpperCase() || '';
      let room = rooms.get(roomId);
      
      // Fallback: check Supabase DB if not in memory
      if (!room) {
        const dbRoom = await fetchRoomFromSupabase(roomId);
        if (dbRoom) {
          room = dbRoom;
          rooms.set(roomId, room);
        }
      }

      if (!room) {
        return new Response(JSON.stringify({ error: 'Room not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
      }
      return new Response(JSON.stringify(room), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    // Upgrade WebSocket connections for topic `room:<roomId>`
    if (url.pathname === '/ws') {
      const upgraded = server.upgrade(req, {
        data: {},
      });
      if (upgraded) return undefined;
      return new Response('WebSocket upgrade failed', { status: 400 });
    }

    return new Response('⚡ SplitBill Zero Backend Gateway (API + Realtime Mesh)', { status: 200 });
  },

  websocket: {
    open(ws) {
      // Connection established
    },

    async message(ws, rawMessage) {
      try {
        const msg = JSON.parse(rawMessage.toString()) as ClientMessage;

        if (msg.type === 'JOIN_ROOM') {
          const roomId = msg.roomId.toUpperCase();
          ws.data.roomId = roomId;
          ws.data.guestId = msg.guestId;

          // Subscribe socket to room pub/sub topic
          ws.subscribe(`room:${roomId}`);

          let room = rooms.get(roomId);
          if (!room) {
            const dbRoom = await fetchRoomFromSupabase(roomId);
            if (dbRoom) room = dbRoom;
          }

          if (!room) {
            room = {
              roomId,
              hostName: 'Chủ Bàn',
              hostBankBin: '970432',
              hostAccountNumber: '0395828955',
              items: [],
              guests: {},
              status: 'OPEN',
              createdAt: Date.now(),
              updatedAt: Date.now(),
            };
          }

          // Register or update guest presence - DO NOT OVERWRITE EXISTING ITEMS IF ANY
          if (!room.guests[msg.guestId]) {
            room.guests[msg.guestId] = {
              guestId: msg.guestId,
              guestName: msg.guestName,
              isHost: msg.isHost || false,
              claimedItemIds: [],
              isPaid: msg.isHost || false,
            };
          }
          room.updatedAt = Date.now();
          rooms.set(roomId, room);

          // Broadcast updated room state to all clients in this room
          const stateMsg: ServerMessage = { type: 'ROOM_STATE', state: room };
          server.publish(`room:${roomId}`, JSON.stringify(stateMsg));
          ws.send(JSON.stringify(stateMsg));

          // Sync to Supabase in background
          syncRoomToSupabase(room);
        } else if (msg.type === 'CLAIM_ITEM') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room) return;

          const guest = room.guests[msg.guestId];
          if (!guest) return;

          if (msg.action === 'TOGGLE') {
            if (guest.claimedItemIds.includes(msg.itemId)) {
              guest.claimedItemIds = guest.claimedItemIds.filter((id) => id !== msg.itemId);
            } else {
              guest.claimedItemIds.push(msg.itemId);
            }
          } else if (msg.action === 'CLAIM') {
            if (!guest.claimedItemIds.includes(msg.itemId)) {
              guest.claimedItemIds.push(msg.itemId);
            }
          } else if (msg.action === 'UNCLAIM') {
            guest.claimedItemIds = guest.claimedItemIds.filter((id) => id !== msg.itemId);
          }

          room.updatedAt = Date.now();
          rooms.set(roomId, room);

          const stateMsg: ServerMessage = { type: 'ROOM_STATE', state: room };
          server.publish(`room:${roomId}`, JSON.stringify(stateMsg));
          ws.send(JSON.stringify(stateMsg));

          // Sync to Supabase in background
          syncRoomToSupabase(room);
        } else if (msg.type === 'LOCK_ROOM') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room) return;

          room.status = 'LOCKED';
          room.updatedAt = Date.now();
          rooms.set(roomId, room);

          const stateMsg: ServerMessage = { type: 'ROOM_STATE', state: room };
          server.publish(`room:${roomId}`, JSON.stringify(stateMsg));
          syncRoomToSupabase(room);
        } else if (msg.type === 'MARK_PAID') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room) return;

          const guest = room.guests[msg.guestId];
          if (guest) {
            guest.isPaid = true;
            room.updatedAt = Date.now();
            rooms.set(roomId, room);

            const stateMsg: ServerMessage = { type: 'ROOM_STATE', state: room };
            server.publish(`room:${roomId}`, JSON.stringify(stateMsg));
            syncRoomToSupabase(room);
          }
        }
      } catch (err: any) {
        ws.send(JSON.stringify({ type: 'ERROR', message: err.message }));
      }
    },

    close(ws) {
      if (ws.data.roomId) {
        ws.unsubscribe(`room:${ws.data.roomId}`);
      }
    },
  },
});

console.log(`⚡ SplitBill Zero Backend Gateway running on http://localhost:${PORT} and ws://localhost:${PORT}/ws`);
