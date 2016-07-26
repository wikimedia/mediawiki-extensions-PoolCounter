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

class PoolCounter_Client extends PoolCounter {
	/**
	 * @var resource the socket connection to the poolcounter.  Closing this
	 * releases all locks acquired.
	 */
	private $conn;

	/**
	 * @var PoolCounter_ConnectionManager
	 */
	static private $manager;

	/**
	 * PoolCounter_Client constructor.
	 * @param array $conf
	 * @param string $type
	 * @param string $key
	 */
	function __construct( $conf, $type, $key ) {
		parent::__construct( $conf, $type, $key );
		if ( !self::$manager ) {
			global $wgPoolCountClientConf;
			self::$manager = new PoolCounter_ConnectionManager( $wgPoolCountClientConf );
		}
	}

	/**
	 * @return Status
	 */
	function getConn() {
		if ( !isset( $this->conn ) ) {
			$status = self::$manager->get( $this->key );
			if ( !$status->isOK() ) {
				return $status;
			}
			$this->conn = $status->value;

			// Set the read timeout to be 1.5 times the pool timeout.
			// This allows the server to time out gracefully before we give up on it.
			stream_set_timeout( $this->conn, 0, $this->timeout * 1e6 * 1.5 );
		}
		return Status::newGood( $this->conn );
	}

	/**
	 * @return Status
	 */
	function sendCommand( /*, ...*/ ) {
		$args = func_get_args();
		$args = str_replace( ' ', '%20', $args );
		$cmd = implode( ' ', $args );
		$status = $this->getConn();
		if ( !$status->isOK() ) {
			return $status;
		}
		$conn = $status->value;
		wfDebug( "Sending pool counter command: $cmd\n" );
		if ( fwrite( $conn, "$cmd\n" ) === false ) {
			return Status::newFatal( 'poolcounter-write-error' );
		}
		$response = fgets( $conn );
		if ( $response === false ) {
			return Status::newFatal( 'poolcounter-read-error' );
		}
		$response = rtrim( $response, "\r\n" );
		wfDebug( "Got pool counter response: $response\n" );
		$parts = explode( ' ', $response, 2 );
		$responseType = $parts[0];
		switch ( $responseType ) {
			case 'LOCKED':
				$this->onAcquire();
				break;
			case 'RELEASED':
				$this->onRelease();
				break;
			case 'DONE':
			case 'NOT_LOCKED':
			case 'QUEUE_FULL':
			case 'TIMEOUT':
			case 'LOCK_HELD':
				break;
			case 'ERROR':
			default:
				$parts = explode( ' ', $parts[1], 2 );
				$errorMsg = isset( $parts[1] ) ? $parts[1] : '(no message given)';
				return Status::newFatal( 'poolcounter-remote-error', $errorMsg );
		}
		return Status::newGood( constant( "PoolCounter::$responseType" ) );
	}

	/**
	 * @return Status
	 */
	function acquireForMe() {
		$status = $this->precheckAcquire();
		if ( !$status->isGood() ) {
			return $status;
		}
		return $this->sendCommand( 'ACQ4ME', $this->key, $this->workers, $this->maxqueue, $this->timeout );
	}

	/**
	 * @return Status
	 */
	function acquireForAnyone() {
		$status = $this->precheckAcquire();
		if ( !$status->isGood() ) {
			return $status;
		}
		return $this->sendCommand( 'ACQ4ANY', $this->key, $this->workers, $this->maxqueue, $this->timeout );
	}

	/**
	 * @return Status
	 */
	function release() {
		$status = $this->sendCommand( 'RELEASE', $this->key );

		if ( $this->conn ) {
			self::$manager->close( $this->conn );
			$this->conn = null;
		}

		return $status;
	}
}
