component {

	property name="logger";

	function init() {
		variables.instanceId = createUUID();
		return this;
	}

	function getInstanceId() {
		return variables.instanceId;
	}

	function setLogger(required logger) {
		variables.logger = arguments.logger;
	}

	function getLogger() {
		return variables.logger ?: "";
	}

}
