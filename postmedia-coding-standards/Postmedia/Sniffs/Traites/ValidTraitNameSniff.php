<?php
/**
 * Modified WordPress_Sniffs_Classes_ValidClassNameSniff which is a modified Squiz_Sniffs_Classes_ValidClassNameSniff.
 *
 * PHP version 5
 *
 * @category  PHP
 * @package   PHP_CodeSniffer
 * @author    Greg Sherwood <gsherwood@squiz.net>
 * @author    Marc McIntyre <mmcintyre@squiz.net>
 * @copyright 2006 Squiz Pty Ltd (ABN 77 084 670 600)
 * @license   http://matrix.squiz.net/developer/tools/php_cs/licence BSD Licence
 * @version   CVS: $Id: ValidClassNameSniff.php,v 1.6 2008/05/19 05:59:25 squiz Exp $
 * @link      http://pear.php.net/package/PHP_CodeSniffer
 */

class Postmedia_Sniffs_Traites_ValidTraitNameSniff implements PHP_CodeSniffer_Sniff
{


    /**
     * Returns an array of tokens this test wants to listen for.
     *
     * @return array
     */
    public function register()
    {
        return array(
                T_TRAIT,
               );

    }//end register()


    /**
     * Processes this test, when one of its tokens is encountered.
     *
     * @param PHP_CodeSniffer_File $phpcsFile The current file being processed.
     * @param int                  $stackPtr  The position of the current token in the
     *                                        stack passed in $tokens.
     *
     * @return void
     */
    public function process(PHP_CodeSniffer_File $phpcsFile, $stackPtr)
    {
        $tokens = $phpcsFile->getTokens();

        if (isset($tokens[$stackPtr]['scope_opener']) === false) {
            $error  = 'Possible parse error: ';
            $error .= $tokens[$stackPtr]['content'];
            $error .= ' missing opening or closing brace';
            $phpcsFile->addWarning($error, $stackPtr, 'MissingBrace');
            return;
        }

        // Determine the name of the trait. Note that we cannot
        // simply look for the first T_STRING because a trait name
        // starting with the number will be multiple tokens.
        $opener    = $tokens[$stackPtr]['scope_opener'];
        $nameStart = $phpcsFile->findNext(T_WHITESPACE, ($stackPtr + 1), $opener, true);
        $nameEnd   = $phpcsFile->findNext(T_WHITESPACE, $nameStart, $opener);
        $name      = trim($phpcsFile->getTokensAsString($nameStart, ($nameEnd - $nameStart)));

        // Check for camel caps format.
        $valid = PHP_CodeSniffer::isCamelCaps( $name, true, true, false );
        if ($valid === false) {
            $type  = ucfirst($tokens[$stackPtr]['content']);
            $error = "$type name \"$name\" is not in camel caps format";
            $phpcsFile->addError($error, $stackPtr, 'NotCamelCaps');
        }

    }//end process()


}//end class

?>
