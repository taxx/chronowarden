# TODO

### Must fix
* Import / export feature, match google sheet setup
  "We need a way to import data from an older solution, the format is: Start  (date format: yyyy-MM-dd) | Stop (date format: yyyy-MM-dd | Expected work time  (hh:mm) | Overtime (hh:mm) |"
* Something that let's the app check for new versions and ask user to reload the page when a new version is available.
  "We need something that let's the app check for new versions and ask user to reload the page when a new version is available."
* Update all the package versions that we can.
  "Please update all the package versions that we are using, make it iterative and test after each attempt"

### Import data
 What was built                                                                                                                                                                                               
 ### 1. CSV Import Utility — lib/utils/csv_import.dart
                                          
 - parseCsvTimeLogs() — parses a CSV string with header into TimeLog objects                                                                                                                          
 - Returns an ImportResult with imported, errors, and skipped counts                                                                                                                                  
 - Handles quoted fields containing commas, validates date/time formats, skips existing dates to prevent duplicates                                                                                   
 - Expected CSV format documented inline with column reference table                                                                                                                                  
                                                                                                                                                                                                      
 ### 2. AppState import method — lib/app_state.dart
                                                                                                                                                                                                      
 - importDaysFromCsv(String csv) — parses CSV, recalculates overtime per row, inserts each valid log into Supabase, then refreshes all cached data                                                    
 - Uses _getUserId() to scope to the authenticated user                                                                                                                                               
 - Existing dates are automatically skipped (no accidental overwrites)                                                                                                                                
                                                                                                                                                                                                      
 ### 3. Import UI — lib/screens/history_content.dart
                                                                                                                                                                                                      
 - Import button (indigo FAB) added alongside the existing "Add Day" FAB                                                                                                                              
 - _showImportDialog() — opens a dialog with:                                                                                                                                                         
     - A collapsible CSV Format Guide showing the exact column layout with rules and an example                                                                                                       
     - A large textarea for pasting CSV data                                                                                                                                                          
 - After import, shows a snackbar with counts (Imported X day(s), Y skipped, Z errors)                                                                                                                
 - If errors occurred, shows a separate error dialog listing each failed row                                                                                                                          
                                                                                                                                                                                                      
 ### 4. Format documentation                            
                                                                                                                                                                                                      
 The CSV format is documented in two places:                                                                                                                                                          
 1. Inline in the import dialog — collapsible "CSV Format Guide" section visible at import time                                                                                                       
 2. In csv_import.dart — full Dart doc comment with column reference table for developers                                                                                                             
                                          
 ────────────────────────────────────────────────────────────────────────────────                                                                                                                     
                                                                                                                                                                                                      
 ### CSV format expected                                                                                                                                                                              
                                                                                                                                                                                                      
 ```                                                                                                                                                        
   date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note                                                                                                                      
   2026-01-15,08:00:00,16:30:00,480,60,30,Office day                                                                                                                                                  
   2026-01-16,09:00:00,,480,45,0,                                                                                                                                                                     
 ```                                                                                                                                                        

 ┌──────────────────┬────────────┬──────────┬──────────────────────────────────┐                                                                            
 │ Column           │ Format     │ Required │ Notes                            │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ date             │ YYYY-MM-DD │ ✅       │                                  │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ start_time       │ HH:MM:SS   │ ✅       │ 24-hour                          │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ end_time         │ HH:MM:SS   │ —        │ Leave empty for active days      │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ expected_minutes │ integer    │ ✅       │ e.g. 480 for 8h                  │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ overhead_minutes │ integer    │ ✅       │ e.g. 60                          │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ lunch_minutes    │ integer    │ —        │ Default 0                        │
 ├──────────────────┼────────────┼──────────┼──────────────────────────────────┤                                                                            
 │ note             │ string     │ —        │ Use quotes if it contains commas │ 
 └──────────────────┴────────────┴──────────┴──────────────────────────────────┘                                                                                                                      




### Done
* Logotype!
  "Please add favico for the application, use either chronowarden.vsg or chronowarden.png, we can also show the logo on the top of the page just before the "ChronoWarden text""
* Dark mode (three options, light, dark and system. Default to system)
  "Every great app needs dark mode. Let's support light, dark and whatever the users system is using now. Setting should be persisted when user visits the page again it should keep the same"
