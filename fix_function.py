import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://faso_nere_db_user:XFyvIxDXbC0ORplCUgSGg5RJE1sP5YNQ@dpg-d8nur3vlk1mc73a5csag-a.frankfurt-postgres.render.com:5432/faso_nere_db")
    
    # Correction de la fonction pour ajouter "public." aux tables
    await conn.execute("""
        CREATE OR REPLACE FUNCTION public.fn_sync_nb_cadeaux()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
        DECLARE
          v_lot_id UUID;
        BEGIN
          v_lot_id := COALESCE(NEW.lot_id, OLD.lot_id);
          UPDATE public.lots
          SET nb_cadeaux = (
            SELECT COALESCE(SUM(quantite), 0)
            FROM public.cadeaux
            WHERE lot_id = v_lot_id
          )
          WHERE id = v_lot_id;
          RETURN COALESCE(NEW, OLD);
        END;
        $function$;
    """)
    print("✅ Fonction corrigée dans la base de données de production !")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
