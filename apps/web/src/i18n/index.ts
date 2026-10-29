import { create } from 'zustand';

/**
 * Lightweight i18n, mirroring the Flutter client: English strings are the
 * source keys, Swedish lives in a side catalog, and missing keys fall back to
 * English. `i18n.test.ts` fails on missing or unused Swedish entries.
 */
export type Locale = 'en' | 'sv';

const sv: Record<string, string> = {
  Add: 'Lägg till',
  Edit: 'Redigera',
  Done: 'Klar',
  Working: 'Arbetar',
  Expected: 'Förväntat',
  Started: 'Startade',
  Ended: 'Avslutade',
  Remaining: 'Återstår',
  Undertime: 'Undertid',
  'Adjust lunch': 'Justera lunch',
  'Adjust non-work time': 'Justera icke-arbetstid',
  'Adjust if needed:': 'Justera vid behov:',
  'Travel preset': 'Reseprofil',
  'Change commute pattern': 'Ändra pendlingsmönster',
  Apply: 'Verkställ',
  'Start time': 'Starttid',
  'End time': 'Sluttid',
  'Optional note...': 'Valfri anteckning...',
  'Day completed': 'Dagen klar',
  'Day is active': 'Dagen är aktiv',
  "You're free to go!": 'Du kan gå!',
  'Started at {time}': 'Startade {time}',
  'Today has not started': 'Dagen har inte startat',
  'Total: {minutes} min commute': 'Totalt: {minutes} min pendling',
  'Permanently delete the entry for {date}? This cannot be undone.':
      'Radera posten för {date} permanent? Detta kan inte ångras.',
  'Delete day': 'Radera dag',
  'No travel presets available. Add one in Settings.':
      'Inga reseprofiler tillgängliga. Lägg till en i Inställningar.',
  'net: {value}': 'netto: {value}',
  '✓ done': '✓ klart',
  ChronoWarden: 'ChronoWarden',
  'My Day': 'Min dag',
  'Expected today': 'Förväntat idag',
  'Start Day': 'Starta dagen',
  Start: 'Start',
  Stop: 'Stopp',
  'Leave time': 'Sluttid',
  Lunch: 'Lunch',
  'Non-work': 'Icke-arbete',
  'Non-work time': 'Icke-arbetstid',
  'Banked time to withdraw': 'Sparad tid att ta ut',
  'Stop Day': 'Avsluta dagen',
  Overtime: 'Övertid',
  Today: 'Idag',
  Week: 'Vecka',
  Month: 'Månad',
  Year: 'År',
  'Loading…': 'Laddar…',
  'Time bank over time': 'Tidsbank över tid',
  Balance: 'Saldo',
  'Enable transit': 'Aktivera kollektivtrafik',
  'Home station': 'Hemstation',
  'Work station': 'Arbetsstation',
  'Walk from home (min)': 'Gång från hemmet (min)',
  'Walk to work (min)': 'Gång till arbetet (min)',
  Refresh: 'Uppdatera',
  'Transit unavailable': 'Kollektivtrafik otillgänglig',
  'Try again': 'Försök igen',
  'Retrying in {seconds}s': 'Försöker igen om {seconds} s',
  'No journeys found': 'Inga resor hittades',
  'On time': 'I tid',
  Pin: 'Fäst',
  Unpin: 'Ta bort fäst',
  Pinned: 'Fäst',
  'Search station': 'Sök station',
  'Wrap up and head out': 'Dags att varva ner',
  'You have {minutes} min left before your planned leave time.':
      'Du har {minutes} min kvar till din planerade sluttid.',
  'Finish up and stop the day': 'Avsluta och stoppa dagen',
  'You are {minutes} min past your planned leave time.':
      'Du är {minutes} min över din planerade sluttid.',
  Snooze: 'Snooza',
  Dismiss: 'Avfärda',
  Notifications: 'Aviseringar',
  'Enable notifications': 'Aktivera aviseringar',
  'Alert threshold (min)': 'Tröskel för avisering (min)',
  'Snooze (min)': 'Snooze (min)',
  Sound: 'Ljud',
  Vibration: 'Vibration',
  Permission: 'Behörighet',
  Audio: 'Ljud',
  Yes: 'Ja',
  No: 'Nej',
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
  'Forgot passphrase?': 'Glömt krypteringsfrasen?',
  'Recovery phrase': 'Återställningsfras',
  'Show recovery phrase': 'Visa återställningsfras',
  'Enter your recovery phrase': 'Ange din återställningsfras',
  'New encryption passphrase': 'Ny krypteringsfras',
  'Recover access': 'Återställ åtkomst',
  'Recovery phrase is required': 'Återställningsfras krävs',
  'Something went wrong': 'Något gick fel',
  Preferences: 'Inställningar',
  'Show weekends': 'Visa helger',
  'Default flex minutes': 'Standard flexminuter',
  'Slider step (min)': 'Reglage-steg (min)',
  'Travel presets': 'Resepresets',
  'No presets yet': 'Inga presets än',
  'Add preset': 'Lägg till preset',
  'Edit preset': 'Redigera preset',
  'Delete preset?': 'Ta bort preset?',
  Name: 'Namn',
  'Morning overhead': 'Morgon-overhead',
  'Morning productive': 'Morgon produktiv',
  'Evening overhead': 'Kväll-overhead',
  'Evening productive': 'Kväll produktiv',
  'Commute mode': 'Resläge',
  None: 'Ingen',
  Car: 'Bil',
  Vespa: 'Vespa',
  Overhead: 'Overhead',
  Productive: 'Produktiv',
  'A new version is available — reload to update.':
      'En ny version finns tillgänglig – ladda om för att uppdatera.',
  Reload: 'Ladda om',
  "What's New": 'Nyheter',
  'Changelog is not available.': 'Ändringsloggen är inte tillgänglig.',
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
