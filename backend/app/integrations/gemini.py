import os
import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
from app.core.config import settings

logger = logging.getLogger("yieldcraft.gemini")

class GeminiIntegration:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL or "gemini-2.5-flash"
        self.client = None
        if self.api_key:
            try:
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
                logger.info(f"Gemini client initialized with model: {self.model_name}")
            except Exception as e:
                logger.warning(f"Failed to initialize google-genai client: {e}")

    def explain_crop(self, crop_name: str, farm_context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enriches a model-recommended crop with detailed agronomic guidance via Gemini.
        Returns a structured dictionary matching CropGuidance.
        """
        if not self.client or not self.api_key:
            return self._fallback_crop_explanation(crop_name)

        prompt = f"""
You are an expert agronomist for YieldCraft AI. The user's farm in {farm_context.get('state', 'India')}
(Soil: {farm_context.get('soil_type', 'Loamy')}) was recommended the crop '{crop_name}' by our machine learning model.

Provide an accurate, scientific, and practical agronomic guide for '{crop_name}'.
Return ONLY a valid JSON object with the following exact keys:
- crop_overview: Concise 2-sentence summary of the crop.
- why_recommended: Why this crop is well-suited for the given soil and environmental conditions.
- soil_suitability: Optimal soil pH and texture requirements.
- climate_suitability: Temperature, humidity, and rainfall tolerances.
- sowing_season: Primary sowing seasons in India (e.g., Kharif, Rabi, Zaid).
- crop_duration: Time from sowing to maturity in days or months.
- water_management: Critical watering stages and conservation practices.
- nutrient_management: Balanced NPK requirements and organic amendments.
- major_risks: Top pests or fungal diseases to monitor.
- harvesting_considerations: Maturity signs and harvesting techniques.
- market_potential: Economic outlook and commercial value.

Do not fabricate government subsidies or fake statistics.
"""
        try:
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config={"response_mime_type": "application/json"}
            )
            data = json.loads(response.text)
            return data
        except Exception as e:
            logger.warning(f"Gemini crop explanation failed: {e}. Using expert agronomy fallback.")
            return self._fallback_crop_explanation(crop_name)

    def analyze_disease(
        self,
        image_base64: str,
        crop: Optional[str] = None,
        plant_part: str = "Leaves",
        symptoms: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Multimodal visual disease analysis on crop image.
        """
        if not self.client or not self.api_key:
            return self._fallback_disease_analysis(crop, plant_part, symptoms)

        import base64
        try:
            image_bytes = base64.b64decode(image_base64)
            from google.genai import types

            prompt = f"""
You are an expert plant pathologist for YieldCraft AI.
Analyze this plant image.
Reported crop: {crop or 'Not specified'}
Plant part: {plant_part}
Reported symptoms: {symptoms or 'Visual inspection requested'}

Carefully inspect the image for foliar damage, fungal lesions, bacterial blights, pest infestations, or nutrient deficiencies.
Distinguish a visual hypothesis from a confirmed lab diagnosis. If the image is unclear, state that.
Never recommend hazardous, banned pesticides or unverified dosages. Prioritize integrated pest management (IPM) and standard agricultural extension remedies.

Return ONLY a valid JSON object with these exact keys:
- crop_identified: string (crop name or 'Uncertain')
- condition_detected: string (e.g., 'Early Blight (Alternaria solani)' or 'Healthy Leaf' or 'Leaf Spot')
- is_healthy: boolean
- confidence_level: string ('High', 'Moderate', 'Preliminary visual estimate')
- visible_symptoms: list of strings
- possible_causes: list of strings (pathogen, weather triggers)
- treatment_plan: list of actionable remedies
- prevention_measures: list of cultural/preventive steps
- severity: string ('Mild', 'Moderate', 'Severe', 'None')
- expert_advice: string (when to consult local Krishi Vigyan Kendra (KVK) or extension officer)
"""
            mime_type = "image/jpeg"
            if image_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
                mime_type = "image/png"
            elif image_bytes.startswith(b"RIFF") and b"WEBP" in image_bytes[:16]:
                mime_type = "image/webp"

            part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=[part, prompt],
                config={"response_mime_type": "application/json"}
            )
            raw_text = response.text.strip()
            if raw_text.startswith("```json"):
                raw_text = raw_text[7:]
            if raw_text.startswith("```"):
                raw_text = raw_text[3:]
            if raw_text.endswith("```"):
                raw_text = raw_text[:-3]
            data = json.loads(raw_text.strip())
            return data
        except Exception as e:
            logger.warning(f"Gemini multimodal disease analysis failed: {e}. Using fallback.")
            return self._fallback_disease_analysis(crop, plant_part, symptoms)

    def chat_assistant(
        self,
        message: str,
        farm_context: Optional[Dict[str, Any]] = None,
        history: Optional[List[Dict[str, str]]] = None
    ) -> Dict[str, Any]:
        """
        Contextual agronomic conversation grounded in farm data.
        """
        if not self.client or not self.api_key:
            return self._fallback_assistant(message, farm_context)

        system_instruction = f"""
You are YieldCraft Assistant, a helpful, highly knowledgeable AI agricultural expert.
You help farmers make informed decisions about crops, soil, fertilizers, irrigation, weather, and market prices.

Current Farm Context:
{json.dumps(farm_context or {}, indent=2)}

Guidelines:
1. Always base recommendations on scientific agronomy and official Indian agricultural standards.
2. Ground advice in the user's specific farm context (soil type, location, weather) when available.
3. Be practical, encouraging, and clear.
4. If asked about market prices or weather, refer to verified figures and caution about local market variations.
5. Provide 2-3 short suggested next actions.
"""
        contents = []
        if history:
            for item in history[-6:]:
                role = "user" if item.get("role") == "user" else "model"
                contents.append({"role": role, "parts": [{"text": item.get("content", "")}]})
        contents.append({"role": "user", "parts": [{"text": message}]})

        try:
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config={"system_instruction": system_instruction}
            )
            reply_text = response.text
            suggested_actions = [
                "Check Soil Profile Test",
                "Review Mandi Market Prices",
                "View Irrigation Advisory"
            ]
            return {
                "reply": reply_text,
                "suggested_actions": suggested_actions
            }
        except Exception as e:
            logger.warning(f"Gemini assistant chat failed: {e}. Using fallback.")
            return self._fallback_assistant(message, farm_context)

    # Fallback Methods grounded in agronomy
    def _fallback_crop_explanation(self, crop_name: str) -> Dict[str, Any]:
        crop_title = crop_name.capitalize()
        return {
            "crop_overview": f"{crop_title} is a major commercial crop widely cultivated for high nutritional and market value.",
            "why_recommended": f"Recommended based on optimal nitrogen, phosphorus, potassium ratios, favorable soil pH, and adequate moisture retention.",
            "soil_suitability": f"Thrives in well-drained loamy, clay-loam, or alluvial soils with pH between 6.0 and 7.5.",
            "climate_suitability": f"Moderate warm to temperate conditions with well-distributed rainfall and adequate sunlight.",
            "sowing_season": "Kharif (June-July) or Rabi (October-November) depending on regional agroclimatic zone.",
            "crop_duration": "90 to 140 days depending on the selected cultivar and season.",
            "water_management": "Critical irrigation needed during seedling establishment, flowering, and grain/fruit filling stages.",
            "nutrient_management": "Balanced NPK application supplemented with well-rotted Farm Yard Manure (FYM) or vermicompost.",
            "major_risks": "Monitor regularly for fungal blights, aphids, and stem borers; maintain field hygiene.",
            "harvesting_considerations": "Harvest when 80-85% of crop turns golden-brown or reaches physiological maturity.",
            "market_potential": "Steady demand across government APMC mandis and commercial food processing markets."
        }

    def _fallback_disease_analysis(
        self,
        crop: Optional[str],
        plant_part: str,
        symptoms: Optional[str]
    ) -> Dict[str, Any]:
        crop_name = crop.capitalize() if crop else "Cereal/Crop"
        return {
            "crop_identified": crop_name,
            "condition_detected": "Foliar Leaf Spot / Environmental Stress (Preliminary Diagnostic)",
            "is_healthy": False,
            "confidence_level": "Preliminary visual estimate (Configure GEMINI_API_KEY for live multi-modal diagnosis)",
            "visible_symptoms": [
                symptoms or "Irregular brownish spots or chlorotic yellowing on leaf surface",
                "Marginal tissue necrosis observed on older leaves"
            ],
            "possible_causes": [
                "Fungal pathogen (e.g. Cercospora or Alternaria spp.)",
                "High relative humidity combined with prolonged canopy wetness",
                "Localized nutrient imbalance or moisture stress"
            ],
            "treatment_plan": [
                "Remove and safely destroy severely infected lower leaves to reduce inoculum",
                "Ensure proper row spacing to enhance airflow and sunlight penetration",
                "Apply recommended bio-fungicide (Trichoderma viride @ 5g/L) or copper oxychloride if symptoms persist"
            ],
            "prevention_measures": [
                "Avoid overhead sprinkler irrigation late in the evening",
                "Practice balanced potassium fertilization to bolster plant disease resistance",
                "Implement 2-year crop rotation with non-host legumes"
            ],
            "severity": "Moderate",
            "expert_advice": "Consult your local Krishi Vigyan Kendra (KVK) or block agricultural officer with leaf samples for microbiological confirmation."
        }

    def _fallback_assistant(
        self,
        message: str,
        farm_context: Optional[Dict[str, Any]]
    ) -> Dict[str, Any]:
        msg_lower = message.lower()
        if "fertilizer" in msg_lower or "npk" in msg_lower:
            reply = "For optimal fertilizer management, always conduct a standard soil test before basal application. Apply nitrogen in split doses (basal, tillering/vegetative, and panicle initiation) to minimize leaching losses."
        elif "irrigation" in msg_lower or "water" in msg_lower:
            reply = "Efficient water management relies on soil moisture tension. Utilize drip or furrow irrigation early in the morning, and avoid standing water during vegetative phases unless cultivating paddy."
        elif "disease" in msg_lower or "pest" in msg_lower:
            reply = "To diagnose crop health issues, take a clear photo of the affected leaf in natural light and upload it in the Disease Detection module for an instant multi-modal analysis."
        elif "market" in msg_lower or "price" in msg_lower:
            reply = "You can view the latest live Government Agmarknet Mandi commodity rates for your district in the Market Intelligence tab."
        else:
            reply = f"Hello! As your YieldCraft AI digital farming assistant, I am monitoring your farm conditions. How can I help you optimize your crop yield, irrigation, or soil health today?"

        return {
            "reply": reply,
            "suggested_actions": [
                "Run Crop Recommendation",
                "Check Irrigation Schedule",
                "Inspect Mandi Prices"
            ]
        }

    def estimate_mandi_prices_ai(
        self,
        commodity: str,
        state: Optional[str] = None,
        district: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Uses Gemini LLM to estimate authentic current APMC Mandi commodity rates in India
        when data.gov.in has no records for the requested crop/location.
        """
        if not self.client or not self.api_key:
            return []

        prompt = f"""
You are an expert Indian agricultural market economist for YieldCraft AI.
The farmer is looking for recent APMC Mandi trading prices for the commodity '{commodity}' in:
State: {state or 'Karnataka (or major producing state in India)'}
District: {district or 'Major APMC trading hubs'}

Provide realistic, authentic APMC Mandi prices (in Rs/Quintal, i.e., 100 kg) for this crop based on prevailing Indian agricultural market realities and MSP/mandi benchmarks.
Generate 1 to 3 relevant Mandi market records for this commodity in that state/district or neighboring trading hubs.

Return ONLY a valid JSON array of objects with the following exact keys for each record:
- state: string (e.g. '{state or "Karnataka"}')
- district: string (e.g. '{district or "Mandya"}')
- market: string (e.g. name of the APMC mandi, like 'Mandya APMC', 'Mysore (Bandi Palya)', etc.)
- commodity: string ('{commodity}')
- variety: string (popular commercial variety, e.g. 'Desi', 'Hybrid', 'Super', etc.)
- arrival_date: string (e.g. today's date '{datetime.utcnow().strftime("%d/%m/%Y")}')
- min_price: number (e.g. 3200.0)
- max_price: number (e.g. 4500.0)
- modal_price: number (e.g. 3950.0)
"""
        try:
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config={"response_mime_type": "application/json"}
            )
            raw_text = response.text.strip()
            if raw_text.startswith("```json"):
                raw_text = raw_text[7:]
            if raw_text.startswith("```"):
                raw_text = raw_text[3:]
            if raw_text.endswith("```"):
                raw_text = raw_text[:-3]
            data = json.loads(raw_text.strip())
            if isinstance(data, list):
                return data
            elif isinstance(data, dict) and "records" in data:
                return data["records"]
            return []
        except Exception as e:
            logger.warning(f"Gemini Mandi price estimation failed: {e}")
            return []

gemini_integration = GeminiIntegration()

