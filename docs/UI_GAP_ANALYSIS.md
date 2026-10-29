# UI Gap Analysis — Flutter → React parity

Comparison of the retired Flutter client (`/opt/appdata/chronowarden-old`, branch
`feat/selfhost`) against the React client (`apps/web`). The Flutter source used
for this analysis is recoverable with `git archive feat/selfhost apps/web`.

Status legend: ✅ done · 🟡 partial · ⬜ open.

## Fixed in the latest pass

| Feature | Flutter | React before | React now |
|---|---|---|---|
| Live day timer (`HH:MM:SS`) | ✅ | ⬜ (minutes only) | ✅ |
| Live lunch / non-work timers (`mm:ss`) | ✅ | ⬜ | ✅ |
| Adjust lunch / non-work (slider dialog) | ✅ | ⬜ | ✅ |
| Adjust flex (banked time) | ✅ | numeric input | ✅ slider + step |
| Edit note on the active day | ✅ | ⬜ | ✅ |
| Change commute pattern mid-day | ✅ | ⬜ | ✅ |
| Start Day dialog (expected, preset, lunch, non-work, flex, note) | ✅ | ⬜ (one click) | ✅ |
| Stop Day dialog (end time, lunch, non-work, note) | ✅ | ⬜ | ✅ |
| Edit / delete a completed day from My Day | ✅ | ⬜ | ✅ |
| Edit / delete a day in History (confirm dialog, not `window.confirm`) | ✅ | 🟡 | ✅ |
| Weekend visibility honoured in History | ✅ | ⬜ | ✅ |
| Projection analytics (avg growth, net weekly change, weeks to zero, zero date, trend) | ✅ | ⬜ (chart only) | ✅ |
| Transit occupancy / transfers / departs-in / platform | ✅ | 🟡 (line only) | ✅ |
| Light / dark / system theme | ✅ | ⬜ (dark only) | ✅ |
| Change encryption passphrase | ✅ | ⬜ | ✅ |
| About / privacy / version card | ✅ | ⬜ | ✅ |
| Sign-out confirmation | ✅ | ⬜ | ✅ |
| Design system (tokens, primitives, toasts, sidebar/bottom-nav shell) | ✅ (Material) | ⬜ (bare) | ✅ |

## Still open (lower priority)

| Feature | Notes |
|---|---|
| ⬜ Full "How encryption works" explainer screen | We show a condensed privacy card; Flutter had a dedicated 4-layer diagram page. |
| ⬜ Admin: reset password (issue temporary password) | Admin UI manages users/invites; no reset-password action yet. |
| ⬜ Admin: pending/rejected status flows | Invite registration auto-approves, so the reserved flow is unused. |
| ⬜ Notifications: "Send test", permission status readout | Settings exist; no explicit test button. |
| ⬜ CSV format guide dialog | A help panel explaining the CSV columns. |
| ⬜ Diagnostics panel (version, API reachability, storage mode) | Partly covered by the About card. |
| ⬜ "Check for updates" manual button | The update banner is automatic. |
| ⬜ Committed-journey wording ("Committed ride — departed") | We show "Departed" + Pinned. |
| ⬜ Multi-device / session-persistence info screen | Documentation-only. |
| ⬜ Onboarding & one-time migration screens | Not needed — no plaintext-era data on new instances. |

## Intentional differences

- **Cookie sessions** instead of bearer-by-default (bearer still accepted).
- **Official BIP39** recovery phrase (the DEK/envelope are unchanged).
- **Client-side day editing** now covers the whole log, not just the active day.
- **Route-based screens** (TanStack Router) instead of a tab shell.
