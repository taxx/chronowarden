import { useEffect, useState } from 'react';

import { Card, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { fetchChangelog, type Changelog } from '../services/changelog';

/** Renders the generated changelog (What's New). */
export function ChangelogScreen() {
  const t = useT();
  const [changelog, setChangelog] = useState<Changelog | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void fetchChangelog().then((result) => {
      setChangelog(result);
      setLoading(false);
    });
  }, []);

  return (
    <Card>
      <h1 className="text-xl font-semibold text-foreground">{t("What's New")}</h1>

      {loading ? (
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      ) : !changelog || changelog.sections.length === 0 ? (
        <p className="mt-4 text-sm text-muted-foreground">{t('Changelog is not available.')}</p>
      ) : (
        <div className="mt-4 space-y-6">
          {changelog.sections.map((section) => (
            <section key={section.date}>
              <h2 className="text-sm font-medium text-foreground">{section.date}</h2>
              <ul className="mt-2 space-y-1">
                {section.entries.map((entry) => (
                  <li key={`${section.date}-${entry.text}`} className="flex items-baseline gap-2 text-sm">
                    <span className="text-foreground">{entry.text}</span>
                    {entry.hash ? (
                      <code className="text-xs text-muted-foreground">{entry.hash}</code>
                    ) : null}
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </Card>
  );
}
