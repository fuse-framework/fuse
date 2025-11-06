/**
 * ExampleUserTest - Example test demonstrating passing tests
 *
 * Demonstrates:
 * - Basic assertion usage
 * - Setup/teardown lifecycle
 * - Multiple test methods
 * - All tests pass
 */
component extends="fuse.testing.TestCase" {

	variables.testUser = "";

	/**
	 * Setup runs before each test method
	 * Prepare test data and state
	 */
	public void function setup() {
		variables.testUser = {
			id: 1,
			name: "Test User",
			email: "test@example.com",
			active: true
		};
	}

	/**
	 * Teardown runs after each test method
	 * Clean up test data and state
	 */
	public void function teardown() {
		variables.testUser = "";
	}

	/**
	 * Test basic equality assertions
	 */
	public void function testUserProperties() {
		assertEqual(1, variables.testUser.id);
		assertEqual("Test User", variables.testUser.name);
		assertEqual("test@example.com", variables.testUser.email);
	}

	/**
	 * Test boolean assertions
	 */
	public void function testUserIsActive() {
		assertTrue(variables.testUser.active);
		assertFalse(!variables.testUser.active);
	}

	/**
	 * Test null assertions
	 */
	public void function testSetupRan() {
		assertNotNull(variables.testUser);
		assertNotEmpty(variables.testUser.name);
	}

	/**
	 * Test struct contains key
	 */
	public void function testUserHasRequiredFields() {
		assertContains("id", structKeyArray(variables.testUser));
		assertContains("name", structKeyArray(variables.testUser));
		assertContains("email", structKeyArray(variables.testUser));
	}

	/**
	 * Test numeric comparisons
	 */
	public void function testUserIdIsPositive() {
		assertGreaterThan(0, variables.testUser.id);
		assertLessThan(1000, variables.testUser.id);
	}

	/**
	 * Test string pattern matching
	 */
	public void function testEmailFormat() {
		assertMatches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", variables.testUser.email);
	}

	/**
	 * Test instance type checking
	 */
	public void function testUserIsStruct() {
		assertInstanceOf("struct", variables.testUser);
	}

}
