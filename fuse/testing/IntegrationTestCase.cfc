/**
 * IntegrationTestCase - Base class for integration tests with framework loading
 *
 * Extends TestCase with full Framework.cfc stack initialization before tests.
 * Loads Router, DI Container, ModuleRegistry, EventService and makes framework
 * services accessible via variables.framework.
 *
 * USAGE EXAMPLES:
 *
 * Basic integration test:
 *     component extends="fuse.testing.IntegrationTestCase" {
 *         public function testFullStackRequest() {
 *             var router = variables.framework.getContainer().resolve("router");
 *             assertNotNull(router);
 *         }
 *     }
 *
 * With factories and database:
 *     component extends="fuse.testing.IntegrationTestCase" {
 *         public function testUserRegistration() {
 *             var user = create("User", {email: "test@example.com"});
 *             assertDatabaseHas("users", {email: "test@example.com"});
 *
 *             // Access framework services
 *             var eventService = variables.framework.getContainer().resolve("eventService");
 *             assertNotNull(eventService);
 *         }
 *     }
 *
 * Conventions:
 * - Integration tests extend IntegrationTestCase instead of TestCase
 * - Framework loads once per test via TestRunner.runTestMethod()
 * - Framework initialization happens BEFORE transaction begins
 * - Transaction rollback works same as unit tests (database changes only)
 * - All test helpers (factories, mocks, assertions) still available
 * - Framework services accessed via variables.framework.getContainer()
 */
component extends="fuse.testing.TestCase" {

	/**
	 * Setup lifecycle hook - overridden to NOT initialize framework
	 *
	 * TestRunner calls initFramework() directly before transaction begins.
	 * This setup() method can be overridden by test classes for additional setup.
	 */
	public void function setup() {
		// Note: Framework initialization happens in TestRunner.runTestMethod()
		// BEFORE this setup() is called. Framework is already available in
		// variables.framework at this point.

		// Call parent setup for standard initialization
		super.setup();
	}

	/**
	 * Get framework instance for test access
	 *
	 * Provides access to framework instance from test methods.
	 * Use framework.getContainer() to resolve services.
	 *
	 * @return Framework instance
	 */
	public function getFramework() {
		if (!structKeyExists(variables, "framework")) {
			throw(
				type = "IntegrationTestCase.FrameworkNotInitialized",
				message = "Framework not initialized",
				detail = "TestRunner should have called initFramework() before setup(). This is likely a TestRunner bug."
			);
		}

		return variables.framework;
	}

	/**
	 * Get variables scope for testing
	 *
	 * Helper method to expose variables scope for test verification.
	 * Used by IntegrationTestCaseTest to verify internal state.
	 *
	 * @return Variables scope struct
	 */
	public function getVariables() {
		return variables;
	}

	// PRIVATE METHODS

	/**
	 * Initialize full Framework.cfc stack
	 *
	 * Loads DI Container, Router, ModuleRegistry, EventService following
	 * same initialization pattern as Bootstrap.initializeFramework().
	 * Stores framework instance in variables.framework for test access.
	 *
	 * NOTE: This method is called by TestRunner.runTestMethod() BEFORE
	 * transaction begins. Framework initialization does not create database
	 * changes, so it's safe to initialize before transaction.
	 *
	 * This method is private and called by TestRunner via invoke().
	 */
	private void function initFramework() {
		// Instantiate DI container
		var container = new fuse.core.Container();

		// Load configuration
		var configLoader = new fuse.core.Config();
		var baseConfig = configLoader.load();

		// Discover modules
		var moduleRegistry = new fuse.core.ModuleRegistry();
		var frameworkModules = moduleRegistry.discover(expandPath("/fuse"), "framework");
		var appModules = moduleRegistry.discover(expandPath("/"), "application");
		var allModules = moduleRegistry.merge(frameworkModules, appModules);

		// Merge module configs into base config
		var finalConfig = moduleRegistry.mergeConfigs(allModules, baseConfig);

		// Bind config to container
		configLoader.bindToContainer(container, finalConfig);

		// Register routing and event services
		container.singleton("router", function(c) {
			return new fuse.core.Router();
		});

		container.singleton("eventService", function(c) {
			return new fuse.core.EventService();
		});

		container.bind("dispatcher", function(c) {
			return new fuse.core.Dispatcher(
				c.resolve("router"),
				c,
				c.resolve("eventService")
			);
		});

		// Load routes from /config/routes.cfm
		configLoader.loadRoutes(container.resolve("router"));

		// Initialize modules (two-phase: register then boot)
		moduleRegistry.initialize(allModules, container);

		// Create and store framework instance
		variables.framework = new fuse.core.Framework(container);
	}

}
