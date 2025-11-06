/**
 * PassingTestCase - Fixture with passing tests
 *
 * Used to test TestRunner handles successful test execution.
 */
component extends="fuse.testing.TestCase" {

	public function init() {
		super.init();
		return this;
	}

	public function testPass1() {
		assertTrue(true);
	}

	public function testPass2() {
		assertEqual(5, 5);
	}

}
