component {

	/**
	 * Discover modules from a directory
	 *
	 * @basePath Base path to search for modules
	 * @type Module type (framework or application)
	 * @return Ordered struct of module name -> module metadata
	 */
	public struct function discover(required string basePath, string type = "application") {
		var modules = structNew("ordered");
		var modulesPath = arguments.basePath & "/modules/";

		// Check if modules directory exists
		if (!directoryExists(modulesPath)) {
			return modules;
		}

		// Scan for *Module.cfc files
		var files = directoryList(modulesPath, false, "path", "*Module.cfc");

		for (var file in files) {
			var fileName = getFileFromPath(file);
			var moduleName = replaceNoCase(fileName, ".cfc", "");

			// Build component path
			var componentPath = arguments.basePath & ".modules." & moduleName;

			try {
				// Instantiate module
				var instance = createObject("component", componentPath);

				// Validate IModule interface
				validateModule(instance, moduleName);

				// Add to registry
				modules[moduleName] = {
					path: componentPath,
					instance: instance,
					dependencies: instance.getDependencies(),
					loaded: false,
					type: arguments.type
				};
			} catch (any e) {
				throw(
					type = "ModuleRegistry.InvalidModule",
					message = "Failed to load module '#moduleName#'",
					detail = "Error: #e.message#"
				);
			}
		}

		return modules;
	}

	/**
	 * Merge framework and application modules
	 * Framework modules are added first to ensure they load before app modules
	 *
	 * @frameworkModules Framework modules struct
	 * @appModules Application modules struct
	 * @return Merged ordered struct with framework modules first
	 */
	public struct function merge(required struct frameworkModules, required struct appModules) {
		var merged = structNew("ordered");

		// Add framework modules first
		for (var name in arguments.frameworkModules) {
			merged[name] = arguments.frameworkModules[name];
		}

		// Add application modules
		for (var name in arguments.appModules) {
			merged[name] = arguments.appModules[name];
		}

		return merged;
	}

	/**
	 * Sort modules by dependencies using topological sort
	 *
	 * @modules Struct of module name -> module metadata
	 * @return Array of module names in dependency order
	 */
	public array function sortByDependencies(required struct modules) {
		var sorted = [];
		var visited = {};
		var visiting = {};

		// Visit each module
		for (var moduleName in arguments.modules) {
			if (!structKeyExists(visited, moduleName)) {
				visitModule(moduleName, arguments.modules, visited, visiting, sorted);
			}
		}

		return sorted;
	}

	/**
	 * Initialize modules in two phases
	 *
	 * @modules Struct of module name -> module metadata
	 * @container DI container instance
	 */
	public void function initialize(required struct modules, required container) {
		// Sort modules by dependencies
		var orderedModules = sortByDependencies(arguments.modules);

		// Phase 1: Register - bind services to container
		for (var moduleName in orderedModules) {
			var moduleData = arguments.modules[moduleName];
			moduleData.instance.register(arguments.container);
		}

		// Phase 2: Boot - resolve dependencies and initialize
		for (var moduleName in orderedModules) {
			var moduleData = arguments.modules[moduleName];
			moduleData.instance.boot(arguments.container);
			moduleData.loaded = true;
		}
	}

	/**
	 * Merge module configurations into global config
	 *
	 * @modules Struct of module name -> module metadata
	 * @baseConfig Base configuration struct
	 * @return Configuration struct with module configs merged
	 */
	public struct function mergeConfigs(required struct modules, required struct baseConfig) {
		var result = duplicate(arguments.baseConfig);

		for (var moduleName in arguments.modules) {
			var moduleConfig = arguments.modules[moduleName].instance.getConfig();
			if (!structIsEmpty(moduleConfig)) {
				result[moduleName] = moduleConfig;
			}
		}

		return result;
	}

	// Private methods

	private void function validateModule(required instance, required string moduleName) {
		// Check for required methods
		var requiredMethods = ["register", "boot", "getDependencies", "getConfig"];

		for (var methodName in requiredMethods) {
			if (!structKeyExists(arguments.instance, methodName)) {
				throw(
					type = "ModuleRegistry.InvalidModule",
					message = "Module '#arguments.moduleName#' does not implement IModule interface",
					detail = "Missing required method: #methodName#()"
				);
			}
		}
	}

	private void function visitModule(
		required string moduleName,
		required struct modules,
		required struct visited,
		required struct visiting,
		required array sorted
	) {
		// Check if module exists
		if (!structKeyExists(arguments.modules, arguments.moduleName)) {
			throw(
				type = "ModuleRegistry.MissingDependency",
				message = "Module '#arguments.moduleName#' not found",
				detail = "This module is required by another module but was not discovered"
			);
		}

		// Check for circular dependency
		if (structKeyExists(arguments.visiting, arguments.moduleName)) {
			throw(
				type = "ModuleRegistry.CircularDependency",
				message = "Circular dependency detected involving module '#arguments.moduleName#'",
				detail = "Review module dependencies to remove circular references"
			);
		}

		// Mark as visiting
		arguments.visiting[arguments.moduleName] = true;

		// Visit dependencies
		var dependencies = arguments.modules[arguments.moduleName].dependencies;
		for (var dependency in dependencies) {
			if (!structKeyExists(arguments.visited, dependency)) {
				visitModule(dependency, arguments.modules, arguments.visited, arguments.visiting, arguments.sorted);
			}
		}

		// Mark as visited
		arguments.visited[arguments.moduleName] = true;
		structDelete(arguments.visiting, arguments.moduleName);

		// Add to sorted list
		arrayAppend(arguments.sorted, arguments.moduleName);
	}

}
