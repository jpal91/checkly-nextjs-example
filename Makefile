all: help

### PACKAGE_MANAGER ###
PACKAGE_MANAGER := $(if $(shell which pnpm 2>/dev/null),pnpm,npm)

ifeq ($(PACKAGE_MANAGER), pnpm)
	pm_exec=pnpm exec $(1)
	pm_install=pnpm install $(1)
	pm_rm=pmpm remove $(1)
else
	pm_exec=npx $(1)
	pm_install=npm install $(1)
	pm_rm=npm uninstall $(1)
endif
	
#######

### INIT ###
ENV_VARS := CHECKLY_ACCOUNT_ID CHECKLY_API_KEY VERCEL_TOKEN
OPT_ENV_VARS := CHECKLY_ALERT_EMAIL CHECKLY_ALERT_PHONE_NUMBER ENVIRONMENT_URL
NEEDED_ENV_VARS := $(filter-out $(shell grep -soE '^([A-Z_]+)' .env.local | sed -E s/=.*//g),$(ENV_VARS))
NEEDED_OPT_ENV_VARS := $(filter-out $(shell grep -soE '^([A-Z_]+)' .env.local | sed -E s/=.*//g),$(OPT_ENV_VARS))
GIT_REMOTE := $(shell git remote get-url origin)

# Ask user to input required env variables
create-env.pre:
	@echo "\n---Creating env variables---\n"
	@echo "\n\nNOTE: If only using the cli to perform CI actions, you can safely ignore setting"
	@echo "these variables by pressing 'enter' to skip. However, when using third party CI tools"
	@echo "(ie GitHub), the 'required' variables must be set. You can rerun with 'make create-env'\n\n"
create-env: create-env.pre $(addsuffix .env, $(NEEDED_ENV_VARS)) $(addsuffix .env.opt, $(NEEDED_OPT_ENV_VARS))
	
%.env:
	@echo "Please provide value for $* (required):"
	@read -p "> " val; \
	echo "$*=$$val" >> .env.local;

%.env.opt:
	@echo "Provide value for $* (optional):"
	@read -p "> " val; \
	[ -n "$$val" ] && echo "$*=$$val" >> .env.local || true

# Remove default git remote
rm-git-remote:
ifeq ($(GIT_REMOTE),https://github.com/jpal91/checkly-nextjs-example.git)
	@echo "\n---Removing git remote---\n";
	# git remote remove origin
endif

# Install dependencies
install-deps:
	@echo "\n---Installing dependencies---\n"
	$(pm_install)
	@echo "\n---Installing Vercel CLI---\n"
	$(call pm_install,-g vercel)

vercel-login:
	@echo "\n---Logging into Vercel---\n"
	vercel whoami 2>/dev/null || vercel login
	vercel link

checkly-login:
	@echo "\n---Logging in to Checkly---\n"
	$(call pm_exec,checkly whoami) 2>/dev/null || $(call pm_exec,checkly login)

# Checks for any set env secrets in the .env.local and syncs them with Checkly
sync-secrets:
	@echo "\n---Syncing Local Secrets with Checkly---\n"
	@for e in $(filter-out CHECKLY_API_KEY% CHECKLY_ACCOUNT_ID%,$(shell cat .env.local)); do \
		if [ -z "$$(echo $$e | grep -sE '[A-Z_]+=(\n|$$)')" ]; then \
			input="$$(echo $$e | sed 's/=/ /g')"; \
			$(call pm_exec,checkly env add $$input) 2>/dev/null || $(call pm_exec,checkly env update $$input); \
		fi; \
	done;


init: create-env rm-git-remote install-deps checkly-login sync-secrets vercel-login
	@echo "\nRemember to - "
	@echo " - Add env secrets to GitHub/GitLab (if applicable)"
	@echo " - Add env secrets to this repo in the .env.local file (can be done with 'make create-env')"
	@echo " - Add new remote repo url"
######

### VERCEL HELPERS ###
vercel-build-%:
ifeq ($*,prod)
	@echo "\n---Building Production---\n"
	vercel build --prod
else ifeq ($*,prev)
	@echo "\n---Building Preview---\n"
	vercel build
else
	exit 1
endif

vercel-deploy-prev:
	@echo "\n---Deploying to Vercel---\n"
	vercel deploy --prebuilt > deployment-url.txt
######

### COMMANDS ###
.EXPORT_ALL_VARIABLES:
-include .env.local

# Runs through the entire process of build preview, deployment, and running Checkly tests against the preview 
# If the tests pass, the build is then promoted to production
vercel-deploy: vercel-build-prev vercel-deploy-prev
	@echo "\n---Running Checkly Tests---\n"
	@deployment_url=$(shell cat deployment-url.txt); \
	# Gets all env variables that are set and updates ENVIRONMENT_URL to the preview url given by Vercel 
	envs="$(shell cat .env.local | grep -E '^[A-Z_]+=.+$$' | sed -E "s/(ENVIRONMENT_URL=).*/\1$$deployment_url/" | sed -E 's/(\S+)/-e \1/g')"; \
	if ! $$(echo "$$envs" | grep -qE 'ENVIRONMENT_URL' ); then \
		envs="$$envs -e ENVIRONMENT_URL=$$deployment_url"; \
	else \
		envs=$(shell echo $$envs | sed -E "s/(ENVIRONMENT_URL=).*/\1$$deployment_url/"); \
	fi; \
	# Runs checkly tests and exits on error
	$(call pm_exec,checkly test -r github --record $$envs) || exit 1 
	vercel promote
	# Deploy new checks
	$(call pm_exec,checkly deploy --force)
	
trigger-fail:
	$(call pm_exec,checkly deploy --force);
	@echo "Waiting a few seconds for test to fail..."
	sleep 10
	$(call pm_exec,checkly destroy --force)

test:
	$(call pm_exec,checkly test -r github --record --env-file=".env.local")

clean:
	rm -rf .next playwright-report node_modules test-results deployment-url.txt
	$(call pm_exec,checkly destroy --force)

clean-all: clean
	$(call pm_rm,-g vercel)

help:
	@echo "Usage: make <command>"
	@echo "Commands:"
	@echo " init - Walks through project creation, adding necessary dependencies"
	@echo " test - Runs checkly tests locally"
	@echo " vercel-deploy - Builds preview, deploys to vercel, and runs Checkly tests."
	@echo "  If tests are successful, the build is promoted to production"
	@echo " trigger-fail - Shows what would happen if a test were to fail. See README for more details"
	@echo " clean - Deletes all assets and dependencies"
	@echo " clean-all - 'clean' + removes vercel cli globally"
	@echo " help - prints this message and exits"

######
