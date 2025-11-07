# Spec Requirements: Documentation & Examples

## Initial Description
Documentation & Examples

## Requirements Discussion

### Recommendations Basis

Based on cross-framework analysis (Rails, Laravel, Django) and Fuse's AI-first mission, providing opinionated best recommendations without explicit user answers.

**Framework Context:**
- Fuse is Rails-inspired CFML framework for Lucee 7
- Target audience: Modern CFML devs, Rails/Laravel migrants, AI-assisted developers
- Completed roadmap items #1-13: Core bootstrap, routing, ORM, migrations, testing, CLI tools
- Next item: #14 Documentation & Examples

**Cross-Framework Documentation Patterns:**
- **Rails**: guides.rubyonrails.org - comprehensive guides + API reference, "Getting Started" tutorial builds blog
- **Laravel**: laravel.com/docs - single-page scrollable docs with strong search, example-driven
- **Django**: docs.djangoproject.com - versioned docs, tutorial + topic guides + reference split
- **Common pattern**: Getting started → Guides → API reference → Advanced topics

### Documentation Structure

**Recommended Structure:**

```
/docs
├── /getting-started
│   ├── installation.md
│   ├── quickstart.md
│   └── configuration.md
├── /guides
│   ├── routing.md
│   ├── handlers.md
│   ├── models-orm.md
│   ├── migrations.md
│   ├── validations.md
│   ├── relationships.md
│   ├── eager-loading.md
│   ├── testing.md
│   ├── views.md
│   ├── modules.md
│   └── cli.md
├── /tutorials
│   └── blog-application.md
├── /reference
│   ├── api-reference.md (human-readable from YAML)
│   ├── configuration-reference.md
│   ├── cli-reference.md
│   └── error-reference.md
├── /advanced
│   ├── module-development.md
│   ├── cache-providers.md
│   ├── custom-validators.md
│   └── performance.md
├── /migration-guides
│   ├── from-wheels.md
│   ├── from-fw1.md
│   └── from-coldbox.md
└── README.md (overview + links)
```

**Justification:**
- Rails/Laravel/Django all separate: getting started → topic guides → reference
- Progressive disclosure: quick wins first, depth later
- Migration guides address key persona (Framework Maintainers migrating legacy apps)
- Tutorial reinforces learning through building real app (blog = Rails tradition)

### Documentation Style & Format

**Format:**
- **Markdown** for all docs (GitHub-friendly, AI-parseable, tooling-agnostic)
- **Single repository** (`/docs` in main repo, not separate docs site initially)
- **Versioned** (match Fuse releases, e.g., `/docs/v1.0/`)

**Style Guidelines:**
- **Code-first**: Every concept shows code example immediately
- **Copy-pasteable**: All examples are complete, runnable snippets
- **Convention-explicit**: Always show file paths and naming conventions
- **AI-friendly**: Clear headings, consistent structure, explicit return types in examples
- **Concise**: Rails/Laravel style - get to the point, no fluff

**Example Structure (per doc):**
```markdown
# Topic Title

Brief 1-2 sentence overview.

## Basic Usage

```cfc
// Minimal working example with comments
component extends="fuse.Model" {
  // Convention: table = "users", pk = "id"
}
```

## Common Patterns

### Pattern Name
Code example with explanation

## Advanced Usage

### Advanced Pattern
Code + when to use

## API Reference
Brief method signatures (link to full reference)

## Related Topics
- [Link to related doc]
```

**Justification:**
- Markdown = industry standard, AI tools parse well
- Code-first matches AI-assisted developer persona need for copy-paste accuracy
- Single repo = easier maintenance pre-1.0, can split later
- Rails/Laravel both prioritize "show me the code" over prose

### Content Priorities

**Phase 1: Essential Docs (Minimum Viable Documentation)**

1. **Getting Started Guide** (installation.md, quickstart.md, configuration.md)
   - Install via lucli
   - 5-minute quickstart: new app → generate model → run server
   - Environment config (.env), database setup

2. **Core Guides** (models-orm.md, routing.md, handlers.md, migrations.md)
   - ActiveRecord basics: `User::find(1)`, `where()`, `save()`
   - RESTful routes: `router.resource("users")`
   - Handler CRUD pattern
   - Migration: create/add/remove patterns

3. **Tutorial** (blog-application.md)
   - Build blog: Post model, comments relationship, CRUD handlers, views
   - Rails tradition: tutorial builds blog to teach framework

4. **CLI Reference** (cli-reference.md)
   - All lucli commands: `new`, `generate`, `migrate`, `test`, `routes`, `serve`
   - Generator patterns for AI code gen

**Phase 2: Depth Docs**

5. **Advanced ORM** (relationships.md, eager-loading.md, validations.md)
6. **Testing Guide** (testing.md with factories, assertions, integration tests)
7. **Views & Modules** (views.md, modules.md)

**Phase 3: Advanced & Migration**

8. **Advanced Topics** (module-development.md, performance.md, cache-providers.md)
9. **Migration Guides** (from-wheels.md, from-fw1.md, from-coldbox.md)
10. **API Reference** (generated from existing api-reference.yaml)

**Justification:**
- Phase 1 unblocks new developers immediately (Solo Developer persona: "ship fast")
- Tutorial = proven Rails onboarding pattern
- CLI reference critical for AI-assisted developer persona
- Migration guides address Framework Maintainer persona but lower priority

### Tutorial Application

**Recommendation: Classic Blog Application**

**Scope:**
- **Models**: Post (title, body, published_at), Comment (body, post_id), User (name, email)
- **Relationships**: Post hasMany Comments, Post belongsTo User, Comment belongsTo User
- **Features**: CRUD posts, add comments, user authentication (basic), publish/draft toggle
- **Pages**: Homepage (list posts), post detail, new/edit post form, admin dashboard

**Rationale:**
- Rails canonical tutorial is blog (reinforces "Rails-inspired")
- Teaches: models, relationships, migrations, validations, eager loading, RESTful routes, views
- Relatable domain (everyone understands blog)
- Progressive: start simple (Post CRUD) → add complexity (comments, relationships, auth)

**Tutorial Structure:**
1. Setup: `lucli new blog`
2. First model: Generate Post, migrate, test in REPL
3. CRUD handlers: RESTful routes, create/edit forms
4. Relationships: Add Comment model, `hasMany`/`belongsTo`, display on post page
5. Eager loading: Prevent N+1 queries with `includes()`
6. Users & auth: User model, basic login, associate posts/comments
7. Validations: Required fields, email format
8. Polish: Published/draft logic, timestamps display

**Justification:**
- Django tutorial builds poll app, Rails builds blog - proven pattern
- Covers 80% of framework features in realistic context
- AI developers can use as reference template for generating similar code

### Code Examples Philosophy

**Every Guide Must Include:**

1. **Minimal Example** (first code block)
   - Absolute simplest usage
   - Full component code (not snippets)
   - Shows conventions clearly

2. **Real-World Example** (second code block)
   - Realistic use case
   - Multiple features together
   - Comments explaining choices

3. **Common Patterns Section**
   - Hash-based where: `where({active: true, age: {gte: 18}})`
   - Relationship loading: `User::find(1).posts()`
   - Eager loading: `Post::where({published: true}).includes("comments")`

4. **Anti-Patterns Section** (what NOT to do)
   - N+1 queries example (before/after with `includes()`)
   - Missing validations
   - SQL injection risks (show parameterized alternative)

**Code Example Standards:**
- Always show full file path: `// app/models/User.cfc`
- Always show component declaration: `component extends="fuse.Model" {`
- Always show complete method signatures with types (AI-friendly)
- Use realistic variable names (not `foo`, `bar`)
- Show both static and instance method usage: `User::find(1)` vs `user.save()`

**Justification:**
- AI tools need complete context (full file paths, extends declarations)
- Anti-patterns prevent common mistakes (high support cost if missing)
- Rails guides excel at showing "the Rails way" - Fuse should show "the Fuse way"
- Realistic names improve AI code generation accuracy

### API Reference Approach

**Recommendation: Dual-Format API Documentation**

**1. Machine-Readable (existing):**
- Keep `api-reference.yaml` as source of truth
- AI agents consume directly
- Explicit types, returns, throws, timing

**2. Human-Readable (generate):**
- Generate `/docs/reference/api-reference.md` FROM yaml
- Grouped by module: Models, QueryBuilder, Migrations, Testing, etc.
- Each method shows:
  - Signature with types
  - Description
  - Parameters table
  - Return type
  - Example usage
  - Related methods

**Generation Script:**
- `lucli docs:generate-api-reference` (future CLI command)
- Parses yaml, outputs markdown
- Re-run on yaml changes

**Example Output:**
```markdown
### Model.find()

**Signature:** `static Model find(required numeric id)`

**Description:** Finds a record by primary key. Returns model instance or throws RecordNotFound.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | numeric | Yes | Primary key value |

**Returns:** `Model` instance

**Throws:** `RecordNotFound` if id doesn't exist

**Example:**
```cfc
user = User::find(1);
writeOutput(user.getName());
```

**Related:** `findBy()`, `where()`, `all()`
```

**Justification:**
- Laravel Dusk, Rails API docs follow this pattern (human-friendly generated from structured source)
- Maintains single source of truth (yaml)
- AI agents read yaml, humans read markdown
- Automation prevents docs drift from code

### Documentation Maintenance

**Who Updates:**
- Spec-writer updates relevant guide when implementing roadmap item
- All code changes include doc updates in same PR
- API reference yaml updated with every public method change

**Validation:**
- Code examples are tested (extract to test files)
- Links checked via automated tool
- API reference generation catches yaml errors

**Versioning:**
- Docs version matches Fuse version
- `/docs/v1.0/`, `/docs/v1.1/` folders
- GitHub Pages or simple static site shows latest by default

**Justification:**
- Rails/Laravel enforce "docs with code" in contribution guidelines
- Automated validation prevents broken examples (high cost of inaccurate AI training data)
- Versioned docs critical for frameworks (breaking changes between releases)

### AI-Specific Documentation Enhancements

**Decision Trees (New):**
Create `/docs/ai/decision-trees/` with flowcharts for common tasks:
- `creating-a-model.md`: When to use migration? Validation? Relationships?
- `querying-data.md`: When `find()` vs `where()` vs `includes()`?
- `testing-strategy.md`: Unit vs integration? Factories vs fixtures?

**Code Templates (Existing):**
Reference existing CLI templates in docs:
- "Generator templates are in `/config/templates/` and can be customized"
- Show template structure in module-development.md

**Error Taxonomy (Existing):**
- Cross-reference existing `error-reference.md` in all guides
- Add "Common Errors" section to each guide linking to taxonomy

**Justification:**
- AI-first mission requires machine-decision-making aids
- Decision trees reduce AI hallucination (explicit logic paths)
- Claude/Cursor can traverse decision trees to generate correct code

### Existing Code Reuse

**Similar Documentation Patterns:**
Given Fuse is new framework, no existing Fuse docs exist. However:

**Reference for Structure:**
- CLI generators spec docs: `agent-os/specs/2025-11-06-cli-generators/CLI_USAGE.md`
- Shows good example of Fuse doc style: code-first, explicit paths, examples

**Reference for Content:**
- Roadmap item descriptions contain mini-specs (e.g., "CFC-based Migration base class, Schema builder...")
- Extract these as starting points for guide content

**Template Style:**
- Examine existing generator templates (`config/templates/`) for code style
- Docs examples should match generator output (consistency)

### Visual Assets

**No visual assets provided.**

**Recommendation: Add Diagrams Later**

For initial docs, prioritize text + code. Add diagrams in Phase 2+:
- Architecture diagram (module system, request lifecycle)
- ORM relationship diagrams (hasMany/belongsTo visualization)
- Eager loading strategy flowchart

**Tooling:** Mermaid diagrams in markdown (GitHub renders, AI can generate)

**Justification:**
- Rails/Laravel docs are text-heavy initially, diagrams added later
- Code examples > diagrams for AI training
- Mermaid = markdown-native, version-controllable, AI-generatable

## Requirements Summary

### Functional Requirements

**Documentation Structure:**
- Four-tier hierarchy: Getting Started → Guides → Reference → Advanced
- 20+ markdown files organized by topic
- Tutorial blog application with progressive complexity
- API reference generated from existing yaml

**Content Requirements:**
- Code-first style: every concept shows immediate example
- Complete, copy-pasteable code snippets with file paths
- Anti-patterns section in each guide
- Migration guides from Wheels/FW/1/ColdBox

**AI-Specific Requirements:**
- Decision tree docs for common tasks
- Cross-reference existing api-reference.yaml
- Consistent structure for machine parsing
- Explicit types and return values in all examples

**Maintenance Requirements:**
- Docs updated in same PR as code changes
- Automated example testing
- Versioned docs matching releases

### Reusability Opportunities

**Existing Content to Reference:**
- CLI generator spec docs (`CLI_USAGE.md`, `TEMPLATE_CUSTOMIZATION.md`) for style examples
- Roadmap descriptions for guide starting points
- Existing `api-reference.yaml` as source of truth
- Existing `error-reference.md` for error taxonomy
- Generator templates (`config/templates/`) for consistent code style

**Similar Patterns to Model:**
- Rails guides structure (progressive disclosure)
- Laravel single-page doc style (for web version later)
- Django tutorial approach (build complete app)
- CLI generators documentation style (already established in Fuse)

### Scope Boundaries

**In Scope:**
- Getting started guide (installation, quickstart, configuration)
- Core topic guides (routing, ORM, migrations, testing, CLI)
- Blog tutorial application (complete walkthrough)
- API reference markdown (generated from yaml)
- CLI reference (all commands documented)
- Migration guides (from Wheels/FW/1/ColdBox)
- AI decision trees for common tasks

**Out of Scope (Future Enhancements):**
- Separate documentation website (use GitHub initially)
- Video tutorials or screencasts
- Interactive code examples (REPL embed)
- Multi-language translations
- Advanced architecture diagrams (add later)
- Community contribution guides (comes with 1.0)
- Plugin/extension marketplace docs (no marketplace yet)

### Technical Considerations

**Format & Tooling:**
- Markdown files in `/docs` directory
- Version folders: `/docs/v1.0/`, `/docs/v1.1/`
- Mermaid for diagrams (GitHub-compatible)
- API reference generation script (future CLI command)

**Integration Points:**
- Cross-reference existing `api-reference.yaml` (don't duplicate)
- Link to existing CLI templates in module-development guide
- Reference existing `error-reference.md` in guides

**Testing Strategy:**
- Extract code examples to test files
- Automated link checking
- Example code must run successfully
- API reference generation validates yaml

**AI Optimization:**
- Clear heading hierarchy (H1 → H2 → H3)
- Consistent code block format with language tags
- Explicit "Related Topics" sections for traversal
- Decision trees in flowchart format

**Technology Stack:**
- Pure markdown (no Jekyll, Docusaurus, etc initially)
- GitHub Pages for hosting (later)
- Mermaid for diagrams
- Existing Fuse CLI for generation tooling
