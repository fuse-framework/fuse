component {

	function init() {
		variables.registered = false;
		variables.booted = false;
		return this;
	}

	public void function register(required container) {
		variables.registered = true;
	}

	public void function boot(required container) {
		variables.booted = true;
	}

	public array function getDependencies() {
		return ["ModuleA", "ModuleB"];
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

}
