"""Facades for tool modules used by tests.

Exposes `SpeechTools` and `StorageTools` from the services layer so that
`from agents.tools.speech_tools import SpeechTools` works.
"""

from services.speech_tools import SpeechTools  # re-export for compatibility
from services.storage_tools import StorageTools  # re-export for compatibility

__all__ = ["SpeechTools", "StorageTools"]


