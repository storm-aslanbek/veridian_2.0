from datetime import datetime, timedelta, timezone

# Vercel работает в UTC, Казахстан — UTC+5
LOCAL_TIMEZONE = timezone(timedelta(hours=5))


def now_local() -> datetime:
    return datetime.now(LOCAL_TIMEZONE).replace(tzinfo=None)
