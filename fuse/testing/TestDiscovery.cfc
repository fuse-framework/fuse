/**
 * TestDiscovery - Convention-based test file and method discovery
 *
 * Scans filesystem for *Test.cfc files, filters to TestCase subclasses,
 * and builds registry of test files with their test methods.
 *
 * USAGE EXAMPLES:
 *
 * Basic discovery:
 *     discovery = new fuse.testing.TestDiscovery();
 *     tests = discovery.discover();
 *     // Returns array of test descriptors
 *
 * Custom test path:
 *     discovery = new fuse.testing.TestDiscovery("/app/tests");
 *     tests = discovery.discover();
 *
 * Test descriptor structure:
 *     {
 *         filePath: "/path/to/UserTest.cfc",
 *         componentName: "tests.UserTest",
 *         testMethods: ["testCreate", "testValidation"]
 *     }
 *
 * Conventions:
 * - Test files must end with Test.cfc suffix
 * - Test files must extend fuse.testing.TestCase
 * - Test methods must start with "test" prefix
 * - Discovery is recursive from test path
 */
component {

	variables.testPath = "";
	variables.baseTestPath = "";

	/**
	 * Initialize TestDiscovery
	 *
	 * @testPath Directory to scan for tests (defaults to /tests)
	 * @return TestDiscovery instance for chaining
	 */
	public function init(string testPath = "/tests") {
		variables.testPath = arguments.testPath;

		// Store base test path for component name calculation
		variables.baseTestPath = expandPath(arguments.testPath);

		return this;
	}

	/**
	 * Discover all test files and methods
	 *
	 * Scans test path recursively for *Test.cfc files, instantiates each
	 * component to verify it extends TestCase, and discovers test methods.
	 *
	 * @return Array of test descriptor structs with filePath, componentName, testMethods
	 */
	public array function discover() {
		var tests = [];
		var testFiles = findTestFiles();

		for (var filePath in testFiles) {
			try {
				var componentName = getComponentName(filePath);
				var testInstance = createObject("component", componentName);

				// Verify extends TestCase using metadata
				if (extendsTestCase(testInstance)) {
					var testMethods = testInstance.getTestMethods();

					arrayAppend(tests, {
						filePath: filePath,
						componentName: componentName,
						testMethods: testMethods
					});
				}
			} catch (any e) {
				// Skip files that fail to instantiate or don't extend TestCase
				// This allows non-test CFCs to exist in test directory
			}
		}

		return tests;
	}

	// PRIVATE METHODS

	/**
	 * Find all *Test.cfc files in test path recursively
	 *
	 * Uses DirectoryList to scan for .cfc files matching *Test.cfc pattern.
	 *
	 * @return Array of absolute file paths
	 */
	private array function findTestFiles() {
		var absolutePath = expandPath(variables.testPath);

		// Handle case where test directory doesn't exist
		if (!directoryExists(absolutePath)) {
			return [];
		}

		var allFiles = directoryList(
			path = absolutePath,
			recurse = true,
			listInfo = "path",
			filter = "*.cfc"
		);

		// Filter to only *Test.cfc files
		var testFiles = [];
		for (var file in allFiles) {
			if (right(file, 8) == "Test.cfc") {
				arrayAppend(testFiles, file);
			}
		}

		return testFiles;
	}

	/**
	 * Convert file path to component notation
	 *
	 * Converts /path/to/tests/UserTest.cfc to tests.UserTest
	 *
	 * @filePath Absolute file path
	 * @return Component name in dot notation
	 */
	private string function getComponentName(required string filePath) {
		var webroot = expandPath("/");
		var relativePath = replace(arguments.filePath, webroot, "");

		// Remove .cfc extension
		relativePath = left(relativePath, len(relativePath) - 4);

		// Convert path separators to dots
		relativePath = replace(relativePath, "/", ".", "all");
		relativePath = replace(relativePath, "\", ".", "all");

		return relativePath;
	}

	/**
	 * Check if component extends TestCase
	 *
	 * Walks inheritance chain via getMetadata to verify TestCase ancestry.
	 * Follows ActiveRecord pattern for metadata inspection.
	 *
	 * @testInstance Component instance to check
	 * @return Boolean true if extends fuse.testing.TestCase
	 */
	private boolean function extendsTestCase(required any testInstance) {
		var metadata = getMetadata(arguments.testInstance);

		// Check current component
		if (structKeyExists(metadata, "name") && metadata.name == "fuse.testing.TestCase") {
			return true;
		}

		// Walk inheritance chain
		if (structKeyExists(metadata, "extends")) {
			var current = metadata.extends;
			while (structKeyExists(current, "name")) {
				if (current.name == "fuse.testing.TestCase") {
					return true;
				}
				if (structKeyExists(current, "extends")) {
					current = current.extends;
				} else {
					break;
				}
			}
		}

		return false;
	}

}
