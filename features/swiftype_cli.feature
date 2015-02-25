Feature: Generating Swiftype manifest files
  Scenario: Generating search.json for Swiftype with the CLI
    Given a fixture app "swiftype-app"
    And I run `middleman swiftype --only-generate`
    Then the exit status should be 0
    And the following files should exist:
      | build/search.json |
