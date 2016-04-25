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
 * Postmedia_Sniffs_Files_TraitFileNameSniff.
 *
 * Ensures filenames do not contain underscores
 *
 * @category	PHP
 * @package		PHP_CodeSniffer
 * @author		Keith Benedict
 */
class Postmedia_Sniffs_Files_TraitFileNameSniff implements PHP_CodeSniffer_Sniff
{

	 /**
	 * Returns an array of tokens this test wants to listen for.
	 *
	 * @return array
	 */
	public function register() {
		return array( T_TRAIT );
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
		$needles = array( '_', '-' );

		$tokens = $phpcsFile->getTokens();

		// Determine the name of the trait. Note that we cannot
		// simply look for the first T_STRING because a class name
		// starting with the number will be multiple tokens.
		$opener		= $tokens[$stackPtr]['scope_opener'];
		$nameStart	= $phpcsFile->findNext( T_WHITESPACE, ( $stackPtr + 1 ), $opener, true );
		$nameEnd	= $phpcsFile->findNext( T_WHITESPACE, $nameStart, $opener );
		$name		= trim($phpcsFile->getTokensAsString( $nameStart, ($nameEnd - $nameStart) ) );

		// Check for more than one trait per file.
		exec( 'grep -Ri ' . escapeshellarg( '^trait[[:space:]]' ) . ' ' . $filename . ' | wc -l | tr -d ' .escapeshellarg( '[[:space:]]' ), $output );
		if ( 2 <= (int) $output[0] ) {
			$error = '2 or more traites defined in file, expected 1';
			$phpcsFile->addError( $error, $stackPtr, 'TooManyTraites' );
			return;
		}

		if ( $name != $basename ) {
			$expected = $name;
			$error = 'Trait filename "' . $pathparts['basename'] . '" does not match trait name "'. $name . '", check the trait name and filename are both in CamelCaps';
			$phpcsFile->addError( $error, $stackPtr, 'TraitFilenameMustMatchTrait' );
			return;
		}

		$valid = PHP_CodeSniffer::isCamelCaps( $basename, true, true, false );
		if ( ! $valid ) {
			$expected = ucfirst( str_replace( $needles, '', $basename ) . '.php' );
			$error = 'Trait filename "'. $pathparts['basename'] . '" is not in Camel Caps, expected at least "' . $expected . '", check trait name to confirm';
			$phpcsFile->addError( $error, $stackPtr, 'TraitFilenameNotCamelCaps' );
		}

		return;

	} //end process()

} //end class
