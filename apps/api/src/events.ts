/**
 * In-process Server-Sent Events hub.
 *
 * All writes go through this API, so instead of tailing Postgres replication we
 * publish an event to the owning user's open streams whenever a row changes.
 * The Flutter client reacts by re-fetching the affected data.
 *
 * This is per-isolate/best-effort — with a single API container that is all we
 * need. A reconnect handler on the client covers missed events.
 */
export interface RealtimeEvent {
  table: string;
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  row: Record<string, unknown>;
}

type Subscriber = (payload: string) => void;

const subscribersByUser = new Map<string, Set<Subscriber>>();

export function addSubscriber(userId: string, subscriber: Subscriber): void {
  let set = subscribersByUser.get(userId);
  if (!set) {
    set = new Set();
    subscribersByUser.set(userId, set);
  }
  set.add(subscriber);
}

export function removeSubscriber(userId: string, subscriber: Subscriber): void {
  const set = subscribersByUser.get(userId);
  if (!set) return;
  set.delete(subscriber);
  if (set.size === 0) subscribersByUser.delete(userId);
}

/** Pushes an event to every open stream belonging to `userId`. */
export function publish(userId: string, event: RealtimeEvent): void {
  const set = subscribersByUser.get(userId);
  if (!set || set.size === 0) return;
  const payload = `data: ${JSON.stringify(event)}\n\n`;
  for (const subscriber of set) {
    try {
      subscriber(payload);
    } catch {
      // A dead stream is cleaned up by its own onAbort handler.
    }
  }
}
