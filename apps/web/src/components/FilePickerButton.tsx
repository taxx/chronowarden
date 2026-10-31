import { useRef } from 'react';
import { Upload } from 'lucide-react';

import { Button } from './ui';

/**
 * A small "choose a file" button that reads the picked file as text.
 * Used by the CSV and backup import dialogs so users don't have to paste.
 */
export function FilePickerButton({
  accept,
  label,
  onLoad,
}: {
  accept: string;
  label: string;
  onLoad: (text: string, fileName: string) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="hidden"
        onChange={async (event) => {
          const file = event.target.files?.[0];
          if (!file) return;
          onLoad(await file.text(), file.name);
          event.target.value = '';
        }}
      />
      <Button variant="outline" size="sm" onClick={() => inputRef.current?.click()}>
        <Upload className="h-3.5 w-3.5" />
        {label}
      </Button>
    </>
  );
}
