/**
 * User - Test fixture model for factory tests
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "users";

	public function init(required string datasource) {
		super.init(arguments.datasource);
		return this;
	}

}
