import type { Sql } from './db.ts';

/**
 * Runs the numbered SQL migrations in `migrations/`, tracking applied versions
 * in `schema_migrations`. Idempotent — safe to run on every container start.
 */
export async function migrate(sql: Sql): Promise<void> {
  await sql`
    create table if not exists schema_migrations (
      version    text primary key,
      applied_at timestamptz not null default now()
    )
  `;

  const applied = new Set(
    (await sql<{ version: string }[]>`select version from schema_migrations`).map((r) => r.version),
  );

  const dir = new URL('../migrations/', import.meta.url);
  const files = Array.from(new Bun.Glob('*.sql').scanSync({ cwd: dir.pathname })).sort();

  for (const file of files) {
    const version = file.replace(/\.sql$/, '');
    if (applied.has(version)) continue;

    const contents = await Bun.file(new URL(file, dir)).text();
    await sql.begin(async (tx) => {
      await tx.unsafe(contents);
      await tx`insert into schema_migrations (version) values (${version})`;
    });
    console.log(`[migrate] applied ${version}`);
  }
}
