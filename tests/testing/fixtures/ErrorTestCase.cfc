/**
 * ErrorTestCase - Fixture with intentional runtime errors
 *
 * Used to test TestRunner handles unexpected exceptions correctly.
 */
component extends="fuse.testing.TestCase" {

	public function init() {
		super.init();
		return this;
	}

	public function testError() {
		// Intentionally throws runtime exception
		var result = 10 / 0;
	}

}
