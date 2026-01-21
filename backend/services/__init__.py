"""
Kisan AI Backend Services

This module provides various services for the Kisan AI application.
"""

from services.qdrant_service import QdrantService, get_qdrant_service

__all__ = [
    "QdrantService",
    "get_qdrant_service",
]

