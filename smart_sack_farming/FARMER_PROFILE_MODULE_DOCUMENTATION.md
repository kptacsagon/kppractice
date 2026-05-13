# Farmer Profile Module - Complete Implementation Guide

## Overview
The Farmer Profile Module provides a complete view and edit functionality for farmer profiles in the SmartSack Farming system. It displays farmer information organized in clear sections with full edit capabilities, form validation, and real-time updates.

## Architecture

### File Structure
```
smart_sack_farming/
├── lib/
│   ├── screens/
│   │   ├── farmer/
│   │   │   └── farmer_profile_screen.dart      # Main profile display & edit
│   │   ├── home/
│   │   │   └── farmer_dashboard_screen.dart    # Updated with profile navigation
│   │   └── auth/
│   │       └── complete_profile_screen.dart    # Profile completion during signup
│   └── theme/
│       └── app_theme.dart                       # Design system
├── supabase_migration_farmer_profile.sql        # Database schema & RLS
└── pubspec.yaml                                  # Dependencies
```

## Features

### 1. Profile Display
- **Header Section**
  - Profile avatar with user initials
  - Role badge ("FARMER")
  - Full name and email
  - Key stats (Age, Land Size, Member Year)

- **Profile Completion Indicator**
  - Visual progress bar
  - Percentage completion
  - Green indicator for complete profile

- **Organized Sections**
  - Personal Information (Name, Sex, Date of Birth, Address)
  - Contact (Email, Phone)
  - Farm Details (Land Size, Role, Member Since, Age)

### 2. Edit Mode
- Toggle edit mode with "Edit" button
- Form validation on all editable fields
- Date picker for date of birth
- Dropdown selector for sex/gender
- Numeric validation for age and land size

### 3. Data Persistence
- Real-time updates to Supabase database
- Proper error handling and user feedback
- Success/error toast notifications
- Profile complete flag updates

### 4. User Experience
- Clean, modern design matching app theme
- Responsive layout (works on mobile and desktop)
- Smooth transitions between view and edit modes
- Comprehensive form validation
- Loading states and error messages

## UI Components

### FarmerProfileScreen
Main stateful widget that manages:
- Profile data loading from Supabase
- Form state and validation
- Edit mode toggling
- Data updates and synchronization

```dart
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});
  
  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}
```

### Key Methods

#### `_loadProfileData()`
Fetches user profile from Supabase profiles table
```dart
Future<void> _loadProfileData() async {
  final user = Supabase.instance.client.auth.currentUser;
  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
}
```

#### `_updateProfile()`
Saves profile changes to Supabase
```dart
Future<void> _updateProfile() async {
  final updateData = {
    'full_name': _fullNameController.text.trim(),
    'phone': _phoneController.text.trim(),
    'address': _addressController.text.trim(),
    'sex': _selectedSex,
    'age': int.parse(_ageController.text),
    'date_of_birth': _dateOfBirth.toIso8601String(),
    'land_size_ha': double.parse(_landSizeController.text),
    'profile_complete': true,
  };
  
  await Supabase.instance.client
      .from('profiles')
      .update(updateData)
      .eq('id', user.id);
}
```

#### `_getProfileCompletionPercentage()`
Calculates profile completion based on filled fields
```dart
String _getProfileCompletionPercentage() {
  int completed = 0;
  int total = 6; // Required fields
  
  if (profile.full_name != null) completed++;
  if (profile.email != null) completed++;
  if (profile.phone != null) completed++;
  if (profile.address != null) completed++;
  if (profile.age != null) completed++;
  if (profile.date_of_birth != null) completed++;
  
  return '${((completed / total) * 100).toStringAsFixed(0)}%';
}
```

### Build Widgets

#### `_buildProfileField()`
Generic field component for both view and edit modes
- Supports text input, dropdown, and date picker
- Includes form validation
- Disabled state for read-only fields

```dart
Widget _buildProfileField({
  required String label,
  required String value,
  required IconData icon,
  TextEditingController? controller,
  bool enabled = false,
  Function()? onTap,
  String? Function(String?)? validator,
  bool isDropdown = false,
  String? dropdownValue,
  Function(String?)? onDropdownChanged,
})
```

#### `_buildSectionHeader()`
Section title styling with consistent typography
```dart
Widget _buildSectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: Color(0xFF5D846D),
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
  );
}
```

#### `_buildStatItem()`
Stats display in header (Age, Land Size, Member Year)
```dart
Widget _buildStatItem({
  required String label,
  required String value,
})
```

#### `_buildProfileCompletion()`
Progress bar and percentage indicator
```dart
Widget _buildProfileCompletion() {
  final percentage = _getProfileCompletionPercentage();
  final progressValue = double.parse(percentage.replaceAll('%', '')) / 100;
}
```

## Form Validation

### Validation Rules

| Field | Rules | Error Message |
|-------|-------|---------------|
| Full Name | Required, non-empty | "Full name is required" |
| Phone | Required in edit mode | "Phone is required" |
| Address | Required | "Address is required" |
| Age | Valid integer, 13-120 | "Enter valid age (13-120)" |
| Land Size | Valid decimal, positive | "Enter a valid number" |
| Sex | Dropdown selection | N/A (always valid) |
| Date of Birth | Valid date | N/A (date picker enforces) |

### Validation Example
```dart
TextFormField(
  controller: _ageController,
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      final age = int.tryParse(value);
      if (age == null || age < 13 || age > 120) {
        return 'Enter valid age (13-120)';
      }
    }
    return null;
  },
)
```

## Database Schema

### Profiles Table (Supabase)
```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  address TEXT NOT NULL DEFAULT '',
  age SMALLINT CHECK (age IS NULL OR (age >= 13 AND age <= 120)),
  sex TEXT DEFAULT 'Prefer not to say' 
    CHECK (sex IN ('Male', 'Female', 'Prefer not to say')),
  date_of_birth DATE,
  land_size_ha NUMERIC(10, 2) CHECK (land_size_ha IS NULL OR land_size_ha > 0),
  role TEXT NOT NULL DEFAULT 'farmer',
  profile_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### RLS Policies
- Users can view only their own profile (admins can view all)
- Users can update only their own profile (admins can update any)
- New users can insert their own profile
- See `supabase_migration_farmer_profile.sql` for complete policy setup

## Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Primary Dark | Dark Green | #0B2114 |
| Accent | Gold | #C49A50 |
| Success | Light Green | #5FB87B |
| Text Dark | Very Dark Green | #142B1B |
| Text Medium | Muted Green | #5D846D |
| Text Light | Light Gray-Green | #8F9F94 |
| Border | Light | #E5E9E0 |
| Background | Off White | #F6F7F0 |

## Typography

- **Headers**: 20-28px, Bold, #142B1B
- **Section Titles**: 12px, Bold, #5D846D, Uppercase, Letter-spacing 1
- **Field Labels**: 11-12px, Semi-bold, #8F9F94
- **Field Values**: 15-16px, Medium, #2A5239
- **Body Text**: 13-15px, Regular, #5D846D

## Responsive Design

### Desktop (> 1000px)
- Full width content with generous padding
- Side-by-side layout for complex forms

### Tablet (600-1000px)
- Adjusted spacing and padding
- Single column layout
- Touch-friendly button sizes

### Mobile (< 600px)
- Full-width fields
- Optimized spacing
- Larger touch targets
- Bottom-aligned buttons

## Integration Points

### 1. From Dashboard
```dart
// In farmer_dashboard_screen.dart
onPressed: () => _navigateToFeature(context, 'My Profile'),

// Navigation handler
if (featureName == 'My Profile') {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const FarmerProfileScreen()),
  );
}
```

### 2. From Sign-up Flow
```dart
// In complete_profile_screen.dart
_navigateToDashboard() {
  // Shows farmer profile completion screen during first login
}
```

### 3. From Profile Completion Screen
```dart
// In complete_profile_screen.dart
await Supabase.instance.client.rpc(
  'complete_profile',
  params: {
    'p_user_id': user.id,
    'p_address': addressValue,
    'p_age': ageValue,
    // ... other params
  },
);
```

## Error Handling

### Loading State
```dart
if (_isLoading) {
  return Scaffold(
    body: const Center(
      child: CircularProgressIndicator(color: Color(0xFF285437)),
    ),
  );
}
```

### Error Display
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error: $e'),
    backgroundColor: AppTheme.error,
  ),
);
```

### Validation Feedback
```dart
if (!_formKey.currentState!.validate()) {
  return; // Form shows validation errors
}
```

## Usage Example

### Navigate to Profile Screen
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const FarmerProfileScreen(),
  ),
);
```

### Programmatic Edit
```dart
// The screen handles all edit state internally
// Simply navigate to it and user can toggle edit mode
```

## Performance Considerations

1. **Lazy Loading**: Profile data loaded on screen open
2. **Debouncing**: Text field changes don't trigger updates until save
3. **Caching**: Profile data cached in state to minimize API calls
4. **Efficient Queries**: Single SELECT query to load profile
5. **Batch Updates**: All changes sent in single UPDATE query

## Security

1. **RLS Policies**: Database enforces user can only access own profile
2. **Authentication**: Requires Supabase auth session
3. **Authorization**: Admins can view all profiles
4. **Input Validation**: Frontend and backend validation
5. **SQL Injection**: Prevented by Supabase query builder

## Testing Checklist

- [ ] Profile loads correctly for authenticated user
- [ ] Edit mode toggles on/off
- [ ] Form validation works (all field types)
- [ ] Validation errors display correctly
- [ ] Date picker opens and selects dates
- [ ] Sex dropdown shows all options
- [ ] Profile saves successfully
- [ ] Success toast appears after save
- [ ] Error toast appears on failure
- [ ] Completion percentage updates correctly
- [ ] RLS policies prevent unauthorized access
- [ ] Mobile responsiveness works
- [ ] Back button navigates correctly

## Troubleshooting

### Profile Data Not Loading
**Issue**: Blank screen or loading spinner
**Solutions**:
1. Check Supabase connection
2. Verify user is authenticated
3. Ensure profiles table exists with all columns
4. Check RLS policies allow SELECT

### Update Fails Silently
**Issue**: Save button doesn't show error
**Solutions**:
1. Check form validation
2. Verify all required fields have values
3. Check Supabase error logs
4. Ensure RLS policies allow UPDATE

### Date Picker Not Opening
**Issue**: Date field taps don't open picker
**Solutions**:
1. Verify onTap function is not null
2. Check _isEditing flag is true
3. Ensure _pickDateOfBirth() function is defined

## Future Enhancements

1. **Profile Image Upload**
   - Add image picker integration
   - Store in Supabase Storage
   - Display avatar from uploaded image

2. **Bank Details**
   - Securely store bank information
   - Support multiple accounts
   - Encryption at rest

3. **Farm Location Map**
   - Integrate Google Maps
   - Mark farm location
   - Calculate farm area from polygon

4. **Document Upload**
   - Upload farmer license
   - Certificate of land ownership
   - Proof of identity

5. **Activity Timeline**
   - Show profile edit history
   - Display important milestones
   - Audit trail for admin

6. **Profile Sharing**
   - Generate shareable profile link
   - Public profile view option
   - CSV/PDF export

## Support & Maintenance

For issues or questions:
1. Check Supabase logs in dashboard
2. Review Flutter console for errors
3. Verify database schema matches migration
4. Check RLS policies in Supabase dashboard
5. Test with `supabase_migration_farmer_profile.sql`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-05-05 | Initial implementation |
| | | - Profile view/edit |
| | | - Form validation |
| | | - Supabase integration |
| | | - RLS policies |

