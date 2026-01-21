"""
Qdrant Vector Database Service for KisanVaani

This module provides Qdrant-based vector storage and retrieval
for the government schemes RAG functionality.
"""

import os
from typing import List, Optional
from dotenv import load_dotenv
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import google.generativeai as genai

load_dotenv()

# Configuration
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", "6333"))
QDRANT_URL = os.getenv("QDRANT_URL")  # For Qdrant Cloud
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY")  # For Qdrant Cloud
COLLECTION_NAME = os.getenv("QDRANT_COLLECTION_NAME", "government_schemes")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "models/embedding-001")


class QdrantService:
    """Service class for Qdrant vector database operations."""
    
    def __init__(self, use_memory: bool = False):
        """
        Initialize Qdrant client.
        
        Args:
            use_memory: If True, use in-memory Qdrant (for testing without server)
        """
        self.use_memory = use_memory
        
        if use_memory:
            # Use in-memory Qdrant (no server needed)
            self.client = QdrantClient(":memory:")
            print("Using in-memory Qdrant (data will not persist)")
        elif QDRANT_URL and QDRANT_API_KEY:
            # Use Qdrant Cloud
            self.client = QdrantClient(
                url=QDRANT_URL,
                api_key=QDRANT_API_KEY
            )
        else:
            # Try to use local Qdrant, fall back to in-memory
            try:
                self.client = QdrantClient(
                    host=QDRANT_HOST,
                    port=QDRANT_PORT
                )
                # Test connection
                self.client.get_collections()
                print(f"Connected to Qdrant at {QDRANT_HOST}:{QDRANT_PORT}")
            except Exception as e:
                print(f"Could not connect to Qdrant server: {e}")
                print("Falling back to in-memory Qdrant (data will not persist)")
                self.client = QdrantClient(":memory:")
                self.use_memory = True
        
        # Initialize Google embedding model
        google_api_key = os.getenv("GOOGLE_API_KEY")
        if google_api_key:
            genai.configure(api_key=google_api_key)
        
        self.embedding_dimension = 768  # Default for Google's embedding model
        
    def get_embedding(self, text: str) -> List[float]:
        """
        Generate embedding for given text using Google's embedding model.
        
        Args:
            text: Text to embed
            
        Returns:
            List of floats representing the embedding vector
        """
        try:
            result = genai.embed_content(
                model=EMBEDDING_MODEL,
                content=text,
                task_type="retrieval_document"
            )
            return result['embedding']
        except Exception as e:
            print(f"Error generating embedding: {e}")
            # Return zero vector as fallback
            return [0.0] * self.embedding_dimension
    
    def get_query_embedding(self, text: str) -> List[float]:
        """
        Generate embedding for a query text.
        
        Args:
            text: Query text to embed
            
        Returns:
            List of floats representing the embedding vector
        """
        try:
            result = genai.embed_content(
                model=EMBEDDING_MODEL,
                content=text,
                task_type="retrieval_query"
            )
            return result['embedding']
        except Exception as e:
            print(f"Error generating query embedding: {e}")
            return [0.0] * self.embedding_dimension
    
    def create_collection(self, collection_name: str = COLLECTION_NAME) -> bool:
        """
        Create a collection in Qdrant if it doesn't exist.
        
        Args:
            collection_name: Name of the collection
            
        Returns:
            True if successful
        """
        try:
            collections = self.client.get_collections().collections
            collection_names = [c.name for c in collections]
            
            if collection_name not in collection_names:
                self.client.create_collection(
                    collection_name=collection_name,
                    vectors_config=VectorParams(
                        size=self.embedding_dimension,
                        distance=Distance.COSINE
                    )
                )
                print(f"Created collection: {collection_name}")
            else:
                print(f"Collection {collection_name} already exists")
            return True
        except Exception as e:
            print(f"Error creating collection: {e}")
            return False
    
    def add_documents(
        self,
        documents: List[dict],
        collection_name: str = COLLECTION_NAME
    ) -> bool:
        """
        Add documents to Qdrant collection.
        
        Args:
            documents: List of dicts with 'id', 'text', and optional 'metadata'
            collection_name: Name of the collection
            
        Returns:
            True if successful
        """
        try:
            points = []
            for doc in documents:
                embedding = self.get_embedding(doc['text'])
                point = PointStruct(
                    id=doc['id'],
                    vector=embedding,
                    payload={
                        "text": doc['text'],
                        "source": doc.get('source', 'unknown'),
                        "metadata": doc.get('metadata', {})
                    }
                )
                points.append(point)
            
            self.client.upsert(
                collection_name=collection_name,
                points=points
            )
            print(f"Added {len(documents)} documents to {collection_name}")
            return True
        except Exception as e:
            print(f"Error adding documents: {e}")
            return False
    
    def search(
        self,
        query: str,
        collection_name: str = COLLECTION_NAME,
        top_k: int = 5,
        score_threshold: float = 0.6
    ) -> List[dict]:
        """
        Search for similar documents in the collection.
        
        Args:
            query: Search query text
            collection_name: Name of the collection
            top_k: Number of results to return
            score_threshold: Minimum similarity score
            
        Returns:
            List of matching documents with scores
        """
        try:
            query_embedding = self.get_query_embedding(query)
            
            results = self.client.search(
                collection_name=collection_name,
                query_vector=query_embedding,
                limit=top_k,
                score_threshold=score_threshold
            )
            
            documents = []
            for result in results:
                documents.append({
                    "id": result.id,
                    "score": result.score,
                    "text": result.payload.get("text", ""),
                    "source": result.payload.get("source", ""),
                    "metadata": result.payload.get("metadata", {})
                })
            
            return documents
        except Exception as e:
            print(f"Error searching: {e}")
            return []
    
    def delete_collection(self, collection_name: str = COLLECTION_NAME) -> bool:
        """
        Delete a collection from Qdrant.
        
        Args:
            collection_name: Name of the collection to delete
            
        Returns:
            True if successful
        """
        try:
            self.client.delete_collection(collection_name=collection_name)
            print(f"Deleted collection: {collection_name}")
            return True
        except Exception as e:
            print(f"Error deleting collection: {e}")
            return False
    
    def get_collection_info(self, collection_name: str = COLLECTION_NAME) -> dict:
        """
        Get information about a collection.
        
        Args:
            collection_name: Name of the collection
            
        Returns:
            Dictionary with collection info
        """
        try:
            info = self.client.get_collection(collection_name=collection_name)
            return {
                "name": collection_name,
                "vectors_count": info.vectors_count,
                "points_count": info.points_count,
                "status": info.status.value
            }
        except Exception as e:
            print(f"Error getting collection info: {e}")
            return {}


# Singleton instance
_qdrant_service: Optional[QdrantService] = None


def get_qdrant_service() -> QdrantService:
    """Get or create the Qdrant service singleton."""
    global _qdrant_service
    if _qdrant_service is None:
        _qdrant_service = QdrantService()
    return _qdrant_service

