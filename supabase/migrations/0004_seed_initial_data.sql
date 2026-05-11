-- =========================================================
-- DJAWAL V2 — Sprint 3 : Seed initial de données réelles
-- 8 destinations, 14 sites, 12 hôtels, 12 restaurants
-- =========================================================

-- ===== DESTINATIONS =====
-- Coordonnées : longitude, latitude (PostGIS Point order)

INSERT INTO destinations (id, name, name_ar, slug, wilaya, cultural_theme, description, coordinates) VALUES
(
  '11111111-1111-1111-1111-111111111001',
  'Alger',
  'الجزائر',
  'alger',
  'Alger',
  'mauresque',
  'La capitale et sa Casbah classée UNESCO. Bleu Sidi Bou Said, ruelles labyrinthiques, palais ottomans et marchés effervescents. Au croisement de la Méditerranée et du désert.',
  ST_SetSRID(ST_MakePoint(3.0588, 36.7538), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111002',
  'Tipaza',
  'تيبازة',
  'tipaza',
  'Tipaza',
  'mauresque',
  'Ruines romaines en bord de mer, classées UNESCO. Plages cristallines, mausolée royal mauritanien, et l''écho de Camus qui y a écrit "Noces".',
  ST_SetSRID(ST_MakePoint(2.4480, 36.5944), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111003',
  'Constantine',
  'قسنطينة',
  'constantine',
  'Constantine',
  'aures',
  'La ville suspendue des ponts. Gorges du Rhumel, pont de Sidi M''Cid, médersa et palais Bey Ahmed. Berceau de la culture chaouie et du malouf.',
  ST_SetSRID(ST_MakePoint(6.6147, 36.3650), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111004',
  'Béjaïa',
  'بجاية',
  'bejaia',
  'Béjaïa',
  'mauresque',
  'La perle de la Soummam. Cap Carbon, parc national de Gouraya, fort de Bordj Moussa et un littoral kabyle d''émeraude qui inspira Léon l''Africain.',
  ST_SetSRID(ST_MakePoint(5.0840, 36.7525), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111005',
  'Djanet & Tassili',
  'جانت',
  'djanet-tassili',
  'Illizi',
  'saharien',
  'Le musée à ciel ouvert du Tassili n''Ajjer. Gravures et peintures rupestres vieilles de 10 000 ans, plateau lunaire, peuple touareg et nuits étoilées comme nulle part ailleurs.',
  ST_SetSRID(ST_MakePoint(9.4847, 24.5544), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111006',
  'Ghardaïa & M''Zab',
  'غرداية',
  'ghardaia',
  'Ghardaïa',
  'saharien',
  'La pentapole mozabite classée UNESCO. Cinq cités-oasis blanches accrochées à la roche, urbanisme parfait, artisanat du tapis et tradition d''hospitalité ibadite.',
  ST_SetSRID(ST_MakePoint(3.6810, 32.4911), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111007',
  'Tlemcen',
  'تلمسان',
  'tlemcen',
  'Tlemcen',
  'mauresque',
  'La perle du Maghreb. Capitale zianide, mosquée de Mansourah, médersa Sidi Boumediene, jardins andalous et héritage almohade. Influence arabo-andalouse partout.',
  ST_SetSRID(ST_MakePoint(-1.3140, 34.8826), 4326)::geography
),
(
  '11111111-1111-1111-1111-111111111008',
  'Tikjda & Djurdjura',
  'تيكجدة',
  'tikjda-djurdjura',
  'Bouira',
  'aures',
  'Le toit de la Kabylie. Parc national du Djurdjura, sommet du Lalla Khedidja (2 308m), villages berbères perchés, cèdres millénaires et neige en hiver.',
  ST_SetSRID(ST_MakePoint(4.1530, 36.4500), 4326)::geography
)
ON CONFLICT (id) DO NOTHING;

-- ===== SITES =====

INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, entry_fee_da, best_season, validated_at) VALUES
-- ALGER
('11111111-1111-1111-1111-111111111001', 'La Casbah d''Alger', 'القصبة', 'Médina ottomane classée UNESCO. Ruelles en escaliers, palais des Deys, mosquée Ketchaoua, vues sur la baie depuis les terrasses.', 'medina', ST_SetSRID(ST_MakePoint(3.0598, 36.7867), 4326)::geography, 0, ARRAY['printemps','automne'], NOW()),
('11111111-1111-1111-1111-111111111001', 'Notre-Dame d''Afrique', 'كاتدرائية إفريقيا', 'Basilique néo-byzantine perchée sur les hauteurs. Vue panoramique sur la baie d''Alger et la Méditerranée.', 'monument', ST_SetSRID(ST_MakePoint(3.0364, 36.8033), 4326)::geography, 0, ARRAY['printemps','été','automne'], NOW()),
('11111111-1111-1111-1111-111111111001', 'Jardin d''Essai du Hamma', 'حديقة التجارب', 'Jardin botanique de 32 hectares créé en 1832. Allées de palmiers, dragonniers centenaires, bambous, vue depuis le Musée des Beaux-Arts.', 'jardin', ST_SetSRID(ST_MakePoint(3.0822, 36.7503), 4326)::geography, 100, ARRAY['printemps','automne'], NOW()),
-- TIPAZA
('11111111-1111-1111-1111-111111111002', 'Ruines romaines de Tipaza', 'الآثار الرومانية', 'Site UNESCO. Forum, théâtre, basiliques chrétiennes, nécropole face à la mer. À visiter au coucher du soleil.', 'monument', ST_SetSRID(ST_MakePoint(2.4434, 36.5944), 4326)::geography, 200, ARRAY['printemps','automne'], NOW()),
('11111111-1111-1111-1111-111111111002', 'Mausolée royal de Maurétanie', 'ضريح موريطانيا', 'Tombeau de Cléopâtre Séléné et Juba II, IIe siècle av. J.-C. Cylindre cyclopéen de 60m de diamètre dans la garrigue.', 'monument', ST_SetSRID(ST_MakePoint(2.5631, 36.5703), 4326)::geography, 150, ARRAY['printemps','automne'], NOW()),
-- CONSTANTINE
('11111111-1111-1111-1111-111111111003', 'Gorges du Rhumel', 'وادي الرمال', 'Gouffre vertigineux de 200m de profondeur traversant la ville. Sept ponts dont le pont suspendu de Sidi M''Cid (1912).', 'monument', ST_SetSRID(ST_MakePoint(6.6160, 36.3650), 4326)::geography, 0, ARRAY['toutes_saisons'], NOW()),
('11111111-1111-1111-1111-111111111003', 'Palais Ahmed Bey', 'قصر أحمد باي', 'Palais ottoman du XIXe siècle. Cours intérieures, zellige, mosaïque, mobilier d''époque. Musée d''art et d''histoire.', 'musee', ST_SetSRID(ST_MakePoint(6.6147, 36.3650), 4326)::geography, 200, ARRAY['toutes_saisons'], NOW()),
-- BÉJAÏA
('11111111-1111-1111-1111-111111111004', 'Cap Carbon', 'رأس كربون', 'Le plus haut phare naturel de Méditerranée (220m). Falaise vertigineuse, sentier de pèlerinage, vue sur le golfe.', 'plage', ST_SetSRID(ST_MakePoint(5.1058, 36.7878), 4326)::geography, 0, ARRAY['printemps','été','automne'], NOW()),
('11111111-1111-1111-1111-111111111004', 'Pic des Singes (Gouraya)', 'قمة القرود', 'Parc national, macaques de Berbérie en liberté, sentiers panoramiques sur la baie de Béjaïa.', 'parc', ST_SetSRID(ST_MakePoint(5.1106, 36.7892), 4326)::geography, 0, ARRAY['printemps','été','automne'], NOW()),
-- TASSILI
('11111111-1111-1111-1111-111111111005', 'Plateau du Tassili n''Ajjer', 'هضبة الطاسيلي', 'Plateau gréseux UNESCO. 15 000 gravures et peintures rupestres préhistoriques, formations rocheuses sculptées par l''érosion, accessibles uniquement à pied/chameau.', 'site_naturel', ST_SetSRID(ST_MakePoint(9.5980, 25.0830), 4326)::geography, 0, ARRAY['hiver','printemps','automne'], NOW()),
('11111111-1111-1111-1111-111111111005', 'Erg Admer', 'عرق ادمر', 'Dunes orange à perte de vue au sud de Djanet. Coucher de soleil mythique, bivouac touareg, sable parmi les plus fins du Sahara.', 'site_naturel', ST_SetSRID(ST_MakePoint(9.4500, 24.3000), 4326)::geography, 0, ARRAY['hiver','printemps'], NOW()),
-- GHARDAÏA
('11111111-1111-1111-1111-111111111006', 'Vieille ville de Ghardaïa', 'المدينة العتيقة', 'Médina mozabite UNESCO. Maisons blanches étagées, mosquée Sidi Brahim, marché traditionnel, urbanisme défensif unique au monde.', 'medina', ST_SetSRID(ST_MakePoint(3.6810, 32.4911), 4326)::geography, 0, ARRAY['hiver','printemps','automne'], NOW()),
-- TLEMCEN
('11111111-1111-1111-1111-111111111007', 'Mosquée de Mansourah', 'مسجد المنصورة', 'Vestiges d''une mosquée mérinide du XIVe siècle. Minaret de 38m encore debout, ruines évocatrices au crépuscule.', 'monument', ST_SetSRID(ST_MakePoint(-1.3392, 34.8636), 4326)::geography, 0, ARRAY['printemps','automne'], NOW()),
-- TIKJDA
('11111111-1111-1111-1111-111111111008', 'Lalla Khedidja', 'لالة خديجة', 'Plus haut sommet de Kabylie (2 308m). Trek de 5-7h, vue sur le golfe d''Alger par temps clair, neige de décembre à mars.', 'montagne', ST_SetSRID(ST_MakePoint(4.1786, 36.4583), 4326)::geography, 0, ARRAY['printemps','été'], NOW())
ON CONFLICT DO NOTHING;

-- ===== HOTELS =====

INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, price_range_da, star_rating, amenities, validated_at) VALUES
('11111111-1111-1111-1111-111111111001', 'Hôtel El Aurassi', 'فندق الأوراسي', 'Palace surplombant la baie d''Alger. Architecture moderne des années 70, piscine panoramique, restaurants gastronomiques.', 'Avenue du Frantz Fanon, Alger', ST_SetSRID(ST_MakePoint(3.0463, 36.7672), 4326)::geography, '[15000,40000)'::int4range, 5, ARRAY['wifi','piscine','restaurant','spa','parking'], NOW()),
('11111111-1111-1111-1111-111111111001', 'Maison d''hôtes Dar Hassan Pacha', 'دار حسن باشا', 'Riad ottoman restauré dans la Casbah. 6 chambres autour d''un patio à zellige, terrasse vue baie, petit-déjeuner traditionnel.', 'Rue Hassan Pacha, La Casbah, Alger', ST_SetSRID(ST_MakePoint(3.0612, 36.7855), 4326)::geography, '[8000,15000)'::int4range, 3, ARRAY['wifi','terrasse','petit-dejeuner'], NOW()),
('11111111-1111-1111-1111-111111111002', 'Hôtel La Corne d''Or Tipaza', 'القرن الذهبي', 'Hôtel de charme face aux ruines romaines. Architecture méditerranéenne, jardin d''oliviers, accès direct plage.', 'Route des Sablières, Tipaza', ST_SetSRID(ST_MakePoint(2.4490, 36.5950), 4326)::geography, '[6000,12000)'::int4range, 4, ARRAY['wifi','plage','restaurant','piscine'], NOW()),
('11111111-1111-1111-1111-111111111003', 'Hôtel Cirta Constantine', 'فندق سيرتا', 'Hôtel historique de 1914 dans le centre. Façade Art déco, vue gorges du Rhumel, restaurant traditionnel.', 'Avenue Rahmani Achour, Constantine', ST_SetSRID(ST_MakePoint(6.6147, 36.3650), 4326)::geography, '[7000,15000)'::int4range, 4, ARRAY['wifi','restaurant','bar'], NOW()),
('11111111-1111-1111-1111-111111111004', 'Hôtel Atlantique Béjaïa', 'فندق الأطلسي', 'Hôtel balnéaire face au golfe. Plage privée, bungalows familiaux, restaurant de poisson, accès Cap Carbon.', 'Boulevard de la Soummam, Béjaïa', ST_SetSRID(ST_MakePoint(5.0840, 36.7525), 4326)::geography, '[5000,10000)'::int4range, 3, ARRAY['plage','wifi','restaurant','famille'], NOW()),
('11111111-1111-1111-1111-111111111005', 'Camp touareg Tin Khlega', 'مخيم تين خلقة', 'Bivouac sahara authentique à 80km de Djanet. Tentes berbères, repas au feu de bois, observation des étoiles, guide touareg.', 'Erg Admer, Djanet', ST_SetSRID(ST_MakePoint(9.4500, 24.3000), 4326)::geography, '[12000,25000)'::int4range, NULL, ARRAY['immersion','guide','etoiles','feu_bois'], NOW()),
('11111111-1111-1111-1111-111111111005', 'Hôtel Zeriba Djanet', 'فندق زريبة', 'Hôtel d''adobe traditionnel. Confort moderne dans architecture saharienne, jardin de palmiers, point de départ des expéditions.', 'Centre-ville Djanet', ST_SetSRID(ST_MakePoint(9.4847, 24.5544), 4326)::geography, '[8000,15000)'::int4range, 3, ARRAY['wifi','restaurant','jardin','climatisation'], NOW()),
('11111111-1111-1111-1111-111111111006', 'Hôtel El Djanoub Ghardaïa', 'فندق الجنوب', 'Hôtel mozabite traditionnel à l''entrée de la vieille ville. Patio frais, terrasses étagées, vue sur Beni Isguen.', 'Beni Isguen, Ghardaïa', ST_SetSRID(ST_MakePoint(3.7172, 32.5089), 4326)::geography, '[5000,10000)'::int4range, 3, ARRAY['wifi','terrasse','restaurant'], NOW()),
('11111111-1111-1111-1111-111111111007', 'Hôtel Renaissance Tlemcen', 'فندق النهضة', 'Palace de luxe au cœur de la ville almohade. Jardin andalou, hammam, restaurant gastronomique, vue Mansourah.', 'Plateau Lalla Setti, Tlemcen', ST_SetSRID(ST_MakePoint(-1.3140, 34.8826), 4326)::geography, '[12000,25000)'::int4range, 5, ARRAY['wifi','spa','piscine','restaurant','hammam'], NOW()),
('11111111-1111-1111-1111-111111111008', 'Refuge du Djurdjura Tikjda', 'مأوى جرجرة', 'Auberge de montagne en pierre et bois. Idéal point de départ pour trek Lalla Khedidja. Cheminée, cuisine kabyle, neige en hiver.', 'Station Tikjda', ST_SetSRID(ST_MakePoint(4.1530, 36.4500), 4326)::geography, '[3000,8000)'::int4range, 2, ARRAY['cheminee','restaurant','randonnee'], NOW())
ON CONFLICT DO NOTHING;

-- ===== RESTAURANTS =====

INSERT INTO restaurants (destination_id, name, name_ar, description, cuisine, coordinates, price_range_da, signature_dishes, validated_at) VALUES
('11111111-1111-1111-1111-111111111001', 'Le Tantonville', 'تانتونفيل', 'Brasserie historique d''Alger (1908). Cadre Belle Époque, cuisine algéro-française, ambiance bourgeoise du Vieux Alger.', ARRAY['algeroise','francaise'], ST_SetSRID(ST_MakePoint(3.0563, 36.7765), 4326)::geography, '[1500,3500)'::int4range, ARRAY['Tajine d''agneau','Loup au four','Calentita'], NOW()),
('11111111-1111-1111-1111-111111111001', 'El Bahdja', 'البهجة', 'Cuisine algéroise authentique dans la Basse Casbah. Spécialités ottomanes, dolma, baklawa, ambiance familiale.', ARRAY['algeroise','ottomane'], ST_SetSRID(ST_MakePoint(3.0598, 36.7867), 4326)::geography, '[800,2000)'::int4range, ARRAY['Dolma','Chorba frik','Baklawa'], NOW()),
('11111111-1111-1111-1111-111111111001', 'La Calabraise', 'الكالابريز', 'Pizzeria-trattoria italienne face au port. Pizzas au feu de bois, pâtes maison, ambiance décontractée populaire.', ARRAY['italienne'], ST_SetSRID(ST_MakePoint(3.0625, 36.7720), 4326)::geography, '[1000,2500)'::int4range, ARRAY['Pizza margherita','Spaghetti vongole'], NOW()),
('11111111-1111-1111-1111-111111111002', 'La Terrasse de Tipaza', 'تيراسة تيبازة', 'Restaurant face aux ruines romaines. Poisson grillé, paella, vue mer panoramique au coucher du soleil.', ARRAY['poisson','mediterraneenne'], ST_SetSRID(ST_MakePoint(2.4450, 36.5945), 4326)::geography, '[2000,4500)'::int4range, ARRAY['Loup grillé','Paella','Calamars frits'], NOW()),
('11111111-1111-1111-1111-111111111003', 'Le Khroub', 'الخروب', 'Cuisine constantinoise traditionnelle. Berkoukes au mouton, chakhchoukha de Biskra, mh''adjeb maison, ambiance malouf en soirée.', ARRAY['constantinoise','chaouie'], ST_SetSRID(ST_MakePoint(6.6147, 36.3650), 4326)::geography, '[1200,3000)'::int4range, ARRAY['Chakhchoukha','Berkoukes','Mh''adjeb'], NOW()),
('11111111-1111-1111-1111-111111111004', 'L''Embarcadère Béjaïa', 'المرسى', 'Restaurant de poisson au port. Pêche du jour, kebbeb façon kabyle, vue sur la rade, jus de figue de barbarie.', ARRAY['kabyle','poisson'], ST_SetSRID(ST_MakePoint(5.0913, 36.7547), 4326)::geography, '[1500,3500)'::int4range, ARRAY['Poisson grillé du jour','Couscous au poulpe','Kebbeb'], NOW()),
('11111111-1111-1111-1111-111111111004', 'Chez Tassadit Ath Yenni', 'دار تاسعديت', 'Table d''hôtes dans village berbère. Repas chez l''habitant, couscous au feu de bois, bijoux kabyles d''époque, immersion totale.', ARRAY['kabyle','traditionnelle'], ST_SetSRID(ST_MakePoint(4.1850, 36.6450), 4326)::geography, '[1500,2500)'::int4range, ARRAY['Couscous au feu de bois','Tomate sauce','Galette berbère'], NOW()),
('11111111-1111-1111-1111-111111111005', 'Tente touarègue Tin Khlega', 'الخيمة الطوارقية', 'Repas sous tente touarègue dans le Tassili. Méchoui de chameau, taguella (pain dans le sable), thé à la menthe en trois temps.', ARRAY['touarègue','saharienne'], ST_SetSRID(ST_MakePoint(9.4500, 24.3000), 4326)::geography, '[3500,5500)'::int4range, ARRAY['Méchoui de chameau','Taguella','Thé touareg'], NOW()),
('11111111-1111-1111-1111-111111111006', 'Restaurant El Aatik Ghardaïa', 'العتيق', 'Cuisine mozabite chez l''habitant. Couscous oasien aux dattes, tajine de chevreau, salon ibadite traditionnel à coussins.', ARRAY['mozabite','saharienne'], ST_SetSRID(ST_MakePoint(3.6810, 32.4911), 4326)::geography, '[1200,2500)'::int4range, ARRAY['Couscous aux dattes','Tajine chevreau','Tcharak'], NOW()),
('11111111-1111-1111-1111-111111111007', 'Dar Es Soltane Tlemcen', 'دار السلطان', 'Cuisine tlemcénienne raffinée. Couscous au cardon, mhalbi, gâteaux andalous, décor inspiré de la médersa.', ARRAY['tlemcenienne','andalouse'], ST_SetSRID(ST_MakePoint(-1.3155, 34.8830), 4326)::geography, '[1500,3500)'::int4range, ARRAY['Couscous au cardon','Tajine pruneaux','Makroud'], NOW()),
('11111111-1111-1111-1111-111111111008', 'Auberge des Cèdres Tikjda', 'فندق الأرز', 'Cuisine kabyle de montagne. Boukhaboukh, ttirimt, plats au feu de cheminée en hiver, vue sur les sommets du Djurdjura.', ARRAY['kabyle','montagne'], ST_SetSRID(ST_MakePoint(4.1530, 36.4500), 4326)::geography, '[1000,2500)'::int4range, ARRAY['Boukhaboukh','Ttirimt','Galette à l''huile d''olive'], NOW())
ON CONFLICT DO NOTHING;

-- ===== STATISTIQUES =====
DO $$
DECLARE
  c_dest INT; c_sites INT; c_hotels INT; c_restos INT;
BEGIN
  SELECT COUNT(*) INTO c_dest FROM destinations;
  SELECT COUNT(*) INTO c_sites FROM sites WHERE validated_at IS NOT NULL;
  SELECT COUNT(*) INTO c_hotels FROM hotels WHERE validated_at IS NOT NULL;
  SELECT COUNT(*) INTO c_restos FROM restaurants WHERE validated_at IS NOT NULL;
  RAISE NOTICE 'Seed terminé : % destinations, % sites, % hôtels, % restaurants', c_dest, c_sites, c_hotels, c_restos;
END $$;
