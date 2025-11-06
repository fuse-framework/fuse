/**
 * LifecycleTestCase - Fixture for testing setup/teardown execution order
 *
 * Tracks execution order of setup, test, and teardown methods
 * to verify lifecycle hooks execute in correct sequence.
 */
component extends="fuse.testing.TestCase" {

	public function init() {
		super.init();
		variables.executionLog = [];
		return this;
	}

	public function setup() {
		arrayAppend(variables.executionLog, "setup");
	}

	public function teardown() {
		arrayAppend(variables.executionLog, "teardown");
	}

	public function testLifecycleOrder() {
		arrayAppend(variables.executionLog, "test");
	}

	// Helper methods for test verification

	public function resetLog() {
		variables.executionLog = [];
	}

	public function getLog() {
		return variables.executionLog;
	}

}
