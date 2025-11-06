/**
 * Migration: CreateTags
 *
 * Creates tags table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("tags", function(table) {
			table.id();
			table.string("name");
			
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("tags");
	}

}
