/**
 * UserWithPosts - Test fixture demonstrating relationship definition in init
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "users";

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships in init
		this.hasMany("posts");

		return this;
	}

}
