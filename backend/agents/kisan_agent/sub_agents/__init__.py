"""Aggregators for Kisan sub-agent wrappers used by tests.

The test imports these names directly from this package:
  - plant_disease_detector_wrapper
  - market_analyzer_wrapper
  - government_schemes_wrapper
"""

# Export simple wrappers pointing to the actual agent modules. These are
# intentionally lightweight to make import succeed in test environments.

from .plant_health_support_agent.agent import disease_agent as plant_disease_detector_wrapper  # type: ignore
from .market_analyzer_agent.agent import market_agent as market_analyzer_wrapper  # type: ignore
from .government_schemes_agent.agent import scheme_agent as government_schemes_wrapper  # type: ignore

__all__ = [
    "plant_disease_detector_wrapper",
    "market_analyzer_wrapper",
    "government_schemes_wrapper",
]


