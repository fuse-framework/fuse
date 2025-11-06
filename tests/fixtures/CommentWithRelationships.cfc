/**
 * CommentWithRelationships - Test fixture with relationship definitions
 */
component extends="fuse.orm.ActiveRecord" {

	this.tableName = "comments";

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships
		this.belongsTo("post");
		this.belongsTo("author", {className: "User", foreignKey: "user_id"});

		return this;
	}

}
