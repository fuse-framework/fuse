/**
 * ExampleValidationTest - Example test demonstrating intentional failure
 *
 * Demonstrates:
 * - Assertion failure behavior
 * - Expected vs actual output in failure message
 * - Test continues to run other methods after failure
 */
component extends="fuse.testing.TestCase" {

	/**
	 * This test will PASS to show contrast
	 */
	public void function testValidEmail() {
		var email = "valid@example.com";
		assertTrue(find("@", email) > 0, "Email should contain @");
	}

	/**
	 * This test will FAIL intentionally
	 * Demonstrates assertion failure output
	 */
	public void function testInvalidEmailFails() {
		var invalidEmail = "not-an-email";
		assertTrue(find("@", invalidEmail) > 0, "Expected email to contain @ symbol");
	}

	/**
	 * This test will PASS to show runner continues after failure
	 */
	public void function testAnotherValidation() {
		assertEqual(4, len("test"));
	}

	/**
	 * This test will FAIL with equality assertion
	 * Shows expected vs actual in failure output
	 */
	public void function testEqualityFailure() {
		var expected = 10;
		var actual = 5;
		assertEqual(expected, actual, "Values should match");
	}

}
