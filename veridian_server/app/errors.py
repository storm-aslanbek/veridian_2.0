from fastapi import Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


async def validation_error_handler(request: Request, error: RequestValidationError) -> JSONResponse:
    # NaN и Infinity не сериализуются в JSON
    details = [
        {key: item[key] for key in ("type", "loc", "msg")} for item in error.errors()
    ]
    return JSONResponse(status_code=422, content={"detail": jsonable_encoder(details)})
