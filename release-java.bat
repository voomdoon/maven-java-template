:: Release script for Java projects using Maven.

@ECHO OFF

setlocal enabledelayedexpansion

set "DRY=0"
set "VERBOSE=1"
FOR %%A IN (%*) DO (
  IF /I "%%~A"=="--dry" SET "DRY=1"
  IF /I "%%~A"=="--quiet" SET "VERBOSE=0"
)

:: TODO GH release
:: TODO check maven instance
:: FEATURE update JavaDoc inception versions
:: FEATURE pin (Sonars) status badges values in README.md
:: FEATURE check TODOs
:: FEATURE update dependency version at README
:: FEATURE mvn javadoc:javadoc

ECHO HINT: make sue you are using the correct SSH identity
PAUSE

ECHO HINT: you need to manually set the JavaDoc inception version of all members
ECHO HINT: remember to set the corret version, e.g. convert to minor version, if code has patch version set
PAUSE

:: + + + + + check POM + + + + +
CALL :log_action "checking pom.xml for scm section"
IF NOT EXIST "pom.xml" (
  ECHO ERROR: pom.xml not found in current directory
  GOTO error
)
findstr /i /c:"<scm>" "pom.xml" >nul
IF ERRORLEVEL 2 (
  ECHO ERROR: failed to read pom.xml
  GOTO error
)
IF ERRORLEVEL 1 (
  ECHO ERROR: pom.xml does not contain an scm section
  GOTO error
)

CALL :log_action "checking pom.xml for name/description/url"
findstr /i /c:"<name>" "pom.xml" >nul
IF ERRORLEVEL 2 (
  ECHO ERROR: failed to read pom.xml
  GOTO error
)
IF ERRORLEVEL 1 (
  ECHO ERROR: pom.xml does not contain a name tag
  GOTO error
)
findstr /i /c:"<description>" "pom.xml" >nul
IF ERRORLEVEL 2 (
  ECHO ERROR: failed to read pom.xml
  GOTO error
)
IF ERRORLEVEL 1 (
  ECHO ERROR: pom.xml does not contain a description tag
  GOTO error
)
findstr /i /c:"<url>" "pom.xml" >nul
IF ERRORLEVEL 2 (
  ECHO ERROR: failed to read pom.xml
  GOTO error
)
IF ERRORLEVEL 1 (
  ECHO ERROR: pom.xml does not contain a url tag
  GOTO error
)
:: - - - - - check POM - - - - -

:: + + + + + + + + + + check GIT + + + + + + + + + +
:: + + + + + check GIT status + + + + +
CALL :log_action "checking remote state (git fetch)"
git fetch origin || GOTO error

CALL :log_action "checking current branch"
FOR /f %%i IN ('git rev-parse --abbrev-ref HEAD') DO SET BRANCH=%%i

IF NOT "!BRANCH!"=="main" (
  ECHO ERROR: not on main branch, current: !BRANCH!
  GOTO error
)

CALL :log_action "checking local vs origin/main commit"
FOR /f %%i IN ('git rev-parse HEAD') DO SET LOCAL=%%i
FOR /f %%i IN ('git rev-parse origin/main') DO SET REMOTE=%%i

IF NOT "%LOCAL%"=="%REMOTE%" (
  ECHO ERROR: local branch is not up to date with origin/main
  ECHO Local:  %LOCAL%
  ECHO Remote: %REMOTE%
  GOTO error
)

CALL :log_action "checking for unstaged changes"
git diff --quiet || (ECHO ERROR: unstaged changes & GOTO error)
CALL :log_action "checking for staged but uncommitted changes"
git diff --cached --quiet || (ECHO ERROR: staged but uncommitted changes & GOTO error)
CALL :log_action "checking for rebase/merge/cherry-pick in progress"
IF EXIST ".git\REBASE_HEAD" (ECHO ERROR: rebase in progress & GOTO error)
IF EXIST ".git\MERGE_HEAD"  (ECHO ERROR: merge in progress & GOTO error)
IF EXIST ".git\CHERRY_PICK_HEAD" (ECHO ERROR: cherry-pick in progress & GOTO error)
:: - - - - - check GIT status - - - - -
:: + + + + + check GIT remote + + + + +
CALL :log_action "reading git remote origin URL"
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
:: - - - - - check GIT remote - - - - -
:: - - - - - - - - - - check GIT - - - - - - - - - -

CALL :log_action "preflight build"
CALL mvn -B -ntp clean verify || GOTO error

CALL :log_action "checking for external SNAPSHOT dependencies (excluding reactor)"
CALL mvn -B -ntp -DskipTests -DexcludeReactor=true dependency:list ^
  | findstr /i ":SNAPSHOT" >nul && (
    ECHO ERROR: external SNAPSHOT dependency detected
    CALL mvn -B -ntp -DskipTests -DexcludeReactor=true dependency:list
    GOTO error
  )

CALL :log_action "checking GPG signing and pinentry"
ECHO test | gpg --clearsign >nul 2>&1 || (ECHO ERROR: GPG signing failed & GOTO error)

IF "%DRY%"=="1" (
  ECHO DRY RUN: stopping before release:prepare
  GOTO end
)

CALL :log_action "running mvn release:prepare"
ECHO release:prepare ...
CALL mvn -Prelease -B release:prepare || GOTO maven_error

CALL :log_action "running mvn release:perform"
ECHO release:perform ...
CALL mvn -Prelease -B release:perform || GOTO maven_error

ECHO push?
PAUSE

CALL :log_action "pushing tags and main"
git push origin main --tags || GOTO error

GOTO end

:log_action
set "LOG_MSG=%~1"
IF "%VERBOSE%"=="1" (
  ECHO -^> !LOG_MSG!
)
set "LOG_MSG="
EXIT /B 0

:maven_error
ECHO ERROR: Maven release failed.
ECHO You may want to run:
ECHO mvn -Prelease release:rollback
ECHO git fetch origin
ECHO git reset --hard origin/main
GOTO error

:error
ECHO Release script failed.
EXIT /B 1

:end