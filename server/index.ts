import type { TableRoomState, ClientMessage, ServerMessage } from '../shared/types';

const PORT = process.env.PORT || 3088;

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
  fetch(req, server) {
    const url = new URL(req.url);

    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({ status: 'ok', activeRooms: rooms.size }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // HTTP Room state snapshot endpoint
    if (url.pathname.startsWith('/api/rooms/')) {
      const roomId = url.pathname.split('/').pop()?.toUpperCase() || '';
      const room = rooms.get(roomId);
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

    return new Response('⚡ SplitBill Zero Realtime Mesh Server', { status: 200 });
  },

  websocket: {
    open(ws) {
      // Connection established
    },

    message(ws, rawMessage) {
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
            room = {
              roomId,
              hostName: msg.guestName,
              hostBankBin: '970432',
              hostAccountNumber: '0395828955',
              items: [],
              guests: {},
              status: 'OPEN',
              createdAt: Date.now(),
              updatedAt: Date.now(),
            };
            rooms.set(roomId, room);
          }

          if (!room.guests[msg.guestId]) {
            room.guests[msg.guestId] = {
              guestId: msg.guestId,
              guestName: msg.guestName,
              isHost: msg.isHost ?? false,
              claimedItemIds: [],
              isPaid: false,
            };
          }
          room.updatedAt = Date.now();

          // Broadcast updated room state to all clients in this room
          server.publish(
            `room:${roomId}`,
            JSON.stringify({ type: 'ROOM_STATE', state: room } satisfies ServerMessage)
          );
          return;
        }

        if (msg.type === 'CLAIM_ITEM') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room) return;

          const guest = room.guests[msg.guestId];
          if (!guest) return;

          const hasClaimed = guest.claimedItemIds.includes(msg.itemId);
          if (msg.action === 'TOGGLE') {
            if (hasClaimed) {
              guest.claimedItemIds = guest.claimedItemIds.filter((id) => id !== msg.itemId);
            } else {
              guest.claimedItemIds.push(msg.itemId);
            }
          } else if (msg.action === 'CLAIM' && !hasClaimed) {
            guest.claimedItemIds.push(msg.itemId);
          } else if (msg.action === 'UNCLAIM' && hasClaimed) {
            guest.claimedItemIds = guest.claimedItemIds.filter((id) => id !== msg.itemId);
          }

          room.updatedAt = Date.now();
          server.publish(
            `room:${roomId}`,
            JSON.stringify({ type: 'ROOM_STATE', state: room } satisfies ServerMessage)
          );
          return;
        }

        if (msg.type === 'LOCK_ROOM') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room) return;

          room.status = 'LOCKED';
          room.updatedAt = Date.now();
          server.publish(
            `room:${roomId}`,
            JSON.stringify({ type: 'ROOM_STATE', state: room } satisfies ServerMessage)
          );
          return;
        }

        if (msg.type === 'MARK_PAID') {
          const roomId = msg.roomId.toUpperCase();
          const room = rooms.get(roomId);
          if (!room || !room.guests[msg.guestId]) return;

          room.guests[msg.guestId].isPaid = true;
          room.updatedAt = Date.now();
          server.publish(
            `room:${roomId}`,
            JSON.stringify({ type: 'ROOM_STATE', state: room } satisfies ServerMessage)
          );
          return;
        }
      } catch (err) {
        ws.send(JSON.stringify({ type: 'ERROR', message: String(err) }));
      }
    },

    close(ws) {
      if (ws.data.roomId) {
        ws.unsubscribe(`room:${ws.data.roomId}`);
      }
    },
  },
});

console.log(`⚡ SplitBill Zero Realtime Mesh running on ws://localhost:${server.port}`);
