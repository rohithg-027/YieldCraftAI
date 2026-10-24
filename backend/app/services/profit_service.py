from datetime import datetime
from app.schemas.profit import (
    ProfitEstimationRequest,
    ProfitEstimationResponse,
    ScenarioDetail
)

class ProfitService:
    @staticmethod
    def calculate_profit(req: ProfitEstimationRequest) -> ProfitEstimationResponse:
        area = req.area_hectares
        base_yield = req.predicted_yield_per_hectare
        base_price = req.market_price_per_quintal

        total_production = area * base_yield

        # Total itemized expenses
        exp = req.expenses
        total_expenses = (
            exp.seeds +
            exp.fertilizer +
            exp.crop_protection +
            exp.irrigation +
            exp.labour +
            exp.machinery +
            exp.transport +
            exp.miscellaneous
        )

        base_gross_revenue = total_production * base_price
        base_net_profit = base_gross_revenue - total_expenses
        base_margin = (base_net_profit / base_gross_revenue * 100.0) if base_gross_revenue > 0 else 0.0

        def build_scenario(name: str, yield_mult: float, price_mult: float, desc: str) -> ScenarioDetail:
            s_yield = base_yield * yield_mult
            s_price = base_price * price_mult
            s_prod = area * s_yield
            s_rev = s_prod * s_price
            s_profit = s_rev - total_expenses
            s_margin = (s_profit / s_rev * 100.0) if s_rev > 0 else 0.0
            return ScenarioDetail(
                scenario_name=name,
                assumed_yield_per_ha=round(s_yield, 2),
                assumed_price_per_quintal=round(s_price, 2),
                total_production_quintals=round(s_prod, 2),
                gross_revenue=round(s_rev, 2),
                total_expenses=round(total_expenses, 2),
                net_profit=round(s_profit, 2),
                profit_margin_pct=round(s_margin, 2),
                description=desc
            )

        scenarios = {
            "conservative": build_scenario(
                "Conservative Scenario",
                0.85,
                0.90,
                "Adverse weather or market dip (-15% yield, -10% market price)"
            ),
            "base": build_scenario(
                "Base Scenario",
                1.0,
                1.0,
                "Expected baseline yield and prevailing APMC mandi modal price"
            ),
            "optimistic": build_scenario(
                "Optimistic Scenario",
                1.15,
                1.10,
                "Favorable climate and premium market realization (+15% yield, +10% market price)"
            )
        }

        return ProfitEstimationResponse(
            crop=req.crop,
            area_hectares=round(area, 2),
            expected_production_quintals=round(total_production, 2),
            market_price_per_quintal=round(base_price, 2),
            market_name=req.market_name or "Local Mandi",
            total_expenses=round(total_expenses, 2),
            base_gross_revenue=round(base_gross_revenue, 2),
            base_net_profit=round(base_net_profit, 2),
            profit_margin_percentage=round(base_margin, 2),
            scenarios=scenarios,
            disclaimer="Estimates are for planning purposes and do not guarantee market realization.",
            calculated_at=datetime.utcnow().isoformat() + "Z"
        )

profit_service = ProfitService()
