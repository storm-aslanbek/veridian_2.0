import os
from motor.motor_asyncio import AsyncIOMotorClient
from google import genai
from dotenv import load_dotenv

load_dotenv()

# Configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-3.5-flash-lite"
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 10080
MONGO_URL = os.getenv('MONGO_URL')

if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY not found!")

if not GEMINI_API_KEY:
    print("WARNING: GEMINI_API_KEY not found!")
    gemini_client = None
else:
    print("Gemini API Key loaded successfully.")
    gemini_client = genai.Client(api_key=GEMINI_API_KEY)

# Database
client = AsyncIOMotorClient(MONGO_URL)
db = client.veridian_db