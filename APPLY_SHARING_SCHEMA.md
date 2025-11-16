# Apply Collection Sharing Schema

## Important: Run This SQL First

Before using the collection sharing features, you must apply the sharing schema to your Supabase database.

### Steps:

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file: `database/collection_sharing_schema.sql`
4. Copy the entire contents
5. Paste into Supabase SQL Editor
6. Click **Run**

### What This Creates:

- **`collection_members` table**: Tracks users who have access to collections (owners, editors, viewers)
- **`collection_invites` table**: Tracks pending/accepted/rejected invitations
- **Shareable tokens**: Adds `shareable_token` and `share_enabled` fields to collections table
- **RLS Policies**: Security policies for member access
- **SQL Functions**:
  - `generate_shareable_token()`: Creates unique tokens for sharing
  - `accept_collection_invite()`: Processes invite acceptance

### Verify Installation:

Run this query to check if schema is applied:

```sql
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'collection_members'
) as members_exists,
EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'collection_invites'
) as invites_exists;
```

Both should return `true`.

### Also Apply Stats Triggers:

For automatic stat updates, also run:

```
database/triggers/update_collection_stats.sql
```

This ensures article counts, chat counts, and contributor counts stay accurate automatically.

### Troubleshooting:

If you get errors about existing tables:
1. The schema may already be partially applied
2. Check which tables exist
3. Comment out the parts already created
4. Run the remaining parts

If you get RLS policy errors:
1. First drop existing policies if they conflict
2. Then create the new ones
3. Or use the `DROP POLICY IF EXISTS` commands in the script

