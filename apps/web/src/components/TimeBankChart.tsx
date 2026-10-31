import {
  Bar,
  Cell,
  ComposedChart,
  Line,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { TrendingUp } from 'lucide-react';

import { useT } from '../i18n';
import type { TimeBankChartData } from '../lib/domain/time-bank-chart';
import { formatSignedMinutes } from '../lib/format';
import { Card, CardContent, CardHeader, Switch } from './ui';

const POSITIVE = 'hsl(var(--warning))'; // worked over → flagged
const NEGATIVE = 'hsl(var(--success))'; // kept time → good

/**
 * Deviation-from-baseline bar chart with an optional cumulative trend line.
 * Positive bars (worked over) are amber; negative bars (time kept) are green.
 */
export function TimeBankChart({
  data,
  showTrend,
  onToggleTrend,
}: {
  data: TimeBankChartData;
  showTrend: boolean;
  onToggleTrend: (value: boolean) => void;
}) {
  const t = useT();

  if (data.points.length === 0) return null;

  const range = Math.max(1, Math.ceil(data.maxAbs * 1.15));

  return (
    <Card>
      <CardHeader
        title={
          <span className="flex items-center gap-2">
            <TrendingUp className="h-4 w-4 text-primary" />
            {t('Time Bank')}
          </span>
        }
        description={t(
          'Daily overtime relative to your time bank — green bars mean you earned time back.',
        )}
        action={
          <label className="flex items-center gap-2 text-xs text-muted-foreground">
            {t('Trend')}
            <Switch checked={showTrend} onCheckedChange={onToggleTrend} />
          </label>
        }
      />
      <CardContent className="space-y-3">
        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <ComposedChart data={data.points} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
              <XAxis dataKey="label" stroke="hsl(var(--muted-foreground))" fontSize={11} />
              <YAxis
                stroke="hsl(var(--muted-foreground))"
                fontSize={11}
                width={52}
                domain={[-range, range]}
                tickFormatter={(value: number) => formatSignedMinutes(value)}
              />
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
              <Bar dataKey="delta" name={t('Change')} radius={[3, 3, 0, 0]}>
                {data.points.map((point, index) => (
                  <Cell key={index} fill={point.delta >= 0 ? POSITIVE : NEGATIVE} />
                ))}
              </Bar>
              {showTrend ? (
                <Line
                  type="monotone"
                  dataKey="deviation"
                  name={t('Trend')}
                  stroke="hsl(var(--primary))"
                  strokeWidth={2}
                  strokeDasharray="5 4"
                  dot={{ r: 2 }}
                />
              ) : null}
            </ComposedChart>
          </ResponsiveContainer>
        </div>

        <dl className="space-y-1 text-sm">
          <div className="flex items-center justify-between gap-4">
            <dt className="text-muted-foreground">
              {t('Started with ')}
              <span className="font-semibold text-primary">{formatSignedMinutes(data.baseline)}</span>
              {t(' in the bank')}
            </dt>
          </div>
          <div className="flex items-center justify-between gap-4">
            <dt className="text-muted-foreground">{t('Period total: ')}</dt>
            <dd
              className={
                'font-semibold ' + (data.netChange >= 0 ? 'text-warning' : 'text-success')
              }
            >
              {formatSignedMinutes(data.netChange)}
            </dd>
          </div>
          <div className="flex items-center justify-between gap-4">
            <dt className="text-muted-foreground">{t('Ends with ')}</dt>
            <dd className="font-semibold">{formatSignedMinutes(data.endBalance)}</dd>
          </div>
        </dl>
      </CardContent>
    </Card>
  );
}
