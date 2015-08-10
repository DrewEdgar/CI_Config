V 0.0.5 Aug 6, 2015
============================
* Updated Codesniffer rules to no longer exclude XSS Checks
* Updated Wordpress version for testing from 4.2.2 to 4.2.4

V 0.0.4 June 3, 2015
============================
* Updated Wordpress version for testing from 4.1.1 to 4.2.2
* Added WordPress-Docs to exclusion list.
* Removed Taxonomy tests as they are broken in 4.2.2  (again....)

V 0.0.3 March 26, 2015
============================
* Added config file for eslint (.eslintrc)
* Added config file for csslint (.csslintrc)
* Base eslint config sets the environment to be used so that globals are available as required.
* Base csslint sets an unrealistic error and warning setting such that the code is only likly to trigger a note if there is a syntax error
* Created package.json to control the versions of modules installed for testing (specifically cssling and eslint)

V 0.0.2 March 11, 2015
============================
* Modified changelog format in HISTORY.md
* Added the wordpress_latest.sh to represent centralized value for latest (starting with 4.1.1)
* Remove WordPress.Variables.GlobalVariables checks for smartphone team

V 0.0.1 March 9, 2015
============================
* Initial repo synced up
* Includes the exclusion of taxonomy tests due to current WP test failures