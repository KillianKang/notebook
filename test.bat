set /p msg=Please input commit message: 
git add -A
git commit -m "%msg%"
git push