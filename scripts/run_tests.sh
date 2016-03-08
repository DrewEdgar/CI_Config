#!/bin/bash

# Formatting output to make it easier to function read 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
	find ./ \( -name '*.php' \) -exec php -lf {} \;
	SYNTAX_OUT=$?
	if [[ $SYNTAX_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"find ./ \\( -name '*.php' \\) -exec php -lf {} \\;\" exited with ${SYNTAX_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"find ./ \\( -name '*.php' \\) -exec php -lf {} \\;\" exited with ${SYNTAX_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# Wordpress Coding Standards
{
	$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php
	PHPCS_OUT=$?
	if [[ $PHPCS_OUT == 0 ]]; then
		echo -ne "${GREEN}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
	else
		echo -ne "${RED}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
		RESULT=1
	fi
}

# ESLint - Javascript lint tests
#   Files can be ignored by adding to the .eslintignore file, please see the documentation
#   provided here: http://eslint.org/docs/user-guide/command-line-interface
# {
#	$(npm bin)/eslint -f compact ./
#	ESLINT_OUT=$?
#	if [[ $ESLINT_OUT == 0 ]]; then
#		echo -ne "${GREEN}The command \"$(npm bin)/eslint -f compact ./\" exited with ${ESLINT_OUT}.${NC}\n\n"
#	else
#		echo -ne "${RED}The command \"$(npm bin)/eslint -f compact ./\" exited with ${ESLINT_OUT}.${NC}\n\n"
#		RESULT=1
#	fi
# }

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

# @codingStandardsIgnoreLine checks
# We can not have standards ignored, since devs could put these anywhere we need to grep and count, this will check, more than 5 = failure
{
	GREP_OUT="$(grep -Ri '@codingStandardsIgnoreLine' ./* | wc -l | tr -d '[[:space:]]')"
	if [[ $GREP_OUT -eq 0 ]]; then
		echo -ne "${GREEN}Check for coding standards ignore passed.${NC}\n\n"
	elif [[ $GREP_OUT -lt 6 ]]; then
		echo -ne "${YELLOW}Several lines (${GREP_OUT}) are ignoring coding standards.${NC}\n\n"
	else
		echo -ne "${RED}Failure - Too many coding standards ignored (${GREP_OUT}), code must be inspected for @codingStandardsIgnoreLine comments and manually given a pass by Integration.${NC}\n\n"
		RESULT=1
	fi
}

exit $RESULT