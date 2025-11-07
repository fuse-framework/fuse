# Documentation Style Guide

This guide defines standards for all Fuse framework documentation to ensure consistency, clarity, and AI-friendliness.

## Code Examples

### File Path Comments

Every code example must include file path as first line comment:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // ...
}
```

### Complete Component Declarations

Always show full component declaration, never partial:

**Good:**
```cfml
// app/handlers/Users.cfc
component {
    public function init() {
        return this;
    }

    public struct function index() {
        return {users: []};
    }
}
```

**Bad:**
```cfml
public struct function index() {
    return {users: []};
}
```

### Realistic Variable Names

Use domain-appropriate, realistic names. Avoid foo/bar/baz.

**Good:**
```cfml
var user = User::find(1);
var publishedPosts = Post::where({published: true});
```

**Bad:**
```cfml
var foo = User::find(1);
var bar = Post::where({baz: true});
```

### Static vs Instance Methods

Show both static and instance method patterns where applicable:

```cfml
// Static method - class-level operation
var user = User::find(1);

// Instance method - object operation
user.save();
```

### Runnable Examples

All code examples must be:
- Copy-pasteable without modification
- Syntactically correct
- Executable in context
- Free of placeholder values (unless explicitly noted)

## Document Structure

### Heading Hierarchy

Use strict H1 → H2 → H3 progression. Never skip levels.

```markdown
# Page Title (H1)

## Major Section (H2)

### Subsection (H3)

#### Detail Level (H4)
```

### Standard Sections

Every guide document should include:

1. **Introduction** - What this guide covers
2. **Basic Usage** - Simple examples
3. **Common Patterns** - Real-world use cases
4. **Advanced Usage** - Complex scenarios
5. **Anti-Patterns** - Common mistakes to avoid
6. **Related Topics** - Links to related guides

### Tutorial Structure

Tutorial documents follow progressive steps:

1. **Overview** - What you'll build
2. **Prerequisites** - Required knowledge
3. **Steps** - Numbered progressive steps
4. **Summary** - What you learned
5. **Next Steps** - Where to go next

### Reference Structure

API/CLI reference documents follow:

1. **Overview** - Purpose and scope
2. **Method/Command Groups** - Organized by category
3. **Method/Command Details** - Individual entries with:
   - Signature/Syntax
   - Description
   - Parameters table
   - Return value
   - Throws/Errors
   - Example
   - Related methods/commands

## Code Block Formatting

### Language Tags

Always specify language for syntax highlighting:

```markdown
\```cfml
component {
    // CFML code
}
\```

\```bash
lucli new myapp
\```

\```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY
);
\```
```

### Console Output

Show expected output for CLI commands:

```bash
$ lucli generate model User name:string email:string

Creating model...
  ✓ Created app/models/User.cfc
  ✓ Created tests/models/UserTest.cfc
  ✓ Created migrations/2025-11-06-123456-create-users.cfc
```

## Tables

Use tables for parameter documentation, comparison charts, etc:

```markdown
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name      | string | Yes    | -       | User's name |
| email     | string | Yes    | -       | Email address |
```

## Cross-References

### Internal Links

Link to other docs using relative paths:

```markdown
See [Routing Guide](guides/routing.md) for more details.
```

### Section Links

Link to specific sections:

```markdown
See [Eager Loading](guides/eager-loading.md#nested-eager-loading).
```

### Related Topics

Include "Related Topics" section at end of each guide:

```markdown
## Related Topics

- [Models & ORM](models-orm.md)
- [Validations](validations.md)
- [Testing](testing.md)
```

## Mermaid Diagrams

Use Mermaid for flowcharts, architecture diagrams, decision trees:

```markdown
\```mermaid
flowchart TD
    A[Start] --> B{Need persistence?}
    B -->|Yes| C[Create model]
    B -->|No| D[Use plain component]
    C --> E[Generate migration]
\```
```

### Diagram Conventions

- Use clear, short node labels
- Top-to-bottom or left-to-right flow
- Include legend if complex
- Keep diagrams focused on single concept

## Anti-Patterns Section

Every guide should include common mistakes:

```markdown
## Anti-Patterns

### Hardcoding URLs

**Don't:**
\```cfml
return {editUrl: "/users/edit/#user.id#"};
\```

**Do:**
\```cfml
return {editUrl: this.urlFor("users_edit", {id: user.id})};
\```

### Manual Foreign Key Queries

**Don't:**
\```cfml
var comments = Comment::where({post_id: post.id});
\```

**Do:**
\```cfml
var comments = post.comments();
\```
```

## Voice and Tone

### Active Voice

Use active voice, present tense:

**Good:** "The router maps URLs to handler actions."
**Bad:** "URLs are mapped to handler actions by the router."

### Direct Instructions

Use imperative mood for instructions:

**Good:** "Create a new model with `lucli generate model User`."
**Bad:** "You should create a new model..."

### Concise Language

Be direct and concise:

**Good:** "Handlers process requests and return responses."
**Bad:** "Handlers are components that are responsible for processing incoming requests and generating appropriate responses."

## Version Indicators

Mark future features clearly:

```markdown
## Cache Providers

**Status:** Coming in v1.1

Cache providers allow custom caching backends...
```

## AI-Friendly Enhancements

### Clear Hierarchy

Maintain strict heading hierarchy for machine parsing.

### Explicit Types

Always specify types in examples:

```cfml
public struct function index() {
    var users = User::all(); // returns array of User objects
    return {users: users}; // returns struct
}
```

### Decision Trees

Use Mermaid flowcharts for decision-making processes in `/ai/decision-trees/`.

### Graph Traversal

Include bidirectional "Related Topics" links to enable graph traversal.

## Accessibility

### Alt Text

Provide descriptive alt text for images (when added):

```markdown
![Fuse request lifecycle diagram](images/lifecycle.png)
```

### Descriptive Links

Use descriptive link text, avoid "click here":

**Good:** "See the [Routing Guide](guides/routing.md)."
**Bad:** "Click [here](guides/routing.md) for routing info."

## File Naming

- Use kebab-case: `models-orm.md`, `eager-loading.md`
- Be descriptive: `from-wheels.md` not `wheels.md`
- Match content: filename should indicate document purpose

## Common Terms

### Consistent Terminology

Use these terms consistently:

- **Handler** (not controller)
- **Action** (not method, when referring to handler actions)
- **Model** (not entity, record)
- **Migration** (not schema change)
- **Validation** (not validator, when referring to rules)
- **Relationship** (not association, when referring to model relationships)
- **Eager loading** (not preloading)
- **DI Container** or **Container** (not IoC container)

### Framework Names

- **Fuse** (never FUSE or fuse in prose)
- **lucli** (never Lucli or LUCLI)
- **Lucee** (never LUCEE or lucee)
- **CFML** (all caps)

## Examples

### Method Documentation Template

```markdown
## methodName()

Description of what the method does.

**Signature:**
\```cfml
public returnType function methodName(
    required type param1,
    type param2 = defaultValue
)
\```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| param1    | type | Yes      | -       | Description |
| param2    | type | No       | default | Description |

**Returns:** `returnType` - Description of return value

**Throws:**
- `ExceptionType` - When this exception is thrown

**Example:**
\```cfml
// app/handlers/Users.cfc
var result = methodName(param1, param2);
\```

**Related Methods:**
- [otherMethod()](#othermethod)
```

### Guide Document Template

```markdown
# Guide Title

Brief introduction to the topic.

## Basic Usage

Simple examples showing basic usage.

\```cfml
// app/models/Example.cfc
component extends="fuse.orm.ActiveRecord" {
    // ...
}
\```

## Common Patterns

Real-world patterns and use cases.

### Pattern Name

Description and example.

## Advanced Usage

Complex scenarios and edge cases.

## Anti-Patterns

Common mistakes and how to avoid them.

### Anti-Pattern Name

**Don't:**
\```cfml
// Wrong way
\```

**Do:**
\```cfml
// Right way
\```

## Related Topics

- [Related Guide](path/to/guide.md)
- [Another Guide](path/to/other.md)
```

## Quality Checklist

Before publishing documentation:

- [ ] File path comments on all code examples
- [ ] Complete component declarations
- [ ] Realistic variable names
- [ ] Proper heading hierarchy (H1 → H2 → H3)
- [ ] Code blocks have language tags
- [ ] Cross-references use relative paths
- [ ] Related Topics section included
- [ ] Anti-Patterns section included (for guides)
- [ ] Examples are runnable
- [ ] Consistent terminology
- [ ] Active voice, present tense
- [ ] Concise, clear language
