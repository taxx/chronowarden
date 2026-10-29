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
| ⬜ Admin: pending/rejected status flows | Invite registration auto-approves, so the reserved flow is unused. |
| ⬜ Multi-device / session-persistence info screen | Documentation-only. |
| ⬜ A dedicated break-reminder bell (in addition to leave alerts) | The leave-time alerts cover the main case. |
| ⬜ Onboarding & one-time migration screens | Not needed — no plaintext-era data on new instances. |

## Added after the first gap pass

| Feature | Status |
|---|---|
| Edit / add a day from the Overview calendar | ✅ |
| Remember the Overview period (week/month/year; week by default) | ✅ |
| Time-warding colours (green = kept time, red = worked over) | ✅ |
| Three-state theme toggle (light/dark/system) in the shell | ✅ |
| Admin: reset password (issues a temporary password) | ✅ |
| Encryption explainer screen | ✅ |
| Notifications: permission + send test | ✅ |
| CSV format guide | ✅ |
| Diagnostics panel + manual “check for updates” | ✅ |
| shadcn/ui component layer (Radix dialog/tabs/switch) | ✅ |

## Intentional differences

- **Cookie sessions** instead of bearer-by-default (bearer still accepted).
- **Official BIP39** recovery phrase (the DEK/envelope are unchanged).
- **Client-side day editing** now covers the whole log, not just the active day.
- **Route-based screens** (TanStack Router) instead of a tab shell.
