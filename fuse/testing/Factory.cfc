/**
 * Factory - Base component for test data factory system
 *
 * Provides factory registration, instance creation, trait composition,
 * sequence management, and auto-discovery of factory definitions.
 *
 * USAGE EXAMPLES:
 *
 * Register factory:
 *     factory = new fuse.testing.Factory();
 *     factory.registerFactory("User", userFactoryInstance);
 *
 * Create in-memory instance:
 *     user = factory.make("User");
 *     user = factory.make("User", {email: "custom@test.com"});
 *     user = factory.make("User", {}, ["admin", "verified"]);
 *
 * Create and persist instance:
 *     user = factory.create("User");
 *     user = factory.create("User", {email: "custom@test.com"});
 *
 * Use sequences:
 *     n = factory.incrementSequence("email");
 *
 * Conventions:
 * - Factory definitions in tests/factories/*.cfc
 * - Each factory extends Factory and implements definition() method
 * - Traits are methods in factory that return attribute overrides
 * - Auto-discovery strips "Factory" suffix from filename
 */
component {

	// Static registry for factory instances (shared across all instances)
	static.factoryRegistry = {};
	static.sequences = {};
	static.discovered = false;

	/**
	 * Initialize Factory
	 *
	 * @return Factory instance for chaining
	 */
	public function init() {
		return this;
	}

	/**
	 * Register factory instance by name
	 *
	 * @param name Factory name (e.g., "User", "Post")
	 * @param instance Factory instance with definition() method
	 * @return void
	 */
	public void function registerFactory(required string name, required any instance) {
		static.factoryRegistry[arguments.name] = arguments.instance;
	}

	/**
	 * Get factory instance by name
	 *
	 * @param name Factory name
	 * @return Factory instance
	 * @throws FactoryNotFoundException if factory not registered
	 */
	public function getFactory(required string name) {
		// Lazy discovery on first factory access
		if (!static.discovered) {
			discoverFactories();
		}

		if (!structKeyExists(static.factoryRegistry, arguments.name)) {
			var availableFactories = structKeyList(static.factoryRegistry);
			throw(
				type = "FactoryNotFoundException",
				message = "Factory '#arguments.name#' not found",
				detail = "Available factories: #availableFactories#. Check tests/factories/ directory for factory definitions."
			);
		}

		return static.factoryRegistry[arguments.name];
	}

	/**
	 * Create in-memory model instance without persistence
	 *
	 * @param factoryName Name of factory to use
	 * @param attributes Optional attribute overrides
	 * @param traits Optional array of trait names to apply
	 * @return Model instance populated with attributes
	 */
	public function make(required string factoryName, struct attributes = {}, array traits = []) {
		var factoryInstance = getFactory(arguments.factoryName);

		// Get base attributes from definition()
		var baseAttributes = factoryInstance.definition();

		// Apply traits in order
		var mergedAttributes = duplicate(baseAttributes);
		for (var traitName in arguments.traits) {
			if (structKeyExists(factoryInstance, traitName)) {
				var traitAttributes = invoke(factoryInstance, traitName);
				structAppend(mergedAttributes, traitAttributes, true);
			}
		}

		// Apply custom attributes (highest priority)
		structAppend(mergedAttributes, arguments.attributes, true);

		// Create model instance
		var modelInstance = createModelInstance(arguments.factoryName);

		// Apply attributes to model
		applyAttributes(modelInstance, mergedAttributes);

		return modelInstance;
	}

	/**
	 * Create and persist model instance via ActiveRecord save()
	 *
	 * @param factoryName Name of factory to use
	 * @param attributes Optional attribute overrides
	 * @param traits Optional array of trait names to apply
	 * @return Persisted model instance
	 */
	public function create(required string factoryName, struct attributes = {}, array traits = []) {
		// Create in-memory instance
		var instance = make(argumentCollection=arguments);

		// Persist via ActiveRecord save()
		instance.save();

		return instance;
	}

	/**
	 * Increment sequence counter and return new value
	 *
	 * @param key Sequence key
	 * @return Incremented sequence value
	 */
	public numeric function incrementSequence(required string key) {
		if (!structKeyExists(static.sequences, arguments.key)) {
			static.sequences[arguments.key] = 0;
		}

		static.sequences[arguments.key]++;
		return static.sequences[arguments.key];
	}

	/**
	 * Discover and register factory definitions from tests/factories/
	 *
	 * Scans directory for *.cfc files, instantiates each factory,
	 * and registers with name derived from filename.
	 * Supports nested directories: tests/factories/models/UserFactory.cfc -> "models.User"
	 *
	 * @param baseDir Optional base directory (defaults to tests/factories)
	 * @return void
	 */
	public void function discoverFactories(string baseDir = "") {
		// Determine base directory
		var factoriesDir = len(arguments.baseDir) ? arguments.baseDir : expandPath("/tests/factories");

		// Skip if directory doesn't exist
		if (!directoryExists(factoriesDir)) {
			static.discovered = true;
			return;
		}

		// Scan for factory files recursively
		var factoryFiles = directoryList(
			factoriesDir,
			true, // recursive
			"path",
			"*.cfc"
		);

		// Register each factory
		for (var filePath in factoryFiles) {
			registerFactoryFromFile(filePath, factoriesDir);
		}

		// Mark discovery complete
		static.discovered = true;
	}

	/**
	 * Apply attributes to model instance
	 *
	 * @param model Model instance
	 * @param attributes Struct of attributes to apply
	 * @return void
	 */
	private void function applyAttributes(required any model, required struct attributes) {
		for (var key in arguments.attributes) {
			var value = arguments.attributes[key];

			// Set attribute on model
			// Use direct assignment to variables.attributes for ActiveRecord models
			if (structKeyExists(arguments.model, "getVariablesScope")) {
				var vars = arguments.model.getVariablesScope();
				if (structKeyExists(vars, "attributes")) {
					vars.attributes[key] = value;
				}
			}
		}
	}

	/**
	 * Create model instance for factory
	 *
	 * @param factoryName Factory name
	 * @return Model instance
	 */
	private function createModelInstance(required string factoryName) {
		// Resolve model component path from factory name
		var componentPath = resolveModelPath(arguments.factoryName);

		// Get datasource from application scope or default
		var datasource = "fuse";
		if (isDefined("application.datasource")) {
			datasource = application.datasource;
		}

		// Create and initialize model instance
		return createObject("component", componentPath).init(datasource);
	}

	/**
	 * Resolve model component path from factory name
	 *
	 * @param factoryName Factory name (e.g., "User", "models.User")
	 * @return Component path (e.g., "tests.fixtures.User")
	 */
	private string function resolveModelPath(required string factoryName) {
		// For now, assume models are in tests.fixtures namespace
		// Future enhancement: make this configurable
		if (find(".", arguments.factoryName)) {
			// Already has namespace (e.g., "models.User")
			return "tests.fixtures." & arguments.factoryName;
		} else {
			// Simple name (e.g., "User")
			return "tests.fixtures." & arguments.factoryName;
		}
	}

	/**
	 * Register factory from file path
	 *
	 * @param filePath Full path to factory CFC file
	 * @param baseDir Base factories directory
	 * @return void
	 */
	private void function registerFactoryFromFile(required string filePath, required string baseDir) {
		// Get relative path from base directory
		var relativePath = replaceNoCase(arguments.filePath, arguments.baseDir, "");
		relativePath = replaceNoCase(relativePath, "\", "/", "all");
		if (left(relativePath, 1) == "/") {
			relativePath = right(relativePath, len(relativePath) - 1);
		}

		// Remove .cfc extension
		relativePath = replaceNoCase(relativePath, ".cfc", "");

		// Convert path to factory name
		// tests/factories/UserFactory.cfc -> User
		// tests/factories/models/UserFactory.cfc -> models.User
		var factoryName = replaceNoCase(relativePath, "/", ".", "all");

		// Strip "Factory" suffix
		if (right(factoryName, 7) == "Factory") {
			factoryName = left(factoryName, len(factoryName) - 7);
		}

		// Build component path
		var componentPath = "tests.factories." & replaceNoCase(relativePath, "/", ".", "all");

		try {
			// Instantiate factory
			var factoryInstance = createObject("component", componentPath).init();

			// Register factory
			registerFactory(factoryName, factoryInstance);
		} catch (any e) {
			// Log error but continue discovery
			// In production, might want to throw or log more prominently
		}
	}

	/**
	 * Reset factory state for testing
	 * Clears registry and sequences
	 *
	 * @return void
	 */
	public void function resetForTesting() {
		static.factoryRegistry = {};
		static.sequences = {};
		static.discovered = false;
	}

}
