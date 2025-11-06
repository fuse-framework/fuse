/**
 * Test fixture for CallbackManager testing
 */
component {

	public function init() {
		variables.executionOrder = [];
		return this;
	}

	public any function getExecutionOrder() {
		return variables.executionOrder;
	}

	public void function firstCallback() {
		arrayAppend(variables.executionOrder, "first");
	}

	public boolean function secondCallback() {
		arrayAppend(variables.executionOrder, "second");
		return true;
	}

	public boolean function returnFalseCallback() {
		arrayAppend(variables.executionOrder, "returnFalse");
		return false;
	}

	public void function thirdCallback() {
		arrayAppend(variables.executionOrder, "third");
	}

}
