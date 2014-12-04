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

  Scenario Outline: locking while holding a lock warns
    When c sends <lock_type> l1 1 1 1
      And c gets LOCKED
      And c sends <lock_type> l2 1 1 1
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
