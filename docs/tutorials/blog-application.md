# Tutorial: Blog Application

Build a complete blog application with Fuse featuring posts, comments, users, authentication, validations, and optimized database queries.

## What You'll Learn

- Project setup and database configuration
- Model creation with migrations
- RESTful routing and handlers
- Model relationships (hasMany, belongsTo)
- Eager loading to prevent N+1 queries
- User authentication basics
- Model validations
- Published/draft post filtering

## What You'll Build

A multi-user blog with:
- Posts with title, body, and publication status
- Nested comments on posts
- User accounts with authentication
- Published/draft post filtering
- Optimized queries for performance

## Prerequisites

- Lucee 7.0+ installed
- `lucli` CLI tool installed
- Basic understanding of CFML
- Familiarity with SQL databases

## Step 1: Project Setup

### Create New Application

Generate a new Fuse application called `blog`:

```bash
lucli new blog --database=h2
cd blog
```

This creates the directory structure and configuration files. We're using H2 (embedded database) for simplicity.

### Verify Database Connection

The generated `config/database.cfc` is pre-configured for H2:

```cfml
// config/database.cfc
component {

    public struct function getConfig() {
        return {
            "development": {
                "type": "h2",
                "name": "blog_dev",
                "database": "./database/blog_dev.h2"
            },
            "test": {
                "type": "h2",
                "name": "blog_test",
                "database": "./database/blog_test.h2"
            }
        };
    }

}
```

### Test Database Connection

Start the server to verify setup:

```bash
lucli serve
```

Visit `http://localhost:8080` - you should see the Fuse welcome page.

## Step 2: Post Model

### Generate Post Model

Create a Post model with title, body, and publication tracking:

```bash
lucli generate model Post title:string body:text published_at:datetime
```

**Generated files:**

`app/models/Post.cfc`:
```cfml
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Relationships and validations will be added later

        return this;
    }

}
```

`database/migrations/20251106150000_CreatePosts.cfc`:
```cfml
component extends="fuse.orm.Migration" {

    function up() {
        var schema = getSchema();
        schema.create("posts", function(table) {
            table.id();
            table.string("title");
            table.text("body");
            table.datetime("published_at").nullable();
            table.timestamps();
        });
    }

    function down() {
        var schema = getSchema();
        schema.drop("posts");
    }

}
```

### Run Migration

Create the posts table:

```bash
lucli migrate
```

**Output:**
```
Running pending migrations...

  Migrated: 20251106150000_CreatePosts.cfc

Migrations complete! (1 migration)
```

### Test CRUD in Console

Test basic CRUD operations interactively:

```bash
lucli console
```

```cfml
// Create a post
post = Post::create({
    title: "First Post",
    body: "This is my first blog post!",
    published_at: now()
});

// Find the post
found = Post::find(post.id);
writeOutput("Title: " & found.title);

// Update the post
post.title = "Updated First Post";
post.save();

// Query posts
allPosts = Post::all().get();
writeOutput("Total posts: " & arrayLen(allPosts));

// Delete the post
post.delete();
```

### Write Model Test

Create a test to verify Post model:

```cfml
// tests/models/PostTest.cfc
component extends="fuse.testing.TestCase" {

    public function testCreatePost() {
        var post = Post::create({
            title: "Test Post",
            body: "Test content",
            published_at: now()
        });

        assertGreaterThan(0, post.id);
        assertEqual("Test Post", post.title);
        assertNotNull(post.created_at);
    }

    public function testFindPost() {
        var created = Post::create({
            title: "Find Me",
            body: "Content",
            published_at: now()
        });

        var found = Post::find(created.id);
        assertEqual(created.id, found.id);
        assertEqual("Find Me", found.title);
    }

    public function testUpdatePost() {
        var post = Post::create({
            title: "Old Title",
            body: "Content",
            published_at: now()
        });

        post.title = "New Title";
        post.save();

        var reloaded = Post::find(post.id);
        assertEqual("New Title", reloaded.title);
    }

    public function testDeletePost() {
        var post = Post::create({
            title: "Delete Me",
            body: "Content",
            published_at: now()
        });

        var id = post.id;
        post.delete();

        assertThrows(function() {
            Post::find(id);
        });
    }

}
```

Run tests:

```bash
lucli test tests/models/PostTest.cfc
```

## Step 3: Posts Handler and Routes

### Generate Posts Handler

Create handler for post CRUD operations:

```bash
lucli generate handler Posts
```

Generates `app/handlers/Posts.cfc` with basic structure.

### Implement Handler Actions

Update the handler with RESTful CRUD actions:

```cfml
// app/handlers/Posts.cfc
component {

    public function init() {
        return this;
    }

    /**
     * GET /posts - List all posts
     */
    public struct function index() {
        var posts = Post::all()
            .orderBy("created_at DESC")
            .get();

        return {
            posts: posts
        };
    }

    /**
     * GET /posts/new - Show create form
     */
    public struct function new() {
        return {
            post: {}
        };
    }

    /**
     * POST /posts - Create new post
     */
    public struct function create() {
        var post = Post::create({
            title: form.title ?: "",
            body: form.body ?: "",
            published_at: structKeyExists(form, "publish") ? now() : javaCast("null", "")
        });

        if (post.id > 0) {
            return {
                success: true,
                message: "Post created successfully",
                post: post
            };
        } else {
            return {
                success: false,
                message: "Failed to create post",
                errors: post.getErrors()
            };
        }
    }

    /**
     * GET /posts/:id - Show single post
     */
    public struct function show(required string id) {
        var post = Post::find(arguments.id);

        return {
            post: post
        };
    }

    /**
     * GET /posts/:id/edit - Show edit form
     */
    public struct function edit(required string id) {
        var post = Post::find(arguments.id);

        return {
            post: post
        };
    }

    /**
     * PUT/PATCH /posts/:id - Update post
     */
    public struct function update(required string id) {
        var post = Post::find(arguments.id);

        var updated = post.update({
            title: form.title ?: post.title,
            body: form.body ?: post.body,
            published_at: structKeyExists(form, "publish") ? now() : post.published_at
        });

        if (updated) {
            return {
                success: true,
                message: "Post updated successfully",
                post: post
            };
        } else {
            return {
                success: false,
                message: "Failed to update post",
                errors: post.getErrors()
            };
        }
    }

    /**
     * DELETE /posts/:id - Delete post
     */
    public struct function destroy(required string id) {
        var post = Post::find(arguments.id);
        post.delete();

        return {
            success: true,
            message: "Post deleted successfully"
        };
    }

}
```

### Configure Routes

Add RESTful routes for posts:

```cfml
// config/routes.cfm

// Home page
router.get("/", "Posts.index", {name: "home"});

// Post resource routes
router.resource("posts");
```

This creates all 7 RESTful routes automatically.

### Test in Browser

Start the server:

```bash
lucli serve
```

**Test endpoints:**

1. **List posts**: `http://localhost:8080/posts`
2. **Show post**: `http://localhost:8080/posts/1`

**Create post via curl:**

```bash
curl -X POST http://localhost:8080/posts \
  -d "title=My First Post" \
  -d "body=This is the content of my first post." \
  -d "publish=true"
```

**Update post:**

```bash
curl -X PUT http://localhost:8080/posts/1 \
  -d "title=Updated Title" \
  -d "body=Updated content"
```

**Delete post:**

```bash
curl -X DELETE http://localhost:8080/posts/1
```

## Step 4: Comment Model and Relationships

### Generate Comment Model

Create Comment model with post relationship:

```bash
lucli generate model Comment body:text post_id:integer:index
```

Generates model and migration with foreign key index.

### Run Migration

Apply the comments table migration:

```bash
lucli migrate
```

### Define Relationships

Update models to define relationships:

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Post has many comments
        this.hasMany("comments");

        return this;
    }

}
```

```cfml
// app/models/Comment.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Comment belongs to post
        this.belongsTo("post");

        return this;
    }

}
```

### Test Relationships

Test the relationships work correctly:

```cfml
// tests/models/PostRelationshipsTest.cfc
component extends="fuse.testing.TestCase" {

    public function testPostHasComments() {
        // Create post
        var post = Post::create({
            title: "Test Post",
            body: "Content",
            published_at: now()
        });

        // Create comments
        Comment::create({
            post_id: post.id,
            body: "First comment"
        });

        Comment::create({
            post_id: post.id,
            body: "Second comment"
        });

        // Fetch post with comments
        var comments = post.comments().get();

        assertCount(2, comments);
        assertEqual("First comment", comments[1].body);
    }

    public function testCommentBelongsToPost() {
        // Create post
        var post = Post::create({
            title: "Test Post",
            body: "Content",
            published_at: now()
        });

        // Create comment
        var comment = Comment::create({
            post_id: post.id,
            body: "Test comment"
        });

        // Fetch parent post
        var parentPost = comment.post().first();

        assertNotNull(parentPost);
        assertEqual(post.id, parentPost.id);
        assertEqual("Test Post", parentPost.title);
    }

    public function testQueryCommentsWithConditions() {
        var post = Post::create({
            title: "Test Post",
            body: "Content",
            published_at: now()
        });

        Comment::create({post_id: post.id, body: "Good comment"});
        Comment::create({post_id: post.id, body: "Bad comment"});

        // Query with conditions
        var goodComments = post.comments()
            .where({body: {like: "%Good%"}})
            .get();

        assertCount(1, goodComments);
        assertEqual("Good comment", goodComments[1].body);
    }

}
```

Run tests:

```bash
lucli test tests/models/PostRelationshipsTest.cfc
```

### Update Posts Handler

Show comments with posts:

```cfml
// app/handlers/Posts.cfc - Update show action
public struct function show(required string id) {
    var post = Post::find(arguments.id);
    var comments = post.comments()
        .orderBy("created_at ASC")
        .get();

    return {
        post: post,
        comments: comments
    };
}
```

## Step 5: Eager Loading to Fix N+1 Queries

### Demonstrate N+1 Problem

Update the index action to load comments for each post:

```cfml
// app/handlers/Posts.cfc - index action (BAD VERSION)
public struct function index() {
    // Load posts - 1 query
    var posts = Post::all()
        .orderBy("created_at DESC")
        .get();

    // For each post, load comments - N queries!
    for (var post in posts) {
        var comments = post.comments().get();  // Separate query per post
        post.commentCount = arrayLen(comments);
    }

    return {posts: posts};
}
```

**Problem:** With 20 posts, this executes 21 queries:
- 1 query for posts
- 20 queries for comments (one per post)

### Fix with Eager Loading

Use `includes()` to load comments efficiently:

```cfml
// app/handlers/Posts.cfc - index action (GOOD VERSION)
public struct function index() {
    // Load posts with comments - 2 queries total
    var posts = Post::all()
        .includes("comments")
        .orderBy("created_at DESC")
        .get();

    // Access comments without additional queries
    for (var post in posts) {
        post.commentCount = arrayLen(post.comments);  // Already loaded!
    }

    return {posts: posts};
}
```

**Solution:** Only 2 queries executed:
1. `SELECT * FROM posts ORDER BY created_at DESC`
2. `SELECT * FROM comments WHERE post_id IN (1,2,3,...)`

### Performance Comparison

Create a test to demonstrate performance improvement:

```cfml
// tests/integration/EagerLoadingPerformanceTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Create test data: 10 posts with 5 comments each
        for (var i = 1; i <= 10; i++) {
            var post = Post::create({
                title: "Post ##i",
                body: "Content ##i",
                published_at: now()
            });

            for (var j = 1; j <= 5; j++) {
                Comment::create({
                    post_id: post.id,
                    body: "Comment ##j on post ##i"
                });
            }
        }
    }

    public function testWithoutEagerLoading() {
        var startTime = getTickCount();

        // Without eager loading - N+1 problem
        var posts = Post::all().get();
        for (var post in posts) {
            var comments = post.comments().get();
        }

        var withoutEagerLoadingTime = getTickCount() - startTime;
        writeOutput("Without eager loading: #withoutEagerLoadingTime#ms<br>");
    }

    public function testWithEagerLoading() {
        var startTime = getTickCount();

        // With eager loading - optimized
        var posts = Post::all().includes("comments").get();
        for (var post in posts) {
            var comments = post.comments;  // Already loaded
        }

        var withEagerLoadingTime = getTickCount() - startTime;
        writeOutput("With eager loading: #withEagerLoadingTime#ms<br>");

        // Eager loading should be faster
        assertTrue(withEagerLoadingTime < 100);  // Should complete quickly
    }

}
```

## Step 6: User Model and Authentication

### Generate User Model

Create User model with authentication fields:

```bash
lucli generate model User name:string email:string:unique password_hash:string
```

### Run Migration

Apply the users table migration:

```bash
lucli migrate
```

### Add User Relationships

Update models to associate posts and comments with users:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // User has many posts
        this.hasMany("posts");

        // User has many comments
        this.hasMany("comments");

        return this;
    }

}
```

### Create Migration for User Associations

Add user_id columns to posts and comments:

```bash
lucli generate migration AddUserIdToPostsAndComments
```

Update the generated migration:

```cfml
// database/migrations/20251106151500_AddUserIdToPostsAndComments.cfc
component extends="fuse.orm.Migration" {

    function up() {
        var schema = getSchema();

        // Add user_id to posts
        schema.table("posts", function(table) {
            table.integer("user_id").nullable().index();
        });

        // Add user_id to comments
        schema.table("comments", function(table) {
            table.integer("user_id").nullable().index();
        });
    }

    function down() {
        var schema = getSchema();

        schema.table("posts", function(table) {
            table.dropColumn("user_id");
        });

        schema.table("comments", function(table) {
            table.dropColumn("user_id");
        });
    }

}
```

Run migration:

```bash
lucli migrate
```

### Update Models with User Relationships

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Post belongs to user (author)
        this.belongsTo("user");

        // Post has many comments
        this.hasMany("comments");

        return this;
    }

}
```

```cfml
// app/models/Comment.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Comment belongs to post
        this.belongsTo("post");

        // Comment belongs to user (author)
        this.belongsTo("user");

        return this;
    }

}
```

### Simple Authentication Helper

Add basic authentication methods to User model:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        this.hasMany("posts");
        this.hasMany("comments");

        return this;
    }

    /**
     * Hash password before saving
     */
    public function setPassword(required string password) {
        // Simple hash (use bcrypt in production)
        this.password_hash = hash(arguments.password, "SHA-256");
    }

    /**
     * Verify password
     */
    public boolean function verifyPassword(required string password) {
        var testHash = hash(arguments.password, "SHA-256");
        return this.password_hash == testHash;
    }

    /**
     * Authenticate user by email and password
     */
    public static function authenticate(required string email, required string password) {
        var user = User::where({email: arguments.email}).first();

        if (isNull(user)) {
            return javaCast("null", "");
        }

        if (user.verifyPassword(arguments.password)) {
            return user;
        }

        return javaCast("null", "");
    }

}
```

### Update Handlers with User Context

Update Posts handler to associate posts with current user:

```cfml
// app/handlers/Posts.cfc - Update create action
public struct function create() {
    // In production, get current user from session
    // For tutorial, we'll create or find a default user
    var user = User::where({email: "demo@example.com"}).first();
    if (isNull(user)) {
        user = User::create({
            name: "Demo User",
            email: "demo@example.com"
        });
        user.setPassword("password123");
        user.save();
    }

    var post = Post::create({
        user_id: user.id,
        title: form.title ?: "",
        body: form.body ?: "",
        published_at: structKeyExists(form, "publish") ? now() : javaCast("null", "")
    });

    if (post.id > 0) {
        return {
            success: true,
            message: "Post created successfully",
            post: post
        };
    } else {
        return {
            success: false,
            message: "Failed to create post",
            errors: post.getErrors()
        };
    }
}
```

### Eager Load Users with Posts

Load post authors efficiently:

```cfml
// app/handlers/Posts.cfc - Update index action
public struct function index() {
    // Eager load comments AND users
    var posts = Post::all()
        .includes(["comments", "user"])
        .orderBy("created_at DESC")
        .get();

    return {posts: posts};
}
```

Now only 3 queries execute:
1. `SELECT * FROM posts`
2. `SELECT * FROM comments WHERE post_id IN (...)`
3. `SELECT * FROM users WHERE id IN (...)`

## Step 7: Validations

### Add Validations to All Models

Define validation rules to ensure data integrity:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Relationships
        this.hasMany("posts");
        this.hasMany("comments");

        // Validations
        this.validates("name", {
            required: true,
            length: {min: 2, max: 100}
        });

        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        this.validates("password_hash", {
            required: true
        });

        return this;
    }

    // ... authentication methods ...

}
```

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Relationships
        this.belongsTo("user");
        this.hasMany("comments");

        // Validations
        this.validates("title", {
            required: true,
            length: {min: 5, max: 200}
        });

        this.validates("body", {
            required: true,
            length: {min: 10}
        });

        this.validates("user_id", {
            required: true,
            numeric: true
        });

        return this;
    }

}
```

```cfml
// app/models/Comment.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        // Relationships
        this.belongsTo("post");
        this.belongsTo("user");

        // Validations
        this.validates("body", {
            required: true,
            length: {min: 2, max: 1000}
        });

        this.validates("post_id", {
            required: true,
            numeric: true
        });

        this.validates("user_id", {
            required: true,
            numeric: true
        });

        return this;
    }

}
```

### Update Handler with Validation

Handle validation errors in create action:

```cfml
// app/handlers/Posts.cfc - Update create action
public struct function create() {
    var user = User::where({email: "demo@example.com"}).first();
    if (isNull(user)) {
        user = User::create({
            name: "Demo User",
            email: "demo@example.com"
        });
        user.setPassword("password123");
        user.save();
    }

    // Attempt to create post
    var post = new Post(getDatasource());
    post.user_id = user.id;
    post.title = form.title ?: "";
    post.body = form.body ?: "";
    post.published_at = structKeyExists(form, "publish") ? now() : javaCast("null", "");

    // Validate before saving
    if (post.isValid()) {
        post.save();

        return {
            success: true,
            message: "Post created successfully",
            post: post
        };
    } else {
        return {
            success: false,
            message: "Validation failed",
            errors: post.getErrors()
        };
    }
}
```

### Test Validations

Create tests to verify validation behavior:

```cfml
// tests/models/PostValidationTest.cfc
component extends="fuse.testing.TestCase" {

    public function testValidPostPasses() {
        var user = User::create({
            name: "Test User",
            email: "test@example.com"
        });
        user.setPassword("password");
        user.save();

        var post = new Post(getDatasource());
        post.user_id = user.id;
        post.title = "Valid Title";
        post.body = "This is valid content that is long enough.";

        assertTrue(post.isValid());
        assertTrue(post.save());
    }

    public function testTitleRequired() {
        var user = User::create({
            name: "Test User",
            email: "valid@example.com"
        });
        user.setPassword("password");
        user.save();

        var post = new Post(getDatasource());
        post.user_id = user.id;
        post.title = "";  // Invalid
        post.body = "Valid content";

        assertFalse(post.isValid());
        assertTrue(post.hasErrors("title"));
    }

    public function testTitleTooShort() {
        var user = User::create({
            name: "Test User",
            email: "test2@example.com"
        });
        user.setPassword("password");
        user.save();

        var post = new Post(getDatasource());
        post.user_id = user.id;
        post.title = "Hi";  // Too short (min 5)
        post.body = "Valid content";

        assertFalse(post.isValid());
        var errors = post.getErrors("title");
        assertTrue(arrayLen(errors) > 0);
    }

    public function testBodyRequired() {
        var user = User::create({
            name: "Test User",
            email: "test3@example.com"
        });
        user.setPassword("password");
        user.save();

        var post = new Post(getDatasource());
        post.user_id = user.id;
        post.title = "Valid Title";
        post.body = "";  // Invalid

        assertFalse(post.isValid());
        assertTrue(post.hasErrors("body"));
    }

}
```

## Step 8: Polish and Final Features

### Add Published/Draft Toggle

Add helper methods to Post model:

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    function init(datasource) {
        super.init(datasource);

        this.belongsTo("user");
        this.hasMany("comments");

        this.validates("title", {
            required: true,
            length: {min: 5, max: 200}
        });

        this.validates("body", {
            required: true,
            length: {min: 10}
        });

        this.validates("user_id", {
            required: true,
            numeric: true
        });

        return this;
    }

    /**
     * Check if post is published
     */
    public boolean function isPublished() {
        return !isNull(this.published_at) && this.published_at <= now();
    }

    /**
     * Check if post is draft
     */
    public boolean function isDraft() {
        return isNull(this.published_at);
    }

    /**
     * Publish the post
     */
    public boolean function publish() {
        this.published_at = now();
        return this.save();
    }

    /**
     * Unpublish the post (make it a draft)
     */
    public boolean function unpublish() {
        this.published_at = javaCast("null", "");
        return this.save();
    }

    /**
     * Scope: Published posts only
     */
    public function scopePublished(query) {
        return arguments.query
            .where({published_at: {notNull: true}})
            .where({published_at: {lte: now()}});
    }

    /**
     * Scope: Draft posts only
     */
    public function scopeDraft(query) {
        return arguments.query.where({published_at: {isNull: true}});
    }

}
```

### Update Homepage to Show Published Posts Only

```cfml
// app/handlers/Posts.cfc - Update index action
public struct function index() {
    // Show only published posts on homepage
    var posts = Post::published()
        .includes(["comments", "user"])
        .orderBy("published_at DESC")
        .get();

    return {posts: posts};
}
```

### Add Timestamp Display Helper

Create helper function for formatting dates:

```cfml
// app/helpers/DateHelper.cfc
component {

    /**
     * Format datetime for display
     */
    public static string function formatDateTime(required date datetime) {
        return dateFormat(arguments.datetime, "mmmm d, yyyy") & " at " & timeFormat(arguments.datetime, "h:mm tt");
    }

    /**
     * Get relative time (e.g., "2 hours ago")
     */
    public static string function timeAgo(required date datetime) {
        var diff = dateDiff("n", arguments.datetime, now());  // Difference in minutes

        if (diff < 1) {
            return "just now";
        } else if (diff < 60) {
            return diff & " minute" & (diff == 1 ? "" : "s") & " ago";
        } else if (diff < 1440) {
            var hours = int(diff / 60);
            return hours & " hour" & (hours == 1 ? "" : "s") & " ago";
        } else {
            var days = int(diff / 1440);
            return days & " day" & (days == 1 ? "" : "s") & " ago";
        }
    }

}
```

### Create Admin Handler for Drafts

Add admin handler to manage draft posts:

```bash
lucli generate handler Admin
```

```cfml
// app/handlers/Admin.cfc
component {

    public function init() {
        return this;
    }

    /**
     * GET /admin/drafts - List draft posts
     */
    public struct function drafts() {
        var drafts = Post::draft()
            .includes(["user"])
            .orderBy("created_at DESC")
            .get();

        return {
            drafts: drafts
        };
    }

    /**
     * POST /admin/posts/:id/publish - Publish a post
     */
    public struct function publish(required string id) {
        var post = Post::find(arguments.id);

        if (post.publish()) {
            return {
                success: true,
                message: "Post published successfully"
            };
        } else {
            return {
                success: false,
                message: "Failed to publish post"
            };
        }
    }

    /**
     * POST /admin/posts/:id/unpublish - Unpublish a post
     */
    public struct function unpublish(required string id) {
        var post = Post::find(arguments.id);

        if (post.unpublish()) {
            return {
                success: true,
                message: "Post unpublished successfully"
            };
        } else {
            return {
                success: false,
                message: "Failed to unpublish post"
            };
        }
    }

}
```

### Add Admin Routes

```cfml
// config/routes.cfm

// Home page
router.get("/", "Posts.index", {name: "home"});

// Post resource routes
router.resource("posts");

// Admin routes
router.get("/admin/drafts", "Admin.drafts", {name: "admin_drafts"});
router.post("/admin/posts/:id/publish", "Admin.publish", {name: "admin_publish"});
router.post("/admin/posts/:id/unpublish", "Admin.unpublish", {name: "admin_unpublish"});
```

### Final Integration Test

Test the complete workflow:

```cfml
// tests/integration/BlogWorkflowTest.cfc
component extends="fuse.testing.TestCase" {

    public function testCompleteWorkflow() {
        // 1. Create user
        var user = User::create({
            name: "John Doe",
            email: "john@example.com"
        });
        user.setPassword("secret123");
        user.save();

        // 2. Create draft post
        var post = Post::create({
            user_id: user.id,
            title: "My First Draft",
            body: "This is a draft post that hasn't been published yet."
        });

        assertTrue(post.isDraft());
        assertFalse(post.isPublished());

        // 3. Verify draft doesn't show in published list
        var publishedPosts = Post::published().get();
        assertCount(0, publishedPosts);

        // 4. Publish the post
        post.publish();

        assertTrue(post.isPublished());
        assertFalse(post.isDraft());

        // 5. Verify post shows in published list
        var publishedPosts = Post::published().get();
        assertCount(1, publishedPosts);

        // 6. Add comments
        var comment1 = Comment::create({
            post_id: post.id,
            user_id: user.id,
            body: "Great post!"
        });

        var comment2 = Comment::create({
            post_id: post.id,
            user_id: user.id,
            body: "Thanks for sharing!"
        });

        // 7. Load post with eager loaded relationships
        var loadedPost = Post::includes(["comments", "user"]).find(post.id);

        assertEqual(2, arrayLen(loadedPost.comments));
        assertEqual("John Doe", loadedPost.user.name);

        // 8. Unpublish post
        loadedPost.unpublish();

        assertTrue(loadedPost.isDraft());

        // 9. Verify post removed from published list
        var publishedPosts = Post::published().get();
        assertCount(0, publishedPosts);
    }

}
```

Run the test:

```bash
lucli test tests/integration/BlogWorkflowTest.cfc
```

## Summary

You've built a complete blog application with:

✅ **Project setup** - Initialized Fuse app with database
✅ **Models** - Created Post, Comment, and User models with migrations
✅ **Handlers** - Implemented RESTful CRUD operations
✅ **Relationships** - Set up hasMany/belongsTo associations
✅ **Eager loading** - Optimized queries to prevent N+1 problems
✅ **Authentication** - Added basic user authentication
✅ **Validations** - Ensured data integrity with validation rules
✅ **Publishing** - Implemented published/draft toggle logic

### Key Concepts Learned

1. **ActiveRecord ORM** - Models map to database tables with automatic CRUD
2. **Migrations** - Version-controlled database schema changes
3. **Relationships** - Express associations between models declaratively
4. **Query optimization** - Use `includes()` to eliminate N+1 queries
5. **Validations** - Protect data integrity at the model layer
6. **Scopes** - Reusable query filters as model methods
7. **RESTful routing** - Conventional URL structure for resources

### Performance Highlights

Without eager loading (N+1 problem):
- 20 posts = 21 queries (1 + 20)
- 100 posts = 101 queries (1 + 100)

With eager loading:
- Any number of posts = 2 queries (posts + comments)
- 10x-50x faster query execution

## Next Steps

Enhance your blog application:

1. **Add views** - Create CFML views for rendering HTML
2. **Implement sessions** - Add real session-based authentication
3. **Add categories** - Create Category model with many-to-many relationships
4. **Image uploads** - Handle file uploads for post images
5. **Pagination** - Paginate long lists of posts
6. **Search** - Add full-text search for posts
7. **Comments moderation** - Add approval workflow for comments
8. **Rich text editor** - Integrate WYSIWYG editor for post body
9. **API endpoints** - Build JSON API for mobile apps
10. **Testing** - Expand test coverage for all features

## Related Topics

- [Models & ORM](../guides/models-orm.md) - Deep dive into ActiveRecord patterns
- [Handlers](../handlers.md) - Advanced handler patterns and lifecycle
- [Routing](../guides/routing.md) - RESTful routing and URL generation
- [Validations](../guides/validations.md) - Comprehensive validation rules
- [Relationships](../guides/relationships.md) - All relationship types explained
- [Eager Loading](../guides/eager-loading.md) - Query optimization strategies
- [Migrations](../guides/migrations.md) - Database schema management
- [Testing](../guides/testing.md) - Testing models, handlers, and integration
