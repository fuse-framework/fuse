/**
 * Comment Model
 *
 * ActiveRecord model for comments table
 */
component extends="fuse.orm.ActiveRecord" {

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships
		// belongsTo :user
		// belongsTo :post

		// Define validations
		// Add validations here

		return this;
	}

}
