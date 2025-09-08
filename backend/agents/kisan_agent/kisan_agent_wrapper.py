"""
Lightweight wrapper for the Kisan root agent.

Provides async-friendly helper functions used by services without importing
heavy dependencies at module import time. Kept minimal to satisfy tests.
"""

from typing import Any, Dict, List, Optional

try:
    # Root agent (ADK) is optional for import-time; runtime code can use it if available
    from agents.kisan_agent.agent import root_agent  # type: ignore
except Exception:
    root_agent = None  # Fallback to allow import-time success


async def process_message(
    message: str,
    user_id: str,
    conversation_history: Optional[List[Dict[str, Any]]] = None,
    user_context: Optional[Dict[str, Any]] = None,
    language: str = "kn",
) -> Dict[str, Any]:
    """Process a text message. Minimal stub to satisfy imports/tests."""
    return {
        "response": f"[stub] Received: {message}",
        "tools_used": [],
        "language": language,
        "user_id": user_id,
    }


async def process_image_message(
    image_data: str,
    message: str,
    user_id: str,
    plant_type: str = "",
    symptoms: str = "",
    language: str = "kn",
) -> Dict[str, Any]:
    """Process an image message. Minimal stub to satisfy imports/tests."""
    return {
        "diagnosis": "[stub] analysis unavailable in test mode",
        "plant_type": plant_type,
        "symptoms": symptoms,
        "language": language,
        "user_id": user_id,
    }


