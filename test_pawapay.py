import asyncio
from app.services.pawapay_client import pawapay_client

async def test_pawapay():
    try:
        print("Test de la configuration PawaPay...")
        print(f"Base URL: {pawapay_client.base_url}")
        print(f"Mode sandbox: {pawapay_client.is_sandbox}")
        
        providers = await pawapay_client.get_deposit_providers(country="BFA")
        print("\nOpérateurs activés pour les dépôts (BFA):")
        if not providers:
            print("❌ AUCUN OPERATEUR ACTIVE !")
        for p in providers:
            print(f"- {p['label']} ({p['provider']})")
            
    except Exception as e:
        print(f"Erreur: {e}")

if __name__ == "__main__":
    asyncio.run(test_pawapay())
