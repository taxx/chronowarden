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

/** Bounds so a single client cannot pin unbounded server resources. */
export const MAX_SUBSCRIBERS_PER_USER = 5;
export const MAX_SUBSCRIBERS_TOTAL = 500;

const subscribersByUser = new Map<string, Set<Subscriber>>();
let totalSubscribers = 0;

/** Whether a new stream for `userId` may be opened. */
export function canSubscribe(userId: string): boolean {
  if (totalSubscribers >= MAX_SUBSCRIBERS_TOTAL) return false;
  return (subscribersByUser.get(userId)?.size ?? 0) < MAX_SUBSCRIBERS_PER_USER;
}

export function addSubscriber(userId: string, subscriber: Subscriber): void {
  let set = subscribersByUser.get(userId);
  if (!set) {
    set = new Set();
    subscribersByUser.set(userId, set);
  }
  set.add(subscriber);
  totalSubscribers += 1;
}

export function removeSubscriber(userId: string, subscriber: Subscriber): void {
  const set = subscribersByUser.get(userId);
  if (!set) return;
  if (set.delete(subscriber)) totalSubscribers = Math.max(0, totalSubscribers - 1);
  if (set.size === 0) subscribersByUser.delete(userId);
}

/** Test helper — number of open streams across all users. */
export function subscriberCount(): number {
  return totalSubscribers;
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
