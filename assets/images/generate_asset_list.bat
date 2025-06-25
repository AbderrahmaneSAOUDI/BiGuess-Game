@echo off
setlocal enabledelayedexpansion

set "outfile=categoryAssets.txt"
echo const Map<String, List<String>> categoryAssets = { > "%outfile%"

rem Loop through each subfolder (anime name)
for /d %%A in (*) do (
    set "anime=%%A"
    echo   '%%A': [ >> "%outfile%"

    rem Look for all .webp files in that folder
    for %%F in ("%%A\*.webp") do (
        echo     'assets/images/%%A/%%~nxF', >> "%outfile%"
    )

    echo   ], >> "%outfile%"
)

echo }; >> "%outfile%"
echo. >> "%outfile%"
echo ✅ Dart map generated in: %outfile%
pause
