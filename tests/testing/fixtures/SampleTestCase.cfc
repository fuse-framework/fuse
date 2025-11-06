/**
 * SampleTestCase - Fixture for testing test method discovery
 *
 * Provides sample test methods and non-test methods to verify
 * TestCase.getTestMethods() correctly filters methods.
 */
component extends="fuse.testing.TestCase" {

	public function init() {
		super.init();
		return this;
	}

	// TEST METHODS (should be discovered)

	public function testExample() {
		// Sample test method
	}

	public function testAnother() {
		// Another sample test method
	}

	public function testThirdExample() {
		// Third sample test method
	}

	// NON-TEST METHODS (should NOT be discovered)

	public function setup() {
		// Lifecycle hook - not a test
	}

	public function teardown() {
		// Lifecycle hook - not a test
	}

	public function helperMethod() {
		// Helper method - not a test
	}

	private function privateMethod() {
		// Private method - not a test
	}

}
