import json

from google.genai import types

from app.config import gemini_client, GEMINI_MODEL
from app.models.assistant import ChatRequest, ChatTurn

LANGUAGE_NAMES = {"ru": "русском", "kk": "казахском", "en": "английском"}
SYSTEM_PROMPT = (
    "Ты — финансовый помощник банка Veridian. Отвечай кратко на {language} языке, "
    "простым текстом без Markdown. Опирайся только на цифры из сводки ниже и не выдумывай других; "
    "если данных не хватает, так и скажи. Отвечай только на вопросы о личных финансах. "
    "Суммы указаны в тенге.\n\nСводка пользователя за текущий месяц (JSON):\n{summary}"
)
# С запасом на токены размышлений
MAX_OUTPUT_TOKENS = 1500
# 429 не повторяем: квота исчерпана
HTTP_OPTIONS = types.HttpOptions(
    timeout=10000,
    retry_options=types.HttpRetryOptions(
        attempts=3, initial_delay=1, max_delay=4, http_status_codes=[500, 502, 503, 504]),
)


class AssistantUnavailable(Exception):
    pass


def _content(role: str, text: str) -> types.Content:
    return types.Content(role=role, parts=[types.Part(text=text)])


def _build_contents(history: list[ChatTurn], message: str) -> list[types.Content]:
    contents = [
        _content("user" if turn.role == "user" else "model", turn.text) for turn in history
    ]
    # Gemini ждёт первой реплику пользователя
    while contents and contents[0].role == "model":
        contents.pop(0)
    return [*contents, _content("user", message)]


async def generate_reply(summary: dict, request: ChatRequest) -> str:
    if not gemini_client:
        raise AssistantUnavailable()
    system_prompt = SYSTEM_PROMPT.format(
        language=LANGUAGE_NAMES[request.language],
        summary=json.dumps(summary, ensure_ascii=False),
    )
    try:
        response = await gemini_client.aio.models.generate_content(
            model=GEMINI_MODEL,
            contents=_build_contents(request.history, request.message),
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                max_output_tokens=MAX_OUTPUT_TOKENS,
                http_options=HTTP_OPTIONS,
            ),
        )
    except Exception as error:
        print(f"ERROR: Gemini API failed: {error}")
        raise AssistantUnavailable() from error
    if not response.text:
        raise AssistantUnavailable()
    return response.text
