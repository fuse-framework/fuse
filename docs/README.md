# Fuse Framework Documentation

**Version:** v1.0
**Status:** In Development

Fuse is a modern CFML framework for Lucee 7, providing ActiveRecord ORM, RESTful routing, DI container, testing framework, and powerful CLI tools.

---

## Quick Navigation

### Getting Started
**Start here if you're new to Fuse.**

1. [Installation](getting-started/installation.md) - Install Fuse and lucli CLI
2. [Quickstart](getting-started/quickstart.md) - Build your first app in 5 minutes
3. [Configuration](getting-started/configuration.md) - Configure database and environment

**Next:** [Core Guides](#core-guides) to learn framework fundamentals.

---

### Core Guides
**Essential guides for building Fuse applications.**

#### Request Handling
- [Routing](guides/routing.md) - RESTful routes and URL generation
- [Handlers](handlers.md) - Request handling and action methods

#### Database & Models
- [Models & ORM](guides/models-orm.md) - ActiveRecord pattern and query building
- [Migrations](guides/migrations.md) - Database schema management
- [Validations](guides/validations.md) - Model validation rules
- [Relationships](guides/relationships.md) - belongsTo, hasMany, hasOne
- [Eager Loading](guides/eager-loading.md) - Prevent N+1 query problems

#### Testing
- [Testing](guides/testing.md) - Test framework and best practices

**Next:** Try the [Blog Tutorial](#tutorials) for hands-on learning.

---

### Tutorials
**Step-by-step tutorials for learning Fuse.**

- [Blog Application](tutorials/blog-application.md) - Build a complete blog with posts, comments, users

Covers: Models, relationships, validations, eager loading, authentication basics.

**Next:** Explore [Advanced Topics](#advanced-topics) or [API Reference](#reference).

---

### Reference
**API and CLI reference documentation.**

- [API Reference](reference/api-reference.md) - Complete API documentation
- [CLI Reference](reference/cli-reference.md) - lucli command reference

**For AI agents:** See [api-reference.yaml](../fuse-planning/api-reference.yaml) for machine-readable API spec.

---

### Advanced Topics
**Deep-dive guides for advanced use cases.**

- [Custom Validators](advanced/custom-validators.md) - Create custom validation rules
- [Performance](advanced/performance.md) - Query optimization and caching
- [Modules](advanced/modules.md) - Fuse module system
- [Views](advanced/views.md) - View rendering (Coming in v1.1)
- [Cache Providers](advanced/cache-providers.md) - Custom cache providers (Coming in v1.1)

---

### Migration Guides
**Migrate from other CFML frameworks.**

- [From Wheels](migration-guides/from-wheels.md) - Migrate from CFWheels
- [From FW/1](migration-guides/from-fw1.md) - Migrate from FW/1
- [From ColdBox](migration-guides/from-coldbox.md) - Migrate from ColdBox

---

### AI Decision Trees
**Flowcharts and decision trees for AI agents and developers.**

- [Creating a Model](ai/decision-trees/creating-a-model.md) - When to use migrations, validations, relationships
- [Querying Data](ai/decision-trees/querying-data.md) - Which query method to use
- [Testing Strategy](ai/decision-trees/testing-strategy.md) - Unit vs integration tests

---

## Common Tasks

### I want to...

**Get started quickly:**
→ [Quickstart Guide](getting-started/quickstart.md)

**Create a model:**
→ [Models & ORM](guides/models-orm.md) | [Decision Tree](ai/decision-trees/creating-a-model.md)

**Define routes:**
→ [Routing Guide](guides/routing.md)

**Handle requests:**
→ [Handlers Guide](handlers.md)

**Validate data:**
→ [Validations Guide](guides/validations.md)

**Optimize queries:**
→ [Eager Loading Guide](guides/eager-loading.md) | [Performance Guide](advanced/performance.md)

**Write tests:**
→ [Testing Guide](guides/testing.md)

**Troubleshoot errors:**
→ Check "Common Errors" sections in each guide | [Error Reference](../fuse-planning/error-reference.md)

---

## Documentation Standards

All documentation follows these conventions:

- **Code-first examples** - Every concept shown with runnable code
- **Full file paths** - All examples include `// app/models/User.cfc` comments
- **Complete components** - Component declarations shown in full
- **Realistic names** - No foo/bar, use domain-appropriate names
- **Progressive complexity** - Simple to advanced
- **Common Errors** - Each guide includes troubleshooting section

See [Style Guide](STYLE_GUIDE.md) for documentation standards.

---

## Contributing

Documentation improvements welcome. See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## Version Notice

This documentation is for Fuse v1.0 (in development). Features marked "Coming in v1.1" are planned but not yet implemented.

---

## Need Help?

- **API Details:** [API Reference](reference/api-reference.md)
- **CLI Commands:** [CLI Reference](reference/cli-reference.md)
- **Common Errors:** Check guide-specific "Common Errors" sections
- **Error Taxonomy:** [Error Reference](../fuse-planning/error-reference.md)
