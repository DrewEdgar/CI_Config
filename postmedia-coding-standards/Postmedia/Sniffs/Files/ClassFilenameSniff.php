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
		return array( T_CLASS );
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
		$pathparts = pathinfo( $filename );
		$basename = $pathparts['filename'];

		$tokens = $phpcsFile->getTokens();

		// Determine the name of the class or interface. Note that we cannot
		// simply look for the first T_STRING because a class name
		// starting with the number will be multiple tokens.
		$opener		= $tokens[$stackPtr]['scope_opener'];
		$nameStart	= $phpcsFile->findNext(T_WHITESPACE, ($stackPtr + 1), $opener, true);
		$nameEnd	= $phpcsFile->findNext(T_WHITESPACE, $nameStart, $opener);
		$name		= trim($phpcsFile->getTokensAsString($nameStart, ($nameEnd - $nameStart)));

		if ( $name != $basename ) {
			$expected = $basename . 'php';
			$error = 'Class filename is not using Camel Caps';
			$phpcsFile->addError( $error, $stackPtr, 'ClassFilenameNotCamelCaps' );
		}

		return;

	} //end process()

} //end class
