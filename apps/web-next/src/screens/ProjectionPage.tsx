import { useMemo } from 'react';
import {
  Line,
  LineChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { Card, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { formatSignedMinutes } from '../lib/format';
import { useTimeLogs } from '../queries/time-logs';

/** Cumulative time-bank balance over the recorded days. */
export function ProjectionPage() {
  const t = useT();
  const logsQuery = useTimeLogs();

  const data = useMemo(() => {
    const sorted = [...(logsQuery.data ?? [])].sort((a, b) => a.date.localeCompare(b.date));
    let balance = 0;
    return sorted.map((log) => {
      balance += log.overtimeMinutes;
      return { date: log.date, balance };
    });
  }, [logsQuery.data]);

  const current = data.length > 0 ? data[data.length - 1]!.balance : 0;

  if (logsQuery.isLoading) {
    return (
      <Card>
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t('Projection')}</h1>
      <p className="mt-1 text-sm text-slate-400">{t('Time bank over time')}</p>

      <p className="mt-4 text-xs uppercase tracking-wide text-slate-500">{t('Balance')}</p>
      <p className="text-3xl font-semibold text-white">{formatSignedMinutes(current)}</p>

      <div className="mt-6 h-72 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 8, right: 16, bottom: 8, left: 0 }}>
            <XAxis dataKey="date" stroke="#64748b" fontSize={12} minTickGap={24} />
            <YAxis stroke="#64748b" fontSize={12} width={48} />
            <Tooltip
              contentStyle={{ background: '#0f172a', border: '1px solid #1e293b', borderRadius: 8 }}
              labelStyle={{ color: '#cbd5e1' }}
              formatter={(value) => formatSignedMinutes(Number(value))}
            />
            <ReferenceLine y={0} stroke="#475569" />
            <Line type="monotone" dataKey="balance" stroke="#38bdf8" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}
