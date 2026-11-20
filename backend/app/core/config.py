from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore")
    database_url: str = "postgresql://pyroguard:changeme@db:5432/pyroguard_db"


settings = Settings()
