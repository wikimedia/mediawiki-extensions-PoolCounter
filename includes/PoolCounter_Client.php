<?php

class PoolCounter_Client extends PoolCounter {
	/**
	 * @var ?resource the socket connection to the poolcounter.  Closing this
	 * releases all locks acquired.
	 */
	private $conn;

	/**
	 * @var string The server host name
	 */
	private $hostName;

	/**
	 * @var PoolCounter_ConnectionManager
	 */
	private static $manager;

	/**
	 * PoolCounter_Client constructor.
	 * @param array $conf
	 * @param string $type
	 * @param string $key
	 */
	public function __construct( $conf, $type, $key ) {
		parent::__construct( $conf, $type, $key );
		if ( !self::$manager ) {
			global $wgPoolCountClientConf;
			self::$manager = new PoolCounter_ConnectionManager( $wgPoolCountClientConf );
		}
	}

	/**
	 * @return Status
	 */
	public function getConn() {
		if ( !isset( $this->conn ) ) {
			$status = self::$manager->get( $this->key );
			if ( !$status->isOK() ) {
				return $status;
			}
			$this->conn = $status->value['conn'];
			$this->hostName = $status->value['hostName'];

			// Set the read timeout to be 1.5 times the pool timeout.
			// This allows the server to time out gracefully before we give up on it.
			stream_set_timeout( $this->conn, 0, (int)( $this->timeout * 1e6 * 1.5 ) );
		}
		return Status::newGood( $this->conn );
	}

	/**
	 * @param string|int|float ...$args
	 * @return Status
	 */
	public function sendCommand( ...$args ) {
		$args = str_replace( ' ', '%20', $args );
		$cmd = implode( ' ', $args );
		$status = $this->getConn();
		if ( !$status->isOK() ) {
			return $status;
		}
		$conn = $status->value;
		wfDebug( "Sending pool counter command: $cmd\n" );
		if ( fwrite( $conn, "$cmd\n" ) === false ) {
			return Status::newFatal( 'poolcounter-write-error', $this->hostName );
		}
		$response = fgets( $conn );
		if ( $response === false ) {
			return Status::newFatal( 'poolcounter-read-error', $this->hostName );
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
				$errorMsg = $parts[1] ?? '(no message given)';
				return Status::newFatal( 'poolcounter-remote-error', $errorMsg, $this->hostName );
		}
		return Status::newGood( constant( "PoolCounter::$responseType" ) );
	}

	/**
	 * @return Status
	 */
	public function acquireForMe() {
		$status = $this->precheckAcquire();
		if ( !$status->isGood() ) {
			return $status;
		}
		return $this->sendCommand( 'ACQ4ME', $this->key, $this->workers, $this->maxqueue,
			$this->timeout );
	}

	/**
	 * @return Status
	 */
	public function acquireForAnyone() {
		$status = $this->precheckAcquire();
		if ( !$status->isGood() ) {
			return $status;
		}
		return $this->sendCommand( 'ACQ4ANY', $this->key, $this->workers, $this->maxqueue,
			$this->timeout );
	}

	/**
	 * @return Status
	 */
	public function release() {
		$status = $this->sendCommand( 'RELEASE', $this->key );

		if ( $this->conn ) {
			self::$manager->close( $this->conn );
			$this->conn = null;
		}

		return $status;
	}
}
