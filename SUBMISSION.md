# KisanVaani - Convolve 4.0 Hackathon Submission

## Qdrant Problem Statement: Search, Memory, and Recommendations for Societal Impact

**Team Name:** CodeART 
**GitHub Repository:** https://github.com/DhairyaMeh/KisanVaani

---

## 1. Problem Statement

### What societal issue are you addressing?

**Agricultural Information Accessibility for Indian Farmers**

India has over **500 million farmers**, many of whom face critical challenges:

| Challenge | Impact |
|-----------|--------|
| **Language Barriers** | 65% of farmers speak regional languages; most digital resources are in English |
| **Information Asymmetry** | Farmers miss government subsidies worth ₹6,000+ annually due to lack of awareness |
| **Late Disease Detection** | Crop losses of 15-25% due to delayed identification of plant diseases |
| **Market Price Opacity** | Farmers sell at 20-30% below market rates due to lack of real-time price information |
| **Digital Literacy Gap** | Complex interfaces exclude farmers who are not tech-savvy |

### Why does it matter?

- Agriculture contributes **18% of India's GDP** and employs **42% of the workforce**
- Small and marginal farmers (< 2 hectares) constitute **86% of all farmers**
- Government schemes like PM-KISAN provide ₹6,000/year but **awareness is only ~60%**
- Timely information can increase farmer income by **15-20%**

### Our Solution: KisanVaani

An AI-powered farming assistant that provides:
- **Voice-first interface** in Kannada, Hindi, and English
- **Semantic search** over government schemes using Qdrant
- **Image-based plant disease detection**
- **Real-time market prices and weather information**

---

## 2. System Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KisanVaani Architecture                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    USER INTERFACE LAYER                              │   │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │   │
│   │  │   Voice     │  │   Text      │  │   Image     │                 │   │
│   │  │  (Kannada/  │  │   Input     │  │   Upload    │                 │   │
│   │  │  Hindi/EN)  │  │             │  │  (Camera)   │                 │   │
│   │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │   │
│   └─────────┼────────────────┼────────────────┼─────────────────────────┘   │
│             │                │                │                              │
│             ▼                ▼                ▼                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    FLUTTER MOBILE APPLICATION                        │   │
│   │              (iOS / Android / Web - Cross Platform)                  │   │
│   └────────────────────────────┬────────────────────────────────────────┘   │
│                                │                                             │
│                                ▼                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    FASTAPI BACKEND SERVER                            │   │
│   │  ┌───────────────────────────────────────────────────────────────┐  │   │
│   │  │                 ROOT AGENT (Gemini 2.5 Flash)                  │  │   │
│   │  │              Intent Detection & Query Routing                  │  │   │
│   │  └───────────────────────────────────────────────────────────────┘  │   │
│   │         │              │              │              │               │   │
│   │         ▼              ▼              ▼              ▼               │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│   │  │ SCHEMES  │  │  MARKET  │  │  PLANT   │  │ WEATHER  │            │   │
│   │  │  AGENT   │  │  AGENT   │  │  HEALTH  │  │  AGENT   │            │   │
│   │  └────┬─────┘  └──────────┘  │  AGENT   │  └──────────┘            │   │
│   │       │                      └──────────┘                           │   │
│   │       │                                                              │   │
│   │       ▼                                                              │   │
│   │  ┌─────────────────────────────────────────────────────────────┐    │   │
│   │  │              🔷 QDRANT VECTOR DATABASE 🔷                    │    │   │
│   │  │  ┌─────────────────────────────────────────────────────┐   │    │   │
│   │  │  │           government_schemes Collection              │   │    │   │
│   │  │  │  • 768-dimensional vectors (Google Embeddings)       │   │    │   │
│   │  │  │  • Cosine similarity search                          │   │    │   │
│   │  │  │  • Metadata: source, state, scheme_type              │   │    │   │
│   │  │  └─────────────────────────────────────────────────────┘   │    │   │
│   │  └─────────────────────────────────────────────────────────────┘    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Why Qdrant is Critical

| Requirement | Qdrant Capability | Our Implementation |
|-------------|-------------------|-------------------|
| **Fast Semantic Search** | Sub-100ms query latency | Real-time scheme retrieval during voice conversations |
| **Hybrid Search** | Dense + sparse vectors | Combine semantic meaning with keyword matching |
| **Metadata Filtering** | Payload-based filtering | Filter by state, scheme type, eligibility |
| **Scalability** | Horizontal scaling | Handle growing agricultural knowledge base |
| **Production Ready** | High availability | Reliable for farmer-facing application |

### Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (iOS, Android, Web) |
| **Backend** | FastAPI + Google ADK |
| **Vector Database** | Qdrant |
| **LLM** | Google Gemini 2.5 Flash |
| **Embeddings** | Google text-embedding-001 (768 dims) |
| **Speech** | Google Cloud Speech-to-Text / Text-to-Speech |
| **Cloud** | Google Cloud Platform |

---

## 3. Multimodal Strategy

### Data Types Used

| Data Type | Source | Processing |
|-----------|--------|------------|
| **Text** | Government scheme PDFs, policy documents | Chunked (512 tokens) → Embedded → Stored in Qdrant |
| **Voice** | Farmer speech in Kannada/Hindi/English | Speech-to-Text → Query Qdrant → Text-to-Speech response |
| **Images** | Crop photos from farmers | Gemini Vision → Disease identification |

### Embedding Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCUMENT INGESTION PIPELINE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │     PDF      │     │    TEXT      │     │   CHUNKING   │    │
│  │  Documents   │────►│  Extraction  │────►│   (512 tok)  │    │
│  │              │     │   (pypdf)    │     │  100 overlap │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                                                    │            │
│                                                    ▼            │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   QDRANT     │     │   VECTOR     │     │   GOOGLE     │    │
│  │  Collection  │◄────│   768-dim    │◄────│  Embeddings  │    │
│  │              │     │              │     │              │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Query Flow

```python
# 1. User asks in Kannada: "ರೈತರಿಗೆ ಯಾವ ಯೋಜನೆಗಳು ಲಭ್ಯವಿವೆ?"
# 2. Speech-to-Text converts to: "What schemes are available for farmers?"
# 3. Query is embedded using Google Embeddings
# 4. Qdrant searches for similar vectors (cosine similarity)
# 5. Top-k results are retrieved with metadata
# 6. Gemini generates contextual response
# 7. Response is converted to Kannada speech
```

---

## 4. Search / Memory / Recommendation Logic

### Search Implementation

```python
# Qdrant Search Configuration
def search(query: str, top_k: int = 5, score_threshold: float = 0.6):
    # Generate query embedding
    query_embedding = embed_content(
        model="models/embedding-001",
        content=query,
        task_type="retrieval_query"
    )
    
    # Search Qdrant
    results = qdrant_client.search(
        collection_name="government_schemes",
        query_vector=query_embedding,
        limit=top_k,
        score_threshold=score_threshold
    )
    
    return results
```

**Key Parameters:**
- `similarity_top_k = 5`: Return top 5 most relevant documents
- `score_threshold = 0.6`: Minimum cosine similarity for relevance
- `vector_distance = COSINE`: Semantic similarity metric

### Memory Architecture

| Memory Type | Implementation | Purpose |
|-------------|----------------|---------|
| **Knowledge Memory** | Qdrant persistent collection | Store agricultural schemes, treatments, prices |
| **Session Memory** | In-memory (per conversation) | Track conversation context |
| **User Context** | Request payload | Farmer location, language preference |

**Qdrant Collection Schema:**
```json
{
  "collection_name": "government_schemes",
  "vectors": {
    "size": 768,
    "distance": "Cosine"
  },
  "payload_schema": {
    "text": "string",
    "source": "string (PDF filename)",
    "metadata": {
      "state": "string",
      "scheme_type": "string",
      "chunk_index": "integer"
    }
  }
}
```

### Recommendation Logic

1. **Context-Aware Retrieval**: User's state (Karnataka) filters relevant schemes
2. **Semantic Matching**: Query intent matched with scheme descriptions
3. **Confidence Scoring**: Qdrant similarity score indicates recommendation strength
4. **Fallback Strategy**: Google Search if Qdrant results are below threshold

---

## 5. Limitations & Ethical Considerations

### Known Limitations

| Limitation | Description | Mitigation |
|------------|-------------|------------|
| **Language Coverage** | Currently Kannada, Hindi, English only | Architecture supports adding more Indic languages |
| **Offline Mode** | RAG requires internet connectivity | Basic cached responses for common queries |
| **Data Currency** | Scheme information may become outdated | Scheduled corpus updates recommended |
| **Image Quality** | Disease detection accuracy depends on photo quality | User guidance for better capture |

### Bias Considerations

| Bias Type | Risk | Mitigation |
|-----------|------|------------|
| **Regional Bias** | Initial focus on Karnataka schemes | Expanding to pan-India coverage |
| **Literacy Bias** | Assumes basic smartphone use | Voice-first interface prioritized |
| **Gender Bias** | Agricultural resources often target male farmers | Inclusive language and examples |

### Privacy & Safety

| Aspect | Implementation |
|--------|----------------|
| **Data Privacy** | No PII stored beyond session; queries not logged |
| **Consent** | Clear permissions for voice recording and camera |
| **Medical Disclaimer** | Plant disease recommendations are advisory only |
| **Financial Disclaimer** | Scheme info is informational; official verification recommended |

### Responsible AI Practices

1. **Traceable Outputs**: All recommendations cite source documents
2. **Confidence Transparency**: Similarity scores shown for reliability indication
3. **Hallucination Prevention**: Responses grounded in Qdrant-retrieved documents
4. **Human Oversight**: Designed to augment agricultural extension officers, not replace

---

## 6. Demo & Examples

### Sample Queries

| Query (Kannada) | Translation | Qdrant Action | Response |
|-----------------|-------------|---------------|----------|
| "ರೈತರಿಗೆ ಯಾವ ಸಬ್ಸಿಡಿ ಇದೆ?" | "What subsidies for farmers?" | Search `government_schemes` | PM-KISAN, KCC details |
| "ಟೊಮೇಟೊ ಬೆಲೆ ಎಷ್ಟು?" | "What is tomato price?" | Market Agent (no Qdrant) | Real-time price data |
| "ಎಲೆ ಹಳದಿಯಾಗುತ್ತಿದೆ" | "Leaves turning yellow" | Plant Health Agent | Disease diagnosis |

### Example Qdrant Retrieval

**Query:** "What is PM-KISAN scheme eligibility?"

**Qdrant Results:**
```json
[
  {
    "id": 42,
    "score": 0.89,
    "payload": {
      "text": "PM-KISAN provides ₹6,000 per year to all landholding farmer families...",
      "source": "Schemes_for_Welfare_of_Farmers.pdf",
      "metadata": {"state": "all_india", "scheme_type": "direct_benefit"}
    }
  },
  {
    "id": 156,
    "score": 0.82,
    "payload": {
      "text": "Eligibility: All farmer families with cultivable land...",
      "source": "Karnataka_Agri_Schemes_24-25.pdf",
      "metadata": {"state": "karnataka", "scheme_type": "eligibility"}
    }
  }
]
```

---

## 7. Setup & Reproducibility

### Quick Start

```bash
# Clone repository
git clone https://github.com/DhairyaMeh/KisanVaani.git
cd KisanVaani

# Start Qdrant
docker run -d -p 6333:6333 qdrant/qdrant

# Backend setup
cd backend
pip install -r requirements.txt
python agents/kisan_agent/sub_agents/government_schemes_agent/prepare_corpus/prepare_qdrant_corpus.py
uvicorn main:app --reload

# Frontend setup
cd ../frontend
flutter pub get
flutter run -d chrome
```

### Environment Variables

```env
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_COLLECTION_NAME=government_schemes
GOOGLE_APPLICATION_CREDENTIALS=./keyfile.json
```

---

## 8. Conclusion

KisanVaani demonstrates how **Qdrant** can power a socially impactful AI application:

| Qdrant Capability | KisanVaani Usage |
|-------------------|------------------|
| ✅ **Semantic Search** | Find relevant government schemes |
| ✅ **Persistent Memory** | Store agricultural knowledge base |
| ✅ **Recommendations** | Context-aware scheme suggestions |
| ✅ **Multimodal Support** | Text embeddings for voice queries |
| ✅ **Production Ready** | Reliable for farmer-facing app |

**Societal Impact:** Bridging the information gap for 500+ million Indian farmers through accessible, voice-first AI assistance.

---

## Team: CodeART

**Convolve 4.0 | Pan-IIT AI/ML Hackathon | Qdrant Problem Statement**

🌾 *Built with ❤️ for Indian farmers* 🌾

