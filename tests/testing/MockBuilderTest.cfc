/**
 * MockBuilderTest - Tests for lightweight mock system
 *
 * Tests mock creation, stub configuration, call verification, and error handling.
 */
component extends="fuse.testing.TestCase" {

	public function testMockCreatesProxyWithCallTracking() {
		// Create a simple component to mock
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Verify mock was created
		assertNotNull(mockComponent);

		// Verify mock has call tracking structure
		assertTrue(structKeyExists(mockComponent, "getCallHistory"));
		assertTrue(structKeyExists(mockComponent, "getStubs"));
	}

	public function testStubConfiguresMethodReturnValue() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub a method to return static value
		mockBuilder.stub(mockComponent, "getName", "Stubbed Name");

		// Call stubbed method
		var result = mockComponent.getName();

		// Verify stubbed value returned
		assertEqual("Stubbed Name", result);
	}

	public function testVerifyAssertsExactCallCount() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub method
		mockBuilder.stub(mockComponent, "save", true);

		// Call method twice
		mockComponent.save();
		mockComponent.save();

		// Verify exact call count
		mockBuilder.verify(mockComponent, "save", 2);
	}

	public function testUnstubbedMethodsThrowDescriptiveError() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Try to call unstubbed method
		assertThrows(function() {
			mockComponent.getName();
		}, "MethodNotStubbedException");
	}

	public function testVerificationFailureShowsExpectedVsActual() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub method
		mockBuilder.stub(mockComponent, "save", true);

		// Call method once
		mockComponent.save();

		// Try to verify different call count
		try {
			mockBuilder.verify(mockComponent, "save", 3);
			fail("Expected verification to fail");
		} catch (VerificationFailedException e) {
			// Verify error message contains expected and actual counts
			assertTrue(find("Expected: 3", e.detail) > 0);
			assertTrue(find("Actual: 1", e.detail) > 0);
		}
	}

	public function testVerifySupportsMinMaxCallCounts() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub method
		mockBuilder.stub(mockComponent, "save", true);

		// Call method twice
		mockComponent.save();
		mockComponent.save();

		// Verify with min/max range
		mockBuilder.verify(mockComponent, "save", {min: 1, max: 3});
	}

	public function testVerifyMinFailsWhenTooFewCalls() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub method
		mockBuilder.stub(mockComponent, "save", true);

		// Call method once
		mockComponent.save();

		// Try to verify min of 2 calls
		assertThrows(function() {
			mockBuilder.verify(mockComponent, "save", {min: 2});
		}, "VerificationFailedException");
	}

	public function testVerifyMaxFailsWhenTooManyCalls() {
		var mockBuilder = new fuse.testing.MockBuilder();
		var mockComponent = mockBuilder.mock("tests.testing.fixtures.SimpleService");

		// Stub method
		mockBuilder.stub(mockComponent, "save", true);

		// Call method three times
		mockComponent.save();
		mockComponent.save();
		mockComponent.save();

		// Try to verify max of 2 calls
		assertThrows(function() {
			mockBuilder.verify(mockComponent, "save", {max: 2});
		}, "VerificationFailedException");
	}

	// Helper method for testing verification failures
	private void function fail(required string message) {
		throw(type="AssertionFailedException", message=arguments.message);
	}

}
