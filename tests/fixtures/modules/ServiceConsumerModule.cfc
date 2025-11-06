component {

	function init() {
		variables.registered = false;
		variables.booted = false;
		variables.service = "";
		return this;
	}

	public void function register(required container) {
		variables.registered = true;
	}

	public void function boot(required container) {
		variables.booted = true;

		// Resolve service registered by ServiceProviderModule
		if (arguments.container.has("testService")) {
			variables.service = arguments.container.resolve("testService");
		}
	}

	public array function getDependencies() {
		return ["ServiceProviderModule"];
	}

	public struct function getConfig() {
		return {};
	}

	public boolean function isRegistered() {
		return variables.registered;
	}

	public boolean function isBooted() {
		return variables.booted;
	}

	public boolean function hasService() {
		return isObject(variables.service);
	}

}
