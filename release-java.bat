:: Release script for Java projects using Maven.

@ECHO OFF

setlocal enabledelayedexpansion

set "DRY=0"
FOR %%A IN (%*) DO (
  IF /I "%%~A"=="--dry" SET "DRY=1"
)

:: TODO check maven instance
:: FEATURE update JavaDoc inception versions
:: FEATURE pin (Sonars) status badges values in README.md
:: FEATURE check TODOs
:: FEATURE update dependency version at README
:: FEATURE mvn javadoc:javadoc

ECHO HINT: you need to manually set the JavaDoc inception version of all members
ECHO HINT: remember to set the corret version, e.g. convert to minor version, if code has patch version set
PAUSE

:: + + + + + check GIT status + + + + +
git fetch origin || GOTO error

FOR /f %%i IN ('git rev-parse --abbrev-ref HEAD') DO SET BRANCH=%%i

IF NOT "!BRANCH!"=="main" (
  ECHO ERROR: not on main branch, current: !BRANCH!
  GOTO error
)

FOR /f %%i IN ('git rev-parse HEAD') DO SET LOCAL=%%i
FOR /f %%i IN ('git rev-parse origin/main') DO SET REMOTE=%%i

IF NOT "%LOCAL%"=="%REMOTE%" (
  ECHO ERROR: local branch is not up to date with origin/main
  ECHO Local:  %LOCAL%
  ECHO Remote: %REMOTE%
  GOTO error
)

git diff --quiet || (ECHO ERROR: unstaged changes & GOTO error)
git diff --cached --quiet || (ECHO ERROR: staged but uncommitted changes & GOTO error)
IF EXIST ".git\REBASE_HEAD" (ECHO ERROR: rebase in progress & GOTO error)
IF EXIST ".git\MERGE_HEAD"  (ECHO ERROR: merge in progress & GOTO error)
IF EXIST ".git\CHERRY_PICK_HEAD" (ECHO ERROR: cherry-pick in progress & GOTO error)
:: - - - - - - check GIT status - - - - -
:: + + + + + check GIT remote + + + + +
FOR /f "delims=" %%u IN ('git remote get-url origin') DO SET "ORIGIN_URL=%%u"
ECHO INFO: origin = %ORIGIN_URL%

REM Soft warning if owner "voomdoon" isn't visible (supports SSH scp-style and https/ssh:// forms)
SET "ORIGIN_OK="
ECHO %ORIGIN_URL% | findstr /i ":voomdoon/" >nul && SET "ORIGIN_OK=1"
IF NOT DEFINED ORIGIN_OK (
  ECHO %ORIGIN_URL% | findstr /i "/voomdoon/" >nul && SET "ORIGIN_OK=1"
)

IF NOT DEFINED ORIGIN_OK (
  ECHO WARNING: origin does not contain expected owner "voomdoon"
  ECHO WARNING: continuing anyway (sync check vs origin/main will still protect you)
)
:: - - - - check GIT remote - - - - -

ECHO test | gpg --clearsign >nul 2>&1 || (ECHO ERROR: GPG signing failed & GOTO error)

IF "%DRY%"=="1" (
  ECHO DRY RUN: stopping before release:prepare
  GOTO end
)

ECHO release:prepare ...
CALL mvn -Prelease -B release:prepare || GOTO maven_error

ECHO release:perform ...
CALL mvn -Prelease -B release:perform || GOTO maven_error

ECHO push?
PAUSE

git push origin main --tags || GOTO error

GOTO end

:maven_error
ECHO ERROR: Maven release failed.
ECHO You may want to run:
mvn -Prelease release:rollback
git fetch origin
git reset --hard origin/main
GOTO error

:error
ECHO Release script failed.
EXIT /B 1

:end