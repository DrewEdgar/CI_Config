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

# TODO: Make this part of the installation script, once it is moved to this project
# Temporary, we want this in the installer ideally, with versioning
cp -r /tmp/ci_config/postmedia-coding-standards $INSTALL_PATH/
echo -ne "${CYAN}Setting paths to sniffs, the following are the active sniffs being used by phpcs:${NC}\n\n"
$INSTALL_PATH/php-codesniffer/scripts/phpcs --config-set installed_paths $INSTALL_PATH/wordpress-coding-standards/,$INSTALL_PATH/postmedia-coding-standards/
$INSTALL_PATH/php-codesniffer/scripts/phpcs -e --standard=./tests/codesniffer.ruleset.xml --extensions=php
echo -ne "\n\n"

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

# PHPUNIT Code Coverage
{
	# Requires Xdebug to run
	# Currently destroys the world when testing because a 11 second test now takes 2 hours thanks to Xdebug
	# so currently we will cheat a little and grep some things.....to get a sanity for how much testing is done
	#
	# phpunit -c tests/phpunit_code_coverage.xml --coverage-text=~/report.txt ./
	{
		echo -ne "Executing check on code coverage.....\n\n"
		PHP_FUNCTIONS_COUNT="$(grep -Ri '[[:space:]]function[[:space:]]' ./ --include='*.php' --exclude-dir='tests' | wc -l | tr -d '[[:space:]]')"
		UNIT_TESTS_COUNT="$(grep -Ri 'function test' ./tests/custom_tests --include='*.php' | wc -l | tr -d '[[:space:]]')"
		FUNCTION_COVERAGE=$((UNIT_TESTS_COUNT*100/PHP_FUNCTIONS_COUNT))
		echo -ne "${CYAN}${PHP_FUNCTIONS_COUNT}/${UNIT_TESTS_COUNT}/${FUNCTION_COVERAGE}${NC}\n"
		if [[ $FUNCTION_COVERAGE -gt 80 ]]; then
			echo -ne "${GREEN}Code coverage score of ${FUNCTION_COVERAGE} is good.${NC}\n\n"
		elif [[ $FUNCTION_COVERAGE -gt 60 ]]; then
			echo -ne "${YELLOW}Code coverage score of ${FUNCTION_COVERAGE} needs improvement, consider additional unit test cases.${NC}\n\n"
		else
			echo -ne "${RED}Failure - Code coverage score of ${FUNCTION_COVERAGE} is too low, please add more unit tests.${NC}\n\n"
			RESULT=1
		fi
	}
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