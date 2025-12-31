# Flutter & Supabase: RLS & Relational Queries Explained

This document explains why Supabase relational queries might return empty nested arrays under Row Level Security (RLS) and provides recommended patterns for fetching hierarchical data, especially for anonymous (logged-out) users.

---

### 1. The Problem: Why `select('*, child(*)')` Returns Empty Arrays

You've encountered a common and confusing issue: you have `SELECT` policies for `anon` on both `topics` and `topic_contents`, but `supabase.from('topics').select('*, topic_contents(*)')` returns an empty `topic_contents` array.

**The Root Cause:** Supabase's PostgREST server performs a re-validation of RLS policies when it executes the implicit `LEFT JOIN` for the nested select. A simple policy like `CREATE POLICY "Allow anon select" ON topic_contents FOR SELECT TO anon USING (true)` is often **not sufficient** for nested queries.

PostgREST checks if the `anon` role has permission to select rows from `topic_contents` that are related to the `topics` being selected. Even if both tables are fully readable on their own, the **relationship itself** can be filtered out by this RLS check during the join. This results in the parent objects (`topics`) being returned correctly, but with empty arrays for their children (`topic_contents`).

---

### 2. Solution 1: Separate Queries (Clear, Robust, Recommended for Simple Cases)

This is the most straightforward and easiest-to-debug pattern. It avoids the complexities of RLS on implicit joins.

**Pattern:**
1.  Fetch the parent items.
2.  Collect the IDs of the parents.
3.  Fetch the child items where the foreign key is in the list of parent IDs.
4.  (Optional) Stitch the data together on the client-side.

**Example: Fetching topics for a unit, then their contents.**

```dart
// Step 1: Fetch all topics for a given unit
final topicsResponse = await supabase
    .from('topics')
    .select('id, title')
    .eq('unit_id', yourUnitId);
    
final List<Topic> topics = topicsResponse.map((data) => Topic.fromMap(data)).toList();

if (topics.isEmpty) {
  // No topics, so no content to fetch
  return;
}

// Step 2: Collect the IDs of the fetched topics
final topicIds = topics.map((topic) => topic.id).toList();

// Step 3: Fetch all contents related to those topics in a single query
final contentsResponse = await supabase
    .from('topic_contents')
    .select('*')
    .in_('topic_id', topicIds);

final List<TopicContent> contents = contentsResponse.map((data) => TopicContent.fromMap(data)).toList();

// Now you have a list of all topics and a separate list of all their contents.
// You can display them grouped by topic in your UI.
// For example, create a Map<int, List<TopicContent>>
final contentsByTopicId = <int, List<TopicContent>>{};
for (var content in contents) {
  (contentsByTopicId[content.topicId] ??= []).add(content);
}

// Now you can build your UI:
// For each topic in `topics`, find its content in `contentsByTopicId[topic.id]`
```

-   **Pros:** Explicit, predictable, and easy to debug. You can check the result of each query.
-   **Cons:** Requires two separate network requests. For deeply nested data, this can become inefficient.

---

### 3. Solution 2: Database Functions (RPC) (Performant & Secure for Complex Views)

For complex data aggregation (e.g., getting a week's worth of outcomes, contents, and videos all at once), a database function is the best practice.

**Pattern:**
1.  Create a PostgreSQL function in your database that takes the necessary parameters (e.g., `unit_id`, `week_no`).
2.  Define the function with `SECURITY DEFINER`. This makes the function run with the privileges of the user who *defined* it (usually the `postgres` admin), bypassing the caller's RLS policies *inside the function*.
3.  Inside the function, perform all the necessary `JOIN`s to build the exact data structure you need. The RLS is bypassed here, so the joins work as expected.
4.  Return the data in a well-defined shape, often as JSON.
5.  In your Flutter app, make a single `.rpc()` call to this function.

Your application **already uses this best practice** with the `get_weekly_curriculum` function. This is an excellent, production-quality pattern. The issues you faced with it were related to bugs in the SQL logic itself (like referencing deleted tables), not the pattern.

**Conceptual Example:**
```sql
-- In a Supabase migration file or SQL editor
CREATE OR REPLACE FUNCTION get_unit_with_contents(p_unit_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
-- SECURITY DEFINER is the key! It bypasses the caller's RLS for the query inside.
SECURITY DEFINER
AS $$
BEGIN
  -- We can still check the user's role if we want to add extra security rules
  -- For public content, we might not need this.
  -- IF auth.role() <> 'anon' AND auth.role() <> 'authenticated' THEN
  --   RAISE EXCEPTION 'Permission denied';
  -- END IF;

  RETURN (
    SELECT jsonb_build_object(
      'id', u.id,
      'title', u.title,
      'topics', (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', t.id,
            'title', t.title,
            'contents', (
              SELECT jsonb_agg(tc.*)
              FROM topic_contents tc
              WHERE tc.topic_id = t.id
            )
          )
        )
        FROM topics t
        WHERE t.unit_id = u.id
      )
    )
    FROM units u
    WHERE u.id = p_unit_id
  );
END;
$$;
```

---

### 4. Summary & Recommendations

-   **Common Mistake:** Relying on nested selects (`select('*, children(*)')`) for public content under RLS. It's convenient but often fails silently.
-   **Common Mistake:** Forgetting to apply a `SELECT` policy to **all** tables involved in a query, including join tables (e.g., `unit_grades`).

#### **Recommended Pattern for Your App:**

Your app's hierarchy is: Grades → Lessons → Units → Topics → Contents.

1.  **Grades Screen:** Fetch all active grades. A simple `select` is fine.
    ```dart
    supabase.from('grades').select('*').eq('is_active', true);
    ```
2.  **Lessons Screen (for a Grade):** Fetch all active lessons related to a `grade_id`. Here, a separate query is also robust.
    ```dart
    // Fetch lesson_grades, then fetch the lessons themselves.
    final lessonGrades = await supabase.from('lesson_grades').select('lesson_id').eq('grade_id', grade.id);
    final lessonIds = lessonGrades.map((lg) => lg['lesson_id']).toList();
    final lessons = await supabase.from('lessons').select('*').in_('id', lessonIds).eq('is_active', true);
    ```
3.  **Outcomes/Content Screen (for a week):** This is a complex view that aggregates data from many tables. **Continue using the RPC (`get_weekly_curriculum`) pattern.** It is the correct, most performant, and most secure approach for this screen. The key is to ensure the SQL inside the function is correct.

By favoring separate queries for simple hierarchical lists and RPC functions for complex views, your application will be more robust, easier to debug, and performant.
