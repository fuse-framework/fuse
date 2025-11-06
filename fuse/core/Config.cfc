component {

	/**
	 * Load base configuration
	 *
	 * @baseConfig Base configuration struct
	 * @return Configuration struct
	 */
	public struct function loadBase(required struct baseConfig) {
		return duplicate(arguments.baseConfig);
	}

	/**
	 * Merge environment-specific overrides into base config
	 *
	 * @baseConfig Base configuration struct
	 * @envConfig Environment override struct
	 * @return Merged configuration struct
	 */
	public struct function mergeEnvironment(required struct baseConfig, required struct envConfig) {
		return deepMerge(arguments.baseConfig, arguments.envConfig);
	}

	/**
	 * Merge module configurations under module name keys
	 *
	 * @baseConfig Base configuration struct
	 * @moduleConfigs Struct of module name -> module config
	 * @return Merged configuration struct
	 */
	public struct function mergeModules(required struct baseConfig, required struct moduleConfigs) {
		var result = duplicate(arguments.baseConfig);

		for (var moduleName in arguments.moduleConfigs) {
			result[moduleName] = arguments.moduleConfigs[moduleName];
		}

		return result;
	}

	/**
	 * Detect current environment
	 *
	 * @envVars Optional environment variables struct (for testing)
	 * @return Environment name (development, production, test, etc)
	 */
	public string function detectEnvironment(struct envVars) {
		// Check APPLICATION.environment first
		if (structKeyExists(application, "environment") && len(trim(application.environment))) {
			return trim(application.environment);
		}

		// Check ENV.FUSE_ENV
		var env = structKeyExists(arguments, "envVars") ? arguments.envVars : server.system.environment;
		if (structKeyExists(env, "FUSE_ENV") && len(trim(env.FUSE_ENV))) {
			return trim(env.FUSE_ENV);
		}

		// Default to production
		return "production";
	}

	/**
	 * Bind configuration to DI container as singleton
	 *
	 * @container DI container instance
	 * @config Configuration struct to bind
	 */
	public function bindToContainer(required container, required struct config) {
		arguments.container.singleton("config", function(c) {
			return config;
		});
	}

	/**
	 * Load configuration from file system
	 *
	 * @configPath Path to config directory (default: /config)
	 * @environment Optional environment name (auto-detected if not provided)
	 * @return Configuration struct
	 */
	public struct function load(string configPath = "/config", string environment) {
		var baseConfigPath = arguments.configPath & "/application.cfc";
		var baseConfig = {};

		// Load base config if exists
		if (fileExists(expandPath(baseConfigPath))) {
			var appConfig = createObject("component", baseConfigPath);
			if (structKeyExists(appConfig, "getConfig")) {
				baseConfig = appConfig.getConfig();
			}
		}

		// Detect environment
		var env = structKeyExists(arguments, "environment") ? arguments.environment : detectEnvironment();

		// Load environment override
		var envConfigPath = arguments.configPath & "/environments/" & env & ".cfc";
		var envConfig = {};

		if (fileExists(expandPath(envConfigPath))) {
			var envCfc = createObject("component", envConfigPath);
			if (structKeyExists(envCfc, "getConfig")) {
				envConfig = envCfc.getConfig();
			}
		}

		// Merge environment overrides
		return mergeEnvironment(baseConfig, envConfig);
	}

	// Private methods

	/**
	 * Deep merge two structs, with override taking precedence
	 *
	 * @base Base struct
	 * @override Override struct
	 * @return Merged struct
	 */
	private struct function deepMerge(required struct base, required struct override) {
		var result = duplicate(arguments.base);

		for (var key in arguments.override) {
			if (structKeyExists(result, key) && isStruct(result[key]) && isStruct(arguments.override[key])) {
				// Recursively merge nested structs
				result[key] = deepMerge(result[key], arguments.override[key]);
			} else {
				// Override value takes precedence
				result[key] = arguments.override[key];
			}
		}

		return result;
	}

}
