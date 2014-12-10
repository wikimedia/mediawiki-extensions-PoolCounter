Feature: Two client use cases
  Background:
    Given client c1
      And client c2

  Scenario Outline: Both lock if there are enough workers and enough queue space
    When c1 sends <lock_type> l 2 2 1
      And c1 gets LOCKED
      And c2 sends <lock_type> l 2 2 1
    Then c2 gets LOCKED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Only one can lock if there are enough workers but not enough queue space
    When c1 sends <lock_type> l 2 1 1
      And c1 gets LOCKED
      And c2 sends <lock_type> l 2 1 1
    Then c2 gets QUEUE_FULL
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Only one can lock if there aren't workers and not enough queue space
    When c1 sends <lock_type> l 1 1 1
      And c1 gets LOCKED
      And c2 sends <lock_type> l 1 1 1
    Then c2 gets QUEUE_FULL
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario: Closing a socket releases the lock
    When c1 sends ACQ4ANY l 2 1 1
      And c1 gets LOCKED
      And c1 is closed
      And c2 sends ACQ4ANY l 2 1 1
    Then c2 gets LOCKED

  Scenario: Second client TIMEOUTs if first never unlocks and timeout > 0
    When c1 sends ACQ4ME l 1 2 1
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 2 1
    Then c2 gets TIMEOUT

  Scenario: Second client TIMEOUTs if first never unlocks and timeout == 0
    When c1 sends ACQ4ME l 1 2 0
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 2 0
    Then c2 gets TIMEOUT

  Scenario: Second client TIMEOUTs if first never unlocks but can get lock after first finishes
    When c1 sends ACQ4ME l 1 2 1
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 2 1
      And c2 gets TIMEOUT
      And c2 sends ACQ4ME l 1 2 1
      And c2 gets TIMEOUT
      And c1 sends RELEASE
      And c2 sends ACQ4ME l 1 2 1
    Then c2 gets LOCKED

  Scenario: Second client TIMEOUTs if first never unlocks but can get lock after first finishes and timeout == 0
    When c1 sends ACQ4ME l 1 2 0
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 2 0
      And c2 gets TIMEOUT
      And c2 sends ACQ4ME l 1 2 0
      And c2 gets TIMEOUT
      And c1 sends RELEASE
      And c2 sends ACQ4ME l 1 2 0
    Then c2 gets LOCKED

  Scenario: Second client's ACQ4ME LOCKs if first unlocks
    When c1 sends ACQ4ME l 1 2 5
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 2 5
      And c1 sends RELEASE
    Then c2 gets LOCKED

  Scenario: Second client's ACQ4ANY DONEs if first unlocks
    When c1 sends ACQ4ME l 1 2 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 2 5
      And c1 sends RELEASE
    Then c2 gets DONE

  Scenario: DONE doesn't require unlock
    When c1 sends ACQ4ME l 1 2 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 2 5
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets DONE
      And c1 sends ACQ4ME l 1 2 5
    Then c1 gets LOCKED

  Scenario: DONE doesn't consume a lock
    When c1 sends ACQ4ME l 1 5 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 5 5
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets DONE
      And c1 sends ACQ4ME l 1 5 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 5 5
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets DONE
      And c1 sends ACQ4ME l 1 5 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 5 5
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets DONE
      And c1 sends ACQ4ME l 1 5 5
      And c1 gets LOCKED
      And c2 sends ACQ4ANY l 1 5 5
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets DONE
      And c2 sends ACQ4ME l 1 2 5
    Then c2 gets LOCKED

  Scenario Outline: locking the same lock twice takes multiple executors
    When c1 sends <lock_type> l 2 2 0
      And c1 gets LOCKED
      And c1 sends <lock_type> l 2 2 0
      And c1 gets LOCKED
      And c2 sends <lock_type> l 2 2 0
    Then c2 gets QUEUE_FULL
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Disconnecting while waiting for a timeout is ok
    When c1 sends <lock_type> l 1 10 1
      And c1 gets LOCKED
      And c2 sends <lock_type> l 1 10 10
      And c2 is closed
      And c1 sends RELEASE
    Then c1 gets RELEASED
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario: Do not get timeout after locking after initial delay
    When c1 sends ACQ4ME l 1 10 1
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 10 3
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets LOCKED
    Then c2 gets no response

  Scenario: Do not get early timeout after initial delay
    The "gets not response" here is within 5 seconds, meaning the timeout doesn't come early
    When c1 sends ACQ4ME l 1 10 1
      And c1 gets LOCKED
      And c2 sends ACQ4ME l 1 10 3
      And c1 sends RELEASE
      And c1 gets RELEASED
      And c2 gets LOCKED
      And c2 sends ACQ4ME l 1 10 10
    Then c2 gets no response




