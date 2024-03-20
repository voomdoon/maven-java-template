:: input:
::  - path to module where to apply the template

SET mypath=%~dp0
SET mypath=%mypath:~0,-1%
SET currentdir=%CD%

CALL xcopy "%mypath%/template-raw" %1 /S /Y

	CD %1
		::TODO fail if not up to date
		::branch=$(git branch --show-current)
		::if [ "$branch" != "main" ]; then
		::git fetch
		::git pull --dry-run
		::if [ -n "$(git status --porcelain)" ]; then
		
		CALL git pull
		CALL git add .gitignore
			CALL git commit -m "chore: update gitignore"
		CALL git add .github/dependabot.yml
			CALL git commit -m "build: update dependabot"
	CD /D %currentdir%
