Feature: Pushing content to Swiftype
	Scenario: Executing with the CLI
		Given a fixture app "swiftype-app"
    And Swiftype expects to receive new search records
	  And I run `middleman swiftype`
	  Then the exit status should be 0
