"""
Prepare Qdrant Corpus for Government Schemes

This script loads PDF documents and indexes them in Qdrant vector database.
"""

import os
import sys
from pathlib import Path
from typing import List
from dotenv import load_dotenv

# Add backend to path
backend_path = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(backend_path))

load_dotenv(backend_path / ".env")

from services.qdrant_service import get_qdrant_service

# Try to import pypdf for PDF processing
try:
    from pypdf import PdfReader
except ImportError:
    print("pypdf not installed. Run: pip install pypdf")
    sys.exit(1)


# Configuration
DOCUMENTS_DIR = Path(__file__).parent / "documents"
COLLECTION_NAME = os.getenv("QDRANT_COLLECTION_NAME", "government_schemes")
CHUNK_SIZE = 512
CHUNK_OVERLAP = 100


def extract_text_from_pdf(pdf_path: Path) -> str:
    """
    Extract text from a PDF file.
    
    Args:
        pdf_path: Path to the PDF file
        
    Returns:
        Extracted text content
    """
    try:
        reader = PdfReader(str(pdf_path))
        text = ""
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
        return text
    except Exception as e:
        print(f"Error extracting text from {pdf_path}: {e}")
        return ""


def chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    """
    Split text into overlapping chunks.
    
    Args:
        text: Text to chunk
        chunk_size: Size of each chunk in characters
        overlap: Overlap between chunks
        
    Returns:
        List of text chunks
    """
    chunks = []
    start = 0
    text_length = len(text)
    
    while start < text_length:
        end = start + chunk_size
        chunk = text[start:end]
        
        # Try to break at a sentence boundary
        if end < text_length:
            last_period = chunk.rfind('.')
            last_newline = chunk.rfind('\n')
            break_point = max(last_period, last_newline)
            if break_point > chunk_size // 2:
                chunk = chunk[:break_point + 1]
                end = start + break_point + 1
        
        if chunk.strip():
            chunks.append(chunk.strip())
        
        start = end - overlap
        if start >= text_length:
            break
    
    return chunks


def process_pdf_files(documents_dir: Path) -> List[dict]:
    """
    Process all PDF files in the documents directory.
    
    Args:
        documents_dir: Path to directory containing PDF files
        
    Returns:
        List of document dictionaries ready for indexing
    """
    documents = []
    doc_id = 0
    
    if not documents_dir.exists():
        print(f"Documents directory not found: {documents_dir}")
        return documents
    
    pdf_files = list(documents_dir.glob("*.pdf"))
    print(f"Found {len(pdf_files)} PDF files in {documents_dir}")
    
    for pdf_path in pdf_files:
        print(f"\nProcessing: {pdf_path.name}")
        
        text = extract_text_from_pdf(pdf_path)
        if not text:
            print(f"  No text extracted from {pdf_path.name}")
            continue
        
        chunks = chunk_text(text)
        print(f"  Extracted {len(chunks)} chunks")
        
        for i, chunk in enumerate(chunks):
            documents.append({
                "id": doc_id,
                "text": chunk,
                "source": pdf_path.name,
                "metadata": {
                    "filename": pdf_path.name,
                    "chunk_index": i,
                    "total_chunks": len(chunks)
                }
            })
            doc_id += 1
    
    return documents


def main():
    """Main function to prepare Qdrant corpus."""
    print("=" * 60)
    print("Preparing Qdrant Corpus for Government Schemes")
    print("=" * 60)
    
    # Initialize Qdrant service
    print("\n1. Initializing Qdrant service...")
    try:
        qdrant_service = get_qdrant_service()
        print("   Qdrant service initialized")
    except Exception as e:
        print(f"   Error initializing Qdrant: {e}")
        print("\n   Make sure Qdrant is running:")
        print("   docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant")
        sys.exit(1)
    
    # Create collection
    print(f"\n2. Creating collection: {COLLECTION_NAME}")
    qdrant_service.create_collection(COLLECTION_NAME)
    
    # Process PDF documents
    print(f"\n3. Processing PDF documents from: {DOCUMENTS_DIR}")
    documents = process_pdf_files(DOCUMENTS_DIR)
    
    if not documents:
        print("   No documents to index!")
        return
    
    print(f"\n   Total documents to index: {len(documents)}")
    
    # Add documents to Qdrant
    print(f"\n4. Adding documents to Qdrant...")
    success = qdrant_service.add_documents(documents, COLLECTION_NAME)
    
    if success:
        # Get collection info
        info = qdrant_service.get_collection_info(COLLECTION_NAME)
        print(f"\n5. Collection info:")
        print(f"   - Name: {info.get('name')}")
        print(f"   - Points count: {info.get('points_count')}")
        print(f"   - Status: {info.get('status')}")
    
    print("\n" + "=" * 60)
    print("Corpus preparation complete!")
    print("=" * 60)
    
    # Test search
    print("\n6. Testing search...")
    test_query = "agricultural subsidy schemes for farmers"
    results = qdrant_service.search(test_query, COLLECTION_NAME, top_k=3)
    
    if results:
        print(f"   Search results for: '{test_query}'")
        for i, result in enumerate(results, 1):
            print(f"\n   Result {i} (score: {result['score']:.3f}):")
            print(f"   Source: {result['source']}")
            print(f"   Text: {result['text'][:200]}...")
    else:
        print("   No results found (this may be normal if embeddings aren't configured)")


if __name__ == "__main__":
    main()

