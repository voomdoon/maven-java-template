::@ECHO OFF

setlocal enabledelayedexpansion

:: TODO check maven instance

:: XXX preparation:
:: git config --local core.sshCommand "ssh -i C:/Users/andrschulz/.ssh/voomdoon/id_voomdoon_2022-03-27 -o IdentitiesOnly=yes"

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

:: FEATURE update JavaDoc inception versions
:: FEATURE pin (Sonars) status badges values in README.md
:: FEATURE check TODOs
:: FEATURE update dependency version at README
:: FEATURE mvn javadoc:javadoc

ECHO test | gpg --clearsign

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
