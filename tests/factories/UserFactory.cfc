/**
 * UserFactory - Example factory definition for User model
 */
component extends="fuse.testing.Factory" {

	public function init() {
		super.init();
		return this;
	}

	/**
	 * Default attributes for User factory
	 *
	 * @return Struct of default attributes
	 */
	public struct function definition() {
		return {
			name: "John Doe",
			email: "john@example.com"
		};
	}

	/**
	 * Admin trait - makes user an admin
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function admin() {
		return {
			is_admin: true,
			role: "admin"
		};
	}

	/**
	 * Verified trait - marks email as verified
	 *
	 * @return Struct of attribute overrides
	 */
	public struct function verified() {
		return {
			email_verified: true
		};
	}

}
