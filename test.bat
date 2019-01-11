set /p msg=Please input commit message:
git add -A
git commit -m "%msg%"

pause>nul