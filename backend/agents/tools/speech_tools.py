"""Proxy module to expose SpeechTools under agents.tools.* path for tests."""

from services.speech_tools import SpeechTools

__all__ = ["SpeechTools"]


