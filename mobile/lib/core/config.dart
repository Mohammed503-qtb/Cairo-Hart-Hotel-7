// API base URL — empty string means relative paths (used when served via Next.js on same origin)
// For mobile/native dev, set via --dart-define=API_BASE=http://localhost:3000
const String apiBase = String.fromEnvironment('API_BASE', defaultValue: '');

const String kCurrencySymbol = 'ر.ي';
const String kDefaultCurrency = 'YER';

String api(String path) {
  if (path.startsWith('http')) return path;
  final base = apiBase.endsWith('/') ? apiBase.substring(0, apiBase.length - 1) : apiBase;
  final p = path.startsWith('/') ? path : '/$path';
  return '$base$p';
}

// WhatsApp default number (overridden by settings from backend)
const String kDefaultWhatsapp = '967700123456';
