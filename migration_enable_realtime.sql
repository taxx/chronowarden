-- Enable Realtime for the time_logs table.
-- Run this once to allow cross-device sync without page reloads.
ALTER PUBLICATION supabase_realtime ADD TABLE time_logs;
