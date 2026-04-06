"""
config.py
─────────
Supabase bağlantı ayarları.
yillik_plan sisteminden bağımsız, aynı DB'yi kullanır.
"""
import os
from supabase import create_client

# Supabase credentials (environment variables veya doğrudan)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://pwzbjhgrhkcdyowknmhe.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3emJqaGdyaGtjZHlvd2tubWhlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTI5ODA1NiwiZXhwIjoyMDgwODc0MDU2fQ.lwyi9uyfvENGHnRqwjRSle01EMZeEDFJA4vlpPI6oag")  # service_role key

def get_supabase():
    """Supabase client oluştur."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("SUPABASE_URL ve SUPABASE_KEY environment variables gerekli")
    return create_client(SUPABASE_URL, SUPABASE_KEY)

# SEO settings
SITE_NAME = "Eğitim Portalı"
SITE_URL  = "https://derstakip.net"  # Kendi domain'iniz
ADSENSE_CLIENT = "ca-pub-8561144837504825"  # AdSense client ID
