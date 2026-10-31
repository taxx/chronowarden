import { useEffect, useState } from 'react';

import { Card, CardContent, CardHeader, Spinner } from '../components/ui';
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
      <CardHeader
        title={t("What's New")}
        description={t('Generated straight from the git history.')}
      />
      <CardContent>
        {loading ? (
          <div className="flex justify-center py-8">
            <Spinner />
          </div>
        ) : !changelog || changelog.sections.length === 0 ? (
          <p className="text-sm text-muted-foreground">{t('Changelog is not available.')}</p>
        ) : (
          <div className="space-y-6">
            {changelog.sections.map((section) => (
              <section key={section.date}>
                <h3 className="sticky top-0 bg-card text-sm font-medium text-muted-foreground">
                  {section.date}
                </h3>
                <ul className="mt-2 space-y-1.5">
                  {section.entries.map((entry) => (
                    <li key={`${section.date}-${entry.text}`} className="flex items-baseline gap-2 text-sm">
                      <span className="flex-1">{entry.text}</span>
                      {entry.hash ? (
                        <code className="shrink-0 text-xs text-muted-foreground">{entry.hash}</code>
                      ) : null}
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
