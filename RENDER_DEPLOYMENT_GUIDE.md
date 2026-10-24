# YieldCraft AI — Render Cloud Hosting & Deployment Guide

This guide details how to deploy the **YieldCraft AI Backend** on [Render](https://render.com), connect the **ESP32 IoT Soil Node** over HTTPS, and build the **Flutter Mobile / Desktop App** to connect to your live cloud deployment.

---

## 1. Quick Deploy to Render

### Method A: Blueprint 1-Click Deploy (Recommended)
1. Push your repository to GitHub:
   ```bash
   git remote add origin https://github.com/rohithg-027/YieldCraftAI.git
   git branch -M main
   git push -u origin main
   ```
2. Log in to [Render Dashboard](https://dashboard.render.com).
3. Click **New +** → **Blueprint**.
4. Connect your `YieldCraftAI` GitHub repository.
5. Render will automatically detect [render.yaml](file:///c:/Users/Rohit/Clients/YieldCraft%20AI/render.yaml) and configure:
   - **Service Name:** `yieldcraft-ai-backend`
   - **Environment:** `Python 3.12`
   - **Build Command:** `pip install --upgrade pip && pip install -r backend/requirements.txt`
   - **Start Command:** `cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path:** `/health`
6. Click **Apply**. Render will clone, build, load the machine learning pipelines, and launch your API!

---

### Method B: Manual Web Service Setup
If you prefer configuring the Web Service manually in Render:
1. Go to **Render Dashboard** → **New +** → **Web Service**.
2. Select your repository `https://github.com/rohithg-027/YieldCraftAI.git`.
3. Configure the following fields:
   * **Name:** `yieldcraft-ai-backend`
   * **Region:** Any (e.g. `Oregon (US West)` or `Singapore`)
   * **Branch:** `main`
   * **Root Directory:** Leave **BLANK** (defaults to repository root)
   * **Runtime:** `Python 3`
   * **Build Command:** `pip install --upgrade pip && pip install -r backend/requirements.txt`
   * **Start Command:** `cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   * **Plan:** `Free`
4. Under **Advanced** → **Environment Variables**, add:
   * `PYTHON_VERSION`: `3.12.0`
   * `ENVIRONMENT`: `production`
   * `ALLOWED_ORIGINS`: `["*"]`
   * `GEMINI_API_KEY`: *(Optional: Your Google Gemini API Key for Crop Doctor & AI Assistant)*
   * `DATA_GOV_IN_API_KEY`: *(Optional: Your Agmarknet API key for live APMC rates)*
5. Under **Health Check Path**, enter: `/health`
6. Click **Create Web Service**.

---

## 2. Verifying Your Live Deployment

Once Render displays **Live**, your service URL will look like:
```text
https://yieldcraft-ai-backend.onrender.com
```

Test your deployment in your browser or terminal:
* **Root Info:** `https://<YOUR-RENDER-APP>.onrender.com/`
* **Health Check & ML Status:** `https://<YOUR-RENDER-APP>.onrender.com/health`
  ```json
  {
    "status": "healthy",
    "service": "YieldCraft AI Engine",
    "version": "1.0.0",
    "models_loaded": {
      "crop_recommendation": true,
      "fertilizer_recommendation": true,
      "yield_prediction": true,
      "irrigation_recommendation": true
    }
  }
  ```
* **Interactive OpenAPI Docs:** `https://<YOUR-RENDER-APP>.onrender.com/docs`

> [!NOTE]
> On Render's Free tier, the web service automatically spins down after 15 minutes of inactivity. The first request after sleep takes ~30–50 seconds to wake up.

---

## 3. Configuring ESP32 to Send Telemetry to Render

Because Render serves all traffic over **HTTPS**, the ESP32 firmware in [iot/yieldcraft_soil_node/yieldcraft_soil_node.ino](file:///c:/Users/Rohit/Clients/YieldCraft%20AI/iot/yieldcraft_soil_node/yieldcraft_soil_node.ino) has been pre-configured with `WiFiClientSecure` and `client.setInsecure()` for reliable SSL transmission without needing manual CA certificate rotation.

### Hardware Pin Mapping:
* **DS18B20 Soil Temperature:** GPIO 4 (with 4.7kΩ pull-up to 3.3V)
* **Analog Soil Moisture (Hygrometer):** GPIO 34 (ADC1_CH6)
* **ZTS-3002 NPK RS485 Transceiver:**
  * RO → GPIO 16 (RX2)
  * DI → GPIO 17 (TX2)
  * DE & RE (tied) → GPIO 26

### Flashing Steps:
1. Open [iot/yieldcraft_soil_node/yieldcraft_soil_node.ino](file:///c:/Users/Rohit/Clients/YieldCraft%20AI/iot/yieldcraft_soil_node/yieldcraft_soil_node.ino) in **Arduino IDE** or **PlatformIO**.
2. Update your Wi-Fi credentials around line 62:
   ```cpp
   const char* WIFI_SSID     = "YOUR_WIFI_NAME";
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
   ```
3. Set `API_ENDPOINT` to your Render URL:
   ```cpp
   const char* API_ENDPOINT  = "https://<YOUR-RENDER-APP>.onrender.com/api/v1/sensors/readings";
   ```
4. Select board **ESP32 Dev Module** and upload.
5. Open Serial Monitor at **115200 baud**. The node will connect to Wi-Fi and stream telemetry to Render every 15 seconds, printing the live ML response:
   ```text
   [HTTP] Transmitting telemetry to https://...onrender.com/api/v1/sensors/readings...
   [HTTP] Ingestion Success (Status 201)
   [AI INSIGHT] Rec Crop: Cotton | Fertilizer: DAP | Irrigation: Low Urgency
   ```

---

## 4. Connecting & Building the Flutter App

### Connecting to Render:
1. In the Flutter App, on the login screen ([auth_screen.dart](file:///c:/Users/Rohit/Clients/YieldCraft%20AI/frontend/lib/screens/auth_screen.dart)), tap the **Server Config (Gear icon)** in the top right.
2. Tap the **Render Cloud** preset chip, or type your Render URL:
   ```text
   https://<YOUR-RENDER-APP>.onrender.com
   ```
3. Tap **Test Server Connection**. Once the green checkmark appears, tap **Save & Use Server**.
4. Alternatively, set `renderCloudBaseUrl` in [frontend/lib/core/constants.dart](file:///c:/Users/Rohit/Clients/YieldCraft%20AI/frontend/lib/core/constants.dart#L14) to your URL so it is selected by default.

### Building the Flutter App:
Run the appropriate build command inside `c:\Users\Rohit\Clients\YieldCraft AI\frontend`:

* **Android APK (Release):**
  ```bash
  flutter build apk --release
  ```
  *Output APK location:* `frontend/build/app/outputs/flutter-apk/app-release.apk`

* **Android App Bundle (for Google Play):**
  ```bash
  flutter build appbundle --release
  ```

* **Windows Desktop App:**
  ```bash
  flutter build windows --release
  ```
  *Output EXE location:* `frontend/build/windows/x64/runner/Release/`

* **Web Deployment:**
  ```bash
  flutter build web --release
  ```
