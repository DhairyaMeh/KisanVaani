import base64
import io
from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
from pydantic import BaseModel
import uvicorn
from google.cloud import texttospeech, speech
try:
    from vertexai import agent_engines  # type: ignore
except Exception:
    agent_engines = None  # Allow import when Vertex AI SDK isn't available
try:
    from agents.kisan_agent.agent import root_agent  # type: ignore
except Exception:
    root_agent = None
from typing import Any
from typing import Optional

# --- FastAPI App Initialization ---
app = FastAPI(
    title="Chat API with Text and Speech Processing",
    description="An API that accepts text or audio, processes it, and returns text and speech.",
    version="1.0.0",
)

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)
# --- Pydantic Models for Response ---
class ChatResponse(BaseModel):
    text_response: str
    audio_response_base64: str

# --- Placeholder Functions for Gemini/Vertex AI ---

async def recognize_speech_to_text(audio_bytes: bytes) -> str:
    """
    Simulates a call to the Gemini/Vertex AI Speech-to-Text API.
    In a real implementation, you would use the Google Cloud client library.
    """
    print("--- Sending audio to Gemini STT (Simulated) ---")
    # This is a placeholder. A real implementation would look like this:
    #    
    client = speech.SpeechClient()
    audio = speech.RecognitionAudio(content=audio_bytes)
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code="en-US",
    )
    response = client.recognize(config=config, audio=audio)
    if not response.results:
        raise HTTPException(status_code=400, detail="Could not transcribe audio.")
    return response.results[0].alternatives[0].transcript


async def synthesize_text_to_speech(text: str) -> bytes:
    """
    Simulates a call to the Gemini/Vertex AI Text-to-Speech API.
    In a real implementation, you would use the Google Cloud client library.
    """
    print(f"--- Sending text to Gemini TTS (Simulated): '{text}' ---")
    # This is a placeholder. A real implementation would look like this:
    #
    
    client = texttospeech.TextToSpeechClient()
    synthesis_input = texttospeech.SynthesisInput(text=text)
    voice = texttospeech.VoiceSelectionParams(
        language_code="en-US", ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3
    )
    response = client.synthesize_speech(
        input=synthesis_input, voice=voice, audio_config=audio_config
    )
    return response.audio_content


# --- External API Call Function ---
try:
    from vertexai.preview import reasoning_engines  # type: ignore
except Exception:
    reasoning_engines = None
def run_vertex_agent_local(text:str):

    final_response = ""

    if reasoning_engines is None or root_agent is None:
        # Return helpful stub response when agent isn't available
        return get_demo_response(text)

    try:
        app = reasoning_engines.AdkApp(
            agent=root_agent,
            enable_tracing=True,
        )

        session = app.create_session(user_id="u_456")

        for event in app.stream_query(
            user_id="u_456",
            session_id=session.id,
            message=text,
        ):
            if event.get("content") and event.get("content", {}).get("parts"):
                final_response = event["content"]["parts"][0].get("text", "")
        
        # If we got an empty response, return demo response
        if not final_response.strip():
            return get_demo_response(text)
            
        return final_response
    except Exception as e:
        print(f"Agent error: {e}")
        return get_demo_response(text)


def get_demo_response(text: str) -> str:
    """Return a helpful demo response when the AI agent is unavailable."""
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['scheme', 'yojana', 'subsidy', 'pm kisan']):
        return """🌾 **Government Schemes for Farmers**

Here are some important schemes available for farmers:

1. **PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)**
   - ₹6,000 per year in 3 installments
   - For all landholding farmer families
   - Apply at: https://pmkisan.gov.in

2. **Kisan Credit Card (KCC)**
   - Low-interest agricultural loans
   - Insurance coverage included

3. **PM Fasal Bima Yojana**
   - Crop insurance scheme
   - Protection against natural calamities

📋 For Karnataka-specific schemes, visit: https://raitamitra.karnataka.gov.in/english

Note: This is a demo response. For personalized assistance, please configure valid GCP credentials."""

    elif any(word in text_lower for word in ['weather', 'rain', 'temperature', 'forecast']):
        return """🌤️ **Weather Information**

For accurate weather forecasts for your area, please check:
- IMD: https://mausam.imd.gov.in
- Skymet: https://www.skymetweather.com

Note: This is a demo response. Configure GCP credentials for live weather data."""

    elif any(word in text_lower for word in ['price', 'market', 'mandi', 'rate']):
        return """📊 **Market Price Information**

Check current agricultural commodity prices at:
- Agmarknet: https://agmarknet.gov.in
- eNAM: https://enam.gov.in

Note: This is a demo response. Configure GCP credentials for live market data."""

    elif any(word in text_lower for word in ['disease', 'pest', 'leaf', 'plant', 'crop']):
        return """🌱 **Plant Health Assistance**

For plant disease diagnosis:
1. Take clear photos of affected parts
2. Note the symptoms you observe
3. Check soil moisture and recent weather

Common resources:
- ICAR Portal: https://icar.org.in
- Plantix App for disease identification

Note: This is a demo response. Configure GCP credentials for AI-powered diagnosis."""

    else:
        return f"""🙏 **Namaskara! Welcome to KisanVaani**

I'm your AI farming assistant. I can help you with:

• 🏛️ Government schemes and subsidies
• 🌤️ Weather forecasts
• 📊 Market prices
• 🌱 Plant disease diagnosis

Your query: "{text}"

Note: This is a demo response. For full AI-powered assistance, please configure valid GCP credentials in the backend.

Try asking about:
- "What schemes are available for farmers?"
- "What is the weather forecast?"
- "Current tomato prices"
"""


def run_vertex_agent_deployed(text: str, initial_state: dict) -> str:
    if agent_engines is None:
        return f"[stub] {text}"
    app = agent_engines.get("projects/683449264474/locations/europe-west4/reasoningEngines/7676244827364655104")

    session = app.create_session(user_id=initial_state["name"], state = initial_state)

    for event in app.stream_query(
        user_id=initial_state["name"],
        session_id=session.id,
        message=text,
    ):
        if event.get("content") and event.get("content", {}).get("parts"):
            final_response = event["content"]["parts"][0].get("text", "")
        
    return final_response


async def call_external_api(text: str,initial_state:dict) -> str:
    """
    Makes a POST request to the external API.
    """
    print(f"--- Calling External API with text: '{text}' ---")
    try:
        # Use local agent instead of deployed one
        response_final = run_vertex_agent_local(text)
        return response_final
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"External API processing failed: {exc}")


# --- API Endpoint ---

class KisanChatSchema(BaseModel):
    text: str 
    audio_file: Optional[Any]
    image: Optional[Any]
    city: Optional[str] = "Bangalore"
    name: Optional[str] = ""
    country: Optional[str] = ""
    state: Optional[str] = ""
    preferred_language: Optional[str] = ""

def create_initial_dict(request):
    state_init = {
            "state": {
                "farmer_info": {
                "name": request["name"], # Required
                "location": {
                    "city/town": request["city"], # One out of city/town, village, or district is required
                    "state": request["state"], # One out of city/town, village, or district is required
                    "country": request["country"] # One out of city/town, village, or district is required
                },
                "preferred_language": request["preferred_language"] # Optional, defaults to English
                },
                "city":request["city"],
                "state": request["state"],
            }
    }
    return state_init["state"]

@app.post("/api/chat_endpoint")
async def chat_endpoint(request: KisanChatSchema):
    """
    This endpoint handles both text and audio chat requests.

    - **To send text:** Use a form field named `text`.
    - **To send audio:** Upload a file to a form field named `audio_file`.

    The endpoint processes the input, calls an external API, and returns
    both a text response and a synthesized audio response.
    """
    # text = "whats weather in delhi today"
    input_text = ""

    # 1. Determine request type and get input text
    requests = request.dict()
    text = requests["text"]
    audio_file = requests["audio_file"]
    image = requests["image"]

    if audio_file:
        print("--- Received audio file ---")
        # Handle base64 encoded audio from JSON request
        if isinstance(audio_file, str):
            try:
                audio_bytes = base64.b64decode(audio_file)
                input_text = await recognize_speech_to_text(audio_bytes)
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Speech-to-Text processing failed: {e}")
        else:
            # Handle traditional file upload (if needed for compatibility)
            if not audio_file.content_type.startswith("audio/"):
                raise HTTPException(status_code=400, detail="Invalid file type. Please upload an audio file.")
            audio_bytes = await audio_file.read()
            try:
                input_text = await recognize_speech_to_text(audio_bytes)
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Speech-to-Text processing failed: {e}")
    elif image and text.strip():
        print("--- Received image with text ---")
        # Handle base64 encoded image from JSON request
        if isinstance(image, str):
            # Image is already base64 encoded from frontend
            base64_image = image
        else:
            # Handle traditional file upload (if needed for compatibility)  
            base64_image = base64.b64encode(image).decode('utf-8')
        
        content_dict = {
            "role": "user",
            "parts": [
                {"text": text},
                {
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64_image
                    }
                }
            ]
        }
        input_text = content_dict
    elif image:
        raise HTTPException(status_code=422, detail=f"Please provide text with the image")
    elif text and text.strip(): # Fixed: Check if text exists and is not empty
        print("--- Received text input ---")
        input_text = text
    else:
        raise HTTPException(status_code=400, detail="No valid input provided. Please send text, audio, or image with text.")
    # 2. Forward text to the external API
    initial_state_dict = create_initial_dict(requests)
    external_api_response_text = await call_external_api(input_text, initial_state_dict)

    # 3. Pass the response to the TTS model (optional - continue if it fails)
    final_audio_bytes = b""
    try:
        final_audio_bytes = await synthesize_text_to_speech(external_api_response_text)
        print(external_api_response_text)
    except Exception as e:
        print(f"Warning: Text-to-Speech processing failed (continuing without audio): {e}")

    # 4. Prepare and return the final response
    # We can return the audio in two ways:
    # a) As a base64 string within a JSON object for clients that prefer it.
    # b) As a direct audio stream for browsers or clients that can play it.

    # For this example, we'll return a JSON response with the base64 audio
    # and also make the streaming audio available if requested via headers.
    # A more advanced implementation could use the 'Accept' header to decide.

    audio_base64 = base64.b64encode(final_audio_bytes).decode('utf-8')

    response_data = ChatResponse(
        text_response=external_api_response_text,
        audio_response_base64=audio_base64
    )

    # You could also return a streaming response directly like this:
    # return StreamingResponse(io.BytesIO(final_audio_bytes), media_type="audio/mpeg")

    return JSONResponse(content=response_data.dict())


# --- Root endpoint for basic health check ---
@app.get("/")
def read_root():
    return {"message": "Chat API is running. Go to /docs for API documentation."}


# --- To run the app ---
# Command: uvicorn main:app --reload
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8084, reload=True)
