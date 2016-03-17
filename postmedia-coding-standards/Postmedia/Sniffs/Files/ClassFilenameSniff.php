<?php

/**
 * Postmedia Coding Standard
 *
 * PHP version 5
 *
 * @category	PHP
 * @package		PHP_CodeSniffer
 * @author		Keith Benedict
 * @link		https://github.com/Postmedia-Digital/CI_Config/tree/master/postmedia-coding-standards/Postmedia
 */

/**
 * Postmedia_Sniffs_Files_ClassFileNameSniff.
 *
 * Ensures filenames do not contain underscores
 *
 * @category	PHP
 * @package		PHP_CodeSniffer
 * @author		Keith Benedict
 */
class Postmedia_Sniffs_Files_ClassFileNameSniff implements PHP_CodeSniffer_Sniff
{

	 /**
	 * Returns an array of tokens this test wants to listen for.
	 *
	 * @return array
	 */
	public function register() {
		return array( T_OPEN_TAG );
	} //end register()


	/**
	 * Processes this test, when one of its tokens is encountered.
	 *
	 * @param PHP_CodeSniffer_File	$phpcsFile	The file being scanned.
	 * @param int					$stackPtr	The position of the current token in the
	 *											stack passed in $tokens.
	 *
	 * @return int
	 */
	public function process(PHP_CodeSniffer_File $phpcsFile, $stackPtr)
	{

		$filename = $phpcsFile->getFileName();
		$basename = basename( $filename );
		$pathparts = pathinfo( $filename );
		$classname = ucwords( $pathparts['filename'] );

		if( exec( 'grep ' . escapeshellarg( '^class[[:space:]]' ) . ' ' . $filename ) ) {
			// this is a class, the filename needs to match, lets test that it does
			if( exec( 'grep ' . escapeshellarg( 'class ' . $classname . '[[:space:]]' ) . ' ' . $filename ) && $classname == $basename ) {
				// this is a class, the filename needs to match, since it does were okay
				return;
			}
			else {
				$expected	= $classname . '.php';
				$filename	= basename( $filename );
				$error		= 'Filename "' . $filename . '" found for class file; use ' . $expected . ' instead';
				$phpcsFile->addError($error, $stackPtr, 'ClassFilesUseCamelCaps');
			}
		}

		return $phpcsFile->numTokens + 1;

	} //end process()

} //end class
