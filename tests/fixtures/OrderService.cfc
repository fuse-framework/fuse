component {

	property name="logger" inject="logger";

	function init() {
		return this;
	}

	function setLogger(required logger) {
		variables.logger = arguments.logger;
	}

	function getLogger() {
		return variables.logger ?: "";
	}

}
