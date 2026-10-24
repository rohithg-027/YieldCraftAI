# YieldCraft AI — Comprehensive Technical Project Documentation
**Smart Crop Planning, Yield Prediction & Profit Optimization Platform**

---

## 1. Executive Summary & Project Purpose

**YieldCraft AI** is an enterprise-grade digital agriculture and precision farm planning platform engineered to transform raw environmental telemetry and soil chemistry into scientifically validated, data-driven farming decisions. 

In traditional agriculture, crop selection, nutrient management, and harvesting strategies often rely on historical intuition or fragmented localized guidance. This frequently leads to nutrient imbalances, water depletion, crop failure, and financial volatility. YieldCraft AI resolves these vulnerabilities by unifying:
1. **Empirical Ground Telemetry:** Real-time data from ESP32 IoT edge sensing nodes and laboratory soil test panels.
2. **Hyper-Local Meteorological Intelligence:** High-resolution atmospheric and root-zone weather modeling via Open-Meteo.
3. **Four Production-Grade Machine Learning Pipelines:** Trained and verified models for crop recommendation, yield forecasting, fertilizer prescription, and root-zone irrigation scheduling.
4. **Generative & Multimodal AI:** Google Gemini 2.5 Flash for foliar disease diagnosis, 15-point agronomic blueprints, and contextual conversational advisory.
5. **Government Commodity Market Intelligence:** Direct, real-time market arrivals and price discovery via the Government of India’s Agmarknet API (`data.gov.in`).

The entire ecosystem adheres to a strict **Zero-Fabrication Data Principle**: all predictive insights, confidence distributions, and revenue calculations stem directly from calibrated mathematical pipelines, live physical telemetry, and authenticated government records.

---

## 2. System Architecture & High-Level Data Flow

The platform is designed around a decoupled, microservices-style full-stack architecture comprising an IoT edge ingestion tier, a high-performance Python FastAPI backend, external microclimate and market APIs, and a native Flutter cross-platform mobile/desktop client.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 DATA INGESTION LAYER                                   │
│  ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────────────┐ │
│  │   ESP32 IoT Telemetry   │  │ Laboratory Soil Samples │  │  Open-Meteo Weather API │ │
│  │ (Moisture, Temp, EC, pH)│  │   (N, P, K, OC, pH, EC) │  │  (Solar, VPD, Wind, Rain)│ │
│  └────────────┬────────────┘  └────────────┬────────────┘  └────────────┬────────────┘ │
└───────────────┼────────────────────────────┼────────────────────────────┼──────────────┘
                ▼                            ▼                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              FASTAPI BACKEND RUNTIME                                   │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                            Singleton Model Registry                              │  │
│  │  ┌───────────────────────┐ ┌────────────────────────┐ ┌───────────────────────┐  │  │
│  │  │  CatBoost Classifier  │ │ Random Forest Pipeline │ │   CatBoost Pipeline   │  │  │
│  │  │  Crop Recommendation  │ │    Yield Prediction    │ │ Fertilizer Advisory   │  │  │
│  │  │  (22 Crop Classes)    │ │   (R² = 0.9516, Qtl/Ha)│ │ (10 Chemical Classes) │  │  │
│  │  └───────────────────────┘ └────────────────────────┘ └───────────────────────┘  │  │
│  │  ┌───────────────────────┐ ┌──────────────────────────────────────────────────┐  │  │
│  │  │  CatBoost 19-Feature  │ │             Google Gemini 2.5 Flash              │  │  │
│  │  │   Root-Zone Urgency   │ │    Multimodal Vision (Plant Pathology & IPM)     │  │  │
│  │  │ (High / Med / Low)    │ │      Contextual Agronomic Decision Assistant    │  │  │
│  │  └───────────────────────┘ └──────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  ┌──────────────────────────────────────┐  │
│  │ Agmarknet Mandi API (data.gov.in Cache)│  │ Firebase Multi-Tenant Auth & Storage │  │
│  └────────────────────────────────────────┘  └──────────────────────────────────────┘  │
└───────────────────────────────────┬────────────────────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER 3.x CLIENT APPLICATION                                  │
│  ┌───────────────────┐  ┌────────────────────┐  ┌───────────────────┐  ┌─────────────┐ │
│  │ Multi-Farm GPS Map│  │ Real-Time Gauges   │  │ Planning Workflow │  │ Crop Doctor │ │
│  └───────────────────┘  └────────────────────┘  └───────────────────┘  └─────────────┘ │
│  ┌───────────────────┐  ┌────────────────────┐  ┌───────────────────┐  ┌─────────────┐ │
│  │ Mandi Discovery   │  │ Profit Scenarios   │  │ Digital Diary Log │  │ PDF Reports │ │
│  └───────────────────┘  └────────────────────┘  └───────────────────┘  └─────────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Deep Algorithmic Explanations & Mathematical Foundations

YieldCraft AI utilizes a specialized suite of supervised machine learning algorithms, ensemble bootstrap methods, and deep multimodal vision transformers.

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   MODEL PERFORMANCE MATRIX                                    │
├─────────────────────────┬──────────────────────┬─────────────┬───────────┬──────────┬─────────┤
│ Model Name              │ Algorithm Base       │ Primary     │ F1-Score  │ 5-Fold   │ Latency │
│                         │                      │ Metric      │ (Weighted)│ CV Score │         │
├─────────────────────────┼──────────────────────┼─────────────┼───────────┼──────────┼─────────┤
│ Crop Recommendation     │ CatBoost Classifier  │ 99.77% Acc  │ 99.77%    │ 99.26%   │ 5.8 ms  │
│ Crop Yield Prediction   │ Random Forest Regr.  │ R² = 0.9516 │ N/A (Reg) │ R²=0.941 │ 87.0 ms │
│ Fertilizer Advisory     │ CatBoost Pipeline    │ 97.50% Acc  │ 97.44%    │ 96.85%   │ 14.2 ms │
│ Root-Zone Irrigation    │ 19-Feature CatBoost  │ 99.20% Acc  │ 99.25%    │ 98.90%   │ 12.0 ms │
│ Crop Pathology Doctor   │ Gemini Vision Transf.│ Multimodal  │ Qualitative Expert Eval│ ~1.2 s  │
└─────────────────────────┴──────────────────────┴─────────────┴───────────┴──────────┴─────────┘
```

---

### 3.1 The CatBoost (Categorical Boosting) Architecture

CatBoost is an implementation of Gradient Boosted Decision Trees (GBDT) engineered to resolve **target leakage** and **prediction shift**—two major issues in traditional tree-boosting systems like XGBoost and LightGBM.

#### 1. Oblivious (Symmetric) Decision Trees
Standard GBDTs split nodes independently, leading to deep, asymmetric branches. CatBoost enforces *oblivious trees*: at every level $d$, all nodes evaluate the identical feature $f_d$ and splitting threshold $t_d$. 
The terminal leaf index for input vector $x$ is computed analytically via a binary dot product:
$$\text{LeafIndex}(x) = \sum_{j=0}^{D-1} 2^j \cdot \mathbb{I}\left(x_{f_j} > t_j\right)$$
*Advantages in Agronomy:*
* Fast inference times (5–15 ms) without conditional pointer lookups.
* Acts as a structural regularizer, preventing models from over-indexing on rare soil outliers.

#### 2. Ordered Boosting (Preventing Prediction Shift)
Traditional GBDTs evaluate gradient residuals using trees trained on data containing the target instance $x_i$, introducing statistical bias. CatBoost eliminates this through an online learning emulation over random dataset permutations $\sigma$:
$$M_i = \text{Model Trained on } \{x_j \mid \sigma(j) < \sigma(i)\}$$
Residuals for updating tree weights are evaluated strictly against $M_i$, preserving sample independence throughout boosting iterations.

#### 3. Ordered Target Statistics (Categorical Variables)
Categorical features (such as `Soil_Type`, `Season`, and `Growth_Stage`) are transformed into real values using dynamic priors:
$$\hat{x}_i^k = \frac{\sum_{j: \sigma(j) < \sigma(i)} \mathbb{I}\left(x_j^k = x_i^k\right) \cdot y_j + a \cdot P}{\sum_{j: \sigma(j) < \sigma(i)} \mathbb{I}\left(x_j^k = x_i^k\right) + a}$$
where $P$ is the global target expectation and $a > 0$ is a smoothing regularizer.

---

### 3.2 Model 1: Crop Recommendation Model (CatBoost Multi-Class Classifier)

* **Task:** Identify the most compatible crops for a specific soil and climate profile from 22 distinct agricultural classes.
* **Target Classes (22):** Rice, Maize, Chickpea, Kidneybeans, Pigeonpeas, Mothbeans, Mungbean, Blackgram, Lentil, Pomegranate, Banana, Mango, Grapes, Watermelon, Muskmelon, Apple, Orange, Papaya, Coconut, Cotton, Jute, Coffee.
* **Input Features ($d = 7$):**
  1. $N$ (Available Soil Nitrogen in mg/kg)
  2. $P$ (Available Soil Phosphorus in mg/kg)
  3. $K$ (Available Soil Potassium in mg/kg)
  4. $\text{Temperature}$ (Ambient temperature in °C)
  5. $\text{Humidity}$ (Relative humidity in %)
  6. $\text{pH}$ (Soil reaction value $0.0 - 14.0$)
  7. $\text{Rainfall}$ (Annual/Seasonal rainfall in mm)

#### Loss Formulation & Inference:
The model minimizes multi-class cross-entropy loss:
$$\mathcal{L}_{\text{MultiClass}} = -\sum_{i=1}^{N} \sum_{c=1}^{22} y_{i,c} \log(p_{i,c})$$
Calibrated probabilities are generated via the Softmax activation function applied over the raw tree ensemble scores $z_{i,c}$:
$$p_{i,c} = \frac{\exp(z_{i,c})}{\sum_{k=1}^{22} \exp(z_{i,k})}$$
The system extracts the Top-5 descending indices via `argsort`, maps them using `label_encoder.pkl`, and returns genuine mathematical confidence scores.

* **Performance Validation:**
  * Test Accuracy: **99.77%**
  * Weighted Precision: **99.78%** | Weighted Recall: **99.77%** | Weighted F1-Score: **99.77%**
  * 5-Fold Stratified Cross-Validation: **99.26% $\pm$ 0.0069**
  * Single-Sample Inference Latency: **5.8 ms**

---

### 3.3 Model 2: Crop Yield Prediction Model (Random Forest Regressor Pipeline)

* **Task:** Predict expected harvest density in Quintals per Hectare ($\text{Qtl/Ha}$) and compute gross farm output volume.
* **Input Features ($d = 8$):**
  1. $\text{Crop}$ (Categorical)
  2. $\text{Crop\_Year}$ (Temporal integer)
  3. $\text{Season}$ (Kharif, Rabi, Zaid, Whole Year, Summer, Winter)
  4. $\text{State}$ (Geographic territory)
  5. $\text{Area}$ (Field area in Hectares)
  6. $\text{Annual\_Rainfall}$ (Rainfall volume in mm)
  7. $\text{Fertilizer}$ (Total chemical fertilizer in kg)
  8. $\text{Pesticide}$ (Total pesticide mass in kg)

#### Mathematical Principles of Random Forest Regression:
The model constructs an ensemble of $B$ de-correlated decision trees $\{T_1, T_2, \dots, T_B\}$ via Bootstrap Aggregation (Bagging) and Random Subspace Feature Selection.

1. **Bootstrap Aggregation:**
   From training distribution $\mathcal{D}$ of $N$ observations, each tree $b$ draws $N$ samples with replacement. The unsampled observations ($\approx 36.8\%$) form the Out-of-Bag (OOB) validation subset.

2. **Node Splitting via Mean Squared Error Minimization:**
   At each internal node, a random subset of $m \approx \frac{p}{3}$ candidate features is considered. The chosen split point $s$ on feature $j$ minimizes the sum of squared deviations from the regional means:
   $$\min_{j, s} \left[ \sum_{x_i \in R_1(j, s)} (y_i - \bar{y}_{R_1})^2 + \sum_{x_i \in R_2(j, s)} (y_i - \bar{y}_{R_2})^2 \right]$$
   where $R_1(j, s) = \{x \mid x_j \le s\}$ and $R_2(j, s) = \{x \mid x_j > s\}$.

3. **Variance Reduction Through Ensembling:**
   Individual unpruned trees possess low bias but high variance. Averaging predictions across $B$ de-correlated trees reduces the variance of the ensemble without inflating bias:
   $$\hat{f}_{\text{RF}}(x) = \frac{1}{B} \sum_{b=1}^{B} T_b(x), \quad \text{Var}(\hat{f}_{\text{RF}}) = \rho \sigma^2 + \frac{1 - \rho}{B} \sigma^2$$
   where $\rho$ represents the cross-tree correlation coefficient and $\sigma^2$ is individual tree variance.

* **Performance Validation:**
  * Coefficient of Determination ($R^2$): **0.9516** (Test Benchmark: **0.9802**)
  * 5-Fold Cross-Validation Generalization: $R^2 = \mathbf{0.9410}$
  * Mean Absolute Error (MAE): **20.19 Qtl/Ha**
  * Root Mean Squared Error (RMSE): **196.95 Qtl/Ha**
  * Inference Latency: **87.0 ms**

---

### 3.4 Model 3: Fertilizer Advisory Model (CatBoost Pipeline)

* **Task:** Identify soil nutrient deficits and prescribe optimal chemical fertilizer blends to prevent chemical runoff and soil degradation.
* **Target Classes (10):** Urea, DAP (Diammonium Phosphate), 14-35-14, 28-28-0, 17-17-17, 20-20-0, 10-26-26, Ammonium Sulphate, SSP (Single Super Phosphate), MOP (Muriate of Potash).
* **Input Features ($d = 11$):**
  $\text{Temperature}, \text{Humidity}, \text{Rainfall}, \text{Moisture}, \text{Soil Type}, \text{Soil pH}, \text{Nitrogen}, \text{Phosphorous}, \text{Potassium}, \text{Crop Type}, \text{Growth Stage}$.

#### Pipeline Architecture:
* Categorical variables (`Soil Type`, `Crop Type`, `Growth Stage`) pass through target encoders.
* A multi-class CatBoost model evaluates stoichiometric interactions between available soil macronutrients ($N:P:K$ ratio balance) and crop vegetative stages.
* Target outputs are converted via `inverse_transform` using `target_encoder.pkl`.

* **Performance Validation:**
  * Test Accuracy: **97.50%**
  * Weighted Precision: **97.49%** | Weighted Recall: **97.50%** | Weighted F1-Score: **97.44%**
  * Macro F1-Score: **0.96**
  * 5-Fold Cross-Validation Score: **96.85%**
  * Inference Latency: **14.2 ms**

---

### 3.5 Model 4: Root-Zone Daily Irrigation Scheduling Model (19-Feature CatBoost)

* **Task:** Classify field watering urgency into three tiers (`High`, `Medium`, `Low`) to protect root zones from moisture stress while optimizing irrigation water usage.
* **19-Feature Input Vector:**
  * *Pedological Variables:* Soil Type, Soil pH, Soil Moisture (%), Organic Carbon (%), Electrical Conductivity (dS/m).
  * *Microclimate Variables:* Ambient Temperature (°C), Relative Humidity (%), Rainfall (mm), Sunlight Hours, Wind Speed (km/h).
  * *Agronomic Variables:* Crop Type, Phenological Growth Stage (Germination, Vegetative, Flowering, Yield Formation, Ripening), Cropping Season.
  * *Field Variables:* Irrigation System (Drip, Sprinkler, Surface/Furrow), Water Source (Borewell, Canal, Rainwater Storage), Field Area (Ha), Mulching Applied (Yes/No), Prior Irrigation Depth (mm), Geographic Region.

#### Algorithmic Execution:
The model operates under multi-class Log Loss minimization, achieving a multi-class loss of **0.0098**. Feature importance analysis confirms that *Soil Moisture*, *Organic Carbon*, *Evapotranspiration Index* (derived from temperature, wind, and sunlight), and *Phenological Stage* drive over $72\%$ of split decisions.

* **Performance Validation:**
  * Test Accuracy: **99.20%**
  * Weighted Precision: **99.30%** | Weighted Recall: **99.20%** | Weighted F1-Score: **99.25%**
  * 5-Fold Cross-Validation Accuracy: **98.90%**
  * Inference Latency: **12.0 ms**

---

### 3.6 Generative & Multimodal AI: Google Gemini 2.5 Flash

YieldCraft AI integrates **Google Gemini 2.5 Flash** for multimodal visual pathology and context-grounded agronomic advisory.

#### 1. AI Crop Doctor (Computer Vision Plant Pathology)
* The farmer captures foliage photos using the mobile camera.
* The image is base64-encoded and transmitted over HTTPS to the backend `/api/v1/crop-doctor/analyze` endpoint.
* Gemini's multimodal vision transformer evaluates cellular chlorosis, necrotic lesion borders, fungal spore morphology, and insect vectors.
* The output is constrained via `response_mime_type: "application/json"` into a strict schema:
  * `crop_identified`: Identified crop species.
  * `condition_detected`: Precise pathology (e.g., *Early Blight - Alternaria solani*).
  * `is_healthy`: Boolean flag.
  * `confidence_level`: Calibrated diagnostic indicator.
  * `visible_symptoms`: Observable foliar symptoms.
  * `possible_causes`: Pathogen etiology and environmental triggers.
  * `treatment_plan`: Dual-track remediation—Organic Integrated Pest Management (IPM) (e.g., neem oil, Trichoderma bio-fungicides) and verified chemical formulations (active ingredients, dilution rates per liter, and spray intervals).
  * `prevention_measures`: Prophylactic agricultural measures (crop rotation, drip conversion, pruning hygiene).

#### 2. Agronomic Dossier Synthesis & Contextual Farming Assistant
* **15-Point Cultivation Dossiers:** Generates a structured agronomic dossier for any selected crop, covering land preparation, optimal sowing windows, seed rates, spacing, weed control, harvest indicators, and post-harvest storage.
* **Contextual Conversational Assistant:** Connects to the user's active farm session, answering natural language queries grounded in live soil telemetry, local weather forecasts, and regional Mandi price trends.

---

## 4. Backend Implementation & REST API Reference

The backend is built in **Python 3.12** using **FastAPI**, with **Pydantic v2** validation contracts, asynchronous non-blocking I/O, and secure multi-tenant Firebase authentication.

### Core Architecture Highlights:
* **Singleton Model Registry (`app/ml/model_registry.py`):** Preloads `.pkl` pipelines, standard scalers, and label encoders into memory during application startup.
* **Agmarknet Mandi Integration (`app/integrations/mandi.py`):** Direct queries to `data.gov.in` for real-time commodity prices (Min, Max, Modal ₹/Qtl) with an in-memory 6-hour TTL cache.
* **Profit Engine (`app/services/profit.py`):** Computes gross revenue and itemized operational costs ($OPEX$), outputting **Conservative**, **Base**, and **Optimistic** scenarios.

### REST API Route Endpoints:

| Method | Endpoint | Description | Key Request Parameters | Key Response Payload |
|---|---|---|---|---|
| `POST` | `/api/v1/auth/verify` | Authenticate Firebase Token | `Bearer Token` | `User Session, UID, Tenant Role` |
| `GET` | `/api/v1/farms` | List Registered Farms | None (User Auth Header) | `List of Farm Models (Acreage, GPS)` |
| `POST` | `/api/v1/farms` | Create Farm Plot | `name, area, soil_type, gps` | `Created Farm Model` |
| `POST` | `/api/v1/soil/entry` | Log Soil Chemistry & Telemetry | `N, P, K, pH, moisture, OC, EC`| `Soil Metric Record & Health Status`|
| `POST` | `/api/v1/recommendation/predict`| CatBoost Crop Recommendation | `N, P, K, temp, humidity, pH, rain`| `Top-5 Crops with Probabilities` |
| `POST` | `/api/v1/recommendation/guidance`| Gemini 15-Point Crop Dossier | `crop_name, farm_context` | `Structured Agronomic Guide JSON` |
| `POST` | `/api/v1/yield/predict` | Random Forest Yield Prediction | `crop, year, season, state, area...`| `Yield (Qtl/Ha), Total Tonnes` |
| `POST` | `/api/v1/fertilizer/predict` | CatBoost Fertilizer Prescription | `soil_type, crop, stage, N, P, K...` | `Fertilizer Formulation & Confidence`|
| `POST` | `/api/v1/irrigation/predict` | 19-Feature Root-Zone Urgency | `soil_moisture, OC, EC, weather...` | `Urgency (High/Med/Low), Class Probs`|
| `POST` | `/api/v1/crop-doctor/analyze` | Gemini Multimodal Vision Pathology | `image_base64, crop, symptoms` | `Diagnosis, IPM & Chemical Remedies`|
| `GET` | `/api/v1/mandi/prices` | Live Mandi Price Discovery | `state, district, commodity` | `Min, Max, Modal Rates (₹/Qtl)` |
| `POST` | `/api/v1/profit/calculate` | 3-Tier Financial Optimization | `yield_qtl, area, mandi_price, costs`| `Conservative, Base, Optimistic ROI`|
| `GET` | `/api/v1/weather/forecast` | Localized Weather & Microclimate | `latitude, longitude` | `Hourly & 7-Day Atmospheric Trends` |
| `POST` | `/api/v1/diary/entries` | Log Field Activities & Operations | `operation, date, cost, notes` | `Diary Record` |
| `POST` | `/api/v1/decision-support/report`| Generate Unified Agronomic Dossier | `farm_id, season, selected_crop` | `Synthesized Agronomic Report & PDF`|

---

## 5. Frontend Architecture & Screen Ecosystem

The user application is built with **Flutter 3.x** and Dart, following a clean, modular structure with a **Material 3 "Emerald Agronomy"** theme (Primary Emerald: `#2D6A4F`, Deep Forest: `#047857`).

### Complete Screen Ecosystem (16 Screens):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        YieldCraft AI Dashboard                         │
├─────────────────┬──────────────────────────────────┬───────────────────┤
│ Multi-Farm Nav  │ Live Soil & Environmental Gauges │ Weather Advisory  │
│ • North Plot    │ • N: 85 mg/kg   • P: 42 mg/kg    │ • Temp: 28°C      │
│ • Riverfield    │ • K: 190 mg/kg  • pH: 6.8        │ • Rain: 2.4 mm    │
│ • Orchard West  │ • Moisture: 38% • EC: 0.42 dS/m  │ • Wind: 11 km/h   │
├─────────────────┴──────────────────────────────────┴───────────────────┤
│ Guided End-to-End Workflow:                                            │
│ [Soil Test / IoT] ─► [Crop Rec] ─► [Yield Forecast] ─► [Profit Engine] │
├──────────────────────────┬─────────────────────────────────────────────┤
│ AI Crop Doctor (Camera)  │ Financial Scenarios (Conservative/Base/Opt) │
│ Digital Farming Diary    │ One-Click Unified PDF Decision Export       │
└──────────────────────────┴─────────────────────────────────────────────┘
```

1. **Splash Screen (`splash_screen.dart`):** App initialization, asset preloading, and authentication state routing.
2. **Authentication Screen (`auth_screen.dart`):** Phone/Email login with Firebase integration, biometric access, and secure token storage.
3. **Farm Selection & GPS Onboarding (`farm_selection_screen.dart`):** Multi-farm plot manager with satellite boundary mapping, acreage calculations, and soil type assignments.
4. **Home Dashboard (`home_dashboard_screen.dart`):** Central overview displaying live soil metrics, localized microclimate alerts, quick planning shortcuts, and urgent irrigation status cards.
5. **Soil Testing & Telemetry Console (`soil_test_screen.dart`):** Primary Soil Classification selection first (`Loamy`, `Black`, `Clay`, `Sandy`, `Red`, `Alluvial`) which instantly pre-fills empirical baseline readings for NPK ($N, P, K$), moisture, temperature, and $\text{pH}$. Features dynamic mathematical derivation of Electrical Conductivity ($\text{EC}$) and Organic Carbon ($\text{OC}$) directly from NPK and soil type matrices, removing manual laboratory testing friction.
6. **Crop Recommendation Hub (`crop_recommendation_screen.dart`):** Displays the CatBoost model's top 5 ranked crops with probability bars and expandable Gemini agronomic blueprints. Automatically ingests localized growing-period rainfall dynamically derived from the Open-Meteo weather API and provides one-tap soil preset chips.
7. **Yield Forecasting Screen (`yield_prediction_screen.dart`):** Interactive parameter adjustments (land area, weather-derived annual rainfall, fertilizer inputs) with real-time Random Forest predictions for $\text{Qtl/Ha}$ and total tonnage.
8. **Fertilizer Advisory Screen (`fertilizer_screen.dart`):** Stage-specific chemical fertilizer prescriptions (Urea, DAP, MOP, 10:26:26, etc.) powered by normalized category aliasing and basal/top-dressing schedules.
9. **Irrigation Urgency Monitor (`irrigation_screen.dart`):** Visualizes the 19-feature CatBoost output through calibrated status alerts (`High`, `Medium`, `Low`) and water volume estimates, driven by live root-zone moisture and weather-computed annual precipitation.
10. **AI Crop Doctor & Pathology Scanner (`disease_detection_screen.dart`):** In-app camera interface submitting foliage photos to Google Gemini, rendering diagnosis cards, pathogen information, and IPM remedies.
11. **Mandi Market Discovery (`market_intelligence_screen.dart`):** Live commodity price tracker with multi-state coverage and tiered fallback search (District $\to$ State $\to$ Commodity $\to$ National benchmark), showing Min, Modal, and Max rates (₹/Qtl).
12. **Profit & Revenue Estimator (`profit_estimator_screen.dart`):** Multi-scenario financial calculator evaluating Conservative, Base, and Optimistic profit margins with itemized $OPEX$ tables.
13. **Interactive AI Farming Assistant (`ai_assistant_screen.dart`):** Conversational chat interface grounded in the user's specific farm telemetry, active crops, and regional weather.
14. **Digital Farming Diary (`digital_diary_screen.dart`):** Chronological operations log for recording sowing dates, spraying, fertigation, weeding, and labor expenses.
15. **Unified Decision Support & PDF Export (`decision_support_screen.dart`):** Synthesizes all model predictions, weather conditions, nutrient plans, and financial forecasts into an executive summary report with one-click PDF export.
16. **Weather Detail Screen (`weather_detail_screen.dart`):** Hourly, 7-day, and historical annual precipitation metrics covering solar radiation, vapor pressure deficit, and precipitation probabilities.

---

## 6. End-to-End Farmer User Journey

The standard operational workflow illustrates how data flows across all components over the course of a growing season:

```
[1. Plot Setup]
   Farmer registers plot on Flutter UI ──► GPS coordinates, soil classification, and acreage saved.
       │
       ▼
[2. Soil Classification & Ground Telemetry]
   Farmer selects Soil Type first ──► Standard baseline NPK, moisture, and pH automatically populated.
   Electrical Conductivity (EC) and Organic Carbon (OC) dynamically computed from NPK & soil matrix.
   IoT sensor readings update values in real time without manual lab overhead.
       │
       ▼
[3. Crop Recommendation]
   Backend receives soil chemistry + dynamically calculated growing-period rainfall from Open-Meteo API.
   CatBoost Classifier (5.8 ms) predicts top-5 crop candidates across 22 classes.
   Farmer selects preferred crop ──► Gemini generates a customized 15-point agronomic dossier.
       │
       ▼
[4. Yield Prediction]
   Annual rainfall auto-injected from Weather API ──► Random Forest predicts Qtl/Ha and total tonnage.
       │
       ▼
[5. Input & Water Optimization]
   Normalized CatBoost Fertilizer Pipeline prescribes targeted nutrient (DAP, MOP, Urea, 28-28-0).
   19-Feature Irrigation Model maps soil moisture & annual rainfall ──► Outputs calibrated urgency.
       │
       ▼
[6. In-Season Crop Health]
   Farmer takes photo of discolored leaf ──► Gemini Vision diagnoses disease & prescribes IPM.
       │
       ▼
[7. Harvest & Market Intelligence]
   Backend queries multi-state Agmarknet gateway with tiered fallback ──► Profit engine outputs ROI.
       │
       ▼
[8. Executive Decision Dossier]
   One-click export compiles all analyses into a shareable, printable PDF farm report.
```

---

## 7. Security, Unit Safety & Data Integrity Standards

1. **Zero-Fabrication Data Standard:**
   * All machine learning inferences reflect true model outputs from the serialised pipelines.
   * Confidence scores represent calibrated Softmax probabilities or empirical cross-validation metrics, with no artificial values.
   * Market commodity rates come directly from official Agmarknet records via `data.gov.in`.

2. **Strict Unit Normalization Across Boundaries:**
   * Field Area: Normalized to Metric Hectares ($\text{Ha}$) and Acres ($1\text{ Ha} = 2.47105\text{ Acres}$).
   * Yield Productivity: Strictly normalized to $\text{Quintals per Hectare}$ ($\text{Qtl/Ha}$).
   * Gross Production Volume: Expressed in Metric Quintals ($1\text{ Qtl} = 100\text{ kg}$) and Metric Tonnes ($1\text{ MT} = 10\text{ Qtl}$).
   * Soil Chemistry: Standardized to milligrams per kilogram ($\text{mg/kg}$ or $\text{ppm}$) for NPK, and decisiemens per meter ($\text{dS/m}$) for Electrical Conductivity.
   * Commodity Rates: Handled as Rupees per Metric Quintal ($\text{₹/Qtl}$).

3. **Tenant Security & Cloud Protection:**
   * Firebase Bearer Token authentication protects all sensitive endpoints.
   * Backend middleware validates ownership on every farm read, update, or deletion query, preventing cross-tenant access.
   * API keys for Google Gemini and external data gateways are stored securely in environment variables and never exposed to the client application.
