import { useMemo, useState } from 'react';
import {
  CartesianGrid,
  Line,
  LineChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { Button, Card, CardContent, CardHeader, Slider, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { computeProjection } from '../lib/domain/projection';
import { formatDurationMinutes, formatSignedMinutes } from '../lib/format';
import { useTimeLogs } from '../queries/time-logs';
import { usePreferences } from '../queries/settings';

function Stat({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className="flex items-center justify-between gap-4 py-1.5">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className={'text-sm font-semibold ' + (tone ?? '')}>{value}</dd>
    </div>
  );
}

/** Time-bank projection: history, a chosen daily flex, and when the bank hits zero. */
export function ProjectionPage() {
  const t = useT();
  const logsQuery = useTimeLogs();
  const prefsQuery = usePreferences();
  const [dailyFlex, setDailyFlex] = useState(30);
  const [useTrend, setUseTrend] = useState(false);

  const today = useMemo(() => new Date(), []);
  const logs = logsQuery.data ?? [];
  const result = useMemo(
    () => computeProjection(logs, dailyFlex, useTrend, today),
    [logs, dailyFlex, useTrend, today],
  );

  if (logsQuery.isLoading) {
    return (
      <Card>
        <CardContent className="grid place-items-center py-10">
          <Spinner />
        </CardContent>
      </Card>
    );
  }

  const zeroDateLabel = result.zeroDate
    ? new Intl.DateTimeFormat(undefined, { day: 'numeric', month: 'long' }).format(result.zeroDate)
    : null;

  const step = prefsQuery.data?.sliderStepMinutes ?? 5;

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader title={t('Current time bank')} description={t('Time bank over time')} />
        <CardContent>
          <p
            className={
              'text-3xl font-semibold ' +
              (result.currentBalance >= 0 ? 'text-success' : 'text-warning')
            }
          >
            {formatSignedMinutes(result.currentBalance)}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          title={t('Daily flex target')}
          description={t('Minutes to take from the bank each workday.')}
          action={
            <Button
              variant={useTrend ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setUseTrend((value) => !value)}
            >
              {t('Use trend')}
            </Button>
          }
        />
        <CardContent>
          {useTrend ? (
            <p className="mb-3 text-xs text-muted-foreground">{t('Trend also subtracts your average growth.')}</p>
          ) : null}
          <div className="flex items-center gap-4">
            <Slider value={dailyFlex} min={0} max={120} step={step} onChange={setDailyFlex} />
            <span className="w-16 text-right font-semibold">{dailyFlex} min</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader title={t('Projection')} />
        <CardContent>
          <dl className="divide-y divide-border">
            {useTrend ? (
              <>
                <Stat
                  label={t('Avg growth rate')}
                  value={`${formatDurationMinutes(result.avgGrowthWeekly)}/${t('week')}`}
                />
                <Stat
                  label={t('Net weekly change')}
                  value={formatSignedMinutes(result.netWeeklyChange)}
                />
              </>
            ) : null}
            <Stat
              label={t('Weekly reduction')}
              value={formatDurationMinutes(-result.effectiveWeekly)}
              tone="text-warning"
            />
            <Stat
              label={t('Weeks to zero')}
              value={t('{count} weeks', { count: result.weeksToZero })}
            />
            <Stat
              label={t('Estimated zero date')}
              value={zeroDateLabel ?? t('Already at zero!')}
            />
          </dl>
          <p className="mt-3 text-xs text-muted-foreground">
            {dailyFlex > 0
              ? t(
                  'Taking {flex} min per workday, your bank of {balance} will reach zero in ~{weeks} weeks ({date}).',
                  {
                    flex: dailyFlex,
                    balance: formatSignedMinutes(result.currentBalance),
                    weeks: result.weeksToZero,
                    date: zeroDateLabel ?? t('Already at zero!'),
                  },
                )
              : t('Set a daily flex target above to see when your bank reaches zero.')}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader title={t('Balance over time')} description={t('Actual vs projected')} />
        <CardContent>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={result.points} margin={{ top: 8, right: 16, bottom: 8, left: 0 }}>
                <CartesianGrid stroke="hsl(var(--border))" vertical={false} />
                <XAxis dataKey="label" stroke="hsl(var(--muted-foreground))" fontSize={12} minTickGap={24} />
                <YAxis stroke="hsl(var(--muted-foreground))" fontSize={12} width={48} />
                <Tooltip
                  contentStyle={{
                    background: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: 8,
                    color: 'hsl(var(--foreground))',
                  }}
                  formatter={(value, name) => [formatSignedMinutes(Number(value)), String(name)]}
                />
                <ReferenceLine y={0} stroke="hsl(var(--border))" />
                <Line
                  type="monotone"
                  dataKey="actual"
                  name={t('Actual')}
                  stroke="hsl(var(--success))"
                  strokeWidth={2}
                  dot={false}
                  connectNulls
                />
                <Line
                  type="monotone"
                  dataKey="projected"
                  name={t('Projected')}
                  stroke="hsl(var(--primary))"
                  strokeWidth={2}
                  strokeDasharray="4 3"
                  dot={false}
                  connectNulls
                />
                {useTrend ? (
                  <Line
                    type="monotone"
                    dataKey="trend"
                    name={t('Trend')}
                    stroke="hsl(var(--warning))"
                    strokeWidth={2}
                    dot={false}
                    connectNulls
                  />
                ) : null}
              </LineChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
