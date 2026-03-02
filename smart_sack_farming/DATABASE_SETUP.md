# Smart Sack Farming - Database Setup Guide

## Prerequisites

- A [Supabase](https://supabase.com) account (free tier works)
- Your Flutter project configured with `supabase_flutter` package

---

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in (GitHub login recommended)
2. Click **New Project**
3. Name it `smart-sack-farming`
4. Set a strong database password (save it somewhere safe)
5. Choose your preferred region
6. Wait 2-5 minutes for provisioning

---

## Step 2: Run the Database Schema

1. In your Supabase dashboard, go to **SQL Editor** → **New Query**
2. Open the file `supabase_schema.sql` from this project
3. Copy the **entire** contents and paste into the SQL Editor
4. Click **Run**

This single script creates everything:

| Table                | Purpose                                   |
|----------------------|-------------------------------------------|
| `profiles`           | User profiles (auto-created on signup)    |
| `farming_projects`   | Crop farming projects per user            |
| `expenses`           | Expenses linked to farming projects       |
| `equipment`          | Equipment rental marketplace              |
| `calamity_reports`   | Disaster/calamity damage reports          |
| `production_reports` | Harvest yield and quality reports         |

Plus:
- **Row Level Security (RLS)** on all tables
- **Auto-create profile** trigger on user signup
- **Auto-update `updated_at`** triggers on all tables
- **Storage bucket** (`farm-images`) for image uploads

---

## Step 3: Get Your API Credentials

1. Go to **Settings → API** in the Supabase dashboard
2. Copy your **Project URL** (e.g., `https://abcdefg.supabase.co`)
3. Copy your **Anon/Public Key**

---

## Step 4: Configure the Flutter App

Update `lib/config/supabase_config.dart`:

```dart
const String SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
const String SUPABASE_ANON_KEY = 'your-anon-key-here';
```

---

## Step 5: Run the App

```bash
cd smart_sack_farming
flutter pub get
flutter run -d chrome
```

---

## Database Schema Overview

```
profiles
├── id (UUID, PK, references auth.users)
├── email, full_name, role, phone, address
└── created_at, updated_at

farming_projects
├── id (UUID, PK)
├── user_id (FK → auth.users)
├── crop_type, area, planting_date, harvest_date
├── revenue, status
└── created_date, created_at, updated_at

expenses
├── id (UUID, PK)
├── project_id (FK → farming_projects)
├── user_id (FK → auth.users)
├── category, description, amount, date, phase
└── created_at, updated_at

equipment
├── id (UUID, PK)
├── owner_id (FK → auth.users)
├── name, description, category
├── daily_rental_price, quantity, condition
├── is_available, image_url, owner_name, owner_phone
└── created_at, updated_at

calamity_reports
├── id (UUID, PK)
├── user_id (FK → auth.users)
├── type, severity, date, area_affected
├── affected_crops, description, damage_estimate
├── farmer_name, image_url, status
└── created_at, updated_at

production_reports
├── id (UUID, PK)
├── user_id (FK → auth.users)
├── crop_type, area, planting_date, harvest_date
├── yield, yield_unit, quality_rating, notes
└── created_at, updated_at
```

---

## RLS Policy Summary

| Table                | SELECT          | INSERT / UPDATE / DELETE |
|----------------------|-----------------|--------------------------|
| `profiles`           | Own only        | Own only                 |
| `farming_projects`   | Own only        | Own only                 |
| `expenses`           | Own only        | Own only                 |
| `equipment`          | **All** (public)| Own only (by `owner_id`) |
| `calamity_reports`   | Own only        | Own only                 |
| `production_reports` | Own only        | Own only                 |

---

## Troubleshooting

| Problem                | Solution                                              |
|------------------------|-------------------------------------------------------|
| "Auth error"           | Verify Anon Key in `supabase_config.dart`             |
| "Connection refused"   | Verify `SUPABASE_URL` is correct                      |
| "RLS policy error"     | Re-run the full `supabase_schema.sql`                 |
| "Table not found"      | Ensure the SQL script ran without errors              |
| "Permission denied"    | User may not be authenticated; check auth flow        |
| Profile not created    | Check the `on_auth_user_created` trigger exists       |

---

For more help: [Supabase Docs](https://supabase.com/docs)
