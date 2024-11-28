### PACKAGE_MANAGER ###
PACKAGE_MANAGER := $(if $(shell which pnpm 2>/dev/null),pnpm,npm)

ifeq ($(PACKAGE_MANAGER), pnpm)
	pm_exec=pnpm exec $(1)
	pm_install=pnpm install $(1)
else
	pm_exec=npx $(1)
	pm_install=npm install $(1)
endif
	
#######

### INIT ###
ENV_VARS := CHECKLY_ACCOUNT_ID CHECKLY_API_KEY
OPT_ENV_VARS := CHECKLY_ALERT_EMAIL CHECKLY_ALERT_PHONE_NUMBER ENVIRONMENT_URL VERCEL_TOKEN
NEEDED_ENV_VARS := $(filter-out $(shell grep -soE '^([A-Z_]+)' .env.local | sed -E s/=.*//g),$(ENV_VARS) $(OPT_ENV_VARS))
GIT_REMOTE := $(shell git remote get-url origin)

# Ask user to input required env variables
create-env.pre:
	@echo "\n---Creating env variables---\n"
	[ -f .env.local ] || cp .env.example .env.local
create-env: create-env.pre $(addsuffix .env, $(NEEDED_ENV_VARS)) $(addsuffix .env.opt, $(OPT_ENV_VARS))
	
%.env:
	@echo "Please provide value for $*:"
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
		if [ -n $$(echo $$e | sed -E 's/=(.*)/\1/g') ]; then \
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

### COMMANDS ###
# .EXPORT_ALL_VARIABLES:
# -include .env.locals

# checkly_commands := whoami login logout test deploy destroy
#
# # Add all Checkly commands that can be ran via chosen package manager
# $(addprefix checkly.,$(checkly_commands)): checkly.%:
# 	$(call pm_exec,checkly $*)

vercel-build.%:
ifeq ($*,prod)
	vercel build --prod
else
	vercel build
endif
vercel-build: vercel-build.prev

vercel-deploy:
	vercel deploy --prebuilt > deployment-url.txt

vercel-test: vercel-build vercel-deploy
	$(call pm_exec,checkly test -r github --record --env-file=".env.local" -e ENVIRONMENT_URL=$(shell cat deployment-url.txt)) || vercel rollback
	

test:
	$(call pm_exec,checkly test -r github --record --env-file=".env.local")

clean:
	rm -rf .next playwright-report node_modules test-results deployment-url.txt

check.%:
	@echo $($*)
