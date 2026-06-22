
import os
from urllib.parse import quote_plus
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()

raw_password = os.getenv('DB_PASSWORD')
encoded_password = quote_plus(raw_password) if raw_password else ""


def _env_flag(name: str, default: bool = False) -> bool:
    raw_value = os.getenv(name)
    if raw_value is None:
        return default
    return raw_value.strip().lower() in {"1", "true", "yes", "on"}

class Settings(BaseSettings):
    DATABASE_URL: str = (
        f"mysql+pymysql://{os.getenv('DB_USER')}:"
        f"{encoded_password}@"
        f"{os.getenv('DB_HOST')}:"
        f"{os.getenv('DB_PORT')}/"
        f"{os.getenv('DB_NAME')}"
    )

    # JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "default_secret_key_if_not_found")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))


    #cloudirary
    CLOUDINARY_CLOUD_NAME: str = os.getenv("CLOUDINARY_CLOUD_NAME")
    CLOUDINARY_API_KEY: str = os.getenv("CLOUDINARY_API_KEY")
    CLOUDINARY_API_SECRET: str = os.getenv("CLOUDINARY_API_SECRET")
    AI_STICKER_CLOUDINARY_FOLDER: str = os.getenv("AI_STICKER_CLOUDINARY_FOLDER", "helmet_shop/stickers")
    EVALUATE_IMAGE_CLOUDINARY_FOLDER: str = os.getenv("EVALUATE_IMAGE_CLOUDINARY_FOLDER", "helmet_shop/evaluates")
    PRODUCT_MODEL_3D_CLOUDINARY_FOLDER: str = os.getenv("PRODUCT_MODEL_3D_CLOUDINARY_FOLDER", "helmet_shop/models")

    # OpenAI image generation
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_BASE_URL: str = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    OPENAI_IMAGE_MODEL: str = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-1.5")
    OPENAI_IMAGE_SIZE: str = os.getenv("OPENAI_IMAGE_SIZE", "1024x1024")
    OPENAI_IMAGE_QUALITY: str = os.getenv("OPENAI_IMAGE_QUALITY", "medium")
    OPENAI_IMAGE_TIMEOUT_SECONDS: int = int(os.getenv("OPENAI_IMAGE_TIMEOUT_SECONDS", 45))
    OPENAI_TRANSCRIPTION_MODEL: str = os.getenv("OPENAI_TRANSCRIPTION_MODEL", "gpt-4o-mini-transcribe")
    OPENAI_TRANSCRIPTION_LANGUAGE: str = os.getenv("OPENAI_TRANSCRIPTION_LANGUAGE", "vi")
    OPENAI_TRANSCRIPTION_TIMEOUT_SECONDS: int = int(os.getenv("OPENAI_TRANSCRIPTION_TIMEOUT_SECONDS", 60))
    CHATBOT_ENABLED: bool = _env_flag("CHATBOT_ENABLED", False)
    OPENAI_CHAT_MODEL: str = os.getenv("OPENAI_CHAT_MODEL", "gpt-5-mini")
    OPENAI_CHAT_FALLBACK_MODEL: str = os.getenv("OPENAI_CHAT_FALLBACK_MODEL", "gpt-5.4")
    OPENAI_CHAT_TIMEOUT_SECONDS: int = int(os.getenv("OPENAI_CHAT_TIMEOUT_SECONDS", 30))
    CHATBOT_MAX_PRODUCTS: int = int(os.getenv("CHATBOT_MAX_PRODUCTS", 5))
    AI_STICKER_MAX_PER_DAY: int = int(os.getenv("AI_STICKER_MAX_PER_DAY", 0))
    AI_STICKER_VOICE_MAX_FILE_MB: int = int(os.getenv("AI_STICKER_VOICE_MAX_FILE_MB", 25))

    # VNPAY
    VNPAY_TMN_CODE: str = os.getenv("VNPAY_TMN_CODE", "")
    VNPAY_HASH_SECRET: str = os.getenv("VNPAY_HASH_SECRET", "")
    VNPAY_URL: str = os.getenv("VNPAY_URL", "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html")
    VNPAY_RETURN_URL: str = os.getenv("VNPAY_RETURN_URL", "")
    VNPAY_VERSION: str = os.getenv("VNPAY_VERSION", "2.1.0")
    APP_DEEP_LINK_SCHEME: str = os.getenv("APP_DEEP_LINK_SCHEME", "helmetshop")
    APP_RETURN_URL: str = os.getenv("APP_RETURN_URL", "")

    # GHN
    GHN_API_BASE: str = os.getenv("GHN_API_BASE", "https://dev-online-gateway.ghn.vn")
    GHN_TOKEN: str = os.getenv("GHN_TOKEN", "")
    GHN_SHOP_ID: str = os.getenv("GHN_SHOP_ID", "")
    GHN_FROM_NAME: str = os.getenv("GHN_FROM_NAME", "")
    GHN_FROM_PHONE: str = os.getenv("GHN_FROM_PHONE", "")
    GHN_FROM_ADDRESS: str = os.getenv("GHN_FROM_ADDRESS", "")
    GHN_FROM_WARD_CODE: str = os.getenv("GHN_FROM_WARD_CODE", "")
    GHN_FROM_DISTRICT_ID: int = int(os.getenv("GHN_FROM_DISTRICT_ID", 0))
    GHN_DEFAULT_WEIGHT: int = int(os.getenv("GHN_DEFAULT_WEIGHT", 1000))
    GHN_DEFAULT_LENGTH: int = int(os.getenv("GHN_DEFAULT_LENGTH", 20))
    GHN_DEFAULT_WIDTH: int = int(os.getenv("GHN_DEFAULT_WIDTH", 20))
    GHN_DEFAULT_HEIGHT: int = int(os.getenv("GHN_DEFAULT_HEIGHT", 20))
    GHN_PAYMENT_TYPE_ID: int = int(os.getenv("GHN_PAYMENT_TYPE_ID", 2))
    GHN_REQUIRED_NOTE: str = os.getenv("GHN_REQUIRED_NOTE", "KHONGCHOXEMHANG")

    # Firebase Cloud Messaging
    FCM_CREDENTIALS_FILE: str = os.getenv("FCM_CREDENTIALS_FILE", "")
    FCM_PROJECT_ID: str = os.getenv("FCM_PROJECT_ID", "")

    # Push outbox worker
    PUSH_OUTBOX_BATCH_SIZE: int = int(os.getenv("PUSH_OUTBOX_BATCH_SIZE", 50))
    PUSH_OUTBOX_POLL_INTERVAL_SECONDS: int = int(os.getenv("PUSH_OUTBOX_POLL_INTERVAL_SECONDS", 2))
    PUSH_OUTBOX_MAX_RETRY: int = int(os.getenv("PUSH_OUTBOX_MAX_RETRY", 5))
    PUSH_OUTBOX_RETRY_BASE_SECONDS: int = int(os.getenv("PUSH_OUTBOX_RETRY_BASE_SECONDS", 30))
    
settings = Settings()
