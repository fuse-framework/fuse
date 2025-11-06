/**
 * Migration: RemovePhoneFromUsers
 *
 * Modifies users table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.table("users", function(table) {
			table.string("phone");
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		// Note: Column dropping not implemented in current spec
		// In production, you would drop the columns here
	}

}
