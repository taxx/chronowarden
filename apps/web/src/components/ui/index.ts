/**
 * UI kit — shadcn/ui components (Radix + Tailwind) plus a few small helpers,
 * re-exported under stable names so existing imports keep working.
 */
export { cn } from '@/lib/utils';
export { Button, buttonVariants } from './button';
export { Badge } from './badge';
export { Card, CardHeader, CardContent, CardFooter } from './card';
export { Input, Textarea, Select, Label, Field } from './input';
export { Modal, ConfirmDialog } from './dialog';
export { Tabs } from './tabs';
export { Switch } from './switch';
export { Slider, Progress, Spinner, Skeleton, Separator } from './feedback';
export { EmptyState } from './empty-state';
export { Toaster } from './toaster';
export { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider } from './tooltip';
export {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
} from './dropdown-menu';
