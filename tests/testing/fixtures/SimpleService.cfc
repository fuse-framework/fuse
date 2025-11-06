/**
 * SimpleService - Test fixture component for mock testing
 *
 * Simple component with a few methods to mock in tests.
 */
component {

	public string function getName() {
		return "Original Name";
	}

	public boolean function save() {
		// Simulate save operation
		return true;
	}

	public numeric function calculate(required numeric a, required numeric b) {
		return arguments.a + arguments.b;
	}

	public void function doSomething() {
		// No return value
	}

}
