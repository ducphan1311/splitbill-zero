export interface BillItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

export interface GuestClaim {
  guestId: string;
  guestName: string;
  isHost?: boolean;
  claimedItemIds: string[];
  isPaid?: boolean;
}

export interface TableRoomState {
  roomId: string;
  hostName: string;
  hostBankBin: string;
  hostAccountNumber: string;
  items: BillItem[];
  guests: Record<string, GuestClaim>; // guestId -> GuestClaim
  status: 'OPEN' | 'LOCKED' | 'COMPLETED';
  createdAt: number;
  updatedAt: number;
}

export type ClientMessage =
  | { type: 'JOIN_ROOM'; roomId: string; guestId: string; guestName: string; isHost?: boolean }
  | { type: 'CLAIM_ITEM'; roomId: string; guestId: string; itemId: string; action: 'TOGGLE' | 'CLAIM' | 'UNCLAIM' }
  | { type: 'LOCK_ROOM'; roomId: string; guestId: string }
  | { type: 'MARK_PAID'; roomId: string; guestId: string };

export type ServerMessage =
  | { type: 'ROOM_STATE'; state: TableRoomState }
  | { type: 'ERROR'; message: string };
