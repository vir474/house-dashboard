from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "House Dashboard"
    DATABASE_URL: str = "mysql+aiomysql://user:password@db:3306/house_dashboard"
    OLLAMA_URL: str = "http://ollama:11434"
    OLLAMA_MODEL: str = "llama3.2"
    SECRET_KEY: str = "change-me-in-production"
    APNS_KEY_ID: str = ""
    APNS_TEAM_ID: str = ""
    APNS_KEY_FILE: str = ""
    APNS_BUNDLE_ID: str = "com.yourname.housedashboard"

    class Config:
        env_file = ".env"


settings = Settings()
