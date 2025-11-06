<cfscript>
// Run CLI support utilities tests
testbox = new testbox.system.TestBox(
	bundles = [
		"tests.cli.support.NamingConventionsTest",
		"tests.cli.support.AttributeParserTest",
		"tests.cli.support.TemplateEngineTest",
		"tests.cli.support.FileGeneratorTest"
	],
	reporter = "simple"
);

results = testbox.run();
writeOutput(results);
</cfscript>
