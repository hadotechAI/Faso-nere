--
-- PostgreSQL database dump
--

\restrict thv4ux3EEAexz40YhYKGXVAg45iyoJi3vc2P3Nhkxuxd3rOtXQvaPkcgq6uATmo

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
-- Data for Name: lots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lots (id, nom, subtitle, icon, prix_min, prix_max, nb_cadeaux, is_active, ordre, created_at, updated_at) FROM stdin;
c1ec77b2-bdba-4682-a096-a837350d60fb	Petit Lot	Terrains 300–500 m² · Ciment · Matériaux BTP	🎁	120000	5000000	20	t	1	2026-05-09 12:26:32.219732+00	2026-05-17 21:57:23.051139+00
39ffdcbc-abe1-4678-a864-d998774acb16	Gros Lot	Terrains 600–1000 m² · Ciment · Matériaux BTP	🏆	360000	10000000	20	t	2	2026-05-09 12:26:32.219732+00	2026-05-20 17:47:43.448403+00
\.


--
-- Data for Name: packs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.packs (id, nom, tentatives, prix, prix_par_tentative, badge, is_popular, is_best_value, is_active, created_at, updated_at) FROM stdin;
512654fb-6f25-40ff-8fe9-7067ca45a9b8	Elite	24	400000	16667	Meilleur choix	f	t	t	2026-05-10 22:36:19.862045+00	2026-05-17 22:25:38.724938+00
b16406cd-8d69-4b07-8953-aa49198583d2	Gold	16	100000	6250	\N	f	f	t	2026-05-10 22:36:19.862045+00	2026-05-17 22:31:07.862763+00
13489b34-87dd-4407-adfe-943639bcaf72	Premium	20	200000	10000	\N	f	f	t	2026-05-10 22:36:19.862045+00	2026-05-17 22:31:57.506748+00
58a39dfc-c29b-483b-b220-16f247d577fe	Starter	3	10000	3333	\N	f	f	t	2026-05-10 22:36:19.862045+00	2026-05-18 11:59:04.974647+00
f36528ff-6b09-4ebf-846b-b9bac1039af0	Bronze	6	20000	3333	\N	t	f	t	2026-05-10 22:36:19.862045+00	2026-05-18 12:03:55.033161+00
e781562c-fead-412f-b445-9fb032ea97fd		8	50000	6250	Populaire	t	f	t	2026-05-10 22:36:19.862045+00	2026-05-18 18:01:21.793683+00
748e04b4-aa65-46f5-96ed-5a172c2068b5	pack prince	12	15000	1250	\N	f	f	f	2026-05-30 17:12:37.188189+00	2026-06-11 22:52:17.749424+00
\.


--
-- PostgreSQL database dump complete
--

\unrestrict thv4ux3EEAexz40YhYKGXVAg45iyoJi3vc2P3Nhkxuxd3rOtXQvaPkcgq6uATmo

