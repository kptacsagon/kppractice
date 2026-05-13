# Farmer Profile Setup - Migration Guide

## Overview
This migration sets up the farmer profile completion screen with proper Supabase database schema, Row-Level Security (RLS) policies, and a helper RPC function.

## Files
- `supabase_migration_farmer_profile.sql` - Complete SQL migration script

## What Gets Created/Updated

### 1. **Profiles Table Columns**
The `profiles` table gets the following columns:
- `address` (text, required) - Farmer's address/location
- `age` (smallint) - Farmer's age (13-120)
- `sex` (text) - Dropdown: Male / Female / Prefer not to say
- `date_of_birth` (date) - Farmer's date of birth
- `land_size_ha` (numeric) - Land size in hectares (optional, must be positive)
- `profile_complete` (boolean, default: false) - Marks if profile is complete
- `updated_at` (timestamp) - Last update timestamp

### 2. **Row-Level Security (RLS) Policies**
Four policies are created:
1. **Users can view their own profile** - Users see only their own profile (admins can see all)
2. **Users can update their own profile** - Users edit only their own profile
3. **Admins can view all profiles** - Admins view any profile
4. **Admins can update any profile** - Admins edit any profile
5. **Enable insert for authenticated users** - New users can create their profile

### 3. **complete_profile() RPC Function**
A secure database function that:
- Updates all profile fields at once
- Validates user authorization
- Sets `profile_complete = true` on success
- Returns JSON response with success/error messages
- Includes comprehensive error handling

**Function Signature:**
```sql
complete_profile(
  p_user_id uuid,
  p_address text,
  p_age smallint,
  p_sex text,
  p_date_of_birth date,
  p_land_size_ha numeric
) RETURNS json
```

### 4. **Data Constraints**
- Age must be between 13 and 120 (or NULL)
- Sex must be: 'Male', 'Female', or 'Prefer not to say'
- Land size must be positive (or NULL)

### 5. **Indexes**
For performance optimization:
- Index on `role` column for RLS checks
- Index on `profile_complete` for filtering incomplete profiles

## How to Apply

### Option 1: Via Supabase Dashboard (Recommended)
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **SQL Editor** → **New Query**
4. Copy the contents of `supabase_migration_farmer_profile.sql`
5. Paste and click **Run**

### Option 2: Via Supabase CLI
```bash
supabase db push
```

### Option 3: Manual via psql
```bash
psql -h <host> -U postgres -d postgres -f supabase_migration_farmer_profile.sql
```

## Testing the Migration

### 1. Test RLS Policies
```sql
-- As a regular user (should see only their own profile)
SELECT * FROM profiles WHERE id = auth.uid();

-- As an admin (should see all profiles)
SELECT * FROM profiles;
```

### 2. Test complete_profile() Function
```sql
-- Call the function
SELECT complete_profile(
  auth.uid(),
  'Cabadbad, Bukidnon',
  25,
  'Male',
  '2001-05-05'::date,
  1.5
);
```

### 3. Expected Response
```json
{
  "success": true,
  "message": "Profile completed successfully",
  "profile": {
    "id": "user-uuid",
    "email": "user@example.com",
    "full_name": "Juan Dela Cruz",
    "role": "farmer",
    "address": "Cabadbad, Bukidnon",
    "age": 25,
    "sex": "Male",
    "date_of_birth": "2001-05-05",
    "land_size_ha": 1.5,
    "profile_complete": true,
    "updated_at": "2026-05-05T..."
  }
}
```

## Flutter Integration

The `complete_profile_screen.dart` has been updated to call the new RPC function:

```dart
final response = await Supabase.instance.client.rpc(
  'complete_profile',
  params: {
    'p_user_id': user.id,
    'p_address': addressValue,
    'p_age': ageValue,
    'p_sex': sexValue,
    'p_date_of_birth': dateValue,
    'p_land_size_ha': landSizeValue,
  },
);
```

## Rollback

To revert this migration:
```sql
-- Drop the function
DROP FUNCTION IF EXISTS public.complete_profile(uuid, text, smallint, text, date, numeric);

-- Drop RLS policies (they'll be reapplied automatically on next migration)
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.profiles;

-- Remove constraints
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_sex;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_age;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_land_size;

-- Drop indexes
DROP INDEX IF EXISTS idx_profiles_role;
DROP INDEX IF EXISTS idx_profiles_profile_complete;
```

## Troubleshooting

### Column Already Exists
The migration uses `ADD COLUMN IF NOT EXISTS` so it's safe to run multiple times.

### Permission Denied
Ensure you're running with a Supabase admin account or as the database owner.

### RLS Policy Conflicts
The migration drops existing policies before creating new ones. If you've customized policies, back them up first.

### RPC Function Issues
Check:
1. The user exists in `auth.users`
2. The user has a corresponding row in `profiles`
3. All required parameters are provided
4. Check the response JSON for error messages

## Security Notes

✅ **What's Secure:**
- RLS prevents users from viewing/editing others' profiles
- RPC function validates authorization
- Age and land size constraints prevent invalid data
- Sex enum restricts to specific values

⚠️ **Additional Considerations:**
- Enable MFA on admin accounts
- Monitor RPC function logs for failed attempts
- Regularly audit profile_complete status
- Consider rate-limiting on RPC calls in production

## Support

For issues or questions:
1. Check Supabase logs: **Supabase Dashboard** → **Logs**
2. Enable query debugging in Flutter: `Supabase.instance.client.rest.addRequestMeta(...)`
3. Review RLS policies: **Supabase Dashboard** → **Database** → **Policies**
