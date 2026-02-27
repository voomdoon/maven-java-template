# maven-java-template

[![CI](https://github.com/voomdoon/maven-java-template/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/voomdoon/maven-java-template/actions/workflows/ci.yml?query=branch%3Amain)
[![License](https://img.shields.io/github/license/voomdoon/maven-java-template)](https://github.com/voomdoon/maven-java-template/blob/main/LICENSE)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=coverage)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=bugs)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=voomdoon_maven-java-template&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=voomdoon_maven-java-template)


## Prerequisites on the target GitHub repository

- set action repository secret `SONAR_TOKEN`
- have `DEPENDABOT_AUTOMERGE_PAT`
	- Fine-grained personal access token
		- Administration: RO
		- Contents: R+W
		- Metadata: RO
		- Pull requests: R+W
		- Workflows: R+W
- set Dependabot secret `DEPENDABOT_AUTOMERGE_PAT`
- set repository secret `DEPENDABOT_AUTOMERGE_PAT`
- add branch classic protection rule for `main`
	- Require a pull request before merging
		- check all
	- Require status checks to pass before merging
		- Require branches to be up to date before merging
		- add `verify` and `CodeQL`
			- might become visible after the first run
	- Require conversation resolution before merging
	- Require linear history
- enable `Allow auto-merge`


## Apply the template

- TODO
