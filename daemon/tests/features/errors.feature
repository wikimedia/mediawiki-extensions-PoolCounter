Feature: Bad commands result in error
  Background:
    Given client c

  Scenario: Bad commands result in error
    When c sends GARBAGE
    Then c gets ERROR BAD_COMMAND

  Scenario Outline: locking with just lock name results in error
    When c sends <lock_type> l
    Then c gets ERROR BAD_SYNTAX
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: locking with no workers results in error
    When c sends <lock_type> l 0 1 1
    Then c gets ERROR BAD_SYNTAX
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Locking with no queue results in error
    When c sends <lock_type> l 1 0 1
    Then c gets ERROR BAD_SYNTAX
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Locking with non integer workers results in error
    When c sends <lock_type> l GARBAGE 1 1
    Then c gets ERROR BAD_SYNTAX
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |

  Scenario Outline: Locking while waiting is an error
    Given client other_c
    When other_c sends <lock_type> l 1 10 10
      And other_c gets LOCKED
      And c sends <lock_type> l 1 10 10
      And c sends <lock_type> l 1 10 10
    Then c gets ERROR WAIT_FOR_RESPONSE
  Examples:
    | lock_type |
    | ACQ4ME    |
    | ACQ4ANY   |
