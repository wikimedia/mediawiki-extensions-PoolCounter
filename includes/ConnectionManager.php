<?php

namespace MediaWiki\Extension\PoolCounter;

use MWException;
use Status;
use Wikimedia\AtEase\AtEase;

class ConnectionManager {
	/** @var string[] */
	public $hostNames;
	/** @var array */
	public $conns = [];
	/** @var array */
	public $refCounts = [];
	/** @var float */
	public $timeout;
	/** @var int */
	public $connect_timeout;

	/**
	 * @param array $conf
	 * @throws MWException
	 */
	public function __construct( $conf ) {
		$this->hostNames = $conf['servers'];
		$this->timeout = $conf['timeout'] ?? 0.1;
		$this->connect_timeout = $conf['connect_timeout'] ?? 0;
		if ( !count( $this->hostNames ) ) {
			throw new MWException( __METHOD__ . ': no servers configured' );
		}
	}

	/**
	 * @param string $key
	 * @return Status
	 */
	public function get( $key ) {
		$hashes = [];
		foreach ( $this->hostNames as $hostName ) {
			$hashes[$hostName] = md5( $hostName . $key );
		}
		asort( $hashes );
		$errno = 0;
		$errstr = '';
		$hostName = '';
		$conn = null;
		foreach ( $hashes as $hostName => $hash ) {
			if ( isset( $this->conns[$hostName] ) ) {
				$this->refCounts[$hostName]++;
				return Status::newGood(
					[ 'conn' => $this->conns[$hostName], 'hostName' => $hostName ] );
			}
			$parts = explode( ':', $hostName, 2 );
			if ( count( $parts ) < 2 ) {
				$parts[] = 7531;
			}
			AtEase::suppressWarnings();
			$conn = $this->open( $parts[0], $parts[1], $errno, $errstr );
			AtEase::restoreWarnings();
			if ( $conn ) {
				break;
			}
		}
		if ( !$conn ) {
			return Status::newFatal( 'poolcounter-connection-error', $errstr, $hostName );
		}
		wfDebug( "Connected to pool counter server: $hostName\n" );
		$this->conns[$hostName] = $conn;
		$this->refCounts[$hostName] = 1;
		return Status::newGood( [ 'conn' => $conn, 'hostName' => $hostName ] );
	}

	/**
	 * Open a socket. Just a wrapper for fsockopen()
	 * @param string $host
	 * @param int $port
	 * @param int &$errno
	 * @param string &$errstr
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
	 * @param resource $conn
	 */
	public function close( $conn ) {
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

class_alias( ConnectionManager::class, 'PoolCounter_ConnectionManager' );
