from typing import Optional

from google.genai import types

from app.config import gemini_client, GEMINI_MODEL

DEFAULT_LANGUAGE = "ru"
SYSTEM_PROMPTS = {
    "kk": "Сіз Veridian банкінің пайдалы виртуалды көмекшісісіз. Жауаптарыңыз қысқа, нақты және қазақ тілінде болсын.",
    "en": "You are a helpful virtual assistant for Veridian Bank. Keep your answers concise and in English.",
    "ru": "Ты — полезный виртуальный помощник банка Veridian. Отвечай кратко, по делу и на русском языке.",
}
# С запасом на токены размышлений
MAX_OUTPUT_TOKENS = 1000


async def generate_support_reply(message: str, language: str) -> Optional[str]:
    system_prompt = SYSTEM_PROMPTS.get(language, SYSTEM_PROMPTS[DEFAULT_LANGUAGE])
    response = await gemini_client.aio.models.generate_content(
        model=GEMINI_MODEL,
        contents=message,
        config=types.GenerateContentConfig(
            system_instruction=system_prompt,
            max_output_tokens=MAX_OUTPUT_TOKENS,
        ),
    )
    return response.text
