Feature: Single client use cases
  Background:
    Given client c

  Scenario: UPTIME fetches uptime
    When c sends STATS UPTIME
    Then c gets /uptime: \d+ days, \d+h \d+m \d+s/

  Scenario: FULL fetches lots of stuff
    When c sends STATS FULL
    Then c gets /uptime: \d+ days, \d+h \d+m \d+s/
      And c gets /total processing time: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /average processing time: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /gained time: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /waiting time: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /waiting time for me: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /waiting time for anyone: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /waiting time for good: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /wasted timeout time: (((\d+ days )?\d+h )?\d+m )?\d+(\.\d+)?s/
      And c gets /total_acquired: \d+/
      And c gets /total_releases: \d+/
      And c gets /hashtable_entries: \d+/
      And c gets /processing_workers: \d+/
      And c gets /waiting_workers: \d+/
      And c gets /connect_errors: \d+/
      And c gets /failed_sends: \d+/
      And c gets /full_queues: \d+/
      And c gets /lock_mismatch: \d+/
      And c gets /lock_while_waiting: \d+/
      And c gets /release_mismatch: \d+/
      And c gets /processed_count: \d+/

  Scenario: waiting_workers is 0 because we aren't running concurrent tests
    When c sends STATS waiting_workers
    Then c gets waiting_workers: 0

  Scenario: hashtable_entries is 0 because we aren't running concurrent tests
    When c sends STATS hashtable_entries
    Then c gets hashtable_entries: 0
