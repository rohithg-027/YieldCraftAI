import os
import logging
from pathlib import Path
from typing import List, Dict, Any, Tuple
import joblib
import numpy as np
import pandas as pd
from app.core.config import settings

logger = logging.getLogger("yieldcraft.ml")

class ModelRegistry:
    def __init__(self):
        self.crop_model = None
        self.crop_scaler = None
        self.crop_label_encoder = None
        self.crop_features = None

        self.fertilizer_model = None
        self.fertilizer_target_encoder = None

        self.yield_model = None

        self.irrigation_model = None
        self.irrigation_target_encoder = None

        self.is_initialized = False

    def load_models(self):
        base_dir = Path(settings.MODEL_BASE_DIR)
        logger.info(f"Loading ML models from base directory: {base_dir}")

        # 1. Crop Recommendation Artifacts
        crop_dir = base_dir / "crop_recommendation_artifacts" / "models"
        if crop_dir.exists():
            try:
                self.crop_model = joblib.load(crop_dir / "crop_recommendation_model.pkl")
                self.crop_scaler = joblib.load(crop_dir / "standard_scaler.pkl")
                self.crop_label_encoder = joblib.load(crop_dir / "label_encoder.pkl")
                self.crop_features = joblib.load(crop_dir / "feature_names.pkl")
                logger.info("Crop recommendation model & artifacts loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load crop recommendation model: {e}")
        else:
            logger.warning(f"Crop directory not found at {crop_dir}")

        # 2. Fertilizer Recommendation Artifacts
        fert_dir = base_dir / "fertilizer_recommendation_artifacts"
        if fert_dir.exists():
            try:
                self.fertilizer_model = joblib.load(fert_dir / "fertilizer_recommendation_model.pkl")
                self.fertilizer_target_encoder = joblib.load(fert_dir / "target_encoder.pkl")
                logger.info("Fertilizer recommendation pipeline loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load fertilizer recommendation model: {e}")
        else:
            logger.warning(f"Fertilizer directory not found at {fert_dir}")

        # 3. Yield Prediction Artifacts
        yield_dir = base_dir / "yield_prediction_artifacts" / "models"
        if yield_dir.exists():
            try:
                self.yield_model = joblib.load(yield_dir / "yield_prediction_model.pkl")
                logger.info("Yield prediction pipeline loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load yield prediction model: {e}")
        else:
            logger.warning(f"Yield directory not found at {yield_dir}")

        # 4. Irrigation Recommendation Artifacts
        irrig_dir = base_dir / "Irrigation_Recommendation_Artifacts"
        if irrig_dir.exists():
            try:
                self.irrigation_model = joblib.load(irrig_dir / "irrigation_recommendation_model.pkl")
                self.irrigation_target_encoder = joblib.load(irrig_dir / "irrigation_target_encoder.pkl")
                logger.info("Irrigation recommendation pipeline loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load irrigation recommendation model: {e}")
        else:
            logger.warning(f"Irrigation directory not found at {irrig_dir}")

        self.is_initialized = True

    def predict_crop(
        self,
        nitrogen: float,
        phosphorus: float,
        potassium: float,
        temperature: float,
        humidity: float,
        ph: float,
        rainfall: float,
        top_n: int = 5
    ) -> List[Dict[str, Any]]:
        if self.crop_model is None or self.crop_label_encoder is None:
            raise RuntimeError("Crop recommendation model is not loaded.")

        sample_df = pd.DataFrame([{
            "N": nitrogen,
            "P": phosphorus,
            "K": potassium,
            "temperature": temperature,
            "humidity": humidity,
            "ph": ph,
            "rainfall": rainfall
        }])

        probabilities = self.crop_model.predict_proba(sample_df)[0]
        sorted_indices = np.argsort(probabilities)[::-1][:top_n]

        results = []
        for rank, idx in enumerate(sorted_indices, start=1):
            crop_name = str(self.crop_label_encoder.classes_[idx])
            prob = float(probabilities[idx])
            results.append({
                "rank": rank,
                "crop_name": crop_name,
                "probability": round(prob, 4),
                "confidence_percentage": round(prob * 100.0, 2)
            })
        return results

    def predict_fertilizer(
        self,
        temperature: float,
        humidity: float,
        rainfall: float,
        moisture: float,
        soil_type: str,
        soil_ph: float,
        nitrogen: float,
        phosphorus: float,
        potassium: float,
        crop_type: str,
        growth_stage: str
    ) -> Dict[str, Any]:
        if self.fertilizer_model is None or self.fertilizer_target_encoder is None:
            raise RuntimeError("Fertilizer recommendation model is not loaded.")

        # Normalize casing and known aliases to match OneHotEncoder categories exactly
        soil_clean = str(soil_type).strip().title()
        if soil_clean in ["Clayey", "Clay Soil"]:
            soil_clean = "Clay"
        elif soil_clean not in ["Alluvial", "Black", "Clay", "Laterite", "Loamy", "Red", "Sandy"]:
            soil_clean = "Loamy"

        crop_clean = str(crop_type).strip().title()
        crop_alias_map = {
            "Kidney Beans": "Kidneybeans",
            "Pigeon Peas": "Pigeonpeas",
            "Moth Beans": "Mothbeans",
            "Mung Bean": "Mungbean",
            "Green Gram": "Mungbean",
            "Black Gram": "Blackgram",
            "Musk Melon": "Muskmelon",
            "Water Melon": "Watermelon",
            "Paddy": "Rice",
            "Corn": "Maize"
        }
        crop_clean = crop_alias_map.get(crop_clean, crop_clean)

        stage_clean = str(growth_stage).strip().title()
        stage_map = {
            "Tillering": "Vegetative",
            "Sowing": "Seedling",
            "Ripening": "Harvest",
            "Maturity": "Harvest"
        }
        stage_clean = stage_map.get(stage_clean, stage_clean)
        if stage_clean not in ["Flowering", "Fruiting", "Harvest", "Seedling", "Vegetative"]:
            stage_clean = "Vegetative"

        sample_df = pd.DataFrame([{
            "Temperature": float(temperature),
            "Humidity": float(humidity),
            "Rainfall": float(rainfall),
            "Moisture": float(moisture),
            "Soil Type": soil_clean,
            "Soil pH": float(soil_ph),
            "Nitrogen": float(nitrogen),
            "Phosphorous": float(phosphorus),
            "Potassium": float(potassium),
            "Crop Type": crop_clean,
            "Growth Stage": stage_clean
        }])

        pred_raw = self.fertilizer_model.predict(sample_df)
        pred_idx = pred_raw[0]
        if isinstance(pred_idx, (int, np.integer, np.ndarray, list)):
            if isinstance(pred_idx, (np.ndarray, list)):
                pred_idx = pred_idx[0]
            fertilizer_name = str(self.fertilizer_target_encoder.inverse_transform([int(pred_idx)])[0])
        else:
            fertilizer_name = str(pred_idx)

        confidence = None
        if hasattr(self.fertilizer_model, "predict_proba"):
            try:
                probas = self.fertilizer_model.predict_proba(sample_df)[0]
                confidence = float(np.max(probas))
            except Exception:
                pass

        return {
            "fertilizer_name": fertilizer_name,
            "confidence": round(confidence, 4) if confidence is not None else None
        }

    def predict_yield(
        self,
        crop: str,
        crop_year: int,
        season: str,
        state: str,
        area: float,
        annual_rainfall: float,
        fertilizer: float,
        pesticide: float
    ) -> float:
        if self.yield_model is None:
            raise RuntimeError("Yield prediction model is not loaded.")

        sample_df = pd.DataFrame([{
            "Crop": str(crop),
            "Crop_Year": int(crop_year),
            "Season": str(season),
            "State": str(state),
            "Area": float(area),
            "Annual_Rainfall": float(annual_rainfall),
            "Fertilizer": float(fertilizer),
            "Pesticide": float(pesticide)
        }])

        predicted_yield = self.yield_model.predict(sample_df)[0]
        return float(predicted_yield)

    def predict_irrigation(
        self,
        soil_type: str,
        soil_ph: float,
        soil_moisture: float,
        organic_carbon: float,
        electrical_conductivity: float,
        temperature_c: float,
        humidity: float,
        rainfall_mm: float,
        sunlight_hours: float,
        wind_speed_kmh: float,
        crop_type: str,
        crop_growth_stage: str,
        season: str,
        irrigation_type: str,
        water_source: str,
        field_area_hectare: float,
        mulching_used: str,
        previous_irrigation_mm: float,
        region: str
    ) -> Dict[str, Any]:
        if self.irrigation_model is None or self.irrigation_target_encoder is None:
            raise RuntimeError("Irrigation recommendation model is not loaded.")

        # Normalize categorical features to match training categories:
        # Soil_Type: ['Clay', 'Loamy', 'Sandy', 'Silt']
        st_clean = str(soil_type).strip().title()
        if st_clean in ["Black", "Laterite", "Clayey"]:
            norm_soil = "Clay"
        elif st_clean in ["Red", "Sandy"]:
            norm_soil = "Sandy"
        elif st_clean in ["Alluvial", "Loamy"]:
            norm_soil = "Loamy"
        else:
            norm_soil = "Loamy"

        # Water_Source: ['Groundwater', 'Rainwater', 'Reservoir', 'River']
        ws_clean = str(water_source).strip().title()
        if ws_clean in ["Borewell", "Well", "Tubewell", "Groundwater"]:
            norm_water = "Groundwater"
        elif ws_clean in ["Canal", "River", "Stream"]:
            norm_water = "River"
        elif ws_clean in ["Pond", "Tank", "Reservoir", "Dam"]:
            norm_water = "Reservoir"
        else:
            norm_water = "Groundwater"

        # Irrigation_Type: ['Canal', 'Drip', 'Rainfed', 'Sprinkler']
        it_clean = str(irrigation_type).strip().title()
        if it_clean in ["Flood", "Furrow", "Basin", "Surface"]:
            norm_it = "Canal"
        elif it_clean in ["Drip", "Sprinkler", "Rainfed", "Canal"]:
            norm_it = it_clean
        else:
            norm_it = "Drip"

        # Crop_Type: ['Cotton', 'Maize', 'Potato', 'Rice', 'Sugarcane', 'Wheat']
        ct_clean = str(crop_type).strip().title()
        if ct_clean in ["Cotton", "Maize", "Potato", "Rice", "Sugarcane", "Wheat"]:
            norm_crop = ct_clean
        elif ct_clean in ["Chickpea", "Lentil", "Blackgram", "Mungbean", "Pigeonpeas", "Mothbeans", "Kidneybeans"]:
            norm_crop = "Wheat"
        elif ct_clean in ["Banana", "Mango", "Papaya", "Pomegranate", "Coconut", "Coffee"]:
            norm_crop = "Sugarcane"
        elif ct_clean in ["Tomato", "Onion", "Chilli", "Watermelon", "Muskmelon"]:
            norm_crop = "Potato"
        elif ct_clean in ["Jute"]:
            norm_crop = "Rice"
        else:
            norm_crop = "Maize"

        # Crop_Growth_Stage: ['Flowering', 'Harvest', 'Sowing', 'Vegetative']
        gs_clean = str(crop_growth_stage).strip().title()
        if gs_clean in ["Seedling", "Germination"]:
            norm_stage = "Sowing"
        elif gs_clean in ["Tillering", "Vegetative"]:
            norm_stage = "Vegetative"
        elif gs_clean in ["Fruiting", "Flowering", "Booting", "Panicle"]:
            norm_stage = "Flowering"
        elif gs_clean in ["Ripening", "Maturity", "Harvest"]:
            norm_stage = "Harvest"
        else:
            norm_stage = "Vegetative"

        # Season: ['Kharif', 'Rabi', 'Zaid']
        sz_clean = str(season).strip().title()
        if sz_clean not in ["Kharif", "Rabi", "Zaid"]:
            sz_clean = "Kharif"

        # Region: ['Central', 'East', 'North', 'South', 'West']
        reg_clean = str(region).strip().title()
        if reg_clean not in ["Central", "East", "North", "South", "West"]:
            reg_clean = "South"

        # Mulching: ['No', 'Yes']
        mulch_clean = "Yes" if str(mulching_used).strip().lower() in ["yes", "true", "1"] else "No"

        # Ensure rainfall aligns with model training feature domain (Annual Rainfall ~1000-1400mm)
        norm_rainfall = float(rainfall_mm)
        if norm_rainfall < 150.0:
            norm_rainfall = 1150.0

        sample_df = pd.DataFrame([{
            "Soil_Type": norm_soil,
            "Soil_pH": float(soil_ph),
            "Soil_Moisture": float(soil_moisture),
            "Organic_Carbon": float(organic_carbon),
            "Electrical_Conductivity": float(electrical_conductivity),
            "Temperature_C": float(temperature_c),
            "Humidity": float(humidity),
            "Rainfall_mm": norm_rainfall,
            "Sunlight_Hours": float(sunlight_hours),
            "Wind_Speed_kmh": float(wind_speed_kmh),
            "Crop_Type": norm_crop,
            "Crop_Growth_Stage": norm_stage,
            "Season": sz_clean,
            "Irrigation_Type": norm_it,
            "Water_Source": norm_water,
            "Field_Area_hectare": float(field_area_hectare),
            "Mulching_Used": mulch_clean,
            "Previous_Irrigation_mm": float(previous_irrigation_mm),
            "Region": reg_clean
        }])

        pred_raw = self.irrigation_model.predict(sample_df)
        pred_idx = pred_raw[0]
        if isinstance(pred_idx, (int, np.integer, np.ndarray, list)):
            if isinstance(pred_idx, (np.ndarray, list)):
                pred_idx = pred_idx[0]
            irrigation_need = str(self.irrigation_target_encoder.inverse_transform([int(pred_idx)])[0])
        else:
            irrigation_need = str(pred_idx)

        prob_dict = {}
        if hasattr(self.irrigation_model, "predict_proba"):
            try:
                probas = self.irrigation_model.predict_proba(sample_df)[0]
                classes = self.irrigation_target_encoder.classes_
                for cls, pr in zip(classes, probas):
                    prob_dict[str(cls)] = round(float(pr), 4)
            except Exception:
                pass

        # Soil moisture agronomic boundary calibration:
        # If moisture is severely dry (< 22%), urgency is High
        # If moisture is well-saturated (> 50%), urgency is Low
        if float(soil_moisture) < 22.0:
            irrigation_need = "High"
            prob_dict["High"] = max(prob_dict.get("High", 0.0), 0.88)
            prob_dict["Low"] = min(prob_dict.get("Low", 0.0), 0.05)
            prob_dict["Medium"] = round(1.0 - prob_dict["High"] - prob_dict["Low"], 4)
        elif float(soil_moisture) > 52.0:
            irrigation_need = "Low"
            prob_dict["Low"] = max(prob_dict.get("Low", 0.0), 0.85)
            prob_dict["High"] = min(prob_dict.get("High", 0.0), 0.03)
            prob_dict["Medium"] = round(1.0 - prob_dict["Low"] - prob_dict["High"], 4)

        return {
            "irrigation_need": irrigation_need,
            "probabilities": prob_dict
        }


model_registry = ModelRegistry()
