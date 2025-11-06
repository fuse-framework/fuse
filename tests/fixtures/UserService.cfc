component {

	function init(required logger, required database) {
		variables.logger = arguments.logger;
		variables.database = arguments.database;
		return this;
	}

	function getLogger() {
		return variables.logger;
	}

	function getDatabase() {
		return variables.database;
	}

}
