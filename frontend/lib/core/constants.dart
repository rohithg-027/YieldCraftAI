class AppConstants {
  static const String appName = 'YieldCraft AI';
  static const String appTagline = 'Smart Digital Farming & Profit Optimization';
  static const String appVersion = '1.0.0';

  // Default API base URLs:
  // - Desktop (Windows/Mac/Linux) or Web: http://127.0.0.1:8000
  // - Android Emulator: http://10.0.2.2:8000
  // - Physical Phone (USB with ADB reverse or Desktop): http://127.0.0.1:8000
  // - Physical Phone (Wi-Fi LAN): http://10.119.12.218:8000
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String localLanBaseUrl = 'http://10.119.12.218:8000';
  static const String renderCloudBaseUrl = 'https://yieldcraft-ai.onrender.com';

  static const List<String> indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  static const List<String> soilTypes = [
    'Alluvial', 'Black', 'Clay', 'Laterite', 'Loamy', 'Red', 'Sandy'
  ];

  static const List<String> growthStages = [
    'Seedling', 'Vegetative', 'Flowering', 'Fruiting', 'Harvest'
  ];

  static const List<String> seasons = [
    'Kharif', 'Rabi', 'Whole Year', 'Summer', 'Autumn', 'Winter'
  ];

  static const List<String> supportedCrops = [
    'Rice', 'Maize', 'Chickpea', 'Kidneybeans', 'Pigeonpeas', 'Mothbeans',
    'Mungbean', 'Blackgram', 'Lentil', 'Pomegranate', 'Banana', 'Mango',
    'Grapes', 'Watermelon', 'Muskmelon', 'Apple', 'Orange', 'Papaya',
    'Coconut', 'Cotton', 'Jute', 'Coffee', 'Wheat'
  ];

  /// Agronomically derives the standard dynamic soil pH based on classification
  static double getDynamicPhForSoilType(String? soilType) {
    if (soilType == null) return 6.6;
    switch (soilType.toLowerCase().trim()) {
      case 'black':
        return 7.6; // High calcium/magnesium, slightly alkaline
      case 'clay':
        return 7.2; // High mineral retention, near neutral to slightly basic
      case 'alluvial':
        return 7.0; // Balanced riverine silt, neutral
      case 'loamy':
        return 6.6; // Ideal agricultural loam, slightly acidic
      case 'sandy':
        return 6.2; // High drainage, mild leaching
      case 'red':
        return 5.9; // Iron & aluminum oxide presence, acidic
      case 'laterite':
        return 5.3; // Tropical heavy leaching, strongly acidic
      default:
        return 6.5;
    }
  }

  /// Returns agronomically characteristic baseline readings for each soil classification
  static Map<String, dynamic> getBaselineReadingsForSoil(String? soilType) {
    final st = (soilType ?? 'Loamy').toLowerCase().trim();
    switch (st) {
      case 'black':
        return {
          'nitrogen': 75.0,
          'phosphorus': 28.0,
          'potassium': 220.0,
          'ph': 7.6,
          'moisture': 54.0,
          'temperature': 26.0,
          'description': 'High moisture retention & potassium rich'
        };
      case 'clay':
        return {
          'nitrogen': 82.0,
          'phosphorus': 34.0,
          'potassium': 195.0,
          'ph': 7.2,
          'moisture': 58.0,
          'temperature': 24.5,
          'description': 'Dense texture with very high water retention'
        };
      case 'alluvial':
        return {
          'nitrogen': 92.0,
          'phosphorus': 46.0,
          'potassium': 160.0,
          'ph': 7.0,
          'moisture': 44.0,
          'temperature': 25.0,
          'description': 'Rich riverine silt, highly fertile & balanced'
        };
      case 'sandy':
        return {
          'nitrogen': 38.0,
          'phosphorus': 18.0,
          'potassium': 55.0,
          'ph': 6.2,
          'moisture': 20.0,
          'temperature': 29.5,
          'description': 'Rapid drainage, low retention, warmer profile'
        };
      case 'red':
        return {
          'nitrogen': 65.0,
          'phosphorus': 22.0,
          'potassium': 110.0,
          'ph': 5.9,
          'moisture': 32.0,
          'temperature': 27.5,
          'description': 'Iron-rich, moderate drainage & slightly acidic'
        };
      case 'laterite':
        return {
          'nitrogen': 58.0,
          'phosphorus': 14.0,
          'potassium': 85.0,
          'ph': 5.3,
          'moisture': 34.0,
          'temperature': 27.0,
          'description': 'Heavy leaching, acidic, P-fixing profile'
        };
      case 'loamy':
      default:
        return {
          'nitrogen': 85.0,
          'phosphorus': 42.0,
          'potassium': 145.0,
          'ph': 6.6,
          'moisture': 40.0,
          'temperature': 25.5,
          'description': 'Optimal agricultural loam with balanced aeration'
        };
    }
  }

  /// Dynamically computes Soil Organic Carbon (%) from Nitrogen & Soil Type
  static double calculateOrganicCarbon(double nitrogen, String? soilType) {
    double baseOc = 0.55;
    final st = (soilType ?? 'Loamy').toLowerCase().trim();
    if (st == 'black') baseOc = 0.85;
    else if (st == 'clay') baseOc = 0.72;
    else if (st == 'alluvial') baseOc = 0.68;
    else if (st == 'loamy') baseOc = 0.60;
    else if (st == 'laterite') baseOc = 0.48;
    else if (st == 'red') baseOc = 0.40;
    else if (st == 'sandy') baseOc = 0.25;

    final factor = (nitrogen / 80.0).clamp(0.4, 2.0);
    final calculated = baseOc * factor;
    return double.parse(calculated.clamp(0.15, 1.40).toStringAsFixed(2));
  }

  /// Dynamically computes Electrical Conductivity (dS/m) from soluble N-P-K mineral levels
  static double calculateElectricalConductivity(double n, double p, double k) {
    // Soluble salt index based on available ionic concentrations
    final ec = 0.20 + (n * 0.0032) + (p * 0.0025) + (k * 0.0038);
    return double.parse(ec.clamp(0.35, 2.80).toStringAsFixed(2));
  }

  /// Human-readable explanation of the dynamic pH profile
  static String getSoilPhDescription(String? soilType) {
    final ph = getDynamicPhForSoilType(soilType);
    if (ph >= 7.5) return "Alkaline (pH ~$ph)";
    if (ph >= 6.8) return "Neutral (pH ~$ph)";
    if (ph >= 6.0) return "Slightly Acidic (pH ~$ph)";
    return "Acidic (pH ~$ph)";
  }
}

