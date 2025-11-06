/**
 * PostFactory - Example factory definition with relationships
 *
 * Demonstrates:
 * - Factory with relationship to User via author_id
 * - Nested factory calls for creating related data
 * - Trait methods for different post states
 * - Sequence usage for unique titles
 */
component extends="fuse.testing.Factory" {

	public function init() {
		super.init();
		return this;
	}

	/**
	 * Default attributes for Post factory
	 *
	 * Demonstrates relationship support via nested factory call.
	 * Creates a User and uses their ID for author_id.
	 *
	 * @return Struct of default attributes
	 */
	public struct function definition() {
		// Use sequence for unique titles
		var seq = incrementSequence("post_title");

		// Create related user via nested factory call
		// This demonstrates relationship support
		var author = create("User");

		return {
			title: "Post Title ##" & seq,
			body: "This is the body of post ##" & seq,
			author_id: author.id,
			status: "draft",
			published_at: ""
		};
	}

	/**
	 * Published trait - marks post as published
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function published() {
		return {
			status: "published",
			published_at: now()
		};
	}

	/**
	 * Featured trait - marks post as featured
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function featured() {
		return {
			is_featured: true
		};
	}

	/**
	 * Archived trait - marks post as archived
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function archived() {
		return {
			status: "archived",
			archived_at: now()
		};
	}

	/**
	 * With specific author trait
	 *
	 * Example usage:
	 *   post = make("Post", {}, ["withAuthor"])
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function withAuthor() {
		// Create admin user as author
		var admin = create("User", {}, ["admin"]);

		return {
			author_id: admin.id
		};
	}

}
