:: applies the maven-java-template to a target module
:: input:
::   - path to target module where to apply the template

@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion

:: + + + + + input + + + + +
REM Input validation
IF "%~1" == "" (
	ECHO Usage: %~nx0 ^<module-path^>
	EXIT /B 1
)
SET MODULE_PATH=%~1
SET SCRIPT_DIR=%~dp0
SET TEMPLATE_RAW_DIR=%SCRIPT_DIR%template-raw
SET TEMPLATE_DIR=%SCRIPT_DIR%template
SET CURRENTDIR=%CD%
:: - - - - - input - - - - -

:: + + + + + git sanity checks + + + + +
REM Git sanity checks
IF NOT EXIST "%MODULE_PATH%\.git" (
	ECHO !!! %MODULE_PATH% : not a git repository
	EXIT /B 1
)
CD /D "%MODULE_PATH%"
FOR /F "delims=" %%B IN ('git branch --show-current') DO SET BRANCH=%%B
IF "!BRANCH!" == "" (
	ECHO !!! %MODULE_PATH% : git repository is in detached HEAD state
	CD /D "%CURRENTDIR%"
	EXIT /B 1
)

SET "STATUS="
FOR /F "delims=" %%S IN ('git status --porcelain') DO SET STATUS=%%S
IF "!STATUS!" NEQ "" (
	ECHO !!! %MODULE_PATH% : git working tree is not clean
	git status --short
	CD /D "%CURRENTDIR%"
	EXIT /B 1
)

REM Check upstream
FOR /F "delims=" %%U IN ('git rev-parse --abbrev-ref --symbolic-full-name @{u} 2^>nul') DO SET UPSTREAM=%%U
IF "!UPSTREAM!" == "" (
	ECHO !!! %MODULE_PATH% : current branch has no upstream configured
	CD /D "%CURRENTDIR%"
	EXIT /B 1
)
git fetch --quiet
FOR /F "delims=" %%L IN ('git rev-parse @') DO SET LOCAL=%%L
FOR /F "delims=" %%R IN ('git rev-parse @{u}') DO SET REMOTE=%%R
FOR /F "delims=" %%B IN ('git merge-base @ @{u}') DO SET BASE=%%B
IF NOT "!LOCAL!" == "!REMOTE!" (
	IF "!LOCAL!" == "!BASE!" (
		ECHO !!! %MODULE_PATH% : local branch is behind remote ^(pull first^)
		CD /D "%CURRENTDIR%"
		EXIT /B 1
	) ELSE (
		IF "!REMOTE!" == "!BASE!" (
			ECHO !!! %MODULE_PATH% : local branch is ahead of remote ^(push first^)
			CD /D "%CURRENTDIR%"
			EXIT /B 1
		) ELSE (
			ECHO !!! %MODULE_PATH% : local and remote branches have diverged
			CD /D "%CURRENTDIR%"
			EXIT /B 1
		)
	)
)
ECHO Git repository is clean and up to date
CD /D "%CURRENTDIR%"
:: - - - - - git sanity checks - - - - -

:: + + + + + raw template files + + + + +
REM Copy template-raw files
IF NOT EXIST "%TEMPLATE_RAW_DIR%" (
	ECHO !!! %MODULE_PATH% : template-raw directory not found at %TEMPLATE_RAW_DIR%
	EXIT /B 1
)

xcopy "%TEMPLATE_RAW_DIR%" "%MODULE_PATH%" /E /I /Y >nul
:: - - - - - raw template files - - - - -

:: + + + + + + + + + + template files + + + + + + + + + +
REM Check for pom.xml
IF NOT EXIST "%MODULE_PATH%\pom.xml" (
	ECHO !!! %MODULE_PATH% : pom.xml not found in %MODULE_PATH%
	EXIT /B 1
)

:: + + + + + extract artifactId + + + + +
SET "MODULE_NAME="

FOR /F "usebackq delims=" %%A IN (`
  mvn -q -N -f "%MODULE_PATH%\pom.xml" -DforceStdout help:evaluate "-Dexpression=project.artifactId" 2^>^&1
`) DO (
  IF NOT "%%A"=="" SET "MODULE_NAME=%%A"
)

REM Validate result
IF NOT DEFINED MODULE_NAME (
  ECHO !!! %MODULE_PATH% : Could not extract ^<artifactId^> from pom.xml ^(empty result^)
  EXIT /B 1
)

REM If the last line is an error, fail
ECHO(!MODULE_NAME!| findstr /B /C:"[ERROR]" >nul
IF %ERRORLEVEL% EQU 0 (
  ECHO !!! %MODULE_PATH% : Could not extract ^<artifactId^> from pom.xml ^(Maven error: !MODULE_NAME!^)
  EXIT /B 1
)

ECHO Module name: !MODULE_NAME!
:: - - - - - extract artifactId - - - - -

:: + + + + + template files + + + + +
SET "TMP_DIR=%TEMP%\maven-java-template-%RANDOM%%RANDOM%"
mkdir "%TMP_DIR%" || (ECHO !!! Failed to create temp dir & EXIT /B 1)
ECHO TMP_DIR: %TMP_DIR%

REM Always clean up temp on exit from this section
SET "RC=0"

REM 1) Copy template-raw into temp
robocopy "%TEMPLATE_RAW_DIR%" "%TMP_DIR%" /E /NFL /NDL /NJH /NJS /NP >nul
IF ERRORLEVEL 8 (
  ECHO !!! Failed to copy template-raw into temp
  SET "RC=1"
  GOTO :cleanup_tmp
)

REM (optional) also copy template into temp (if you have both dirs)
robocopy "%TEMPLATE_DIR%" "%TMP_DIR%" /E /NFL /NDL /NJH /NJS /NP >nul
IF ERRORLEVEL 8 (
  ECHO !!! Failed to copy template into temp
  SET "RC=1"
  GOTO :cleanup_tmp
)

REM 2) Apply replacements ONLY inside temp
powershell -NoProfile -Command ^
  "$root=$env:TMP_DIR; $name=$env:MODULE_NAME;" ^
  "Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {" ^
  "  $p=$_.FullName;" ^
  "  try { $c=Get-Content -LiteralPath $p -Raw -ErrorAction Stop } catch { return }" ^
  "  if($c -notmatch 'TEMPLATE_NAME'){ return }" ^
  "  $n=$c -replace 'TEMPLATE_NAME',$name;" ^
  "  if($n -ne $c){ Set-Content -LiteralPath $p -Value $n -NoNewline }" ^
  "}"
IF ERRORLEVEL 1 (
  ECHO !!! Replacement step failed in temp
  SET "RC=1"
  GOTO :cleanup_tmp
)

REM 3) Deploy temp -> target module (overwrite only template files)
robocopy "%TMP_DIR%" "%MODULE_PATH%" /E /NFL /NDL /NJH /NJS /NP >nul
IF ERRORLEVEL 8 (
  ECHO !!! Failed to deploy staged template into module
  SET "RC=1"
  GOTO :cleanup_tmp
)

:cleanup_tmp
REM 4) Clean up temp
rmdir /s /q "%TMP_DIR%" >nul 2>nul

IF NOT "%RC%"=="0" EXIT /B %RC%
:: - - - - - template files - - - - -
:: - - - - - - - - - - template files - - - - - - - - - -

:: + + + + + cleanup + + + + +
REM Remove .github/workflows/maven.yml
IF EXIST "%MODULE_PATH%\.github\workflows\maven.yml" DEL /F /Q "%MODULE_PATH%\.github\workflows\maven.yml"

REM Remove .github/workflows/dependabot-automerge-patch.yml
IF EXIST "%MODULE_PATH%\.github\workflows\dependabot-automerge-patch.yml" DEL /F /Q "%MODULE_PATH%\.github\workflows\dependabot-automerge-patch.yml"
:: - - - - - cleanup - - - - -

:: + + + + + commit + + + + +
REM Commit changes if any
CD /D "%MODULE_PATH%"
git add .
git diff --cached --quiet
IF ERRORLEVEL 1 (
	git commit -m "build: apply maven-java-template"
	git push
	ECHO OK %MODULE_PATH% : updated
) ELSE (
	ECHO OK %MODULE_PATH%
)
CD /D "%CURRENTDIR%"
:: - - - - - commit - - - - -

ENDLOCAL
