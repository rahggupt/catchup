# Fix Login 400 Error

## Error
```
POST https://qgvmyntagfukrodafzfc.supabase.co/auth/v1/token?grant_type=password 400 (Bad Request)
```

## Common Causes & Solutions

### 1. Email Not Confirmed ⚠️
**Most Common Issue**

**Check:** Go to Supabase Dashboard → Authentication → Users
- Look for your email
- Check if "Email Confirmed" is ✅ or ❌

**Fix:**
1. Go to: https://qgvmyntagfukrodafzfc.supabase.co
2. Click **Authentication** → **Users**
3. Find your user
4. Click the **three dots** → **Send Magic Link** or **Confirm Email**

OR

In SQL Editor, run:
```sql
-- Confirm all users (for development)
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
```

### 2. Email Confirmation Required (Disable for Testing)

**Fix:** Disable email confirmation requirement:
1. Go to **Authentication** → **Providers** → **Email**
2. Scroll to **Email confirmation**
3. **UNCHECK** "Enable email confirmations"
4. Click **Save**

### 3. Wrong Credentials

**Fix:** Reset your password or create a new account

**Reset Password:**
```sql
-- In Supabase SQL Editor, verify user exists:
SELECT email, email_confirmed_at, created_at 
FROM auth.users 
WHERE email = 'your-email@example.com';
```

**Create Test User:**
```sql
-- Create a confirmed test user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'test@example.com',
  crypt('Test123!', gen_salt('bf')),
  NOW(),
  '{"first_name": "Test", "last_name": "User"}'::jsonb,
  NOW(),
  NOW()
);
```

### 4. Auth Rate Limiting

If you've tried logging in many times, wait 5 minutes and try again.

### 5. Check Auth Settings

**Go to:** Authentication → Policies

**Ensure RLS is NOT blocking auth:**
```sql
-- Check if auth tables have restrictive RLS
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'auth';

-- If there are policies on auth schema, this might be the issue
-- Auth schema should NOT have RLS enabled
```

## Quick Test

### Option 1: Create New Test Account
1. Click "Sign Up" in your app
2. Use email: `test@test.com`
3. Password: `Test123!`
4. Complete signup

Then in Supabase SQL Editor:
```sql
-- Immediately confirm the email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'test@test.com';
```

### Option 2: Use Existing Account
1. In Supabase → Authentication → Users
2. Find your user
3. Click three dots → "Send Magic Link"
4. Check your email and click the link
5. Then try login again

## Debug in Browser Console

Add this to see the exact error:

When you try to login, open Browser Console (F12) and look for:
- The error message details
- Status code
- Response body

Common error messages:
- `Invalid login credentials` → Wrong email/password
- `Email not confirmed` → Need to confirm email
- `User not found` → Account doesn't exist

## Recommended: Disable Email Confirmation for Development

**Fastest solution for testing:**

1. **Supabase Dashboard** → **Authentication** → **Providers** → **Email**
2. **Uncheck** "Enable email confirmations"
3. **Save**
4. **Delete your user** and **sign up again**

This way you can test without email confirmation hassle!

## Still Not Working?

Share these details:
1. Browser console error message (full text)
2. Have you successfully logged in before?
3. Did you just create this account?
4. Is email confirmed in Supabase dashboard?

