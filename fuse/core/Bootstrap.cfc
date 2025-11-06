component {

	/**
	 * Initialize framework with thread-safe double-checked locking pattern
	 *
	 * @appScope Application scope to store framework instance
	 * @applicationKey Key under which to store framework (default: "fuse")
	 * @lockTimeout Lock timeout in seconds (default: 30)
	 * @return Framework instance
	 */
	public function initFramework(required struct appScope, string applicationKey = "fuse", numeric lockTimeout = 30) {
		// First check without lock (performance optimization)
		if (structKeyExists(arguments.appScope, arguments.applicationKey)) {
			return arguments.appScope[arguments.applicationKey];
		}

		// Acquire named lock for initialization
		lock name="fuse_bootstrap_#arguments.applicationKey#" type="exclusive" timeout=arguments.lockTimeout {
			// Second check inside lock (double-checked locking)
			if (structKeyExists(arguments.appScope, arguments.applicationKey)) {
				return arguments.appScope[arguments.applicationKey];
			}

			// Initialize framework
			var framework = initializeFramework();

			// Store in application scope
			arguments.appScope[arguments.applicationKey] = framework;

			return framework;
		}
	}

	/**
	 * Initialize framework with all core systems
	 *
	 * @return Framework instance
	 */
	private function initializeFramework() {
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

		// Initialize modules (two-phase: register then boot)
		moduleRegistry.initialize(allModules, container);

		// Create and return framework instance
		var framework = new fuse.core.Framework(container);

		return framework;
	}

}
