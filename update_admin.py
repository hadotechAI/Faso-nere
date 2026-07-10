import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://faso_nere_db_user:XFyvIxDXbC0ORplCUgSGg5RJE1sP5YNQ@dpg-d8nur3vlk1mc73a5csag-a.frankfurt-postgres.render.com:5432/faso_nere_db")
    
    # Hash bcrypt valide pour "admin123"
    hash_admin = "$2b$12$jZzv1TOD192ULxokbSZCIOG0x7a/FbePZGNb5hm65CE6l5U5BbPzm"
    
    await conn.execute(
        "UPDATE users SET mot_de_passe_hash = $1 WHERE telephone = '00000000'",
        hash_admin
    )
    print("✅ Mot de passe administrateur corrigé avec succès !")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
