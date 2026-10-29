import { create } from 'zustand';

/**
 * Lightweight i18n, mirroring the Flutter client: English strings are the
 * source keys, Swedish lives in a side catalog, and missing keys fall back to
 * English. `i18n.test.ts` fails on missing or unused Swedish entries.
 */
export type Locale = 'en' | 'sv';

const sv: Record<string, string> = {
  ChronoWarden: 'ChronoWarden',
  'My Day': 'Min dag',
  'Expected today': 'Förväntat idag',
  'Start Day': 'Starta dagen',
  Start: 'Start',
  Stop: 'Stopp',
  'Leave time': 'Sluttid',
  Elapsed: 'Förfluten tid',
  Lunch: 'Lunch',
  'Start lunch': 'Starta lunch',
  'Stop lunch': 'Stoppa lunch',
  'Non-work': 'Icke-arbete',
  'Start non-work': 'Starta icke-arbete',
  'Stop non-work': 'Stoppa icke-arbete',
  'Banked time to withdraw': 'Sparad tid att ta ut',
  'Stop Day': 'Avsluta dagen',
  'Day complete': 'Dagen klar',
  Overtime: 'Övertid',
  Today: 'Idag',
  Week: 'Vecka',
  'Time bank over time': 'Tidsbank över tid',
  Balance: 'Saldo',
  'Time bank': 'Tidsbank',
  Save: 'Spara',
  Saved: 'Sparat',
  'Work hours': 'Arbetstid',
  'Default expected minutes': 'Förväntade minuter (standard)',
  'Reduced expected minutes': 'Förväntade minuter (reducerad)',
  'Reduced start week': 'Reducerad startvecka',
  'Reduced end week': 'Reducerad slutvecka',
  Cancel: 'Avbryt',
  'Could not save': 'Kunde inte spara',
  'Add day': 'Lägg till dag',
  'Edit day': 'Redigera dag',
  Date: 'Datum',
  'Expected minutes': 'Förväntade minuter',
  'Lunch minutes': 'Lunchminuter',
  'Non-work minutes': 'Minuter icke-arbete',
  Note: 'Anteckning',
  Delete: 'Ta bort',
  'Delete this day?': 'Ta bort denna dag?',
  'No days recorded yet': 'Inga dagar registrerade än',
  Users: 'Användare',
  Invites: 'Inbjudningar',
  Approve: 'Godkänn',
  Reject: 'Neka',
  'Delete user?': 'Ta bort användare?',
  'Create invite': 'Skapa inbjudan',
  'Copy this token and share it with the user:': 'Kopiera koden och dela den med användaren:',
  Copy: 'Kopiera',
  'No invites yet': 'Inga inbjudningar än',
  'Delete invite?': 'Ta bort inbjudan?',
  Active: 'Aktiv',
  Used: 'Använd',
  Expired: 'Utgången',
  'Backup & Restore': 'Backup & återställning',
  'Download a complete, encrypted backup you can restore on any ChronoWarden instance.':
      'Ladda ner en komplett, krypterad säkerhetskopia som du kan återställa på vilken ChronoWarden-instans som helst.',
  'Download backup': 'Ladda ner säkerhetskopia',
  'Restore backup': 'Återställ säkerhetskopia',
  'Backup downloaded': 'Säkerhetskopia nedladdad',
  'Invalid backup file': 'Ogiltig säkerhetskopia',
  'Restoring replaces all data in this account. Use the encryption passphrase from the backup.':
      'Återställning ersätter all data i detta konto. Använd krypteringsfrasen från säkerhetskopian.',
  'Paste your backup JSON below.': 'Klistra in din säkerhetskopia (JSON) nedan.',
  Restore: 'Återställ',
  'Export CSV': 'Exportera CSV',
  'Import CSV': 'Importera CSV',
  'Paste your CSV data below.': 'Klistra in din CSV-data nedan.',
  'Imported {count} day(s)': 'Importerade {count} dag(ar)',
  ', {count} skipped (duplicates)': ', {count} överhoppade (dubbletter)',
  ', {count} error(s)': ', {count} fel',
  Overview: 'Översikt',
  Projection: 'Prognos',
  History: 'Historik',
  Transit: 'Kollektivtrafik',
  Settings: 'Inställningar',
  Admin: 'Admin',
  'Log out': 'Logga ut',
  'First-time setup': 'Första uppsättningen',
  'Full name': 'Namn',
  'Create admin account': 'Skapa admin-konto',
  'You are the first user. This account will be an administrator.':
      'Du är den första användaren. Detta konto blir administratör.',
  'Sign in': 'Logga in',
  'Invite token': 'Inbjudningskod',
  'Create account': 'Skapa konto',
  'Invalid or expired invite token': 'Ogiltig eller utgången inbjudningskod',
  'Ask your administrator for an invite token': 'Be din administratör om en inbjudningskod',
  'Have an invite?': 'Har du en inbjudan?',
  'I have an encryption passphrase': 'Jag har en krypteringsfras',
  'Email': 'E-post',
  'Password': 'Lösenord',
  'Encryption passphrase': 'Krypteringsfras',
  'Confirm encryption passphrase': 'Bekräfta krypteringsfras',
  'Language': 'Språk',
  'Email is required': 'E-post krävs',
  'Password must be at least 10 characters': 'Lösenordet måste vara minst 10 tecken',
  'Encryption passphrase must be at least 8 characters':
      'Krypteringsfrasen måste vara minst 8 tecken',
  'Encryption passphrases do not match': 'Krypteringsfraserna matchar inte',
  'Unlock': 'Lås upp',
  'Your data is encrypted. Enter your encryption passphrase to unlock it.':
      'Din data är krypterad. Ange din krypteringsfras för att låsa upp den.',
  'Your recovery phrase': 'Din återställningsfras',
  'This is the only way to recover your encrypted data if you forget your encryption passphrase. Write it down and keep it safe.':
      'Detta är det enda sättet att återställa din krypterade data om du glömmer din krypteringsfras. Skriv ner den och förvara den säkert.',
  'I have saved my recovery phrase': 'Jag har sparat min återställningsfras',
};

interface LocaleState {
  locale: Locale;
  setLocale: (locale: Locale) => void;
}

const LOCALE_STORAGE_KEY = 'cw_locale';
const stored = typeof localStorage !== 'undefined' ? localStorage.getItem(LOCALE_STORAGE_KEY) : null;

export const useLocaleStore = create<LocaleState>((set) => ({
  locale: stored === 'sv' ? 'sv' : 'en',
  setLocale: (locale) => {
    localStorage.setItem(LOCALE_STORAGE_KEY, locale);
    set({ locale });
  },
}));

function interpolate(template: string, params?: Record<string, string | number>): string {
  if (!params) return template;
  return template.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in params ? String(params[name]) : match,
  );
}

export function translate(
  locale: Locale,
  key: string,
  params?: Record<string, string | number>,
): string {
  const template = locale === 'sv' ? (sv[key] ?? key) : key;
  return interpolate(template, params);
}

/** React hook returning a `t(key, params?)` bound to the current locale. */
export function useT() {
  const locale = useLocaleStore((state) => state.locale);
  return (key: string, params?: Record<string, string | number>) => translate(locale, key, params);
}

export { sv as svCatalog };
