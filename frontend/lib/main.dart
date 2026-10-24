import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'state/auth_provider.dart';
import 'state/farm_provider.dart';
import 'state/farming_workflow_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/farm_selection_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/soil_test_screen.dart';
import 'screens/crop_recommendation_screen.dart';
import 'screens/yield_prediction_screen.dart';
import 'screens/fertilizer_screen.dart';
import 'screens/irrigation_screen.dart';
import 'screens/disease_detection_screen.dart';
import 'screens/market_intelligence_screen.dart';
import 'screens/profit_estimator_screen.dart';
import 'screens/digital_diary_screen.dart';
import 'core/api_client.dart';
import 'screens/decision_support_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/weather_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const YieldCraftApp());
}

class YieldCraftApp extends StatelessWidget {
  const YieldCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..checkSession(),
        ),
        ChangeNotifierProvider<FarmProvider>(
          create: (_) => FarmProvider(),
        ),
        ChangeNotifierProvider<FarmingWorkflowProvider>(
          create: (_) => FarmingWorkflowProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'YieldCraft AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/auth': (_) => const AuthScreen(),
          '/farms': (_) => const FarmSelectionScreen(),
          '/home': (_) => const HomeDashboardScreen(),
          '/soil_test': (_) => const SoilTestScreen(),
          '/crop_recommendation': (_) => const CropRecommendationScreen(),
          '/yield_prediction': (_) => const YieldPredictionScreen(),
          '/fertilizer': (_) => const FertilizerScreen(),
          '/irrigation': (_) => const IrrigationScreen(),
          '/disease': (_) => const DiseaseDetectionScreen(),
          '/market': (_) => const MarketIntelligenceScreen(),
          '/profit': (_) => const ProfitEstimatorScreen(),
          '/diary': (_) => const DigitalDiaryScreen(),
          '/decision_support': (_) => const DecisionSupportScreen(),
          '/assistant': (_) => const AiAssistantScreen(),
          '/weather': (_) => const WeatherDetailScreen(),
        },
      ),
    );
  }
}
