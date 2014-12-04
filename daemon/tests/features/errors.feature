Feature: Bad commands result in error
  Background:
    Given client c

  Scenario: Bad commands result in error
    When c sends GARBAGE
    Then c gets ERROR BAD_COMMAND

  Scenario: ACQ4MEing with just lock name results in error
    When c sends ACQ4ME l
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4MEing with no workers results in error
    When c sends ACQ4ME l 0 1 1
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4MEing with no queue results in error
    When c sends ACQ4ME l 1 0 1
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4MEing with non integer workers results in error
    When c sends ACQ4ME l GARBAGE 1 1
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4ANYing with just lock name results in error
    When c sends ACQ4ANY l
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4ANYing with no workers results in error
    When c sends ACQ4ANY l 0 1 1
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4ANYing with no queue results in error
    When c sends ACQ4ANY l 1 0 1
    Then c gets ERROR BAD_SYNTAX

  Scenario: ACQ4ANYing with non integer workers results in error
    When c sends ACQ4ANY l GARBAGE 1 1
    Then c gets ERROR BAD_SYNTAX
