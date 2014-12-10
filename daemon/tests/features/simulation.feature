Feature: Simulation use cases
  Scenario: Just readers
    When I start 1024 reader like sims
      And wait 10 seconds
    Then all sims report success

  Scenario: Just search without per user locks
    When I start 1024 search like sims without per user locks
      And wait 10 seconds
    Then all sims report success

  Scenario: Just search with per user locks
    When I start 1024 search like sims
      And wait 10 seconds
    Then all sims report success

  Scenario: Search and readers
    When I start 124 search like sims
      And I start 900 reader like sims
      And wait 10 seconds
    Then all sims report success
