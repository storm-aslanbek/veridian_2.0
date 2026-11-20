import os
from motor.motor_asyncio import AsyncIOMotorClient
from openai import AsyncOpenAI
from dotenv import load_dotenv

load_dotenv()

# Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
SECRET_KEY = "a7b02fedbd3c6f1e797f70b501310a9638c40a1bab32e4dcd57f5be66e784ae9"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 10080
MONGO_URL = os.getenv('MONGO_URL')

# OpenAI Client
if not OPENAI_API_KEY:
    print("WARNING: OPENAI_API_KEY not found!")
    openai_client = None
else:
    print("OpenAI API Key loaded successfully.")
    openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)

# Database
client = AsyncIOMotorClient(MONGO_URL)
db = client.veridian_db