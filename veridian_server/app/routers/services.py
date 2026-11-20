import uuid
import httpx
import http.client
import json
import urllib.parse
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from app.config import openai_client, RAPIDAPI_KEY
from app.security import get_current_user
from app.models.user import UserResponse
from app.models.external import SupportChatRequest, SearchResult, BusinessCheckResult, JobOpportunity

router = APIRouter()


@router.post("/support/chat")
async def support_chat(req: SupportChatRequest):
    if not openai_client:
        raise HTTPException(status_code=500, detail="OpenAI client not initialized")
    try:
        system_prompt = ""
        if req.language == 'kk':
            system_prompt = "Сіз Veridian банкінің пайдалы виртуалды көмекшісісіз. Жауаптарыңыз қысқа, нақты және қазақ тілінде болсын."
        elif req.language == 'en':
            system_prompt = "You are a helpful virtual assistant for Veridian Bank. Keep your answers concise and in English."
        else:
            system_prompt = "Ты — полезный виртуальный помощник банка Veridian. Отвечай кратко, по делу и на русском языке."

        chat_completion = await openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": req.message}
            ],
            max_tokens=150,
            temperature=0.7,
        )
        return {"reply": chat_completion.choices[0].message.content}
    except Exception as e:
        print(f"ERROR: OpenAI API failed: {e}")
        return {"reply": "Service temporarily unavailable"}


@router.get("/shopping/search", response_model=List[SearchResult])
async def search_products(query: str, current_user: UserResponse = Depends(get_current_user)):
    external_url = "https://assau-tender.online/api/suppliers"
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(external_url, params={"query": query}, timeout=15.0)
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Search provider unavailable")
            data = response.json()
            results = []
            if isinstance(data, list):
                for item in data:
                    results.append(SearchResult(
                        title=item.get('title', 'Без названия'),
                        link=item.get('link', ''),
                        snippet=item.get('snippet')
                    ))
            return results
    except Exception as e:
        print(f"Search error: {e}")
        return []


@router.get("/business/check", response_model=BusinessCheckResult)
async def check_business(bin: str, current_user: UserResponse = Depends(get_current_user)):
    external_url = "https://assau-tender.online/api/goszakup/customer-check"
    try:
        async with httpx.AsyncClient(verify=False) as client:
            response = await client.post(external_url, json={"customer_bin": bin})
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Business check unavailable")
            data = response.json()
            if not data:
                raise HTTPException(status_code=404, detail="Company not found")
            return BusinessCheckResult(
                bin=data.get("bin", []),
                nameRu=data.get("nameRu", []),
                customerLegalAddress=data.get("customerLegalAddress"),
                customerBankNameRu=data.get("customerBankNameRu"),
                fullyPaid=data.get("fullyPaid"),
                averagePaymentTime=data.get("averagePaymentTime"),
                averageSigningTime=data.get("averageSigningTime"),
                terminated_contracts=data.get("terminated_contracts"),
                total_rating=data.get("total_rating")
            )
    except Exception as e:
        print(f"Business check error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/career/search", response_model=List[JobOpportunity])
async def search_jobs(
        query: str,
        current_user: UserResponse = Depends(get_current_user)
):
    conn = http.client.HTTPSConnection("jsearch.p.rapidapi.com")
    headers = {
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-rapidapi-host': "jsearch.p.rapidapi.com"
    }

    params = {
        "query": query,
        "page": "1",
        "num_pages": "1",
        "date_posted": "all",
        "country": "kz",
        "language": "ru"
    }

    query_string = urllib.parse.urlencode(params)
    try:
        conn.request("GET", f"/search?{query_string}", headers=headers)
        res = conn.getresponse()
        data = res.read()
        response_text = data.decode("utf-8")

        if res.status != 200:
            print(f"RapidAPI Error: {res.status} - {response_text}")
            raise HTTPException(status_code=502, detail="Job search service unavailable")

        json_data = json.loads(response_text)
        jobs_data = json_data.get("data", [])

        results = []
        for job in jobs_data:
            results.append(JobOpportunity(
                job_id=job.get("job_id") or str(uuid.uuid4()),
                job_title=job.get("job_title") or "Без названия",
                employer_name=job.get("employer_name") or "Не указан",
                job_city=job.get("job_city"),
                job_country=job.get("job_country"),
                job_apply_link=job.get("job_apply_link"),
                job_employment_type=job.get("job_employment_type"),
                job_description=job.get("job_description")[:200] + "..." if job.get("job_description") else None
            ))
        return results
    except Exception as e:
        print(f"Connection error: {e}")
        raise HTTPException(status_code=503, detail=f"Connection failed: {str(e)}")