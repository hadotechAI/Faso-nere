// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'core/app_config.dart'; // unused
import 'screens/landing_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'core/app_state.dart';
import 'core/app_colors.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Erreur initialisation Firebase: $e");
  }

  // Détection auto : émulateur (10.0.2.2) ou téléphone (IP du PC sur le Wi‑Fi)
  await api.loadSettings();

  // Initialisation des notifications
  await notificationService.initialize();

  // Demande des permissions notifications (Android + iOS)
  final permissionGranted = await notificationService.requestPermissions();
  print('Permission notifications accordée : $permissionGranted');
  if (kDebugMode) {
    print('🔗 API URL : ${api.baseUrl}');
  }

  // Configuration de l'orientation et du style de la barre d'état
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  

  runApp(const FasoNereApp());
}

class FasoNereApp extends StatelessWidget {
  const FasoNereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isDark = appState.isDarkMode;
        final bgColor = AppColors.bg;
        return MaterialApp(
          title: 'Faso Nere',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF5A623),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            fontFamily: 'Roboto',
            useMaterial3: true,
            scaffoldBackgroundColor: bgColor,
            appBarTheme: AppBarTheme(
              backgroundColor: bgColor,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.white),
              titleTextStyle: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bg,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.gold,
                  width: 1.5,
                ),
              ),
              hintStyle: TextStyle(color: AppColors.grey),
            ),
          ),
          home: UpgradeAlert(
            showIgnore: false, // Force l'utilisateur à mettre à jour
            showLater: false,
            barrierDismissible: false, // Empêche de fermer la pop-up en cliquant à côté
            upgrader: Upgrader(
              durationUntilAlertAgain: Duration.zero,
              debugLogging: kDebugMode,
              languageCode: 'fr',
              messages: UpgraderMessages(code: 'fr'),
              storeController: UpgraderStoreController(
                onAndroid: () => UpgraderAppcastStore(
                  appcastURL: 'https://faso-nere-backend-kxzb.onrender.com/api/appcast.xml',
                ),
                oniOS: () => UpgraderAppcastStore(
                  appcastURL: 'https://faso-nere-backend-kxzb.onrender.com/api/appcast.xml',
                ),
              ),
            ),
            child: const LandingScreen(),
          ),
        );
      },
    );
  }
}