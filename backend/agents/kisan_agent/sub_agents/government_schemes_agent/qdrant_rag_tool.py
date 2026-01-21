"""
Qdrant RAG Tool for Government Schemes Agent

This module provides a RAG retrieval tool that uses Qdrant vector database
for retrieving relevant government scheme information.
"""

import os
import sys
from pathlib import Path
from typing import List, Optional
from dotenv import load_dotenv

# Add backend to path for imports
backend_path = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(backend_path))

load_dotenv()

from google.adk.tools import FunctionTool

# Qdrant configuration
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", "6333"))
COLLECTION_NAME = os.getenv("QDRANT_COLLECTION_NAME", "government_schemes")

# Lazy import of qdrant service to avoid circular imports
_qdrant_service = None


def _get_qdrant_service():
    """Lazy load the Qdrant service."""
    global _qdrant_service
    if _qdrant_service is None:
        try:
            from services.qdrant_service import get_qdrant_service
            _qdrant_service = get_qdrant_service()
        except Exception as e:
            print(f"Error loading Qdrant service: {e}")
            return None
    return _qdrant_service


def retrieve_government_schemes(
    query: str,
    top_k: int = 5,
    score_threshold: float = 0.5
) -> str:
    """
    Retrieve relevant government agricultural scheme information from the Qdrant vector database.
    
    Use this tool to search for information about government agricultural schemes,
    subsidies, welfare programs, and related policies for farmers.
    
    Args:
        query: The search query describing what scheme information you're looking for.
               Examples: "subsidy for organic farming", "PM Kisan scheme benefits",
               "irrigation assistance Karnataka"
        top_k: Number of most relevant documents to retrieve (default: 5)
        score_threshold: Minimum similarity score for results (default: 0.5)
    
    Returns:
        A formatted string containing relevant government scheme information
        from the corpus, or a message indicating no results were found.
    """
    qdrant_service = _get_qdrant_service()
    
    if qdrant_service is None:
        return (
            "Unable to connect to the vector database. "
            "Please ensure Qdrant is running and try again. "
            "For now, use Google Search to find scheme information."
        )
    
    try:
        results = qdrant_service.search(
            query=query,
            collection_name=COLLECTION_NAME,
            top_k=top_k,
            score_threshold=score_threshold
        )
        
        if not results:
            return (
                f"No relevant scheme information found in the corpus for query: '{query}'. "
                "Consider using Google Search for more recent or specific information. "
                "Default portal for Karnataka schemes: https://raitamitra.karnataka.gov.in/english"
            )
        
        # Format results
        formatted_results = []
        formatted_results.append(f"Found {len(results)} relevant documents for: '{query}'\n")
        formatted_results.append("-" * 50)
        
        for i, result in enumerate(results, 1):
            formatted_results.append(f"\n**Document {i}** (Relevance: {result['score']:.2%})")
            formatted_results.append(f"Source: {result['source']}")
            formatted_results.append(f"Content:\n{result['text']}")
            formatted_results.append("-" * 50)
        
        formatted_results.append(
            "\nNote: For the most current information, verify on official government portals."
        )
        
        return "\n".join(formatted_results)
        
    except Exception as e:
        return (
            f"Error searching the scheme database: {str(e)}. "
            "Please try using Google Search as an alternative."
        )


# Create the function tool for the agent
qdrant_rag_tool = FunctionTool(
    func=retrieve_government_schemes,
)


# Alternative: Direct function for use without ADK wrapper
def search_schemes(query: str, top_k: int = 5) -> List[dict]:
    """
    Direct search function that returns raw results.
    
    Args:
        query: Search query
        top_k: Number of results
        
    Returns:
        List of result dictionaries
    """
    qdrant_service = _get_qdrant_service()
    if qdrant_service is None:
        return []
    
    return qdrant_service.search(
        query=query,
        collection_name=COLLECTION_NAME,
        top_k=top_k
    )

