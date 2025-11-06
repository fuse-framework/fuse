component {

	function init() {
		variables.registered = false;
		variables.booted = false;
		variables.configValue = 0;
		return this;
	}

	public void function register(required container) {
		variables.registered = true;
	}

	public void function boot(required container) {
		variables.booted = true;

		// Resolve config and extract module-specific config
		if (arguments.container.has("config")) {
			var config = arguments.container.resolve("config");
			if (structKeyExists(config, "ConfigAwareModule") && structKeyExists(config.ConfigAwareModule, "value")) {
				variables.configValue = config.ConfigAwareModule.value;
			}
		}
	}

	public array function getDependencies() {
		return [];
	}

	public struct function getConfig() {
		return {
			"enabled": true,
			"value": 0
		};
	}

	public boolean function isRegistered() {
		return variables.registered;
	}

	public boolean function isBooted() {
		return variables.booted;
	}

	public numeric function getConfigValue() {
		return variables.configValue;
	}

}
