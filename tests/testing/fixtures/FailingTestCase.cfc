/**
 * FailingTestCase - Fixture with intentional assertion failures
 *
 * Used to test TestRunner handles assertion failures correctly.
 */
component extends="fuse.testing.TestCase" {

	public function init() {
		super.init();
		return this;
	}

	public function testFailure() {
		// Intentionally fails
		assertEqual(5, 10, "Expected failure");
	}

}
