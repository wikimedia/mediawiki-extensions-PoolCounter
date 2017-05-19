<?php

class PoolCounter_ConnectionManager {
	public $hostNames;
	public $conns = [];
	public $refCounts = [];

	/**
	 * @param array $conf
	 * @throws MWException
	 */
	function __construct( $conf ) {
		$this->hostNames = $conf['servers'];
		$this->timeout = isset( $conf['timeout'] ) ? $conf['timeout'] : 0.1;
		$this->connect_timeout = isset( $conf['connect_timeout'] ) ?
			$conf['connect_timeout'] : 0;
		if ( !count( $this->hostNames ) ) {
			throw new MWException( __METHOD__ . ': no servers configured' );
		}
	}

	/**
	 * @param $key
	 * @return Status
	 */
	function get( $key ) {
		$hashes = [];
		foreach ( $this->hostNames as $hostName ) {
			$hashes[$hostName] = md5( $hostName . $key );
		}
		asort( $hashes );
		$errno = $errstr = '';
		$conn = null;
		foreach ( $hashes as $hostName => $hash ) {
			if ( isset( $this->conns[$hostName] ) ) {
				$this->refCounts[$hostName]++;
				return Status::newGood( $this->conns[$hostName] );
			}
			$parts = explode( ':', $hostName, 2 );
			if ( count( $parts ) < 2 ) {
				$parts[] = 7531;
			}
			MediaWiki\suppressWarnings();
			$conn = $this->open( $parts[0], $parts[1], $errno, $errstr );
			MediaWiki\restoreWarnings();
			if ( $conn ) {
				break;
			}
		}
		if ( !$conn ) {
			return Status::newFatal( 'poolcounter-connection-error', $errstr );
		}
		wfDebug( "Connected to pool counter server: $hostName\n" );
		$this->conns[$hostName] = $conn;
		$this->refCounts[$hostName] = 1;
		return Status::newGood( $conn );
	}

	/**
	 * Open a socket. Just a wrapper for fsockopen()
	 * @param string $host
	 * @param int $port
	 * @param $errno
	 * @param $errstr
	 * @return null|resource
	 */
	private function open( $host, $port, &$errno, &$errstr ) {
		// If connect_timeout is set, we try to open the socket twice.
		// You usually want to set the connection timeout to a very
		// small value so that in case of failure of a server the
		// connection to poolcounter is not a SPOF.
		if ( $this->connect_timeout > 0 ) {
			$tries = 2;
			$timeout = $this->connect_timeout;
		} else {
			$tries = 1;
			$timeout = $this->timeout;
		}

		$fp = null;
		while ( true ) {
			$fp = fsockopen( $host, $port, $errno, $errstr, $timeout );
			if ( $fp !== false || --$tries < 1 ) {
				break;
			}
			usleep( 1000 );
		}

		return $fp;
	}

	/**
	 * @param $conn
	 */
	function close( $conn ) {
		foreach ( $this->conns as $hostName => $otherConn ) {
			if ( $conn === $otherConn ) {
				if ( $this->refCounts[$hostName] ) {
					$this->refCounts[$hostName]--;
				}
				if ( !$this->refCounts[$hostName] ) {
					fclose( $conn );
					unset( $this->conns[$hostName] );
				}
			}
		}
	}
}