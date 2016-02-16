#!/bin/bash

# Formatting output to make it easier to function read 
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
RESULT=0

# Lets get env vars and switch path
source /tmp/ci_config/versions.cfg

# PHPUNIT Testing
{
	# What if we made these calls seperate.....
	# phpunit test cases
	phpunit -c tests/phpunit.xml

	PHPUNIT_OUT=$?
	if [[ $PHPUNIT_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"phpunit -c tests/phpunit.xml\" exited with ${PHPUNIT_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"phpunit -c tests/phpunit.xml\" exited with ${PHPUNIT_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# PHP syntax error checks
{
	find ../ \( -name '*.php' \) -exec php -lf {} \;
	SYNTAX_OUT=$?
	if [[ $SYNTAX_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"find ../ \\( -name '*.php' \\) -exec php -lf {} \\;\" exited with ${SYNTAX_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"find ../ \\( -name '*.php' \\) -exec php -lf {} \\;\" exited with ${SYNTAX_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# Wordpress Coding Standards
{
	$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ../ --standard=./tests/codesniffer.ruleset.xml --extensions=php
	PHPCS_OUT=$?
	if [[ $PHPCS_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ../ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ../ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# ESLint - Javascript lint tests
#   Files can be ignored by adding to the .eslintignore file, please see the documentation
#   provided here: http://eslint.org/docs/user-guide/command-line-interface
{
	$(npm bin)/eslint -f compact ./
	ESLINT_OUT=$?
	if [[ $ESLINT_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"$(npm bin)/eslint -f compact ./\" exited with ${ESLINT_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"$(npm bin)/eslint -f compact ./\" exited with ${ESLINT_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# CSSLint - CSS line tests
#   Rules applied come from CI_config, the repo may add files to an exclusion list
#   by specifying the --exclude-list option like:
#      csslint --exclude-list=thirdparty.css,tests/
#   This would ignore the thirdparty.css file and any css files under the tests path
{
	$(npm bin)/csslint --format=compact --quiet ./
	CSSLINT_OUT=$?
	if [[ $CSSLINT_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"$(npm bin)/csslint --format=compact --quiet ./\" exited with ${CSSLINT_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"$(npm bin)/csslint --format=compact --quiet ./\" exited with ${CSSLINT_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

exit $RESULT