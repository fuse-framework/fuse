/**
 * Article Model
 *
 * ActiveRecord model for articles table
 */
component extends="fuse.orm.ActiveRecord" {

	public function init(required string datasource) {
		super.init(arguments.datasource);

		// Define relationships
		

		// Define validations
		// Add validations here

		return this;
	}

}
