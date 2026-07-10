--
-- PostgreSQL database dump
--

\restrict rkD0f57XIZWsqXS0ZqmQRel3epP84De7fCV3QQh2oX0Hv0Dc74uh6S6p84tdgX9

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: cadeaux; Type: TABLE DATA; Schema: public; Owner: postgres
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.cadeaux DISABLE TRIGGER ALL;

COPY public.cadeaux (id, lot_id, nom, description, icon, prix_reel, categorie, is_winner, is_loser, quantite, created_at, updated_at) FROM stdin;
bfa40fe0-581c-492a-a83b-486b60d30aef	39ffdcbc-abe1-4678-a864-d998774acb16	Aucun gain	Pas de chance cette fois-ci	❌	0	aucun	f	t	11	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.429602+00
0dea513a-1568-4ae0-8961-3e6f0d5761f3	c1ec77b2-bdba-4682-a096-a837350d60fb	Parcelle 300 m²	Terrain constructible 300 m²	🏡	3000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
23e75faf-95ee-4ccf-a6ca-0dfb0f9397f8	c1ec77b2-bdba-4682-a096-a837350d60fb	3 tonnes de ciment	60 sacs de ciment 50 kg	🏗️	360000	ciment	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
fa5a64fd-6d02-43c8-91f7-9fbb9d39c1f5	c1ec77b2-bdba-4682-a096-a837350d60fb	Parcelle 500 m²	Terrain constructible 500 m²	🏡	5000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
879630b8-e4c1-463d-b50d-e0eff48f0009	c1ec77b2-bdba-4682-a096-a837350d60fb	Parcelle 400 m²	Terrain constructible 400 m²	🏡	4000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
6a08ff05-1309-4516-88bc-ce8f08a6f9ac	c1ec77b2-bdba-4682-a096-a837350d60fb	5 tonnes de ciment	100 sacs de ciment 50 kg	🏗️	600000	ciment	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
90a065dd-70ee-426c-b66a-fad7ceea65ba	c1ec77b2-bdba-4682-a096-a837350d60fb	Aucun gain	Pas de chance cette fois-ci	❌	0	aucun	f	t	11	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.314331+00
42e9ca74-d095-4642-8831-050a32003432	39ffdcbc-abe1-4678-a864-d998774acb16	Parcelle 800 m²	Terrain constructible 800 m²	🌳	8000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
5e6aea0f-53a8-431d-b7bb-25a9238f55f2	39ffdcbc-abe1-4678-a864-d998774acb16	Parcelle 600 m²	Terrain constructible 600 m²	🌳	6000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
4e1403ad-d024-4c27-a6ac-6d23ab648c4f	39ffdcbc-abe1-4678-a864-d998774acb16	10 tonnes de ciment	200 sacs de ciment 50 kg	🏗️	1200000	ciment	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
df7a0b94-3025-4ef9-a2f5-392a3de193d1	39ffdcbc-abe1-4678-a864-d998774acb16	7 tonnes de ciment	140 sacs de ciment 50 kg	🏗️	840000	ciment	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
625df349-6975-437a-8f2d-0782c1391d68	39ffdcbc-abe1-4678-a864-d998774acb16	3 tonnes de ciment	60 sacs de ciment 50 kg	🏗️	360000	ciment	t	f	2	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
6c829c69-efa5-4a3d-bbb9-50b0cddd9bc5	39ffdcbc-abe1-4678-a864-d998774acb16	Kit BTP Premium	Fer à béton + sable + gravier + parpaings	🧱	750000	materiaux	t	f	2	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
3bde6025-89a9-44db-830b-037afcebdfa0	39ffdcbc-abe1-4678-a864-d998774acb16	Parcelle 1000 m²	Grand terrain constructible 1000 m²	🌳	10000000	terrain	t	f	1	2026-05-09 12:26:32.219732+00	2026-06-12 10:34:42.427598+00
4a07f0dc-b936-4bb1-b1ef-31febee57302	c1ec77b2-bdba-4682-a096-a837350d60fb	1 tonne de ciment	20 sacs de ciment 50 kg	🏗️	120000	ciment	t	f	2	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
760b4d39-dbf5-41bb-bb0f-dee4160aa8b2	c1ec77b2-bdba-4682-a096-a837350d60fb	Kit matériaux	Fer à béton + sable + gravier	🧱	250000	materiaux	t	f	2	2026-05-09 12:26:32.219732+00	2026-06-11 22:41:18.31061+00
\.


ALTER TABLE public.cadeaux ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

\unrestrict rkD0f57XIZWsqXS0ZqmQRel3epP84De7fCV3QQh2oX0Hv0Dc74uh6S6p84tdgX9

