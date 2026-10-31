import { Card, CardContent, CardHeader, Skeleton } from './ui';

/** A card-shaped placeholder with a title bar and a few lines. */
export function CardSkeleton({ lines = 3, className }: { lines?: number; className?: string }) {
  return (
    <Card className={className}>
      <CardHeader title={<Skeleton className="h-5 w-40" />} />
      <CardContent className="space-y-3">
        {Array.from({ length: lines }, (_, i) => (
          <Skeleton key={i} className={i % 2 === 0 ? 'h-10 w-full' : 'h-10 w-3/4'} />
        ))}
      </CardContent>
    </Card>
  );
}

/** Grid of stat tiles (Overview summary). */
export function StatGridSkeleton({ count = 5 }: { count?: number }) {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="rounded-lg border bg-card p-3">
          <Skeleton className="h-3 w-20" />
          <Skeleton className="mt-2 h-6 w-16" />
        </div>
      ))}
    </div>
  );
}

/** Rows inside a card (lists/tables). */
export function ListSkeleton({ rows = 4, className }: { rows?: number; className?: string }) {
  return (
    <Card className={className}>
      <CardHeader title={<Skeleton className="h-5 w-32" />} />
      <CardContent className="space-y-3">
        {Array.from({ length: rows }, (_, i) => (
          <div key={i} className="flex items-center justify-between gap-4">
            <div className="space-y-2">
              <Skeleton className="h-4 w-40" />
              <Skeleton className="h-3 w-24" />
            </div>
            <Skeleton className="h-6 w-16" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

/** Rows without a card wrapper (for use inside an existing card). */
export function SkeletonRows({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="flex items-center justify-between gap-4">
          <div className="space-y-2">
            <Skeleton className="h-4 w-40" />
            <Skeleton className="h-3 w-24" />
          </div>
          <Skeleton className="h-6 w-16" />
        </div>
      ))}
    </div>
  );
}

/** Table-shaped placeholder (History). */
export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <Card>
      <CardHeader title={<Skeleton className="h-5 w-28" />} />
      <CardContent className="space-y-3">
        <Skeleton className="h-8 w-full" />
        {Array.from({ length: rows }, (_, i) => (
          <Skeleton key={i} className="h-10 w-full" />
        ))}
      </CardContent>
    </Card>
  );
}

/** Block placeholder for a chart. */
export function ChartSkeleton({ height = 'h-64' }: { height?: string }) {
  return (
    <Card>
      <CardHeader title={<Skeleton className="h-5 w-32" />} />
      <CardContent>
        <Skeleton className={`w-full ${height}`} />
      </CardContent>
    </Card>
  );
}
