/**
 * Migration: CreatePosts
 *
 * Creates posts table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("posts", function(table) {
			table.id();
			
			table.timestamps();
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("posts");
	}

}
