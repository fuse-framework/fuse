<cfscript>
engine = new fuse.cli.support.TemplateEngine();
template = "Hello {{name}}!";
vars = {name: "World"};

writeOutput("Template: " & template & "<br>");
writeOutput("Variables: " & serializeJSON(vars) & "<br>");

result = engine.renderString(template, vars);
writeOutput("Result: " & result & "<br>");
</cfscript>
