component {

	function init() {
		// Core data structures
		variables.bindings = {};
		variables.instances = {};
		variables.scopes = {};
		variables.resolutionStack = [];

		return this;
	}

	/**
	 * Bind a transient service to the container
	 *
	 * @name Binding name
	 * @implementation CFC path string or closure factory
	 */
	public function bind(required string name, required implementation) {
		validateBindingName(arguments.name);

		variables.bindings[arguments.name] = arguments.implementation;
		variables.scopes[arguments.name] = "transient";

		return this;
	}

	/**
	 * Bind a singleton service to the container
	 *
	 * @name Binding name
	 * @implementation CFC path string or closure factory
	 */
	public function singleton(required string name, required implementation) {
		validateBindingName(arguments.name);

		variables.bindings[arguments.name] = arguments.implementation;
		variables.scopes[arguments.name] = "singleton";

		return this;
	}

	/**
	 * Resolve a service from the container
	 *
	 * @name Binding name to resolve
	 * @return Resolved instance
	 */
	public function resolve(required string name) {
		// Check if binding exists
		if (!structKeyExists(variables.bindings, arguments.name)) {
			throw(
				type = "Container.BindingNotFound",
				message = "No binding found for '#arguments.name#'",
				detail = "Register this service using bind() or singleton() before resolving"
			);
		}

		// Check singleton cache
		if (variables.scopes[arguments.name] == "singleton" && structKeyExists(variables.instances, arguments.name)) {
			return variables.instances[arguments.name];
		}

		// Check for circular dependencies
		if (arrayFind(variables.resolutionStack, arguments.name)) {
			var chain = arrayToList(variables.resolutionStack, " -> ") & " -> " & arguments.name;
			throw(
				type = "Container.CircularDependency",
				message = "Circular dependency detected: #chain#",
				detail = "Refactor your services to remove circular dependencies"
			);
		}

		// Add to resolution stack
		arrayAppend(variables.resolutionStack, arguments.name);

		try {
			var instance = createInstance(arguments.name);

			// Cache singleton
			if (variables.scopes[arguments.name] == "singleton") {
				variables.instances[arguments.name] = instance;
			}

			// Remove from resolution stack
			arrayDeleteAt(variables.resolutionStack, arrayLen(variables.resolutionStack));

			return instance;
		} catch (any e) {
			// Clean up resolution stack on error
			arrayDeleteAt(variables.resolutionStack, arrayLen(variables.resolutionStack));
			rethrow;
		}
	}

	/**
	 * Check if a binding exists
	 *
	 * @name Binding name
	 * @return True if binding exists
	 */
	public boolean function has(required string name) {
		return structKeyExists(variables.bindings, arguments.name);
	}

	// Private methods

	private function validateBindingName(required string name) {
		if (len(trim(arguments.name)) == 0) {
			throw(
				type = "Container.InvalidBinding",
				message = "Binding name cannot be empty",
				detail = "Provide a non-empty string as the binding name"
			);
		}
	}

	private function createInstance(required string name) {
		var binding = variables.bindings[arguments.name];

		// Closure-based binding
		if (isClosure(binding) || isCustomFunction(binding)) {
			return binding(this);
		}

		// CFC path string binding
		var instance = createObject("component", binding).init(argumentCollection = resolveConstructorDependencies(binding));

		// Property injection
		injectProperties(instance, binding);

		return instance;
	}

	private struct function resolveConstructorDependencies(required string cfcPath) {
		var dependencies = {};
		var metadata = getComponentMetadata(arguments.cfcPath);

		// Find init() method
		if (!structKeyExists(metadata, "functions")) {
			return dependencies;
		}

		var initMethod = "";
		for (var func in metadata.functions) {
			if (func.name == "init") {
				initMethod = func;
				break;
			}
		}

		if (!isStruct(initMethod)) {
			return dependencies;
		}

		// Resolve each parameter
		if (structKeyExists(initMethod, "parameters")) {
			for (var param in initMethod.parameters) {
				var paramName = param.name;

				// Try to resolve from container
				if (structKeyExists(variables.bindings, paramName)) {
					dependencies[paramName] = resolve(paramName);
				} else if (!structKeyExists(param, "required") || param.required == false || structKeyExists(param, "default")) {
					// Optional parameter, skip
					continue;
				} else {
					throw(
						type = "Container.MissingDependency",
						message = "Cannot resolve required parameter '#paramName#' for '#arguments.cfcPath#'",
						detail = "Register '#paramName#' in the container before resolving '#arguments.cfcPath#'"
					);
				}
			}
		}

		return dependencies;
	}

	private function injectProperties(required instance, required string cfcPath) {
		var metadata = getComponentMetadata(arguments.cfcPath);

		if (!structKeyExists(metadata, "properties")) {
			return;
		}

		for (var prop in metadata.properties) {
			if (structKeyExists(prop, "inject") && len(trim(prop.inject))) {
				var dependencyName = trim(prop.inject);

				if (!structKeyExists(variables.bindings, dependencyName)) {
					throw(
						type = "Container.MissingDependency",
						message = "Cannot inject property '#prop.name#' with '#dependencyName#' for '#arguments.cfcPath#'",
						detail = "Register '#dependencyName#' in the container before resolving '#arguments.cfcPath#'"
					);
				}

				var dependency = resolve(dependencyName);
				var setterName = "set" & ucase(left(prop.name, 1)) & right(prop.name, len(prop.name) - 1);

				// Call setter if exists
				if (structKeyExists(arguments.instance, setterName)) {
					evaluate("arguments.instance.#setterName#(dependency)");
				}
			}
		}
	}

}
