# maven-java-template


## Prerequisites on the target GitHub repository

- set action repository secret `SONAR_TOKEN`
- set Dependabot secret `DEPENDABOT_AUTOMERGE_PAT`
	- Fine-grained personal access token
		- Administration: RO
		- Contents: R+W
		- Metadata: RO
		- Pull requests: R+W
		- Workflows: R+W
- add branch classic protection rule for `main`
	- Require a pull request before merging
		- add `verify` and `CodeQL` 
	- Require status checks to pass before merging
		- Require branches to be up to date before merging
	- Require conversation resolution before merging
	- Require linear history
- enable `Allow auto-merge`


## Apply the template

- TODO
