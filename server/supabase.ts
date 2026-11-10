import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { TableRoomState } from '../shared/types';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

let supabase: SupabaseClient | null = null;

if (supabaseUrl && supabaseKey && !supabaseUrl.includes('dummy-project')) {
  try {
    supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });
    console.log('✅ Supabase Client initialized on Backend Gateway:', supabaseUrl);
  } catch (err) {
    console.warn('⚠️ Supabase init failed on Backend, falling back to In-Memory Mesh:', err);
  }
} else {
  console.log('ℹ️ Supabase credentials not set or using dummy env. Operating in High-Speed In-Memory Mesh Mode with local TTL.');
}

/**
 * Sync room state to Supabase Postgres / Realtime channel from Backend
 */
export async function syncRoomToSupabase(room: TableRoomState): Promise<void> {
  if (!supabase) return;

  try {
    // 1. Broadcast event via Supabase Realtime channel
    const channel = supabase.channel(`room:${room.roomId}`);
    await channel.send({
      type: 'broadcast',
      event: 'table_state',
      payload: room,
    });

    // 2. Upsert room state to table if configured
    await supabase.from('table_rooms').upsert({
      room_id: room.roomId,
      host_name: room.hostName,
      host_bank_bin: room.hostBankBin,
      host_account_number: room.hostAccountNumber,
      items: room.items,
      guests: room.guests,
      status: room.status,
      updated_at: new Date(room.updatedAt).toISOString(),
    });
  } catch (error) {
    console.error('Error syncing room to Supabase:', error);
  }
}

/**
 * Load room state from Supabase if not found in memory
 */
export async function fetchRoomFromSupabase(roomId: string): Promise<TableRoomState | null> {
  if (!supabase) return null;

  try {
    const { data, error } = await supabase
      .from('table_rooms')
      .select('*')
      .eq('room_id', roomId)
      .single();

    if (error || !data) return null;

    return {
      roomId: data.room_id,
      hostName: data.host_name,
      hostBankBin: data.host_bank_bin,
      hostAccountNumber: data.host_account_number,
      items: data.items || [],
      guests: data.guests || {},
      status: data.status || 'OPEN',
      createdAt: new Date(data.created_at || Date.now()).getTime(),
      updatedAt: new Date(data.updated_at || Date.now()).getTime(),
    };
  } catch (err) {
    console.error('Failed to fetch room from Supabase:', err);
    return null;
  }
}
