SET mypath=%~dp0
SET mypath=%mypath:~0,-1%
SET currentdir=%CD%

CD %1
	MKDIR "%1\.github"
		MKDIR "%1\.github\workflows"
			CALL copy "%mypath%\template\.github\workflows\sonarcloud.yml" ".github\workflows\sonarcloud.yml" /Y
				ECHO "replace 'PROJECT_ID' by '%~n1'"
				CALL powershell -Command "(gc .github\workflows\sonarcloud.yml) -replace 'PROJECT_ID', '%~n1' | Out-File -encoding utf8 .github\workflows\sonarcloud.yml"
				CALL git add .github/workflows/sonarcloud.yml
				CALL git commit -m "build(ci): update sonarcloud"
CD %currentdir%
