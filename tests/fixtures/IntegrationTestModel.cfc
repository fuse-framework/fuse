/**
 * Test fixture for save/update/delete integration testing
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "integration_test_models";

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Register validations
		this.validates("email", {required: true, email: true});

		// Register callbacks
		this.beforeCreate("trackBeforeCreate");
		this.beforeSave("trackBeforeSave");
		this.afterSave("trackAfterSave");
		this.afterCreate("trackAfterCreate");
		this.beforeDelete("trackBeforeDelete");
		this.afterDelete("trackAfterDelete");

		// Initialize tracking
		variables.callbackOrder = [];
		variables.haltBeforeSave = false;
		variables.haltBeforeDelete = false;

		return this;
	}

	public function setHaltBeforeSave(required boolean halt) {
		variables.haltBeforeSave = arguments.halt;
	}

	public function setHaltBeforeDelete(required boolean halt) {
		variables.haltBeforeDelete = arguments.halt;
	}

	public function getCallbackOrder() {
		return variables.callbackOrder;
	}

	public function clearCallbackOrder() {
		variables.callbackOrder = [];
	}

	private boolean function trackBeforeCreate() {
		arrayAppend(variables.callbackOrder, "beforeCreate");
		return true;
	}

	private boolean function trackBeforeSave() {
		arrayAppend(variables.callbackOrder, "beforeSave");
		return !variables.haltBeforeSave;
	}

	private void function trackAfterSave() {
		arrayAppend(variables.callbackOrder, "afterSave");
	}

	private void function trackAfterCreate() {
		arrayAppend(variables.callbackOrder, "afterCreate");
	}

	private boolean function trackBeforeDelete() {
		arrayAppend(variables.callbackOrder, "beforeDelete");
		return !variables.haltBeforeDelete;
	}

	private void function trackAfterDelete() {
		arrayAppend(variables.callbackOrder, "afterDelete");
	}

}
