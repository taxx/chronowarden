import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';

import { useT } from '../i18n';
import { useSaveWorkConfig, useWorkConfig } from '../queries/settings';
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

const NUM_RE = /^\d+$/;
const WEEK_RE = /^$|^([1-9]|[1-4][0-9]|5[0-3])$/;

function makeSchema(t: (key: string) => string) {
  return z.object({
    defaultExpectedMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    reducedExpectedMinutes: z.string(),
    reducedStartWeek: z.string().regex(WEEK_RE, t('Weeks must be between 1 and 53')),
    reducedEndWeek: z.string().regex(WEEK_RE, t('Weeks must be between 1 and 53')),
  });
}

/** Edit the per-user expected work time, including the seasonal reduced period. */
export function WorkConfigCard() {
  const t = useT();
  const query = useWorkConfig();
  const save = useSaveWorkConfig();
  const pushToast = useToastStore((state) => state.push);

  const form = useForm<z.infer<ReturnType<typeof makeSchema>>>({
    resolver: zodResolver(makeSchema(t)),
    defaultValues: {
      defaultExpectedMinutes: '480',
      reducedExpectedMinutes: '',
      reducedStartWeek: '',
      reducedEndWeek: '',
    },
  });

  useEffect(() => {
    const config = query.data;
    form.reset({
      defaultExpectedMinutes: String(config?.defaultExpectedMinutes ?? 480),
      reducedExpectedMinutes:
        config?.reducedExpectedMinutes != null ? String(config.reducedExpectedMinutes) : '',
      reducedStartWeek: config?.reducedStartWeek != null ? String(config.reducedStartWeek) : '',
      reducedEndWeek: config?.reducedEndWeek != null ? String(config.reducedEndWeek) : '',
    });
  }, [query.data, form]);

  const submit = form.handleSubmit(async (values) => {
    try {
      await save.mutateAsync({
        defaultExpectedMinutes: Number(values.defaultExpectedMinutes) || 480,
        reducedExpectedMinutes: values.reducedExpectedMinutes
          ? Number(values.reducedExpectedMinutes)
          : null,
        reducedStartWeek: values.reducedStartWeek ? Number(values.reducedStartWeek) : null,
        reducedEndWeek: values.reducedEndWeek ? Number(values.reducedEndWeek) : null,
      });
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    }
  });

  return (
    <Card>
      <CardHeader
        title={t('Work hours')}
        description={t('Configure your expected work time per day.')}
      />
      <CardContent>
        <Form {...form}>
          <form onSubmit={submit} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="defaultExpectedMinutes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Default expected minutes')}</FormLabel>
                    <FormControl>
                      <Input type="number" inputMode="numeric" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="reducedExpectedMinutes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Reduced expected minutes')}</FormLabel>
                    <FormControl>
                      <Input type="number" inputMode="numeric" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="reducedStartWeek"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Reduced start week')}</FormLabel>
                    <FormControl>
                      <Input type="number" inputMode="numeric" {...field} />
                    </FormControl>
                    <FormMessage>
                      {field.value === ''
                        ? t('Leave reduced fields empty to disable the reduced period.')
                        : null}
                    </FormMessage>
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="reducedEndWeek"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Reduced end week')}</FormLabel>
                    <FormControl>
                      <Input type="number" inputMode="numeric" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            <div>
              <Button type="submit" disabled={save.isPending}>
                {t('Save')}
              </Button>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
