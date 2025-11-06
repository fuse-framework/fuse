/**
 * PostWithRelationships - Test fixture with relationship definitions
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "posts";

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships
		this.belongsTo("user");

		return this;
	}

}
