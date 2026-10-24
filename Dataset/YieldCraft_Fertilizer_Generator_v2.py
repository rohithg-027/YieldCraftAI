
"""
YieldCraft AI - Fertilizer Dataset Generator
Generates a deterministic agronomy-inspired fertilizer recommendation dataset.
"""

import random
import pandas as pd

random.seed(42)

CROPS = {
    "Rice": {"temp":(24,34),"hum":(75,95),"rain":(180,320),"ph":(5.5,6.8),"npk":(90,45,45)},
    "Maize":{"temp":(22,34),"hum":(55,85),"rain":(80,220),"ph":(5.8,7.0),"npk":(100,50,40)},
    "Chickpea":{"temp":(18,30),"hum":(40,65),"rain":(40,120),"ph":(6.0,7.5),"npk":(25,50,25)},
    "Kidneybeans":{"temp":(18,28),"hum":(45,70),"rain":(60,140),"ph":(6.0,7.2),"npk":(30,45,30)},
    "Pigeonpeas":{"temp":(22,34),"hum":(45,75),"rain":(60,180),"ph":(6.0,7.5),"npk":(30,40,30)},
    "Mothbeans":{"temp":(24,36),"hum":(35,60),"rain":(20,80),"ph":(6.5,8.0),"npk":(20,35,25)},
    "Mungbean":{"temp":(24,34),"hum":(45,70),"rain":(40,140),"ph":(6.2,7.5),"npk":(20,35,25)},
    "Blackgram":{"temp":(24,34),"hum":(45,70),"rain":(40,140),"ph":(6.2,7.5),"npk":(25,35,25)},
    "Lentil":{"temp":(18,28),"hum":(40,65),"rain":(40,120),"ph":(6.0,7.5),"npk":(25,40,25)},
    "Pomegranate":{"temp":(24,36),"hum":(45,70),"rain":(40,120),"ph":(6.0,7.5),"npk":(70,45,60)},
    "Banana":{"temp":(25,36),"hum":(70,95),"rain":(120,300),"ph":(6.0,7.5),"npk":(120,50,140)},
    "Mango":{"temp":(24,36),"hum":(50,80),"rain":(80,220),"ph":(5.8,7.2),"npk":(80,40,80)},
    "Grapes":{"temp":(20,32),"hum":(50,75),"rain":(40,120),"ph":(6.0,7.0),"npk":(90,50,110)},
    "Watermelon":{"temp":(22,35),"hum":(50,75),"rain":(40,140),"ph":(6.0,7.5),"npk":(60,40,90)},
    "Muskmelon":{"temp":(22,35),"hum":(50,75),"rain":(40,140),"ph":(6.0,7.5),"npk":(60,40,90)},
    "Apple":{"temp":(15,28),"hum":(55,80),"rain":(80,180),"ph":(6.0,7.0),"npk":(80,45,90)},
    "Orange":{"temp":(20,34),"hum":(55,80),"rain":(80,220),"ph":(6.0,7.5),"npk":(90,45,90)},
    "Papaya":{"temp":(24,36),"hum":(65,90),"rain":(120,280),"ph":(6.0,7.2),"npk":(100,45,100)},
    "Coconut":{"temp":(24,34),"hum":(70,95),"rain":(180,320),"ph":(5.5,7.0),"npk":(80,35,120)},
    "Cotton":{"temp":(24,36),"hum":(45,70),"rain":(40,140),"ph":(6.0,7.0),"npk":(100,50,60)},
    "Jute":{"temp":(24,35),"hum":(70,95),"rain":(180,320),"ph":(5.5,7.0),"npk":(90,40,40)},
    "Coffee":{"temp":(18,28),"hum":(70,95),"rain":(180,300),"ph":(5.5,6.8),"npk":(90,45,90)},
}

SOILS=["Sandy","Loamy","Clay","Black","Red","Laterite","Alluvial"]
STAGES=["Seedling","Vegetative","Flowering","Fruiting","Harvest"]

def recommend(crop,stage,soil,ph,n,p,k):
    rn,rp,rk=CROPS[crop]["npk"]
    if ph<5.5: return "Gypsum"
    if ph>7.8: return "Borax"
    if soil=="Red" and n<rn*0.8: return "Neem Coated Urea"
    if soil=="Black" and k<rk*0.8: return "MOP"
    if n<rn*0.7: return "Urea"
    if p<rp*0.7: return "DAP"
    if k<rk*0.7: return "SOP"
    return {
        "Seedling":"NPK 12-32-16",
        "Vegetative":"Urea",
        "Flowering":"NPK 17-17-17",
        "Fruiting":"NPK 20-20-20",
        "Harvest":"Compost"
    }[stage]

rows=[]
TARGET_ROWS=20000
per_crop=TARGET_ROWS//len(CROPS)

for crop,prof in CROPS.items():
    for _ in range(per_crop):
        t=random.randint(*prof["temp"])
        h=random.randint(*prof["hum"])
        r=random.randint(*prof["rain"])
        ph=round(random.uniform(prof["ph"][0],prof["ph"][1]),1)
        soil=random.choice(SOILS)
        stage=random.choice(STAGES)
        rn,rp,rk=prof["npk"]
        n=max(10,min(140,int(random.gauss(rn,15))))
        p=max(5,min(90,int(random.gauss(rp,8))))
        k=max(5,min(140,int(random.gauss(rk,12))))
        moisture= random.randint(20,55) if soil=="Sandy" else random.randint(35,80)
        fert=recommend(crop,stage,soil,ph,n,p,k)
        rows.append([t,h,r,moisture,soil,ph,n,p,k,crop,stage,fert])

df=pd.DataFrame(rows,columns=[
"Temperature","Humidity","Rainfall","Moisture","Soil Type","Soil pH",
"Nitrogen","Phosphorous","Potassium","Crop Type","Growth Stage","Fertilizer Name"])

df=df.sample(frac=1,random_state=42).reset_index(drop=True)
df.to_csv("YieldCraft_Fertilizer_Dataset_v2.csv",index=False)
print(df.head())
print(df["Fertilizer Name"].value_counts())
