/**
 * Migration: CreateTestPosts
 *
 * Creates test_posts table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("test_posts", function(table) {
			table.id();
			table.string("title");
			table.text("body");
			table.timestamps();
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("test_posts");
	}

}
