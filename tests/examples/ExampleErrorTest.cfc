/**
 * ExampleErrorTest - Example test demonstrating intentional error
 *
 * Demonstrates:
 * - Unexpected exception handling (error vs failure)
 * - Error output includes exception message and stack trace
 * - Runner distinguishes errors from assertion failures
 */
component extends="fuse.testing.TestCase" {

	/**
	 * This test will PASS to show contrast
	 */
	public void function testBasicMath() {
		assertEqual(4, 2 + 2);
	}

	/**
	 * This test will ERROR with division by zero
	 * Demonstrates unexpected exception handling
	 */
	public void function testDivisionError() {
		var numerator = 10;
		var denominator = 0;
		var result = numerator / denominator;  // Division by zero
		assertEqual(0, result);
	}

	/**
	 * This test will ERROR with undefined variable
	 * Shows different type of unexpected error
	 */
	public void function testUndefinedVariableError() {
		assertEqual("test", variables.nonExistentVariable);
	}

	/**
	 * This test will PASS to show runner continues after error
	 */
	public void function testContinuesAfterError() {
		assertTrue(true);
	}

}
