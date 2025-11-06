/**
 * Valid test fixture that extends TestCase
 */
component extends="fuse.testing.TestCase" {

	public function testExample() {
		assertTrue(true);
	}

	public function testAnotherExample() {
		assertEqual(1, 1);
	}

	// Non-test method should be ignored
	public function helperMethod() {
		return "helper";
	}

}
