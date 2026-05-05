// Supabase configuration.
// Preferred: pass values at build/run-time with `--dart-define` to avoid
// checking credentials into source control. Example:
// flutter run -d chrome --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
// Fallback: the values below are used if no dart-define is provided.
const String SUPABASE_URL = String.fromEnvironment(
	'SUPABASE_URL',
	defaultValue: 'https://nnjltgdkuppyesunkpfz.supabase.co',
);

const String SUPABASE_ANON_KEY = String.fromEnvironment(
	'SUPABASE_ANON_KEY',
	defaultValue:
			'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5uamx0Z2RrdXBweWVzdW5rcGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODU4MjYsImV4cCI6MjA4Nzc2MTgyNn0.zx4AVHlCLioIjuFKShM761oYhYdZBYoyk44jJUjSgKM',
);

bool supabaseConfigLooksValid() {
	try {
		final uri = Uri.parse(SUPABASE_URL);
		if (!uri.hasScheme || uri.host.isEmpty) return false;
		if (SUPABASE_ANON_KEY.length < 20) return false;
		return true;
	} catch (_) {
		return false;
	}
}
