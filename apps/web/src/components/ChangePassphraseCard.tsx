import { zodResolver } from '@hookform/resolvers/zod';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { KeyRound } from 'lucide-react';
import { Link } from '@tanstack/react-router';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { useToastStore } from '../state/toast';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
  Input,
} from './ui';

function makeSchema(t: (key: string) => string) {
  return z
    .object({
      newPassphrase: z.string().min(8, t('Passphrase must be at least 8 characters')),
      confirm: z.string(),
    })
    .refine((values) => values.newPassphrase === values.confirm, {
      message: t('Passphrases do not match'),
      path: ['confirm'],
    });
}

/**
 * Re-wrap the DEK under a new encryption passphrase. The data itself is not
 * re-encrypted — only the envelope changes — so this is fast and safe.
 */
export function ChangePassphraseCard() {
  const t = useT();
  const dek = useAuthStore((state) => state.dek);
  const changePassphrase = useAuthStore((state) => state.changePassphrase);
  const pushToast = useToastStore((state) => state.push);
  const [busy, setBusy] = useState(false);

  const form = useForm<z.infer<ReturnType<typeof makeSchema>>>({
    resolver: zodResolver(makeSchema(t)),
    defaultValues: { newPassphrase: '', confirm: '' },
  });

  if (!dek) return null;

  const submit = form.handleSubmit(async (values) => {
    setBusy(true);
    try {
      await changePassphrase(values.newPassphrase);
      form.reset();
      pushToast(t('Passphrase changed'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setBusy(false);
    }
  });

  return (
    <Card>
      <CardHeader
        title={
          <span className="flex items-center gap-2">
            <KeyRound className="h-4 w-4 text-primary" />
            {t('Encryption')}
          </span>
        }
        description={t('Your passphrase protects your encryption key — it never leaves this device.')}
      />
      <CardContent>
        <Form {...form}>
          <form onSubmit={submit} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="newPassphrase"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('New passphrase')}</FormLabel>
                    <FormControl>
                      <Input type="password" autoComplete="new-password" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="confirm"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Confirm passphrase')}</FormLabel>
                    <FormControl>
                      <Input type="password" autoComplete="new-password" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            <div className="flex items-center gap-3">
              <Button type="submit" disabled={busy}>
                {t('Change passphrase')}
              </Button>
              <Link to="/encryption" className="text-sm text-primary hover:underline">
                {t('How encryption works')}
              </Link>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
