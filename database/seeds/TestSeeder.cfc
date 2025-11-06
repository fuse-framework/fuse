/**
 * TestSeeder - Test fixture seeder for SeederTest
 */
component extends="fuse.orm.Seeder" {

	public function run() {
		// Set flag that run was called
		variables.runCalled = true;
	}

	public boolean function wasRunCalled() {
		return structKeyExists(variables, "runCalled") && variables.runCalled;
	}

}
