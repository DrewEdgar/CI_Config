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

# Load exceptions file and set exceptions flags (Bad idea....but not ours)
# If not on travis, we will need a way to get the variable from the ci-check 
# tool which is basically a manual tool anyway
EXCEPTIONS=()
IGNORE_UNITTEST=false
IGNORE_COVERAGE=false
IGNORE_LINTS=false
IGNORE_STANDARDS=false
IGNORE_OVERRIDES=false

# Read the file in parameter and fill the array named "array"
getArray() {
    while IFS= read -r line # Read a line
    do
        EXCEPTIONS+=("$line") # Append line to the array
    done < "$1"
}

# Note if this file isnt found, it fails closed, aka we ignore no tests because the flags on change if we can 
# find the match in the file.
getArray "/tmp/ci_config/exceptions_to_the_rules.txt"
for e in "${EXCEPTIONS[@]}"
do
    if [[ "$e" != *#* ]]
    then
        if [[ "$e" == *$EXAMPLE_ENV_REPO_SLUG ]]
        then
            case "$e" in
                ("unittest:${TRAVIS_REPO_SLUG}") IGNORE_UNITTEST=true ;;
                ("coverage:${TRAVIS_REPO_SLUG}") IGNORE_COVERAGE=true ;;
                ("lints:${TRAVIS_REPO_SLUG}") IGNORE_LINTS=true ;;
                ("standards:${TRAVIS_REPO_SLUG}") IGNORE_STANDARDS=true ;;
                ("overrides:${TRAVIS_REPO_SLUG}") IGNORE_OVERRIDES=true ;;
            esac
        fi
    fi
done



# PHPUNIT Testing
{
	# What if we made these calls seperate.....
	# phpunit test cases
	if [[ $IGNORE_UNITTEST == "false" ]]
	then
		echo -ne "${GREEN} Running PHPUnit Tests.....${NC}\n\n"
		/usr/local/bin/phpunit -c tests/phpunit.xml --disallow-test-output --log-junit tests/results.xml

		PHPUNIT_OUT=$?
		if [[ $PHPUNIT_OUT == 0 ]]; then
			echo -ne "${GREEN}The command \"phpunit -c tests/phpunit.xml\" exited with ${PHPUNIT_OUT}.${NC}\n\n"
		else
			echo -ne "${RED}The command \"phpunit -c tests/phpunit.xml\" exited with ${PHPUNIT_OUT}.${NC}\n\n"
			RESULT=1
		fi
	else
		echo -ne "${RED}PHPUnit Testing is off!${NC}\n\n"
	fi
}


# PHP syntax error checks
{
	# We never ignore syntax error checks!
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
	if [[ $IGNORE_STANDARDS == "false" ]]
	then
		echo -ne "${GREEN}Checking WordPress coding standards.....${NC}\n\n"
		$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php
		PHPCS_OUT=$?
		if [[ $PHPCS_OUT == 0 ]]; then
			echo -ne "${GREEN}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
		else
			echo -ne "${RED}The command \"$INSTALL_PATH/php-codesniffer/scripts/phpcs -p -s -v -n ./ --standard=./tests/codesniffer.ruleset.xml --extensions=php\" exited with ${PHPCS_OUT}.${NC}\n\n"
			RESULT=1
		fi
	else
		echo -ne "${RED}Checking WordPress coding standards off!${NC}\n\n"
	fi
}

if [[ $IGNORE_LINTS == "false" ]]
then
	echo -ne "${GREEN}JS/CSS Lint checking...${NC}\n\n"
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
		"$(npm bin)"/csslint --format=compact --quiet ./
		CSSLINT_OUT=$?
		if [[ $CSSLINT_OUT == 0 ]]; then
			echo -ne "${GREEN}The command \"$(npm bin)/csslint --format=compact --quiet ./\" exited with ${CSSLINT_OUT}.${NC}\n\n"
		else
			echo -ne "${RED}The command \"$(npm bin)/csslint --format=compact --quiet ./\" exited with ${CSSLINT_OUT}.${NC}\n\n"
			RESULT=1
		fi
	}
else
	echo -ne "${RED}JS/CSS Lint checking off!${NC}\n\n"
fi

# @codingStandardsIgnoreLine checks
# We can not have standards ignored, since devs could put these anywhere we need to grep and count, this will check, more than 5 = failure
{
	if [[ $IGNORE_OVERRIDES == "false" ]]
	then
		echo -ne "${GREEN}Checking for overrides....${NC}\n\n"
		GREP_ALL="$(grep -Ri '@codingStandardsIgnoreLine' ./* | wc -l | tr -d '[[:space:]]')"
		GREP_TEST="$(grep -Ri '@codingStandardsIgnoreLine' ./* | wc -l | tr -d '[[:space:]]')"
		IGNORED_STANDARDS=$((GREP_ALL-GREP_TEST))
		if [[ $IGNORED_STANDARDS -eq 0 ]]; then
			echo -ne "${GREEN}Check for coding standards ignore passed.${NC}\n\n"
		elif [[ $IGNORED_STANDARDS -lt 6 ]]; then
			echo -ne "${YELLOW}Several lines (${IGNORED_STANDARDS}) are ignoring coding standards.${NC}\n\n"
		else
			echo -ne "${RED}Failure - Too many coding standards ignored (${IGNORED_STANDARDS}), code must be inspected for @codingStandardsIgnoreLine comments and manually given a pass by Integration.${NC}\n\n"
			RESULT=1
		fi
	else
		echo -ne "${RED}Checking for overrides off!${NC}\n\n"
	fi
}

exit $RESULT
