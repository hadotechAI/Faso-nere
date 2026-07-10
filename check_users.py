import asyncio
import asyncpg
import datetime

async def main():
    # URL de connexion à la DB de production Render
    conn_str = "postgresql://faso_nere_db_user:XFyvIxDXbC0ORplCUgSGg5RJE1sP5YNQ@dpg-d8nur3vlk1mc73a5csag-a.frankfurt-postgres.render.com:5432/faso_nere_db"
    
    print("Connexion à la base de données de production...")
    try:
        conn = await asyncpg.connect(conn_str)
        print("Connecté avec succès.\n")
        
        # Récupérer les 5 derniers utilisateurs inscrits
        query = """
            SELECT id, telephone, role, nom_prenom, created_at
            FROM users
            ORDER BY created_at DESC
            LIMIT 5;
        """
        rows = await conn.fetch(query)
        
        print(f"Les 5 derniers utilisateurs inscrits :")
        print("-" * 50)
        for row in rows:
            print(f"Tel: {row['telephone']} | Rôle: {row['role']} | Nom: {row['nom_prenom']} | Inscrit le: {row['created_at']}")
            
        print("-" * 50)
        await conn.close()
    except Exception as e:
        print(f"Erreur de connexion : {e}")

if __name__ == "__main__":
    asyncio.run(main())
