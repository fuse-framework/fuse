/**
 * Tests for TestDiscovery component
 *
 * Validates test file discovery, TestCase filtering, method discovery,
 * and registry structure building.
 */
component extends="fuse.testing.TestCase" {

	variables.discovery = "";
	variables.fixturePath = "/tests/testing/fixtures/discovery";

	public function setup() {
		variables.discovery = new fuse.testing.TestDiscovery(variables.fixturePath);
	}

	/**
	 * Test: Discovers all *Test.cfc files recursively
	 *
	 * Verifies file pattern matching finds files ending in Test.cfc
	 * in both root and nested directories.
	 */
	public function testDiscoversTestFiles() {
		var tests = variables.discovery.discover();

		// Should find ValidTestCase and AnotherValidTestCase
		// Should NOT find NotATestCase (doesn't end in Test.cfc)
		// Should find NestedTestCase in subdirectory
		assertGreaterThan(0, arrayLen(tests), "Should discover test files");

		// Verify we found the expected test files
		var foundValid = false;
		var foundAnother = false;
		var foundNested = false;

		for (var test in tests) {
			if (findNoCase("ValidTestCase", test.componentName)) {
				foundValid = true;
			}
			if (findNoCase("AnotherValidTestCase", test.componentName)) {
				foundAnother = true;
			}
			if (findNoCase("NestedTestCase", test.componentName)) {
				foundNested = true;
			}
		}

		assertTrue(foundValid, "Should find ValidTestCase");
		assertTrue(foundAnother, "Should find AnotherValidTestCase");
		assertTrue(foundNested, "Should find NestedTestCase in subdirectory");
	}

	/**
	 * Test: Filters to only TestCase subclasses
	 *
	 * Verifies that CFCs not extending TestCase are excluded
	 * even if they match the *Test.cfc pattern.
	 */
	public function testFiltersToTestCaseSubclasses() {
		var tests = variables.discovery.discover();

		// Verify NotATestCase is not included (doesn't extend TestCase)
		for (var test in tests) {
			assertFalse(
				findNoCase("NotATestCase", test.componentName),
				"Should not include CFCs that don't extend TestCase"
			);
		}
	}

	/**
	 * Test: Discovers test methods from TestCase
	 *
	 * Verifies method discovery finds all methods starting with "test"
	 * and includes them in the test registry.
	 */
	public function testDiscoversTestMethods() {
		var tests = variables.discovery.discover();

		// Find ValidTestCase which has testExample and testAnotherExample
		var validTest = {};
		for (var test in tests) {
			if (findNoCase("ValidTestCase", test.componentName) && !findNoCase("AnotherValidTestCase", test.componentName)) {
				validTest = test;
				break;
			}
		}

		assertNotEmpty(validTest, "Should find ValidTestCase");
		assertCount(2, validTest.testMethods, "ValidTestCase should have 2 test methods");

		// Verify specific test methods are found
		assertContains("testExample", validTest.testMethods);
		assertContains("testAnotherExample", validTest.testMethods);

		// Verify non-test methods are excluded
		assertNotContains("helperMethod", validTest.testMethods);
	}

	/**
	 * Test: Builds correct registry structure
	 *
	 * Verifies each test descriptor has required fields:
	 * filePath, componentName, testMethods array.
	 */
	public function testBuildsCorrectRegistryStructure() {
		var tests = variables.discovery.discover();

		assertGreaterThan(0, arrayLen(tests), "Should return non-empty array");

		// Verify each test descriptor has required structure
		for (var test in tests) {
			assertTrue(structKeyExists(test, "filePath"), "Should have filePath");
			assertTrue(structKeyExists(test, "componentName"), "Should have componentName");
			assertTrue(structKeyExists(test, "testMethods"), "Should have testMethods");

			assertNotEmpty(test.filePath, "filePath should not be empty");
			assertNotEmpty(test.componentName, "componentName should not be empty");
			assertTrue(isArray(test.testMethods), "testMethods should be array");
		}
	}

	/**
	 * Test: Handles non-existent test path gracefully
	 *
	 * Verifies discovery returns empty array when test path doesn't exist
	 * rather than throwing exception.
	 */
	public function testHandlesNonExistentPath() {
		var discovery = new fuse.testing.TestDiscovery("/nonexistent/path");
		var tests = discovery.discover();

		assertCount(0, tests, "Should return empty array for non-existent path");
	}

}
