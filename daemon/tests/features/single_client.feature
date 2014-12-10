Feature: Single client use cases
  Background:
    Given client c

  Scenario Outline: Can lock
    When c sends <lock_type> l 1 1 1
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Can lock and release
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
    Then c gets RELEASED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Can lock and release and relock
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Can lock and release and reloack and unlock
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
    Then c gets RELEASED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario: RELEASEing without holding any locks warns
    When c sends RELEASE
    Then c gets NOT_LOCKED

  Scenario Outline: locking while holding four locks warns
    When c sends <lock_type> l1 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l2 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l3 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l4 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l5 1 1 1
    Then c gets LOCK_HELD
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking with no timeout LOCKs
    When c sends <lock_type> l 1 1 0
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking with timeout left off LOCKs
    When c sends <lock_type> l 1 1
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking with garbage timeout LOCKs
    When c sends <lock_type> l 1 1 garbage
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: the same lock can be locked twice
    When c sends <lock_type> l 2 2 1
      And c gets LOCKED
      And c sends <lock_type> l 2 2 1
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking the same lock twice takes can TIMEOUT with non-zero timeout
    When c sends <lock_type> l 1 2 1
      And c gets LOCKED
      And c sends <lock_type> l 1 2 1
    Then c gets TIMEOUT
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking the same lock twice takes can TIMEOUT with zero timeout
    When c sends <lock_type> l 1 2 0
      And c gets LOCKED
      And c sends <lock_type> l 1 2 0
    Then c gets TIMEOUT
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking the same lock twice takes can QUEUE_FULL
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l 1 1 1
    Then c gets QUEUE_FULL
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: timing out doens't unlock locks already held
    When c sends <lock_type> l 1 2 1
      And c gets LOCKED
      And c sends <lock_type> l 1 2 0
      And c gets TIMEOUT
      And c sends <lock_type> l 1 2 0
    Then c gets TIMEOUT
    When c sends RELEASE
    Then c gets RELEASED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: timing out doesn't consume a connection's locks
    When c sends <lock_type> l 1 2 <timeout>
      And c gets LOCKED
      And c sends <lock_type> l 1 2 <timeout>
      And c gets TIMEOUT
      And c sends <lock_type> l 1 2 <timeout>
      And c gets TIMEOUT
      And c sends <lock_type> l 1 2 <timeout>
      And c gets TIMEOUT
      And c sends <lock_type> l 1 2 <timeout>
    Then c gets TIMEOUT
      And c sends <lock_type> l 1 2 <timeout>
      And c gets TIMEOUT
      And c sends <lock_type> l 1 2 <timeout>
      And c gets TIMEOUT
  Examples:
    | lock_type | timeout |
    | ACQ4ME    | 0       |
    | ACQ4ANY   | 0       |
    | ACQ4ME    | 1       |
    | ACQ4ANY   | 1       |

  Scenario Outline: running out of queue slots doesn't consume a connection's locks
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l 1 1 1
      And c gets QUEUE_FULL
      And c sends <lock_type> l 1 1 1
      And c gets QUEUE_FULL
      And c sends <lock_type> l 1 1 1
      And c gets QUEUE_FULL
      And c sends <lock_type> l 1 1 1
    Then c gets QUEUE_FULL
      And c sends <lock_type> l 1 1 1
      And c gets QUEUE_FULL
      And c sends <lock_type> l 1 1 1
      And c gets QUEUE_FULL
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: RELEASEing doesn't consume a connection's locks
    When c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
    Then c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
      And c sends <lock_type> l 1 1 1
      And c gets LOCKED
      And c sends RELEASE
      And c gets RELEASED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Disconnecting releases locks and you get reconnect and get them back
    When c sends <lock_type> l 1 10 1
      And c gets LOCKED
      And c is closed
      And c sends <lock_type> l 1 10 10
    Then c gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |
