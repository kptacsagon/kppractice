# Supabase Database Setup - Quick Reference

## 🚀 QUICK START

### 1️⃣ Create Account & Project
- Go to https://supabase.com
- Sign up with GitHub
- Create new project: `smart-sack-farming`
- Wait 5-10 minutes for initialization

### 2️⃣ Copy Your Credentials
- Go to **Settings → API**
- Copy **Project URL** 
- Copy **Anon Key**

### 3️⃣ Run All SQL (Copy-Paste Everything Below)
- Go to **SQL Editor → New Query**
- Copy all code from **SECTION A** below
- Paste & Run

### 4️⃣ Set Security Policies
- Copy all code from **SECTION B** below
- Paste in SQL Editor & Run

### 5️⃣ Update Your App
- Update `lib/config/supabase_config.dart` with your credentials
- Update `lib/main.dart` (see SECTION C)

---

## 📋 SECTION A: DATABASE TABLES
**Copy & Paste ALL of this into Supabase SQL Editor:**

```sql
-- Create Farming Projects Table
CREATE TABLE farming_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  crop_type VARCHAR(100) NOT NULL,
  area DECIMAL(10, 2) NOT NULL,
  planting_date TIMESTAMP NOT NULL,
  harvest_date TIMESTAMP NOT NULL,
  revenue DECIMAL(15, 2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_date TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(id, user_id)
);

CREATE INDEX idx_farming_projects_user_id ON farming_projects(user_id);
CREATE INDEX idx_farming_projects_status ON farming_projects(status);

-- Create Expenses Table
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES farming_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  description TEXT,
  amount DECIMAL(12, 2) NOT NULL,
  date TIMESTAMP NOT NULL,
  phase VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_project_id ON expenses(project_id);
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_date ON expenses(date);

-- Create Equipment Table
CREATE TABLE equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  daily_rental_price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  condition VARCHAR(50) NOT NULL DEFAULT 'good',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_equipment_owner_id ON equipment(owner_id);
CREATE INDEX idx_equipment_category ON equipment(category);

-- Create Calamity Reports Table
CREATE TABLE calamity_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR(100) NOT NULL,
  severity VARCHAR(20) NOT NULL,
  date TIMESTAMP NOT NULL,
  area_affected DECIMAL(10, 2),
  affected_crops VARCHAR(255),
  description TEXT,
  damage_estimate DECIMAL(15, 2),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_calamity_reports_user_id ON calamity_reports(user_id);
CREATE INDEX idx_calamity_reports_type ON calamity_reports(type);
CREATE INDEX idx_calamity_reports_date ON calamity_reports(date);

-- Create Production Reports Table
CREATE TABLE production_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  crop_type VARCHAR(100) NOT NULL,
  area DECIMAL(10, 2) NOT NULL,
  planting_date TIMESTAMP NOT NULL,
  harvest_date TIMESTAMP NOT NULL,
  yield DECIMAL(12, 2) NOT NULL,
  yield_unit VARCHAR(50) NOT NULL DEFAULT 'kg',
  quality_rating INTEGER CHECK (quality_rating >= 1 AND quality_rating <= 5),
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_production_reports_user_id ON production_reports(user_id);
CREATE INDEX idx_production_reports_crop_type ON production_reports(crop_type);
```

---

## 🔐 SECTION B: SECURITY POLICIES (RLS)
**Copy & Paste ALL of this into Supabase SQL Editor:**

```sql
-- Farming Projects Policies
CREATE POLICY "Users can view their own projects" ON farming_projects
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own projects" ON farming_projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own projects" ON farming_projects
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own projects" ON farming_projects
  FOR DELETE USING (auth.uid() = user_id);

-- Expenses Policies
CREATE POLICY "Users can view their own expenses" ON expenses
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own expenses" ON expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own expenses" ON expenses
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own expenses" ON expenses
  FOR DELETE USING (auth.uid() = user_id);

-- Equipment Policies
CREATE POLICY "Users can view all equipment" ON equipment
  FOR SELECT USING (true);
CREATE POLICY "Users can insert their own equipment" ON equipment
  FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update their own equipment" ON equipment
  FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete their own equipment" ON equipment
  FOR DELETE USING (auth.uid() = owner_id);

-- Calamity Reports Policies
CREATE POLICY "Users can view their own calamity reports" ON calamity_reports
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own calamity reports" ON calamity_reports
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own calamity reports" ON calamity_reports
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own calamity reports" ON calamity_reports
  FOR DELETE USING (auth.uid() = user_id);

-- Production Reports Policies
CREATE POLICY "Users can view their own production reports" ON production_reports
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own production reports" ON production_reports
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own production reports" ON production_reports
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own production reports" ON production_reports
  FOR DELETE USING (auth.uid() = user_id);
```

---

## ⚙️ SECTION C: FLUTTER APP CONFIGURATION

### Step 1: Update `lib/config/supabase_config.dart`
**Copy & Paste:**
```dart
// TODO: Replace with your Supabase credentials from https://supabase.com
// Instructions:
// 1. Create a Supabase project at https://supabase.com
// 2. Go to Settings > API
// 3. Copy your Project URL and Anon Key
// 4. Paste them here

const String SUPABASE_URL = 'https://your-project.supabase.co';
const String SUPABASE_ANON_KEY = 'your-anon-key-here';
```

### Step 2: Update `lib/main.dart`
**Copy & Paste this at the top:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';
```

**Replace your `main()` function with:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService().initialize(
    supabaseUrl: SUPABASE_URL,
    supabaseAnonKey: SUPABASE_ANON_KEY,
  );
  
  runApp(const MyApp());
}
```

---

## 📌 QUICK PASTE ORDER:
1. **SQL Tables** → Paste Section A in Supabase SQL Editor → Run
2. **Security Policies** → Paste Section B in Supabase SQL Editor → Run
3. **Config File** → Update `supabase_config.dart` with your credentials
4. **Main File** → Update `lib/main.dart` with initialization code
5. **Run** → `flutter pub get` then `flutter run -d chrome`

---

## 🧪 TEST IT:
```bash
flutter run -d chrome
```
If no errors → **Database Connected! ✅**

---

## 📚 USAGE IN YOUR APP:

**Create Farming Project:**
```dart
final repo = FarmingProjectRepository();
await repo.createProject(project, userId: user.id);
```

**Add Expense:**
```dart
final repo = FarmingProjectRepository();
await repo.addExpense(expense, projectId: projectId, userId: userId);
```

**Get All Equipment:**
```dart
final repo = EquipmentRepository();
final equipment = await repo.getAllEquipment();
```

**Sign In User:**
```dart
await SupabaseService().signInWithEmail(email, password);
final currentUser = SupabaseService().currentUser;
```

---

## ❌ TROUBLESHOOTING:

| Problem | Solution |
|---------|----------|
| "Auth error" | Check Anon Key is correct in supabase_config.dart |
| "Connection refused" | Verify SUPABASE_URL is correct |
| "RLS policy error" | Make sure Section B SQL was executed |
| "Tables not found" | Make sure Section A SQL was executed completely |

---

For more help: [Supabase Docs](https://supabase.com/docs)
