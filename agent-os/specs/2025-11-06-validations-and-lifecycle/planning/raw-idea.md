# Raw Idea: Validations & Lifecycle

**Feature Name**: Validations & Lifecycle

**Feature Description**:
Validations & Lifecycle — Validator component with validates() DSL in models, built-in validators (required/email/unique/length/format), custom validator support, validation error collection, lifecycle callbacks (beforeSave/afterSave/beforeCreate/afterCreate/beforeDelete/afterDelete) with registration system

**Context**:
This is for the Fuse framework, a CFML/Lucee 7 framework. This is item #9 on the roadmap. Items 1-8 have been completed:
1. Bootstrap Core & DI Container
2. Routing & Event System
3. Cache & View Rendering
4. Query Builder Foundation
5. ActiveRecord Base & CRUD
6. Schema Builder & Migrations
7. ORM Relationships
8. Smart Eager Loading

The framework already has:
- ActiveRecord base class with CRUD operations (save, update, delete)
- Query builder and model builder
- Relationship system with eager loading
- Event system with interceptor points
