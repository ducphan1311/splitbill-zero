import { createClient, RealtimeChannel } from '@supabase/supabase-js';
import type { TableRoomState } from '../../shared/types';

// Default public sandbox or custom env
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://demo.supabase.co';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'public-anon-key-placeholder';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export function subscribeToSupabaseRoom(
  roomId: string,
  onStateUpdate: (state: Partial<TableRoomState>) => void
): RealtimeChannel {
  const channel = supabase.channel(`room:${roomId}`);

  channel
    .on('broadcast', { event: 'table_state' }, (response) => {
      if (response.payload) {
        onStateUpdate(response.payload);
      }
    })
    .subscribe();

  return channel;
}
