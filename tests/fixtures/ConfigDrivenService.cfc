component {

	property name="config" inject="config";

	function init(config) {
		if (structKeyExists(arguments, "config")) {
			variables.config = arguments.config;
		}
		return this;
	}

	public string function getHost() {
		if (structKeyExists(variables, "config") && structKeyExists(variables.config, "database")) {
			return variables.config.database.host;
		}
		return "";
	}

	public function getConfig() {
		return variables.config;
	}

	public function setConfig(required config) {
		variables.config = arguments.config;
	}

}
