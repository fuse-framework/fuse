component {

	function init(required container) {
		variables.container = arguments.container;
		variables.instanceId = createUUID();
		return this;
	}

	/**
	 * Get the DI container
	 *
	 * @return Container instance
	 */
	public function getContainer() {
		return variables.container;
	}

	/**
	 * Get unique instance ID for testing double-checked locking
	 *
	 * @return Instance ID
	 */
	public string function getInstanceId() {
		return variables.instanceId;
	}

}
