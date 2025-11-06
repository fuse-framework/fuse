/**
 * UserWithRelationships - Test fixture with relationship definitions
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "users";

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships
		this.hasMany("posts");
		this.hasOne("profile");

		return this;
	}

}
