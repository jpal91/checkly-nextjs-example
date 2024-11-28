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
# NEEDED_ENV_VARS := $(foreach e,$(ENV_VARS),$(shell grep -s $(e) .env.local && echo "" || echo $(e)))
NEEDED_ENV_VARS := $(filter-out $(shell grep -soE '^([A-Z_]+)' .env.local | sed -E s/=.*//g),$(ENV_VARS) $(OPT_ENV_VARS))
GIT_REMOTE := $(shell git remote get-url origin)

# Ask user to input required env variables
create-env.pre:
	@echo "---Creating env variables---\n"
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
	@echo "---Removing git remote---\n";
	# git remote remove origin
endif

# Install dependencies
install-deps:
	@echo Installing Packages
	$(pm_install)
	@echo Installing Vercel CLI
	$(call pm_install,-g vercel)

vercel-login:
	@echo "---Logging into Vercel---\n"
	vercel whoami 2>/dev/null || vercel login
	vercel link

checkly-login:
	@echo "---Logging in to Checkly---\n"
	$(call pm_exec,checkly whoami) 2>/dev/null || $(call pm_exec,checkly login)

sync-secrets:
	@echo "---Syncing Local Secrets with Checkly---\n"
	@for e in $(filter-out CHECKLY_API_KEY% CHECKLY_ACCOUNT_ID%,$(shell cat .env.local)); do \
		input="$$(echo $$e | sed 's/=$$/ null/g' | sed 's/=/ /g')"; \
		$(call pm_exec,checkly env add $$input) 2>/dev/null || $(call pm_exec,checkly env update $$input); \
	done;


init: create-env rm-git-remote install-deps checkly-login sync-secrets vercel-login
	@echo "Remember to - "
	@echo " - Add env secrets to GitHub/GitLab (if applicable)"
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