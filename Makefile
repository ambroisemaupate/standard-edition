#
# Base theme
# Development tasks
#
GREEN=\033[0;32m
RED=\033[0;31m
# No Color
NC=\033[0m
THEME_PREFIX=Base
THEME=${THEME_PREFIX}Theme
# Use Yarn
INSTALL_CMD="`yarn`"
UPDATE_CMD="`yarn upgrade`"
# Or use NPM
#INSTALL_CMD="`npm install`"
#UPDATE_CMD="`npm update`"
# Use a local available port
DEV_DOMAIN="0.0.0.0:8081"

# TODO: Change FTP credentials
# if you want to deploy old-school style
REMOTE_FTP_PATH="/path/to/server/root"
REMOTE_FTP_USER="ftp-user"
REMOTE_FTP_PASS="ftp-secret"
REMOTE_FTP_HOST="ftp-host"

# Default task install + build
all : configtest install build cache

# Install NPM deps and Bower deps
install : configtest themes/${THEME}/node_modules

themes/${THEME}/node_modules :
	cd ./themes/${THEME} && ${INSTALL_CMD};

.PHONY : clean uninstall update build watch cache

cache :
	bin/roadiz cache:clear
	bin/roadiz cache:clear -e prod
	bin/roadiz cache:clear -e prod --preview
	bin/roadiz cache:clear-fpm -e prod -d ${DEV_DOMAIN}
	bin/roadiz cache:clear-fpm -e prod --preview -d ${DEV_DOMAIN}

# Launch Gulp watch task
watch : configtest
	cd ./themes/${THEME} && npm run dev;
# Build prod ready assets with Gulp
build : configtest
	cd ./themes/${THEME} && npm run build;
# Update NPM deps
update : configtest
	cd ./themes/${THEME} && ${UPDATE_CMD};
	@echo "✅\t${GREEN}Updated NPM dependencies. \tOK.${NC}" >&2;
# Delete generated assets
clean :
	rm -rf ./themes/${THEME}/static/css/*;
	rm -rf ./themes/${THEME}/static/js/*;
	@echo "✅\t${GREEN}Cleaned build and dist folders. \tOK.${NC}" >&2;
# Uninstall NPM deps and clean generated assets
uninstall : clean
	rm -rf ./themes/${THEME}/node_modules;
	@echo "✅\t${GREEN}Removed NPM dependencies. \tOK.${NC}" >&2;

# Launch PHP internal server (for dev purpose only)
dev-server:
	@echo "✅\t${GREEN}Launching PHP dev server in web/ folder${NC}" >&2;
	php -S ${DEV_DOMAIN} -t web vendor/roadiz/roadiz/conf/router.php

# Migrate your configured theme, update DB and empty caches.
migrate:
	@echo "✅\t${GREEN}Update schema node-types${NC}" >&2;
	bin/roadiz themes:install --data /Themes/${THEME}/${THEME}App;
	bin/roadiz generate:nsentities;
	bin/roadiz orm:schema-tool:update --dump-sql --force;
	make cache;

push-prod:
	composer update -o --prefer-dist
	bin/roadiz generate:htaccess
	bin/roadiz themes:assets:install ${THEME_PREFIX}
	lftp -e "mirror --only-newer --parallel=3 -R \
		--exclude '/\..+/$$' \
		-x 'app/conf/config\.yml' \
		-x '\.env' \
		-x '(\.dockerignore|\.editorconfig|\.env\.dist|\.gitignore|\.gitlab\-ci\.yml|composer\.json|composer\.lock|docker\-compose\.yml|docker\-compose\-dev\.yml|docker\-sync\.yml|Dockerfile|Makefile|README\.md|LICENSE\.md|Vagrantfile)' \
		-x '(bin|docker|samples|tmp|\.git|\.idea|files)/' \
		-x 'app/(cache|logs|sessions|tmp)/' \
		-x 'web/files/' \
		-x 'node_modules/' \
		-x 'bower_components/' \
		-x 'themes/${THEME}/(app|node_modules|webpack)/' \
		-x '\.(psd|rev|log|cmd|bat|pif|scr|exe|c?sh|reg|vb?|ws?|sql|db|db3)$$' \
		./ ${REMOTE_FTP_PATH}" -u ${REMOTE_FTP_USER},${REMOTE_FTP_PASS} ${REMOTE_FTP_HOST}
	bin/roadiz themes:assets:install --relative --symlink ${THEME_PREFIX}

#
# Test if required binaries are available
#
configtest:
	@command -v npm >/dev/null 2>&1 || { echo "❌\t${RED}I require npm but it's not installed. \tAborting.${NC}" >&2; exit 1; }
	@echo "✅\t${GREEN}NodeJS is available. \tOK.${NC}" >&2;
