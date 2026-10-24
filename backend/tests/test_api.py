import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.ml.model_registry import model_registry

client = TestClient(app)

@pytest.fixture(scope="session", autouse=True)
def load_all_models():
    model_registry.load_models()

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["models_loaded"]["crop_recommendation"] is True
    assert data["models_loaded"]["fertilizer_recommendation"] is True
    assert data["models_loaded"]["yield_prediction"] is True
    assert data["models_loaded"]["irrigation_recommendation"] is True

def test_farm_lifecycle():
    headers = {"Authorization": "Bearer test-user-999"}

    # 1. Create farm
    farm_payload = {
        "farm_name": "Cauvery Green Valley",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "location_accuracy_meters": 5.0,
        "address": "Mandya Rural",
        "village": "Gejjalagere",
        "district": "Mandya",
        "state": "Karnataka",
        "area": 2.5,
        "area_unit": "hectares",
        "soil_type": "Loamy",
        "irrigation_source": "Canal",
        "active_crop": "Rice"
    }
    create_res = client.post("/api/v1/farms", json=farm_payload, headers=headers)
    assert create_res.status_code == 201
    farm = create_res.json()
    farm_id = farm["farm_id"]
    assert farm["farm_name"] == "Cauvery Green Valley"

    # 2. List farms
    list_res = client.get("/api/v1/farms", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1

    # 3. Add Soil Profile
    soil_payload = {
        "nitrogen": 88.0,
        "phosphorus": 42.0,
        "potassium": 45.0,
        "ph": 6.5,
        "moisture": 50.0,
        "electrical_conductivity": 1.1,
        "organic_carbon": 0.65,
        "soil_type": "Loamy",
        "source": "Manual Lab Entry"
    }
    soil_res = client.post(f"/api/v1/farms/{farm_id}/soil-profiles", json=soil_payload, headers=headers)
    assert soil_res.status_code == 201
    assert soil_res.json()["nitrogen"] == 88.0

    # 4. Get Latest Soil Profile
    latest_res = client.get(f"/api/v1/farms/{farm_id}/soil-profiles/latest", headers=headers)
    assert latest_res.status_code == 200
    assert latest_res.json()["ph"] == 6.5

def test_crop_recommendation():
    headers = {"Authorization": "Bearer test-user-999"}
    payload = {
        "nitrogen": 90.0,
        "phosphorus": 42.0,
        "potassium": 43.0,
        "temperature": 21.5,
        "humidity": 82.0,
        "ph": 6.5,
        "rainfall": 210.0,
        "top_n": 5
    }
    res = client.post("/api/v1/crops/recommend?enrich_with_gemini=false", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert len(data["candidates"]) == 5
    top_candidate = data["candidates"][0]
    assert top_candidate["rank"] == 1
    assert top_candidate["crop_name"].lower() == "rice"
    assert top_candidate["probability"] > 0.5

def test_fertilizer_recommendation():
    headers = {"Authorization": "Bearer test-user-999"}
    payload = {
        "temperature": 28.0,
        "humidity": 70.0,
        "rainfall": 150.0,
        "moisture": 45.0,
        "soil_type": "Loamy",
        "soil_ph": 6.5,
        "nitrogen": 80.0,
        "phosphorus": 40.0,
        "potassium": 40.0,
        "crop_type": "Rice",
        "growth_stage": "Vegetative"
    }
    res = client.post("/api/v1/fertilizer/recommend", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "fertilizer_name" in data
    assert len(data["fertilizer_name"]) > 0

def test_yield_prediction():
    headers = {"Authorization": "Bearer test-user-999"}
    payload = {
        "crop": "Rice",
        "crop_year": 2024,
        "season": "Kharif",
        "state": "Karnataka",
        "area": 2.0,
        "area_unit": "hectares",
        "annual_rainfall": 950.0,
        "fertilizer": 140.0,
        "pesticide": 20.0
    }
    res = client.post("/api/v1/yield/predict", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["predicted_yield_per_hectare"] > 0.0
    assert data["total_estimated_production"] == round(data["predicted_yield_per_hectare"] * 2.0, 2)

def test_irrigation_recommendation():
    headers = {"Authorization": "Bearer test-user-999"}
    payload = {
        "soil_type": "Loamy",
        "soil_ph": 6.5,
        "soil_moisture": 35.0,
        "organic_carbon": 0.5,
        "electrical_conductivity": 1.2,
        "temperature_c": 28.0,
        "humidity": 65.0,
        "rainfall_mm": 5.0,
        "sunlight_hours": 7.5,
        "wind_speed_kmh": 12.0,
        "crop_type": "Rice",
        "crop_growth_stage": "Vegetative",
        "season": "Kharif",
        "irrigation_type": "Drip",
        "water_source": "Borewell",
        "field_area_hectare": 2.0,
        "mulching_used": "No",
        "previous_irrigation_mm": 15.0,
        "region": "South"
    }
    res = client.post("/api/v1/irrigation/recommend", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["irrigation_need"] in ["High", "Medium", "Low"]
    assert "Medium" in data["probabilities"]

def test_market_prices():
    res = client.get("/api/v1/market/prices?commodity=Rice")
    assert res.status_code == 200
    data = res.json()
    assert data["total_records"] > 0
    record = data["records"][0]
    assert record["commodity"] == "Rice"
    assert record["price_unit"] == "Rs/Quintal"
    assert record["modal_price"] > 0.0

def test_profit_estimation():
    headers = {"Authorization": "Bearer test-user-999"}
    payload = {
        "crop": "Rice",
        "area_hectares": 2.0,
        "predicted_yield_per_hectare": 35.0,
        "market_price_per_quintal": 3800.0,
        "market_name": "Shimoga Mandi",
        "expenses": {
            "seeds": 5000.0,
            "fertilizer": 12000.0,
            "crop_protection": 6000.0,
            "irrigation": 4000.0,
            "labour": 25000.0,
            "machinery": 10000.0,
            "transport": 5000.0,
            "miscellaneous": 3000.0
        }
    }
    res = client.post("/api/v1/profit/estimate", json=payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["expected_production_quintals"] == 70.0
    assert data["base_gross_revenue"] == 70.0 * 3800.0
    assert data["total_expenses"] == 70000.0
    assert data["base_net_profit"] == (70.0 * 3800.0) - 70000.0
    assert "conservative" in data["scenarios"]
    assert "optimistic" in data["scenarios"]

def test_decision_support_and_diary():
    headers = {"Authorization": "Bearer test-user-999"}
    # 1. Create farm
    farm_res = client.post("/api/v1/farms", json={
        "farm_name": "Cauvery Demo Farm",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "district": "Bangalore",
        "state": "Karnataka",
        "area": 2.0,
        "area_unit": "hectares",
        "soil_type": "Loamy",
        "active_crop": "Rice"
    }, headers=headers)
    farm_id = farm_res.json()["farm_id"]

    # 2. Add soil profile
    client.post(f"/api/v1/farms/{farm_id}/soil-profiles", json={
        "nitrogen": 90.0,
        "phosphorus": 45.0,
        "potassium": 45.0,
        "ph": 6.5,
        "moisture": 48.0,
        "source": "Manual Lab Entry"
    }, headers=headers)

    # 3. Add diary entry
    diary_res = client.post(f"/api/v1/farms/{farm_id}/diary", json={
        "category": "activity",
        "title": "Nursery Sowing",
        "notes": "Sown certified high-yielding paddy seeds in nursery beds with vermicompost.",
        "crop": "Rice",
        "cost": 3500.0
    }, headers=headers)
    assert diary_res.status_code == 201

    # 4. List diary entries
    entries = client.get(f"/api/v1/farms/{farm_id}/diary", headers=headers).json()
    assert len(entries) >= 1
    assert entries[0]["title"] == "Nursery Sowing"

    # 5. Check Unified Decision Support summary
    ds_res = client.get(f"/api/v1/farms/{farm_id}/decision-support", headers=headers)
    assert ds_res.status_code == 200
    ds_data = ds_res.json()
    assert ds_data["farm_id"] == farm_id
    assert len(ds_data["top_recommended_crops"]) > 0
    assert len(ds_data["key_action_items"]) > 0

