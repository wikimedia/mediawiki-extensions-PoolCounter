<?php

/**
 * MediaWiki client for the pool counter daemon poolcounter.py.
 */

if ( function_exists( 'wfLoadExtension' ) ) {
	wfLoadExtension( 'PoolCounter' );
	$wgMessagesDirs['PoolCounterClient'] = __DIR__ . '/i18n';
} else {
	die( 'This version of the Pool Counter extension requires MediaWiki 1.25+' );
}