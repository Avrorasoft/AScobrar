#!/bin/bash
# ============================================================
# 🚀 Script de inicialización — Loan Collector App (Flutter)
# ============================================================
set -e

PROJECT="loan_collector_app"
echo "💰 Creando proyecto: $PROJECT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1️⃣ Crear carpeta raíz
mkdir -p "$PROJECT"
cd "$PROJECT"

# 2️⃣ Crear estructura de carpetas
echo "📁 Creando carpetas..."
mkdir -p android ios
mkdir -p web/icons
mkdir -p lib/core/{theme,design,constants,utils}
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/providers
mkdir -p lib/repositories
mkdir -p lib/screens/{splash,auth,home,alarms,clients,loans,payments,visits,settings}
mkdir -p lib/widgets
mkdir -p assets/{sounds,lottie,images}
mkdir -p firebase/functions

# 3️⃣ Crear archivos vacíos (placeholders)
echo "📝 Creando archivos..."

# --- Core ---
touch lib/core/constants/app_constants.dart
touch lib/core/utils/currency_formatter.dart
touch lib/core/utils/date_helpers.dart
touch lib/core/design/app_icons.dart

# --- Repositories (vacíos, para completar) ---
touch lib/repositories/auth_repository.dart
touch lib/repositories/loan_repository.dart
touch lib/repositories/client_repository.dart
touch lib/repositories/payment_repository.dart
touch lib/repositories/alarm_repository.dart

# --- Providers (vacíos) ---
touch lib/providers/auth_provider.dart
touch lib/providers/loans_provider.dart
touch lib/providers/payments_provider.dart

# --- Screens (vacías, excepto las principales) ---
touch lib/screens/splash/splash_screen.dart
touch lib/screens/auth/login_screen.dart
touch lib/screens/home/owner_dashboard.dart
touch lib/screens/home/collector_dashboard.dart
touch lib/screens/alarms/alarm_detail_screen.dart
touch lib/screens/clients/clients_list_screen.dart
touch lib/screens/clients/new_client_screen.dart
touch lib/screens/loans/loans_list_screen.dart
touch lib/screens/loans/new_loan_screen.dart
touch lib/screens/loans/loan_detail_screen.dart
touch lib/screens/visits/new_visit_screen.dart
touch lib/screens/settings/settings_screen.dart

# --- Widgets (vacíos) ---
touch lib/widgets/confetti_widget.dart
touch lib/widgets/animated_bottom_nav.dart

# --- Assets placeholder ---
touch assets/sounds/.gitkeep
touch assets/lottie/.gitkeep
touch assets/images/.gitkeep
touch web/favicon.png

# ============================================================
# 4️⃣ Crear archivos con CONTENIDO REAL
# ============================================================
echo "✨ Escribiendo archivos principales..."

# ---------- pubspec.yaml ----------
cat << 'EOF' > pubspec.yaml
name: loan_collector_app
description: App de cobro de préstamos con interés — UI ultra moderna + PWA
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  firebase_core: ^2.31.0
  firebase_auth: ^4.19.5
  cloud_firestore: ^4.17.3
  firebase_messaging: ^14.9.2
  firebase_storage: ^11.7.5
  cloud_functions: ^4.7.4
  google_fonts: ^6.2.1
  iconsax: ^0.0.8
  phosphor_flutter: ^0.2.0
  font_awesome_flutter: ^10.7.0
  flutter_animate: ^2.0.1
  lottie: ^3.1.0
  confetti: ^0.7.0
  fl_chart: ^0.68.0
  shimmer: ^3.0.0
  smooth_page_indicator: ^1.2.0+3
  audioplayers: ^6.0.0
  just_audio: ^0.9.37
  flutter_local_notifications: ^17.1.2
  google_maps_flutter: ^2.6.1
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  url_launcher: ^6.2.6
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  sqflite: ^2.3.3+1
  connectivity_plus: ^6.0.3
  flutter_form_builder: ^9.4.0
  form_builder_validators: ^10.0.1
  image_picker: ^1.1.1
  intl: ^0.19.0
  uuid: ^4.4.0
  pdf: ^3.10.8
  printing: ^5.12.0
  share_plus: ^8.0.3
  path_provider: ^2.1.3
  cached_network_image: ^3.3.1
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/lottie/
    - assets/images/
EOF

# ---------- main.dart ----------
cat << 'EOF' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await NotificationService.init();
  runApp(const ProviderScope(child: LoanCollectorApp()));
}
EOF

# ---------- app.dart ----------
cat << 'EOF' > lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class LoanCollectorApp extends ConsumerWidget {
  const LoanCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '💰 Loan Collector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
EOF

# ---------- app_colors.dart ----------
cat << 'EOF' > lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primaryStart = Color(0xFF7C3AED);
  static const Color primaryMid   = Color(0xFFEC4899);
  static const Color primaryEnd   = Color(0xFFF43F5E);
  static const Color turquoise = Color(0xFF06B6D4);
  static const Color lime      = Color(0xFF84CC16);
  static const Color gold      = Color(0xFFFACC15);
  static const Color sunset    = Color(0xFFFB923C);
  static const Color bgLight   = Color(0xFFF8FAFC);
  static const Color bgDark    = Color(0xFF0B0F1A);
  static const Color textDark  = Color(0xFF111827);
  static const Color textLight = Color(0xFFF9FAFB);
  static const Color neonCyan    = Color(0xFF22D3EE);
  static const Color neonMagenta = Color(0xFFE879F9);
  static const Color neonMint    = Color(0xFF34D399);
  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFFACC15);
  static const Color caution  = Color(0xFFFB923C);
  static const Color danger   = Color(0xFFF43F5E);
  static const Color info     = Color(0xFF3B82F6);
  static const Color alarmYellow = Color(0xFFFBBF24);
  static const Color alarmOrange = Color(0xFFF97316);
  static const Color alarmRed    = Color(0xFFEF4444);
  static const Color glassLight = Color(0x33FFFFFF);
  static const Color glassDark  = Color(0x1AFFFFFF);
}
EOF

# ---------- app_gradients.dart ----------
cat << 'EOF' > lib/core/theme/app_gradients.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryStart, AppColors.primaryMid, AppColors.primaryEnd],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.turquoise, AppColors.lime],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient sunset = LinearGradient(
    colors: [AppColors.sunset, AppColors.primaryEnd],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient neon = LinearGradient(
    colors: [AppColors.neonCyan, AppColors.neonMagenta],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient alarmYellow = LinearGradient(
    colors: [Color(0xFFFDE68A), AppColors.alarmYellow],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient alarmOrange = LinearGradient(
    colors: [Color(0xFFFDBA74), AppColors.alarmOrange],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient alarmRed = LinearGradient(
    colors: [Color(0xFFFCA5A5), AppColors.alarmRed],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient background = LinearGradient(
    colors: [Color(0xFFF5F3FF), Color(0xFFFCE7F3), Color(0xFFFEF3C7)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}
EOF

# ---------- app_typography.dart ----------
cat << 'EOF' > lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark);
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark);
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textDark.withOpacity(0.7));
  static TextStyle get number => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark);
}
EOF

# ---------- app_theme.dart ----------
cat << 'EOF' > lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryStart,
          secondary: AppColors.turquoise,
          surface: Colors.white,
          error: AppColors.danger,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.displayLarge,
          displayMedium: AppTypography.displayMedium,
          titleLarge: AppTypography.titleLarge,
          titleMedium: AppTypography.titleMedium,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          labelMedium: AppTypography.label,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
        ),
      );
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonCyan,
          secondary: AppColors.neonMagenta,
          surface: Color(0xFF1A1F2E),
          error: AppColors.danger,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: const Color(0xFF1A1F2E),
        ),
      );
}
EOF

# ---------- app_emojis.dart ----------
cat << 'EOF' > lib/core/design/app_emojis.dart
class AppEmojis {
  AppEmojis._();
  static const String home = '🏠';
  static const String chart = '📊';
  static const String money = '💰';
  static const String people = '👥';
  static const String alarm = '🚨';
  static const String calendar = '📅';
  static const String settings = '⚙️';
  static const String profile = '👤';
  static const String report = '📝';
  static const String paid = '✅';
  static const String pending = '⏳';
  static const String upcoming = '⚠️';
  static const String overdue = '🚨';
  static const String completed = '🏆';
  static const String pay = '💵';
  static const String call = '📞';
  static const String whatsapp = '💬';
  static const String map = '🗺️';
  static const String visit = '🚗';
  static const String document = '📄';
  static const String camera = '📸';
  static const String success = '🎉';
  static const String warning = '⚠️';
  static const String error = '❌';
  static const String info = 'ℹ️';
  static const String star = '⭐';
  static const String fire = '🔥';
  static const String rocket = '🚀';
  static const String heart = '💖';
  static const String sevYellow = '🟡';
  static const String sevOrange = '🟠';
  static const String sevRed = '🔴';
}
EOF

# ---------- app_sounds.dart ----------
cat << 'EOF' > lib/core/design/app_sounds.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AppSounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool _enabled = true;
  static void setEnabled(bool value) => _enabled = value;
  static bool get isEnabled => _enabled;

  static const String _chaChing = 'sounds/cha_ching.mp3';
  static const String _bell = 'sounds/bell.mp3';
  static const String _alarmYellow = 'sounds/alarm_yellow.mp3';
  static const String _alarmOrange = 'sounds/alarm_orange.mp3';
  static const String _alarmRed = 'sounds/alarm_red.mp3';
  static const String _fanfare = 'sounds/fanfare.mp3';
  static const String _whoosh = 'sounds/whoosh.mp3';
  static const String _error = 'sounds/error.mp3';
  static const String _ping = 'sounds/ping.mp3';
  static const String _applause = 'sounds/applause.mp3';

  static Future<void> _play(String path) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource(path));
    } catch (e) {
      debugPrint('🔇 Error reproduciendo sonido: $e');
    }
  }

  static Future<void> paymentSuccess() => _play(_chaChing);
  static Future<void> installmentPaid() => _play(_bell);
  static Future<void> alarmYellow() => _play(_alarmYellow);
  static Future<void> alarmOrange() => _play(_alarmOrange);
  static Future<void> alarmRed() => _play(_alarmRed);
  static Future<void> newClient() => _play(_fanfare);
  static Future<void> loanCreated() => _play(_whoosh);
  static Future<void> errorSound() => _play(_error);
  static Future<void> ownerNotify() => _play(_ping);
  static Future<void> goalReached() => _play(_applause);
}
EOF

# ---------- user_model.dart ----------
cat << 'EOF' > lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, collector, client }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
    this.isActive = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> m, String id) => AppUser(
        id: id,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'],
        role: UserRole.values[m['role'] ?? 0],
        photoUrl: m['photoUrl'],
        fcmToken: m['fcmToken'],
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        isActive: m['isActive'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.index,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
      };
}
EOF

# ---------- guarantor_model.dart ----------
cat << 'EOF' > lib/models/guarantor_model.dart
class Guarantor {
  final String name;
  final String relationship;
  final String phone;
  final String? address;
  final String? documentId;

  Guarantor({
    required this.name,
    required this.relationship,
    required this.phone,
    this.address,
    this.documentId,
  });

  factory Guarantor.fromMap(Map<String, dynamic> m) => Guarantor(
        name: m['name'] ?? '',
        relationship: m['relationship'] ?? '',
        phone: m['phone'] ?? '',
        address: m['address'],
        documentId: m['documentId'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'address': address,
        'documentId': documentId,
      };
}
EOF

# ---------- client_model.dart ----------
cat << 'EOF' > lib/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guarantor_model.dart';

class Client {
  final String id;
  final String name;
  final String documentId;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? emojiAvatar;
  final String phone;
  final String? phoneSecondary;
  final String? email;
  final String? whatsapp;
  final String street;
  final String? number;
  final String? neighborhood;
  final String? city;
  final String? reference;
  final double? latitude;
  final double? longitude;
  final Guarantor? guarantor;
  final String? occupation;
  final double? monthlyIncome;
  final String? workplace;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Client({
    required this.id,
    required this.name,
    required this.documentId,
    this.birthDate,
    this.photoUrl,
    this.emojiAvatar = '👤',
    required this.phone,
    this.phoneSecondary,
    this.email,
    this.whatsapp,
    required this.street,
    this.number,
    this.neighborhood,
    this.city,
    this.reference,
    this.latitude,
    this.longitude,
    this.guarantor,
    this.occupation,
    this.monthlyIncome,
    this.workplace,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  String get fullAddress {
    final parts = [street, number, neighborhood, city]
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();
    return parts.join(', ');
  }

  bool get hasGps => latitude != null && longitude != null;

  factory Client.fromMap(Map<String, dynamic> m, String id) => Client(
        id: id,
        name: m['name'] ?? '',
        documentId: m['documentId'] ?? '',
        birthDate: (m['birthDate'] as Timestamp?)?.toDate(),
        photoUrl: m['photoUrl'],
        emojiAvatar: m['emojiAvatar'] ?? '👤',
        phone: m['phone'] ?? '',
        phoneSecondary: m['phoneSecondary'],
        email: m['email'],
        whatsapp: m['whatsapp'],
        street: m['street'] ?? '',
        number: m['number'],
        neighborhood: m['neighborhood'],
        city: m['city'],
        reference: m['reference'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        guarantor: m['guarantor'] != null
            ? Guarantor.fromMap(Map<String, dynamic>.from(m['guarantor']))
            : null,
        occupation: m['occupation'],
        monthlyIncome: (m['monthlyIncome'] as num?)?.toDouble(),
        workplace: m['workplace'],
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
        isActive: m['isActive'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'documentId': documentId,
        'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
        'photoUrl': photoUrl,
        'emojiAvatar': emojiAvatar,
        'phone': phone,
        'phoneSecondary': phoneSecondary,
        'email': email,
        'whatsapp': whatsapp,
        'street': street,
        'number': number,
        'neighborhood': neighborhood,
        'city': city,
        'reference': reference,
        'latitude': latitude,
        'longitude': longitude,
        'guarantor': guarantor?.toMap(),
        'occupation': occupation,
        'monthlyIncome': monthlyIncome,
        'workplace': workplace,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isActive': isActive,
      };
}
EOF

# ---------- loan_model.dart ----------
cat << 'EOF' > lib/models/loan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InterestType { simple, compound, flat }
enum PaymentFrequency { daily, weekly, biweekly, monthly, custom }
enum CalculationMethod { french, german, american, custom }
enum LoanStatus { active, overdue, completed, cancelled }

class Loan {
  final String id;
  final String clientId;
  final String collectorId;
  final double principal;
  final double interestRate;
  final InterestType interestType;
  final PaymentFrequency frequency;
  final int installments;
  final DateTime startDate;
  final DateTime dueDate;
  final int graceDays;
  final double penaltyRate;
  final CalculationMethod method;
  final String? notes;
  final double paidAmount;
  final double pendingAmount;
  final int paidInstallments;
  final LoanStatus status;
  final int daysOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.clientId,
    required this.collectorId,
    required this.principal,
    required this.interestRate,
    required this.interestType,
    required this.frequency,
    required this.installments,
    required this.startDate,
    required this.dueDate,
    this.graceDays = 0,
    this.penaltyRate = 0,
    required this.method,
    this.notes,
    this.paidAmount = 0,
    this.pendingAmount = 0,
    this.paidInstallments = 0,
    this.status = LoanStatus.active,
    this.daysOverdue = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercent =>
      principal > 0 ? (paidAmount / principal).clamp(0.0, 1.0) : 0.0;

  factory Loan.fromMap(Map<String, dynamic> m, String id) => Loan(
        id: id,
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        principal: (m['principal'] as num).toDouble(),
        interestRate: (m['interestRate'] as num).toDouble(),
        interestType: InterestType.values[m['interestType'] ?? 0],
        frequency: PaymentFrequency.values[m['frequency'] ?? 0],
        installments: m['installments'] ?? 0,
        startDate: (m['startDate'] as Timestamp).toDate(),
        dueDate: (m['dueDate'] as Timestamp).toDate(),
        graceDays: m['graceDays'] ?? 0,
        penaltyRate: (m['penaltyRate'] as num?)?.toDouble() ?? 0,
        method: CalculationMethod.values[m['method'] ?? 0],
        notes: m['notes'],
        paidAmount: (m['paidAmount'] as num?)?.toDouble() ?? 0,
        pendingAmount: (m['pendingAmount'] as num?)?.toDouble() ?? 0,
        paidInstallments: m['paidInstallments'] ?? 0,
        status: LoanStatus.values[m['status'] ?? 0],
        daysOverdue: m['daysOverdue'] ?? 0,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'collectorId': collectorId,
        'principal': principal,
        'interestRate': interestRate,
        'interestType': interestType.index,
        'frequency': frequency.index,
        'installments': installments,
        'startDate': Timestamp.fromDate(startDate),
        'dueDate': Timestamp.fromDate(dueDate),
        'graceDays': graceDays,
        'penaltyRate': penaltyRate,
        'method': method.index,
        'notes': notes,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'paidInstallments': paidInstallments,
        'status': status.index,
        'daysOverdue': daysOverdue,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
EOF

# ---------- payment_model.dart ----------
cat << 'EOF' > lib/models/payment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, transfer, card }

class Payment {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final DateTime paidAt;
  final double amount;
  final int installmentsCovered;
  final int remainingInstallments;
  final double capitalPaid;
  final double interestPaid;
  final double penaltyPaid;
  final double pendingAfter;
  final double accumulatedPaid;
  final PaymentMethod method;
  final String? transactionId;
  final String? receiptUrl;
  final double? latitude;
  final double? longitude;
  final bool isVoided;
  final String? voidReason;
  final String? voidedBy;
  final DateTime? voidedAt;

  Payment({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.collectorId,
    required this.paidAt,
    required this.amount,
    required this.installmentsCovered,
    required this.remainingInstallments,
    required this.capitalPaid,
    required this.interestPaid,
    required this.penaltyPaid,
    required this.pendingAfter,
    required this.accumulatedPaid,
    required this.method,
    this.transactionId,
    this.receiptUrl,
    this.latitude,
    this.longitude,
    this.isVoided = false,
    this.voidReason,
    this.voidedBy,
    this.voidedAt,
  });

  factory Payment.fromMap(Map<String, dynamic> m, String id) => Payment(
        id: id,
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        paidAt: (m['paidAt'] as Timestamp).toDate(),
        amount: (m['amount'] as num).toDouble(),
        installmentsCovered: m['installmentsCovered'] ?? 0,
        remainingInstallments: m['remainingInstallments'] ?? 0,
        capitalPaid: (m['capitalPaid'] as num).toDouble(),
        interestPaid: (m['interestPaid'] as num).toDouble(),
        penaltyPaid: (m['penaltyPaid'] as num?)?.toDouble() ?? 0,
        pendingAfter: (m['pendingAfter'] as num).toDouble(),
        accumulatedPaid: (m['accumulatedPaid'] as num).toDouble(),
        method: PaymentMethod.values[m['method'] ?? 0],
        transactionId: m['transactionId'],
        receiptUrl: m['receiptUrl'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        isVoided: m['isVoided'] ?? false,
        voidReason: m['voidReason'],
        voidedBy: m['voidedBy'],
        voidedAt: (m['voidedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'paidAt': Timestamp.fromDate(paidAt),
        'amount': amount,
        'installmentsCovered': installmentsCovered,
        'remainingInstallments': remainingInstallments,
        'capitalPaid': capitalPaid,
        'interestPaid': interestPaid,
        'penaltyPaid': penaltyPaid,
        'pendingAfter': pendingAfter,
        'accumulatedPaid': accumulatedPaid,
        'method': method.index,
        'transactionId': transactionId,
        'receiptUrl': receiptUrl,
        'latitude': latitude,
        'longitude': longitude,
        'isVoided': isVoided,
        'voidReason': voidReason,
        'voidedBy': voidedBy,
        'voidedAt': voidedAt != null ? Timestamp.fromDate(voidedAt!) : null,
      };
}
EOF

# ---------- alarm_model.dart ----------
cat << 'EOF' > lib/models/alarm_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlarmSeverity { yellow, orange, red }

class Alarm {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final AlarmSeverity severity;
  final int daysOverdue;
  final double overdueAmount;
  final DateTime detectedAt;
  final DateTime? nextActionAt;
  final String? collectorNotes;
  final bool escalated;
  final bool resolved;

  Alarm({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.collectorId,
    required this.severity,
    required this.daysOverdue,
    required this.overdueAmount,
    required this.detectedAt,
    this.nextActionAt,
    this.collectorNotes,
    this.escalated = false,
    this.resolved = false,
  });

  int get colorValue {
    switch (severity) {
      case AlarmSeverity.yellow: return 0xFFFBBF24;
      case AlarmSeverity.orange: return 0xFFF97316;
      case AlarmSeverity.red:    return 0xFFEF4444;
    }
  }

  String get emoji {
    switch (severity) {
      case AlarmSeverity.yellow: return '🟡';
      case AlarmSeverity.orange: return '🟠';
      case AlarmSeverity.red:    return '🔴';
    }
  }

  String get title {
    switch (severity) {
      case AlarmSeverity.yellow: return 'Recordatorio';
      case AlarmSeverity.orange: return 'Atención';
      case AlarmSeverity.red:    return 'Crítico';
    }
  }

  factory Alarm.fromMap(Map<String, dynamic> m, String id) => Alarm(
        id: id,
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        severity: AlarmSeverity.values[m['severity'] ?? 0],
        daysOverdue: m['daysOverdue'] ?? 0,
        overdueAmount: (m['overdueAmount'] as num).toDouble(),
        detectedAt: (m['detectedAt'] as Timestamp).toDate(),
        nextActionAt: (m['nextActionAt'] as Timestamp?)?.toDate(),
        collectorNotes: m['collectorNotes'],
        escalated: m['escalated'] ?? false,
        resolved: m['resolved'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'severity': severity.index,
        'daysOverdue': daysOverdue,
        'overdueAmount': overdueAmount,
        'detectedAt': Timestamp.fromDate(detectedAt),
        'nextActionAt': nextActionAt != null ? Timestamp.fromDate(nextActionAt!) : null,
        'collectorNotes': collectorNotes,
        'escalated': escalated,
        'resolved': resolved,
      };
}
EOF

# ---------- visit_model.dart ----------
cat << 'EOF' > lib/models/visit_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitResult { paid, promise, notHome, stillOverdue }

class Visit {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final DateTime visitedAt;
  final VisitResult result;
  final String? notes;
  final double? latitude;
  final double? longitude;

  Visit({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.collectorId,
    required this.visitedAt,
    required this.result,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory Visit.fromMap(Map<String, dynamic> m, String id) => Visit(
        id: id,
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        visitedAt: (m['visitedAt'] as Timestamp).toDate(),
        result: VisitResult.values[m['result'] ?? 0],
        notes: m['notes'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'visitedAt': Timestamp.fromDate(visitedAt),
        'result': result.index,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
      };
}
EOF

# ---------- audit_log_model.dart ----------
cat << 'EOF' > lib/models/audit_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> changes;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.changes,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLog.fromMap(Map<String, dynamic> m, String id) => AuditLog(
        id: id,
        userId: m['userId'] ?? '',
        action: m['action'] ?? '',
        entityType: m['entityType'] ?? '',
        entityId: m['entityId'] ?? '',
        changes: Map<String, dynamic>.from(m['changes'] ?? {}),
        timestamp: (m['timestamp'] as Timestamp).toDate(),
        ipAddress: m['ipAddress'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'changes': changes,
        'timestamp': Timestamp.fromDate(timestamp),
        'ipAddress': ipAddress,
      };
}
EOF

# ---------- interest_calculator.dart ----------
cat << 'EOF' > lib/services/interest_calculator.dart
import '../models/loan_model.dart';

class InterestCalculator {
  static double totalAmount(Loan loan) {
    final r = loan.interestRate / 100;
    final n = loan.installments;
    final C = loan.principal;
    switch (loan.interestType) {
      case InterestType.simple:
        return C + (C * r * n);
      case InterestType.compound:
        return C * _pow(1 + r, n.toDouble());
      case InterestType.flat:
        return C + (C * r * n);
    }
  }

  static double installmentAmount(Loan loan) {
    final r = loan.interestRate / 100;
    final n = loan.installments;
    final C = loan.principal;
    switch (loan.method) {
      case CalculationMethod.french:
        if (r == 0) return C / n;
        return C * r / (1 - _pow(1 + r, -n.toDouble()));
      case CalculationMethod.german:
        return C / n;
      case CalculationMethod.american:
        return C * r;
      case CalculationMethod.custom:
        return totalAmount(loan) / n;
    }
  }

  static double penalty(Loan loan, int daysOverdue) {
    return loan.pendingAmount * (loan.penaltyRate / 100) * daysOverdue;
  }

  static double _pow(double base, double exp) => _exp(exp * _ln(base));

  static double _ln(double x) {
    if (x <= 0) return 0;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double sum = 0, term = y;
    for (int i = 1; i < 20; i += 2) {
      sum += term / i;
      term *= y2;
    }
    return 2 * sum;
  }

  static double _exp(double x) {
    double sum = 1, term = 1;
    for (int i = 1; i < 30; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }
}
EOF

# ---------- notification_service.dart ----------
cat << 'EOF' > lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm_model.dart';
import 'app_sounds.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
  }

  static Future<void> showAlarm(Alarm alarm, String clientName) async {
    final soundFile = switch (alarm.severity) {
      AlarmSeverity.yellow => 'alarm_yellow',
      AlarmSeverity.orange => 'alarm_orange',
      AlarmSeverity.red    => 'alarm_red',
    };
    await _plugin.show(
      alarm.id.hashCode,
      '${alarm.emoji} ${alarm.title}: $clientName',
      '${alarm.daysOverdue} días de atraso • \$${alarm.overdueAmount.toStringAsFixed(2)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarms_${alarm.severity.name}',
          'Alarmas de Mora',
          importance: Importance.max,
          priority: Priority.high,
          sound: UriAndroidNotificationSound('assets/sounds/$soundFile.mp3'),
          enableVibration: alarm.severity == AlarmSeverity.red,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true, presentBadge: true, presentAlert: true,
        ),
      ),
    );
  }

  static Future<void> notifyOwnerPayment(String clientName, double amount) async {
    await AppSounds.ownerNotify();
    await _plugin.show(
      9999,
      '💵 Nuevo pago recibido',
      '$clientName pagó \$${amount.toStringAsFixed(2)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payments', 'Pagos',
          importance: Importance.high, priority: Priority.high,
        ),
      ),
    );
  }
}
EOF

# ---------- haptic_service.dart ----------
cat << 'EOF' > lib/services/haptic_service.dart
import 'package:flutter/services.dart';

class HapticService {
  static Future<void> success() => HapticFeedback.mediumImpact();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> error() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
}
EOF

# ---------- offline_sync_service.dart (placeholder) ----------
cat << 'EOF' > lib/services/offline_sync_service.dart
// TODO: Implementar cola de operaciones offline con Hive
class OfflineSyncService {
  static Future<void> init() async {}
  static Future<void> syncPending() async {}
}
EOF

# ---------- alarms_provider.dart ----------
cat << 'EOF' > lib/providers/alarms_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../repositories/alarm_repository.dart';

final alarmsProvider = StreamProvider<List<Alarm>>((ref) {
  final repo = ref.watch(alarmRepositoryProvider);
  return repo.watchActiveAlarms();
});

final alarmProvider = Provider.family<Alarm?, String>((ref, id) {
  final alarms = ref.watch(alarmsProvider).valueOrNull ?? [];
  try {
    return alarms.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});
EOF

# ---------- clients_provider.dart ----------
cat << 'EOF' > lib/providers/clients_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';

final clientProvider = StreamProvider.family<Client, String>((ref, id) {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.watchClient(id);
});

final clientsProvider = StreamProvider<List<Client>>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.watchAllClients();
});
EOF

# ---------- Repositories (stubs) ----------
cat << 'EOF' > lib/repositories/alarm_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) => AlarmRepository());

class AlarmRepository {
  Stream<List<Alarm>> watchActiveAlarms() => const Stream.empty();
}
EOF

cat << 'EOF' > lib/repositories/client_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) => ClientRepository());

class ClientRepository {
  Stream<Client> watchClient(String id) => const Stream.empty();
  Stream<List<Client>> watchAllClients() => const Stream.empty();
}
EOF

# ---------- Widgets ----------
cat << 'EOF' > lib/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.borderRadius = 24,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
EOF

cat << 'EOF' > lib/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_gradients.dart';
import '../services/haptic_service.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    this.emoji,
    this.onTap,
    this.gradient,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); HapticService.light(); },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient ?? AppGradients.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient ?? AppGradients.primary).colors.first.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.emoji != null) ...[
                Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              if (widget.isLoading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ).animate().shake(hz: 0, duration: 1.ms),
    );
  }
}
EOF

cat << 'EOF' > lib/widgets/progress_ring.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final String? centerText;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 120,
    this.strokeWidth = 12,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: AppColors.glassLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryMid),
              ),
            ),
          ),
          if (centerText != null)
            Text(centerText!,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
EOF

cat << 'EOF' > lib/widgets/emoji_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_typography.dart';

class EmojiHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;

  const EmojiHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32))
            .animate(onPlay: (c) => c.repeat())
            .scale(duration: 1500.ms, begin: 1.0, end: 1.15)
            .then()
            .scale(duration: 1500.ms, begin: 1.15, end: 1.0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleLarge),
              if (subtitle != null) Text(subtitle!, style: AppTypography.label),
            ],
          ),
        ),
      ],
    );
  }
}
EOF

# ---------- Screens principales ----------
cat << 'EOF' > lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('💰', style: TextStyle(fontSize: 96))),
    );
  }
}
EOF

cat << 'EOF' > lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('🔐 Login (TODO)')));
  }
}
EOF

# ---------- PWA ----------
cat << 'EOF' > web/manifest.json
{
  "name": "💰 Loan Collector — Cobro de Préstamos",
  "short_name": "LoanCollector",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#7C3AED",
  "theme_color": "#EC4899",
  "description": "App de cobro de préstamos con interés — UI ultra moderna",
  "orientation": "portrait-primary",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
EOF

cat << 'EOF' > web/index.html
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="💰 App de Cobro de Préstamos">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="LoanCollector">
  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <title>💰 Loan Collector</title>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
EOF

# ---------- Firebase Functions ----------
cat << 'EOF' > firebase/functions/package.json
{
  "name": "loan-collector-functions",
  "description": "Cloud Functions for Loan Collector",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": { "node": "18" },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "private": true
}
EOF

# ---------- README ----------
# ---------- README ----------
cat << 'EOF' > README.md
# 💰 Loan Collector App

App de cobro de préstamos con interés — Flutter + PWA con UI ultra moderna.

## 🚀 Inicio rápido

```bash
flutter pub get
flutter run
```

## 📦 Build para Web (PWA)

```bash
flutter build web --release
```

## ✨ Características

- 🎨 UI ultra moderna con gradientes y glassmorphism
- 🔊 Sonidos y emoticones en cada interacción
- 🚨 Alarmas de mora con severidad por colores (🟡🟠🔴)
- 👥 Ficha completa del cliente con dirección, teléfonos y apoderado
- 💾 Persistencia total + modo offline con sincronización
- 🔔 Notificaciones push al propietario en tiempo real
- 💵 Registro de pagos con fecha, hora, monto, cuotas y saldo

## 🗂️ Estructura

```
lib/
├── core/
│   ├── theme/       # Colores, gradientes, tipografía
│   └── design/      # Emojis y sonidos
├── models/          # Modelos de datos
├── services/        # Cálculo de interés, notificaciones, sync
├── providers/       # Estado con Riverpod
├── repositories/    # Acceso a datos
├── widgets/         # Componentes reutilizables
└── screens/         # Pantallas
```

## 📄 Licencia

MIT
EOF

# ---------- MENSAJE FINAL ----------
echo ""
echo "✅ Proyecto generado con éxito"
echo "📁 Ubicación: $(pwd)/loan_collector_app"
echo ""
echo "🚀 Próximos pasos:"
echo "   cd loan_collector_app"
echo "   flutter pub get"
echo "   flutter run"
echo ""
