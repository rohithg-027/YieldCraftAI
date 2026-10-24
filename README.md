# YieldCraft AI — Smart Crop Planning, Prediction & Profit Optimization Platform

[![Python](https://img.shields.io/badge/Python-3.12-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.3-02569B.svg)](https://flutter.dev/)
[![Material 3](https://img.shields.io/badge/Material_3-Emerald_Agronomy-2D6A4F.svg)](https://m3.material.io/)
[![Scikit-Learn](https://img.shields.io/badge/Scikit--Learn-1.6.1-F7931E.svg)](https://scikit-learn.org/)
[![CatBoost](https://img.shields.io/badge/CatBoost-1.2.10-FFCC00.svg)](https://catboost.ai/)
[![Gemini](https://img.shields.io/badge/Google_Gemini-2.5_Flash-8E75B2.svg)](https://deepmind.google/technologies/gemini/)
[![Agmarknet](https://img.shields.io/badge/Mandi_Rates-data.gov.in-FF9933.svg)](https://data.gov.in/)

**YieldCraft AI** is an enterprise-grade digital farming and precision agriculture platform. It empowers farmers and agricultural managers to make data-driven decisions by combining real-time ground telemetry (ESP32 IoT nodes), empirical soil laboratory tests, high-resolution meteorological models, 4 verified machine learning pipelines, and Google Gemini multimodal reasoning.

---

## 🌾 Core Features & Integrated Modules

1. **Multi-Farm Management with GPS**
   - Manage multiple distinct farm plots with satellite coordinate logging, physical area, soil type, and irrigation source tracking.
2. **Soil Testing & IoT Telemetry**
   - Laboratory soil test entry (N, P, K, pH, moisture, organic carbon, electrical conductivity) and live ESP32 edge sensor ingestion.
3. **Intelligent Crop Recommendation (CatBoost Classifier)**
   - Top-5 crop recommendations evaluated across 22 classes with genuine mathematical probabilities.
4. **Deep Agronomic Guidance (Google Gemini)**
   - Rich 15-point dossiers for each crop covering sowing windows, soil management, nutrient schedules, irrigation, and storage.
5. **Crop Yield Forecasting (Scikit-Learn Pipeline + Random Forest, R² = 0.9516)**
   - Accurate prediction of quintals per hectare and gross tonnage based on regional precipitation, area, and agrochemical inputs.
6. **Fertilizer Advisory (Scikit-Learn Pipeline + CatBoost)**
   - 10-class fertilizer formula recommendation matched to crop growth stage and soil nutrient status.
7. **Root-Zone Daily Irrigation (19-Feature CatBoost Pipeline)**
   - High, Medium, or Low moisture urgency based on real-time soil moisture, temperature, solar radiation, and wind speed.
8. **AI Crop Doctor & Plant Pathology (Gemini Multimodal Vision)**
   - Foliage photo analysis identifying visual symptoms, pathogen vectors, severity ratings, organic IPM remedies, and chemical precautions.
9. **Government Mandi Market Intelligence (`data.gov.in`)**
   - Official Agmarknet commodity prices (Min, Max, Modal ₹/Quintal) queried by State, District, and Market with 6-hour caching.
10. **Profit & Revenue Optimization**
    - Gross revenue calculation, itemized cultivation expenses (seeds, labor, equipment, transport), and Conservative/Base/Optimistic scenarios.
11. **Unified Farm Decision Support**
    - Consolidated agronomic report synthesizing all models, weather warnings, and an actionable checklist with PDF export.
12. **Interactive AI Farming Assistant**
    - Conversational chatbot grounded in the selected farm's soil metrics, live weather, and Mandi price trends.
13. **Digital Farming Diary**
    - Chronological log of field operations, spraying, irrigation, milestones, and expenditures.

---

## 📁 Repository Structure

```
YieldCraft AI/
├── Models/                             # Verified trained ML model artifacts
│   ├── Crop_Recommendation_Model/      # CatBoost 22-class classifier (.pkl)
│   ├── Fertilizer_Model/               # Pipeline + CatBoost 10-class classifier (.pkl)
│   ├── Yeild_Prediction_Model/         # Pipeline + RandomForest Regressor (R²=0.9516) (.pkl)
│   └── Irrigation_Model/               # Pipeline + CatBoost 3-class classifier (.pkl)
├── Dataset/                            # Historical agricultural datasets & schemas
├── Notebooks/                          # Model training & preprocessing notebooks
├── backend/                            # FastAPI Python 3.12 Backend
│   ├── app/
│   │   ├── api/routes/                 # 15 REST API Route modules
│   │   ├── core/                       # Configuration, security & auth middleware
│   │   ├── integrations/               # Gemini AI, Mandi (data.gov.in), Weather providers
│   │   ├── ml/                         # Singleton model registry & feature preprocessors
│   │   ├── schemas/                    # Pydantic v2 validation contracts
│   │   └── services/                   # Farm management, profit, decision support services
│   ├── tests/                          # Automated backend test suite (pytest)
│   ├── requirements.txt                # Pinned dependencies (scikit-learn==1.6.1)
│   └── .env.example                    # Environment variable template
├── frontend/                           # Flutter 3.x Mobile & Desktop Client
│   ├── lib/
│   │   ├── core/                       # App theme (Material 3), API client, constants
│   │   ├── models/                     # Strongly typed Dart data models
│   │   ├── screens/                    # 15 Complete, responsive application screens
│   │   ├── state/                      # Providers (Auth, Farm, FarmingWorkflow)
│   │   └── widgets/                    # Custom cards, empty states, loading indicators
│   ├── test/                           # Automated Flutter component test suite
│   └── pubspec.yaml                    # Flutter dependencies
├── PROJECT_AUDIT.md                    # Initial audit report of repository assets
├── ARCHITECTURE.md                     # Full-stack system architecture documentation
├── API_DOCUMENTATION.md                # Comprehensive REST API contracts & examples
├── MODEL_INTEGRATION.md                # Machine learning schemas & preprocessing rules
├── FIREBASE_SETUP.md                   # Firebase Authentication & Firestore security rules
├── EXTERNAL_DATA_SOURCES.md            # data.gov.in, Open-Meteo & Gemini specifications
└── LOCAL_SETUP.md                      # Local startup, test & troubleshooting commands
```

---

## 🚀 Quick Local Startup

### 1. Start FastAPI Backend
```powershell
cd "c:\Users\Rohit\Clients\YieldCraft AI\backend"
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive API documentation: `http://localhost:8000/docs`

### 2. Run Backend Tests
```powershell
cd "c:\Users\Rohit\Clients\YieldCraft AI\backend"
pytest tests/test_api.py -v
```

### 3. Launch Flutter Application
```powershell
cd "c:\Users\Rohit\Clients\YieldCraft AI\frontend"
flutter pub get
flutter run -d windows    # For Windows Desktop
# OR
flutter run -d chrome     # For Chrome Web preview
```

### 4. Run Flutter Component Tests
```powershell
cd "c:\Users\Rohit\Clients\YieldCraft AI\frontend"
flutter test
```

---

## 🔒 Security & Data Integrity Principles

- **Zero Fabricated Data**: No synthetic confidence scores, dummy market prices, or made-up model outputs.
- **Strict Unit Safety**: Yields (Qtl/Ha), harvest production (Quintals), and Mandi commodity rates (₹/Quintal) are rigorously validated across calculations.
- **Tenant Isolation**: Backend middleware verifies user identity and farm ownership for every protected transaction.
- **Credential Protection**: Secrets and private service-account keys are strictly isolated in environment variables.
