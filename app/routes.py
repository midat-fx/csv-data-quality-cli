from .services import get_user

def handle_get_user(user_id: str) -> dict:
    return get_user(user_id)
