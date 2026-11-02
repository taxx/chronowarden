/** Cross-device sync via the API's Server-Sent Events stream. */
export interface RealtimeEvent {
  table: string;
  type: string;
  row: Record<string, unknown>;
}

/**
 * Subscribe to change events. The session cookie authenticates the stream
 * (same origin), and `EventSource` reconnects automatically.
 *
 * `onResync` runs when the stream reconnects after a drop — events sent while
 * the device was asleep are gone, so the caller should refetch once.
 *
 * Returns an unsubscribe function.
 */
export function subscribeRealtime(
  onEvent: (event: RealtimeEvent) => void,
  onResync?: () => void,
): () => void {
  const source = new EventSource('/api/v1/events');
  let openedOnce = false;

  source.onopen = () => {
    if (openedOnce) onResync?.();
    openedOnce = true;
  };

  source.onmessage = (message) => {
    try {
      const data = JSON.parse(message.data) as RealtimeEvent;
      if (data && typeof data.table === 'string') onEvent(data);
    } catch {
      // keep-alive comments and malformed frames are ignored
    }
  };

  return () => source.close();
}
