-- =========================================================
-- DJAWAL V2 — Import en masse depuis dump bilnov.com
-- Généré automatiquement par convert_djawal.py
-- =========================================================

BEGIN;

-- ===== 1. Destinations (créées si manquantes) =====
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Adrar', 'adrar', 'Adrar', 'saharien'::cultural_theme, 'La wilaya de Adrar fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(-0.29, 27.87), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Chlef', 'chlef', 'Chlef', 'mauresque'::cultural_theme, 'La wilaya de Chlef fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(1.33, 36.16), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Laghouat', 'laghouat', 'Laghouat', 'saharien'::cultural_theme, 'La wilaya de Laghouat fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(2.86, 33.8), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Oum El Bouaghi', 'oum-el-bouaghi', 'Oum El Bouaghi', 'aures'::cultural_theme, 'La wilaya de Oum El Bouaghi fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(7.11, 35.87), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Batna', 'batna', 'Batna', 'aures'::cultural_theme, 'La wilaya de Batna fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(6.17, 35.55), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Béjaïa', 'bejaia', 'Béjaïa', 'aures'::cultural_theme, 'La wilaya de Béjaïa fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(5.08, 36.75), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Biskra', 'biskra', 'Biskra', 'saharien'::cultural_theme, 'La wilaya de Biskra fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(5.73, 34.85), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Bouira', 'bouira', 'Bouira', 'aures'::cultural_theme, 'La wilaya de Bouira fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(3.9, 36.37), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Tiaret', 'tiaret', 'Tiaret', 'mauresque'::cultural_theme, 'La wilaya de Tiaret fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(1.32, 35.37), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Tizi Ouzou', 'tizi-ouzou', 'Tizi Ouzou', 'aures'::cultural_theme, 'La wilaya de Tizi Ouzou fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(4.04, 36.71), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Alger', 'alger', 'Alger', 'mauresque'::cultural_theme, 'La wilaya de Alger fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(3.06, 36.75), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Sétif', 'setif', 'Sétif', 'aures'::cultural_theme, 'La wilaya de Sétif fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(5.41, 36.19), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('El Bayadh', 'el-bayadh', 'El Bayadh', 'saharien'::cultural_theme, 'La wilaya de El Bayadh fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(1.02, 33.68), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Bordj Bou Arréridj', 'bordj-bou-arreridj', 'Bordj Bou Arréridj', 'aures'::cultural_theme, 'La wilaya de Bordj Bou Arréridj fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(4.76, 36.07), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Naâma', 'naama', 'Naâma', 'saharien'::cultural_theme, 'La wilaya de Naâma fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(-0.32, 33.27), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('Timimoun', 'timimoun', 'Timimoun', 'saharien'::cultural_theme, 'La wilaya de Timimoun fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(0.23, 29.26), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;
INSERT INTO destinations (name, slug, wilaya, cultural_theme, description, coordinates)
VALUES ('In Salah', 'in-salah', 'In Salah', 'saharien'::cultural_theme, 'La wilaya de In Salah fait partie des 58 wilayas d''Algérie. Découvrez ses sites touristiques, hôtels et restaurants sélectionnés par la communauté Djawal.', ST_SetSRID(ST_MakePoint(2.46, 27.21), 4326)::geography)
ON CONFLICT (slug) DO NOTHING;

-- ===== 2. Hôtels =====

INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'Ibis Alger Aéroport', NULL, 'Les hôtels en Algérie sont des établissements touristiques destinés à l’hébergement des voyageurs.
Ils proposent différents niveaux de confort allant des hôtels économiques aux complexes 5 étoiles.
La plupart des chambres sont équipées de climatisation, salle de bain, télévision et connexion WiFi.
Les services courants incluent la restauration, le room service et la réception 24h/24.
Certains hôtels offrent des espaces de détente comme piscine, café, salle de sport ou spa.
Les établissements sont classés par étoiles selon la qualité des services et des équipements.
On trouve des hôtels dans toutes les grandes villes, régions côtières, sites naturels et zones sahariennes.
Ils accueillent aussi bien les touristes locaux que les visiteurs étrangers.
Grâce à leur diversité, ils participent activement au développement du tourisme national.
Les hôtels jouent un rôle clé dans l’accueil, le confort et la promotion de l’image de l’Algérie.', 'Route De L''université Bp 12 5 Juillet Bab Ezzouar, Dar el Beïda 16311', ST_SetSRID(ST_MakePoint(3.198055, 36.714722), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/1/main_images/hotel_1755710855_9j2DhY9P.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'Alger Marriott Hotel Bab Ezzouar', NULL, 'L’hôtel Algiers Marriott Hotel Bab Ezzouar est un établissement 5 étoiles situé à proximité de l’aéroport d’Alger, idéal pour les voyageurs d’affaires et les touristes. Doté d’un design moderne et élégant, il propose des chambres et suites spacieuses avec vue sur la ville ou la mer. Les équipements incluent une salle de sport, une piscine extérieure et un spa pour la détente. Plusieurs restaurants offrent une cuisine internationale et locale, dont un rooftop avec panorama. Les salles de réunion et le centre d’affaires répondent aux besoins des professionnels. Son emplacement permet un accès facile aux zones commerciales et aux transports. Le service est personnalisé et de haut standing, dans une ambiance luxueuse. Idéal pour des séjours confortables ou des événements prestigieux, le Marriott Bab Ezzouar allle luxe et praticité.', 'Trust Complex Buildings, Nouveau Quartier des Affaires, Bab Ezzouar, Algiers, DZ-16 16311', ST_SetSRID(ST_MakePoint(3.1922, 36.712008), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/2/main_images/hotel_1755710876_pc4DCegD.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'Best Night', NULL, 'Situé en plein cœur d''Alger, l''Hôtel Best Night est une adresse prisée pour son ambiance conviviale et son service chaleureux. Idéal pour les voyageurs en quête de confort à petit prix, il propose des chambres propres et fonctionnelles, dotées des équipements essentiels (Wi-Fi, climatisation, TV).

Son emplacement central permet un accès facile aux sites touristiques, restaurants et transports en commun. Le personnel est accueillant et disponible pour conseiller les visiteurs. Bien que simple, l''hôtel offre un excellent rapport qualité-prix pour un séjour court ou d''affaires.

Une option économique et pratique pour découvrir Alger sans se ruiner', 'Cite Boushaki D, No. 158, Bab Ezzouar, Alger 16000 Algérie', ST_SetSRID(ST_MakePoint(3.0586, 36.765), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/3/main_images/hotel_1755710911_nHr3vWkd.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'Auberge de Jeunesse d''Azeffoun- بيت الشباب ازفون', NULL, 'L''Auberge de Jeunesse d''Azeffoun est chargée d’œuvrer au développement et à la promotion de la mobilité des jeunes et du tourisme éducatif de la jeunesse. Activités de loisirs et échanges de jeunes. Située à 300 m de la plage du centre.', 'ََAzeffoun', ST_SetSRID(ST_MakePoint(4.8661721, 36.8890798), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/4/main_images/hotel_1755697755_iEvByUFz.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب ادرار', NULL, 'ــ بيــت الشبـــاب وسط الولاية أدرار بجوار المركب الرياضي
50 سرير', 'بيت الشباب ادرار', ST_SetSRID(ST_MakePoint(-0.30440473, 27.8670974), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/5/main_images/hotel_1756044730_KNH6QsjS.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'Adrar' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيــت الشبـــاب رقان', NULL, 'بيــت الشبـــاب رقان حي الاستقلال', 'بيــت الشبـــاب رقان حي الاستقلال', ST_SetSRID(ST_MakePoint(0.1671713, 26.7150559), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/6/main_images/hotel_1756045314_3l4yEvaW.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Adrar' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت شباب أولف', NULL, '049977756 
قدرة الإستعاب   

80سرير', 'أولف  أولف', ST_SetSRID(ST_MakePoint(1.2197637, 26.9584313), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/7/main_images/hotel_1756046823_aMm5ikIa.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'In Salah' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب تمنطيط', NULL, 'تمنطيط - أدرار
500 دج / اليوم
قدرة الإستعاب : 80 
رقم الهاتف :  049961336', 'تمنطيط - أدرار', ST_SetSRID(ST_MakePoint(0.2730304, 27.756206), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/8/main_images/hotel_1756047039_zMGQFLxG.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Adrar' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب تيميمون', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'تيميمون - تيميمون', ST_SetSRID(ST_MakePoint(0.2317493, 29.2683138), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/9/main_images/hotel_1756047216_S90xfkNU.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Timimoun' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب معمر مصابيح', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'الشلف - الشلف', ST_SetSRID(ST_MakePoint(1.3370681, 36.1633425), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/10/main_images/hotel_1756047518_gdQBSeQR.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب قدور بودواو', NULL, '500 دج / اليوم
قدرة الإستعاب : 80 
رقم الهاتف :  029758284', 'الأغواط - الأغواط', ST_SetSRID(ST_MakePoint(2.8410693, 33.7868599), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/11/main_images/hotel_1756048263_g5twlEat.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Laghouat' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب قاسمي الطيب', NULL, '437W+4GQ دار الشباب عويفات الحسين, Aflou
500 دج / اليوم
قدرة الإستعاب : 80 
0776288972', 'أفلو - الأغواط', ST_SetSRID(ST_MakePoint(2.0941345, 34.1129506), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/12/main_images/hotel_1756049021_JJuPWOXe.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'Laghouat' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب ياحي ياسين', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'أم البواقي - أم البواقي', ST_SetSRID(ST_MakePoint(7.1060261, 35.8770278), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/13/main_images/hotel_1756049291_UYKUyFMb.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Oum El Bouaghi' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب باتنة', NULL, '500 دج / اليوم
قدرة الإستعاب : 80 
رقم الهاتف :  033273204', 'باتنة - باتنة', ST_SetSRID(ST_MakePoint(6.1510359, 35.5488374), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/14/main_images/hotel_1756049920_1wvW25BP.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Batna' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب تيمقاد', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'تيمقاد - باتنة', ST_SetSRID(ST_MakePoint(6.467855, 35.4908775), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/15/main_images/hotel_1756050293_QMune9uQ.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Batna' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب درقينة', NULL, '500 دج / اليوم
قدرة الإستعاب : 80 
  رقم الهاتف : 034258068', 'درقينة - بجاية', ST_SetSRID(ST_MakePoint(5.3149635, 36.5645671), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/16/main_images/hotel_1756051728_yNTKTmAh.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب تيشي', NULL, 'قدرة الإستعاب : 80 
500 دج / اليوم', 'الطريق الوطني رقم 9 تيشي مركز
  ولاية بجاية', ST_SetSRID(ST_MakePoint(5.1551956, 36.6692464), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/17/main_images/hotel_1756052340_eh09hOA7.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب الشهيد مسعودي رابح', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'الطريق الوطني رقم 9 - بجوار دائرة خراطة
خراطة - بجاية', ST_SetSRID(ST_MakePoint(5.2742335, 36.4943842), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/18/main_images/hotel_1756053004_FtCjgu6H.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب القنطرة', NULL, '500 دج / اليوم
قدرة الإستعاب : 80', 'بيت الشباب 5 جويلية - القنطرة', ST_SetSRID(ST_MakePoint(5.71648942, 35.2254352), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/19/main_images/hotel_1756053776_oLuQiFBg.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Biskra' LIMIT 1;
INSERT INTO hotels (destination_id, name, name_ar, description, address, coordinates, images, validated_at)
SELECT id, 'بيت الشباب مشونش', NULL, '500 دج / اليوم
قدرة الإستعاب : 80 
رقم الهاتف : لا يوجد', 'مشونش - بسكرة', ST_SetSRID(ST_MakePoint(5.9944142, 34.9438236), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/hotels/20/main_images/hotel_1756055626_TLwlMaFA.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Biskra' LIMIT 1;

-- ===== 3. Sites touristiques =====
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Azru n Thur', 'ازرو نطهور', 'Azru n’Thor, culminant à 1 883 m dans le massif du Djurdjura (commune d’Iferhounene), est un sommet emblématique et lieu de pèlerinage en Kabylie. Chaque année, des milliers de fidèles y participent à la procession traditionnelle « Assensi bwazrou n’Thor ». Son nom, lié à la prière de Dohr, reflète une forte symbolique religieuse et culturelle. L’accès se fait par le col de Tirourda, puis à pied jusqu’au marabout blanc au sommet, offrant une vue imprenable sur les montagnes environnantes.', 'nature', ST_SetSRID(ST_MakePoint(4.38899517, 36.4890063), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/20/main_images/site_1755692897_BhZ7W81h.jpg','https://djawal.bilnov.com/storage/tourist_site/20/images/img_1755717069_jJTFTmlS.jpg','https://djawal.bilnov.com/storage/tourist_site/20/images/img_1755717069_erHzTEHK.jpg','https://djawal.bilnov.com/storage/tourist_site/20/images/img_1755717069_U4BRVYVp.jpg','https://djawal.bilnov.com/storage/tourist_site/20/images/img_1756157745_cSa4pmdC.jpg','https://djawal.bilnov.com/storage/tourist_site/20/images/img_1756157745_SI1ieFLI.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Tizi Ouzou' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Ghoufi', 'شرفات الغوفي', 'Les Gorges de Ghoufi, situées dans les Aurès (Batna), sont un canyon impressionnant creusé par l’oued Abiod.
On y découvre des habitations troglodytiques accrochées aux falaises, témoins d’un mode de vie ancestral.
Le paysage naturel est spectaculaire : falaises abruptes, palmiers et vue panoramique sur toute la vallée.
Ce site classé attire les amoureux de la nature, de la randonnée et du patrimoine historique traditionnel.', 'monument', ST_SetSRID(ST_MakePoint(6.16738192, 35.0499786), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/21/main_images/site_1755272431_Rmcg0tGm.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Biskra' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Cascade', 'شلال لعلام', 'Les cascades de Laalam, situées à Tamridjet (Béjaïa), se trouvent en hauteur dans un décor sauvage magnifique.
On y accède par un petit sentier de randonnée facile, idéal pour une sortie nature.
L’eau tombe en plusieurs niveaux, entourée d’arbres et de verdure, parfait pour se détendre ou se baigner.
Ce lieu reste peu connu mais très apprécié par les randonneurs et partagé sur les réseaux comme un bijou caché de Tamrijt.', 'nature', ST_SetSRID(ST_MakePoint(5.3751185, 36.5623061), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/22/main_images/site_1755273718_5NgU9CUb.jpg','https://djawal.bilnov.com/storage/tourist_site/22/images/img_1758324568_WzxWdgNS.png','https://djawal.bilnov.com/storage/tourist_site/22/images/img_1758324568_Wmfi0aPF.png','https://djawal.bilnov.com/storage/tourist_site/22/images/img_1758324568_28MHVChB.png','https://djawal.bilnov.com/storage/tourist_site/22/images/img_1758324568_meTig2nh.png','https://djawal.bilnov.com/storage/tourist_site/22/images/img_1758324568_LqCOiaCW.png']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Lac Agulmim', 'بحيرة اقلميم', 'Le lac Agoulmim est un petit lac de montagne situé à Tikjda (Djurdjura), à environ 1700 mètres d’altitude.
On y accède après une randonnée, dans un paysage rocheux et verdoyant très calme.
Son atmosphère sauvage, parfois brumeuse ou enneigée, lui donne un charme mystérieux.
C’est une destination appréciée des randonneurs en quête de tranquillité et de nature pure.', 'nature', ST_SetSRID(ST_MakePoint(4.0405, 36.27512), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/23/main_images/site_1755278022_vn5rbMwj.jpg','https://djawal.bilnov.com/storage/tourist_site_media/63/galleries/gallery_1758779516_0_GEZV1MzX.jpg','https://djawal.bilnov.com/storage/tourist_site_media/63/galleries/gallery_1758779516_1_GYMnNX2O.jpg','https://djawal.bilnov.com/storage/tourist_site_media/63/galleries/gallery_1758779516_2_wtsonnCV.jpg','https://djawal.bilnov.com/storage/tourist_site_media/63/galleries/gallery_1758779516_3_9vBsUc8h.jpg','https://djawal.bilnov.com/storage/tourist_site_media/63/galleries/gallery_1758779516_4_jLji6I7G.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Bouira' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Tighremt', 'ثيغرمت', 'La plage de Tighremt, à Toudja (commune à l’ouest de Béjaïa), est une belle plage de galets, entourée de rochers et falaises. Avec ses dimensions généreuses (1,2 km de long sur 60 m de large), elle est autorisée à la baignade et se distingue par une ambiance paisible et authentique, parfaite pour les amateurs de calme et de nature préservée.', 'nature', ST_SetSRID(ST_MakePoint(4.8661721, 36.8589277), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/24/main_images/site_1755278299_xp1mI3Tw.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Tiout', 'واحة تيوت', 'L’oasis de Tiout, située près de la ville de Naâma, est une palmeraie verdoyante en plein désert, entourée de collines arides.
On y trouve un petit lac naturel formé par une source, reflétant les palmiers et offrant un paysage très paisible.
Le vieux ksar traditionnel en pierre domine la vallée et rappelle l’histoire ancienne de cette région saharienne.
Cet endroit est apprécié pour sa fraîcheur, ses dattiers, et son ambiance authentique qui attire touristes, familles et photographes.', 'nature', ST_SetSRID(ST_MakePoint(1.4395055, 34.1801236), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/25/main_images/site_1755279065_PAeHov0a.jpg','https://djawal.bilnov.com/storage/tourist_site_media/55/galleries/gallery_1758655959_0_xeOeCRyQ.jpg','https://djawal.bilnov.com/storage/tourist_site_media/55/galleries/gallery_1758655959_1_GDi8aTjb.jpg','https://djawal.bilnov.com/storage/tourist_site_media/55/galleries/gallery_1758655959_2_BU5SjjC9.jpg','https://djawal.bilnov.com/storage/tourist_site_media/55/galleries/gallery_1758655959_3_fsWgTa6d.jpg','https://djawal.bilnov.com/storage/tourist_site_media/55/galleries/gallery_1758655959_4_GuXwfY6E.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'El Bayadh' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Timgad', 'تيمقاد', 'Voici une sélection d’images illustrant les ruines romaines de Timgad (Thamugadi) : l’impressionnant arc de triomphe, les colonnes corinthiennes alignées, les vestiges du forum, du théâtre antique… un vrai voyage dans l’Antiquité !', 'monument', ST_SetSRID(ST_MakePoint(6.46457, 35.48718), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/26/main_images/site_1755279407_75tW92Hp.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Batna' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Tombeau d’Imedghassen', 'ضريح امذغاسن', 'Le tombeau Imedghassen (ou Medracen) est un monument funéraire numide situé près de la commune de Boumia dans la wilaya de Batna.
Il se présente comme une grande construction circulaire de pierre, avec un cône en gradins et entourée de colonnes, rappelant une pyramide aplatie.
Construit au IIIᵉ siècle avant J.-C., il servait de mausolée aux rois numides et reste un symbole historique important de la culture berbère.
Isolé dans la plaine, il attire les passionnés d’histoire et d’architecture antique.', 'monument', ST_SetSRID(ST_MakePoint(6.43444, 35.70722), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/27/main_images/site_1755280731_KMhmZDCa.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Batna' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'La Qal’a des Beni Hammad-قلعة بني حماد', NULL, 'Perchée à 1 000 m d’altitude sur les monts du Hodna en Algérie, la Qal’a des Beni Hammad est un site archéologique classé à l’UNESCO. Fondée en 1007 comme capitale de la dynastie berbère des Hammadides, cette cité fut un centre de pouvoir et de culture raffiné avant son abandon stratégique en 1090 face à la menace des Banu Hilal.
Ses vestiges exceptionnellement préservés offrent le témoignage rare d’une cité palatiale fortifiée du XIe siècle. Ceinturée de remparts de 7 km, elle abrite les ruines de sa Grande Mosquée, l’une des plus vastes d’Algérie, et son minaret iconique annonçant l’art almohade. Le joyau du site est le Palais de l’Émir (Dar al-Bahr), renommé pour son immense bassin cérémoniel intégrant architecture, eau et jardins.
La Qal’a est un jalon essentiel pour comprendre la civilisation islamique médiévale au Maghreb. Son architecture et son esthétique, synthèse d’influences berbères, andalouses et fatimides, eurent une influence majeure sur le développement urbain.', 'monument', ST_SetSRID(ST_MakePoint(4.793333, 35.813889), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/30/main_images/site_1755617599_RvVIOTtq.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Bordj Bou Arréridj' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Casbah D''Alger', 'قصبة الجزائر', 'Perchée en amphithéâtre face à la mer, la Casbah d''Alger est bien plus qu''un simple quartier : c''est la cité historique, le cœur originel de la capitale algérienne et un site classé au patrimoine mondial de l''UNESCO. Fondée sur les ruines de l''ancienne Icosium, elle atteignit son apogée durant la période ottomane aux XVIIe et XVIIIe siècles, servant de repaire aux corsaires et de place forte imprenable.
Ce dédale unique de ruelles étroites et escarpées, d''escaliers secrets et de maisons blanchies à la chaux forme un modèle d''urbanisme méditerranéen musulman. Son architecture mêle magistralement les styles ottoman, maure et arabo-andalou. Derrière des façades sobres se cachent des palais (comme le Palais de la Jenina) et des demeures aristocratiques (dar) aux cours intérieures richement décorées de faïences, de stucs finement sculptés et de fontaines rafraîchissantes.
La Casbah fut aussi un haut lieu de la résistance durant la guerre d''indépendance algérienne.', 'monument', ST_SetSRID(ST_MakePoint(3.06, 36.7875), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/31/main_images/site_1755618618_8QpkHCFb.jpg','https://djawal.bilnov.com/storage/tourist_site/31/images/img_1756159301_xNWr6QNE.jpg','https://djawal.bilnov.com/storage/tourist_site/31/images/img_1756159301_Q3l85R9l.jpg','https://djawal.bilnov.com/storage/tourist_site/31/images/img_1756159301_sQAUEiEK.jpg','https://djawal.bilnov.com/storage/tourist_site/31/images/img_1756159301_JJZ9Bkdh.jpg','https://djawal.bilnov.com/storage/tourist_site/31/images/img_1756159301_dhqhEYHk.jpg','https://djawal.bilnov.com/storage/tourist_site_media/47/galleries/gallery_1758495045_0_oZ2n4AED.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/47/galleries/gallery_1758495045_1_IzGcFIfg.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/47/galleries/gallery_1758495045_2_hkeX4kuF.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/47/galleries/gallery_1758495045_3_DWliZkk6.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/47/galleries/gallery_1758495045_4_Ln8XzDAr.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/84/galleries/gallery_1759540118_0_KF6vNdtn.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Jardin d’Essai du Hamma', 'حديقة التجارب الحامة', 'Créé en 1832, le Jardin d''Essai du Hamma est un écrin de verdure mythique de 58 hectares, s''étirant entre la mer Méditerranée et le quartier du Hamma à Alger. Véritable musée vivant, il est célèbre pour sa collection botanique exceptionnelle de milliers d''espèces végétales, des séquoias géants aux palmiers majestueux, organisée en jardins à la française et à l''anglaise.

Lieu de recherche scientifique et de conservation, son immense valeur historique et paysagère en fait un poumon vert et un havre de paix unique. Ses allées ombragées, ses serres monumentales et son petit lac ont servi de décor à de nombreux films. Après une longue rénovation, il a rouvert en 2009, réaffirmant son statut de patrimoine naturel et culturel incontournable de l''Algérie.', 'jardin', ST_SetSRID(ST_MakePoint(3.0727392, 36.7481772), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/33/main_images/site_1755728556_2Dws3WOl.jpg','https://djawal.bilnov.com/storage/tourist_site/33/images/img_1755728606_Nk9MbkmM.jpg','https://djawal.bilnov.com/storage/tourist_site/33/images/img_1755728606_1bRsLtnk.jpg','https://djawal.bilnov.com/storage/tourist_site/33/images/img_1755728606_tXTVO0Lv.jpg','https://djawal.bilnov.com/storage/tourist_site/33/images/img_1755728606_lB24sA2T.jpg','https://djawal.bilnov.com/storage/tourist_site/33/images/img_1755728606_GoGT0JPk.jpg','https://djawal.bilnov.com/storage/tourist_site_media/41/galleries/gallery_1758419039_0_DOUugLCv.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/41/galleries/gallery_1758419039_1_gr5oEzlm.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/41/galleries/gallery_1758419039_2_zCAgHVCK.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/41/galleries/gallery_1758419039_3_Ou1LIH8R.jpeg','https://djawal.bilnov.com/storage/tourist_site_media/41/galleries/gallery_1758419039_4_chv5h2uu.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Monument aux Martyrs -مقام الشهيد', NULL, 'Symbole de la Mémoire Nationale
Surplombant Alger du haut de ses 92 mètres, le Makam Echahid est une imposante stèle commémorative érigée en 1982 pour le 20ème anniversaire de l''indépendance. Il honore la mémoire des chouhada, les martyrs de la guerre de libération nationale (1954-1962).

Cette œuvre architecturale majeure, composée de trois palmes stylisées en béton qui se rejoignent, symbolise les trois piliers de la révolution : le peuple, la lutte armée et le parti. Abritant une flamme éternelle et un musée, il domine le site du Bois des Arcades et offre un panorama saisissant sur la capitale. Symbole de sacrifice et de résilience, c''est un lieu de recueillement et de fierté pour tous les Algériens.', 'monument', ST_SetSRID(ST_MakePoint(3.0646977, 36.745932), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/34/main_images/site_1755729302_55P2lKH4.jpg','https://djawal.bilnov.com/storage/tourist_site/34/images/img_1755729448_1OGgMyNg.jpg','https://djawal.bilnov.com/storage/tourist_site/34/images/img_1755729448_AznbQ6vm.jpg','https://djawal.bilnov.com/storage/tourist_site/34/images/img_1755729448_8S57utS2.jpg','https://djawal.bilnov.com/storage/tourist_site/34/images/img_1755729448_AWLt67Gy.jpg','https://djawal.bilnov.com/storage/tourist_site/34/images/img_1755729448_NV1YrX4U.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Fort de Tamentfoust -قلعة ثامنفوست', NULL, 'Fort de Tamentfoust Alger : Sentinelle Millénaire sur la Côte

Perché sur un cap rocheux à l’est de la baie d’Alger, le fort de Tamentfoust, aussi appelé Borj El Fnar, domine la mer depuis le IXe siècle. Fondé à l’origine par les Aghlabides comme phare et place forte, il fut considérablement renforcé par les Espagnols au XVIe siècle puis par les Ottomans.

Cette forteresse historique, témoin des conquêtes successives, offre une architecture robuste et une vue panoramique exceptionnelle sur le littoral et la rade d’Alger. Aujourd’hui, le site abrite un musée naval, mêlant ainsi la mémoire des anciens corsaires à l’histoire maritime de la région. Un lieu chargé d’histoire où le vent murmure les récits des siècles passés.', 'monument', ST_SetSRID(ST_MakePoint(3.2161586, 36.715377), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/35/main_images/site_1755733156_UFt4CaAP.jpg','https://djawal.bilnov.com/storage/tourist_site/35/images/img_1756166220_ByOcJZ3F.jpg','https://djawal.bilnov.com/storage/tourist_site/35/images/img_1756166220_a4ZkiYdO.jpg','https://djawal.bilnov.com/storage/tourist_site/35/images/img_1756166220_m8uzYTJw.jpg','https://djawal.bilnov.com/storage/tourist_site/35/images/img_1756166220_2ov2m6jN.jpg','https://djawal.bilnov.com/storage/tourist_site/35/images/img_1756166220_OMEzPL5j.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Fort de Bateau cassé', 'حصن الباخرة المحطمة', 'Surplombant la mer à Bordj El Kiffan en Algérie, le Fort Ottoman est un emblème historique de la région. Construit au XVIe siècle par la régence d''Alger durant l''expansion de l''Empire ottoman, ce bastion avait pour vocation de protéger la côte des incursions étrangères et de sécuriser la navigation.

Avec ses murs épais en pierre, son architecture défensive caractéristique et sa position stratégique sur les hauteurs, il offrait un point de surveillance imprenable sur la Méditerranée.

Aujourd’hui, bien que partiellement en ruine, il demeure un témoin silencieux de l’histoire riche et mouvementée de la domination ottomane en Afrique du Nord. Le site attire les visiteurs en quête d’histoire et de points de vue exceptionnels.', 'monument', ST_SetSRID(ST_MakePoint(3.2225142, 36.7675424), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/36/main_images/site_1756167047_wV6GW3kR.jpg','https://djawal.bilnov.com/storage/tourist_site/36/images/img_1756167074_A44zrlhj.jpg','https://djawal.bilnov.com/storage/tourist_site/36/images/img_1756167074_yGnGhTGj.jpg','https://djawal.bilnov.com/storage/tourist_site/36/images/img_1756167074_yQGcBUbp.jpg','https://djawal.bilnov.com/storage/tourist_site/36/images/img_1756167074_l4TlKq5h.jpg','https://djawal.bilnov.com/storage/tourist_site/36/images/img_1756167074_6nrAoKxb.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Jardin Prague', 'حديقة براغ', 'Niché au cœur de la Casbah d''Alger, le Jardin Prague (حديقة براغ) est un havre de paix insoupçonné. Cet espace vert en terrasse, récemment réhabilité, offre une échappée bucolique et une vue imprenable sur la baie d''Alger et la Méditerranée.

Son nom singulier, hérité de l''époque socialiste et des liens internationaux de l''Algérie, ajoute une touche d''exotisme à ce lieu chargé d''histoire. Les sentiers ombragés, les parterres de fleurs et les bancs publics invitent à la flânerie et à la contemplation, loin de l''agitation de la médina.

Symbole de renouveau, il marie avec poésie le patrimoine historique de la vieille cité ottomane et la quiétude d''un jardin public, offrant aux habitants et aux visiteurs un moment de sérénité unique.', 'jardin', ST_SetSRID(ST_MakePoint(3.0564536, 36.7890322), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/37/main_images/site_1756167891_d6y6meHt.jpg','https://djawal.bilnov.com/storage/tourist_site/37/images/img_1756167923_HuLvOAJh.jpg','https://djawal.bilnov.com/storage/tourist_site/37/images/img_1756167923_C6FqU6oJ.jpg','https://djawal.bilnov.com/storage/tourist_site/37/images/img_1756167923_B3mOPNlB.jpg','https://djawal.bilnov.com/storage/tourist_site/37/images/img_1756167923_dWXJrxzk.jpg','https://djawal.bilnov.com/storage/tourist_site/37/images/img_1756167923_8YO0HQGY.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Alger' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'La forteresse de Cheikh Bouamama- قلعة الشيخ بوعمامة', NULL, 'La forteresse de Cheikh Bouamama, ex-Ksar Meghrar Tahtani (sud-est de Naâma), est un joyau historique vieux de neuf siècles. Témoin de l''occupation humaine depuis la préhistoire (art rupestre d''Oum El Braïm), elle fut le bastion du chef de la résistance Bouamama contre la colonisation française (1881-1904). Cette citadelle impressionnante, avec ses 34 tours et ses ruelles, abrite une école coranique. Dominant une oasis palmée irriguée par des sources séculaires, elle allie richesses historique et naturelle, offrant aujourd''hui un tourisme culturel avec des infrastructures modernes.', 'monument', ST_SetSRID(ST_MakePoint(0.4678607, 32.4933142), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/38/main_images/site_1756221591_v7fZYfZA.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Naâma' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'El Ghour -الغور', NULL, 'El Ghour (ou monts des Ksour) est une chaîne montagneuse emblématique de l''ouest algérien, formant le prolongement sud du massif de l''Atlas saharien. Elle s''étend principalement sur les wilayas de Naâma et d''El Bayadh.

Cette région se caractérise par ses paysages arides et majestueux, ses canyons profonds et ses anciens ksour (villages fortifiés) accrochés aux montagnes, témoins d''un riche passé historique et d''un savoir-faire architectural unique.

El Ghour est un conservatoire naturel et culturel exceptionnel. Elle abrite de nombreux sites d''art rupestre préhistorique et constitue une zone cruciale pour le développement d''un tourisme saharien axé sur la randonnée, la découverte des patrimoines et la géologie.', 'nature', ST_SetSRID(ST_MakePoint(1.2076807, 33.0088659), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/39/main_images/site_1756222227_ZZhoHqKo.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'El Bayadh' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Ksar Thala', 'قصر تالة', 'Ksar Taala n''Hammou, situé à 18 km de Timimoun, est un monument historique unique alliant patrimoine ancestral et beauté du paysage désertique. Construit au VIIIe siècle Hijri (XIVe siècle) par le sultan Abou Hammou Moussa II, il représentait l''ultime avancée du pouvoir de l''État Zianide dans le Sahara.

Décrit comme un "navire englouti dans une oasis de palmiers", ce ksar de terre fut un carrefour vital sur la route historique de l''or reliant Tombouctou à l''Europe. Installé au cœur d''une palmeraie luxuriante, il possède un système d''irrigation ingénieux appelé "sâqiya", témoignant du génie hydraulique des anciens. Aujourd''hui, le site offre un exemple remarquable d''architecture présaharienne et attire les visiteurs pour son authenticité et son cadre panoramique unique.', 'monument', ST_SetSRID(ST_MakePoint(0.1428694, 29.310637), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/40/main_images/site_1756222642_iuLOblaM.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Timimoun' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Ksar Draâ- قصر الدراع،', NULL, 'Ksar Draâ, joyau préservé près de Timimoun en Algérie, surgit des sables dans une palette de rouge ocre et d''orangé. Cette ancienne citadelle en pisé, aux formes épurées et aux lignes organiques, semble être une extension naturelle de la dune qui l''abrite. Construit sur une crête pour dominer l''immensité désertique, il offre un panorama spectaculaire sur le Grand Erg Occidental.

Plus qu''un simple vestige, Ksar Draâ incarne le génie architectural saharien, conçu pour résister aux conditions extrêmes tout en créant des espaces de vie communautaire. Son isolement et son état de conservation exceptionnel lui confèrent une aura de mystère et d''authenticité rare. Aujourd''hui en cours de restauration respectueuse, il s''impose comme une étape incontournable pour les voyageurs en quête de beauté brute et d''histoire silencieuse, offrant une immersion totale dans la magie du désert algérien', 'monument', ST_SetSRID(ST_MakePoint(0.0986374, 29.48783), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/41/main_images/site_1756223148_cLz7cut9.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Timimoun' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Plage Barbajani', 'شاطئ بربجاني', 'Niché près de Honaïne à Tlemcen, Barbadjani est une plage sauvage et préservée, accessible uniquement par bateau. Cette crique secrète de 500 mètres, dominée par une grande falaise, offre des eaux turquoise cristallines et une source d''eau douce naturelle. Autrefois repaire de corsaires, son nom vient d''un pêcheur italien du XIXe siècle, "Barba Jani".

Site prisé des locaux pour la pêche, les pique-niques et la baignade, la plage allie calme absolu et paysage méditerranéen intact. Protégée des regards, elle demeure un joyau authentique du littoral oranais, idéal pour ceux qui cherchent tranquillité et connexion avec la nature.', 'nature', ST_SetSRID(ST_MakePoint(1.723411, 35.152163), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/42/main_images/site_1756224394_tF5l0cjq.jpg','https://djawal.bilnov.com/storage/tourist_site_media/46/galleries/gallery_1758469090_0_dK5e1m1f.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'Tiaret' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Lala Khedidja', 'لالة خديجة', 'Tamgout Lalla Khedidja, située à Saharidj en Kabylie, est un site naturel d''exception dominé par le plus haut sommet de la région, le mont Lalla Khedidja (2 308 m). Ce paysage majestueux offre une biodiversité remarquable, avec ses forêts de cèdres et de chênes, ses prairies alpines et ses sources d''eau vive.

Lieu de randonnée privilégié, le site propose des sentiers escarpés menant à des panoramas spectaculaires sur les montagnes kabyles. Il abrite également le sanctuaire de Lalla Khedidja, lieu de pèlerinage annuel qui mêle spiritualité et traditions ancestrales. Entre nature préservée et patrimoine culturel immémorial, Tamgout incarne la beauté sauvage et mystique de la Kabylie.', 'nature', ST_SetSRID(ST_MakePoint(4.2054462, 36.4448348), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/43/main_images/site_1756225461_zVPDypFi.jpg','https://djawal.bilnov.com/storage/tourist_site/43/images/img_1756739722_urAnBBzb.jpg','https://djawal.bilnov.com/storage/tourist_site/43/images/img_1756739722_xlxTTaFo.jpg','https://djawal.bilnov.com/storage/tourist_site/43/images/img_1756739722_wj0rICcE.jpg','https://djawal.bilnov.com/storage/tourist_site/43/images/img_1756739722_XA22MWYI.jpg','https://djawal.bilnov.com/storage/tourist_site/43/images/img_1756739722_F2bYGaEO.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Tizi Ouzou' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Les aiguades', 'زيقواط', 'La plage des Aiguades, joyau de Béjaïa, séduit par son cadre unique où la montagne embrasse la Méditerranée. Nichée au pied du parc national de Gouraya, classé Réserve de la Biosphère, elle offre une vue splendide sur la baie et la casbah.

Sa plage de sable fin et ses eaux calmes et transparentes, protégées par une digue naturelle, sont idéales pour la baignade familiale. La promenade animée, bordée de palmiers et de cafés, invite à la flânerie.

Avec son riche passé historique (port phénicien et romain), son port de pêche coloré et sa proximité avec les sites naturels, les Aiguades allient parfaitement détente, loisirs et dépaysement, incarnant l''âme de la Kabylie maritime.', 'nature', ST_SetSRID(ST_MakePoint(5.1012772, 36.76447), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/44/main_images/site_1756238329_tutbJai7.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Cap carbon', 'رأس كربون', 'urplombant fièrement la Méditerranée à l''est de Béjaïa, le majestueux Cap Carbon est une sentinelle de pierre, site naturel d''une beauté sauvage et brute. Il forme l''un des promontoires les plus hauts d''Afrique du Nord, culminant à plus de 220 mètres au-dessus des flots.

Ses falaises vertigineuses, striées de rouge et d''ocre, plongent dans une eau d''un bleu profond où jouent souvent les dauphins. Il est couronné par un phare mythique, le plus puissant d''Afrique, dont le rayon guide les marins depuis des décennies.

Réserve intégrale du parc national de Gouraya, le cap offre des sentiers de randonnée spectaculaires avec des vues à couper le souffle sur toute la baie de Béjaïa, les montagnes de Kabylie et le large. Un lieu emblématique où la puissance de la nature inspire respect et fascination.', 'nature', ST_SetSRID(ST_MakePoint(5.0977555, 36.7733565), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/45/main_images/site_1756243192_XsKz3Vcy.jpg','https://djawal.bilnov.com/storage/tourist_site_media/99/galleries/gallery_1763111974_0_mD2Gqygp.jpg','https://djawal.bilnov.com/storage/tourist_site_media/99/galleries/gallery_1763111974_1_bVpNXms5.jpg','https://djawal.bilnov.com/storage/tourist_site_media/99/galleries/gallery_1763111974_2_OcUgrV3m.jpg','https://djawal.bilnov.com/storage/tourist_site_media/99/galleries/gallery_1763111974_3_PQw5sRcm.jpg','https://djawal.bilnov.com/storage/tourist_site_media/99/galleries/gallery_1763111974_4_p2UZIKg3.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Pic des singes', 'رأس القردة', 'Dominant la ville et la rade de Béjaïa, le Pic des Singes (ou Pic des Babouches) est une montagne iconique et le point culminant du massif de Gouraya, s''élevant à 672 mètres d''altitude.

Ce site, intégré au parc national du même nom, offre un panorama absolument exceptionnel et l''un des plus beaux points de vue d''Algérie. Son sommet, accessible via des sentiers de randonnée assez ardus mais magnifiques, récompense l''effort par une vision à 360 degrés : la Méditerranée à perte de vue, la ville de Béjaïa, le cap Carbon, et les montagnes kabyles.

Comme son nom l''indique, il est fréquenté par des bandes de macaques berbères, ajoutant une touche sauvage et vivante à l''expérience. Un incontournable pour les amateurs de nature et de paysages grandioses.', 'nature', ST_SetSRID(ST_MakePoint(5.0756843, 36.7692287), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/46/main_images/site_1756243632_UeJT7bah.jpeg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Yemma Gouraya- يما قورايا', NULL, 'Yemma Gouraya, montagne sacrée et âme de Béjaïa, est bien plus qu''un simple pic. Cette montagne culminant à 660 mètres, qui donne son nom au parc national, est un symbole spirituel et identitaire fort, veillant maternellement sur la ville et ses habitants depuis des siècles.

Son sommet abrite le marabout de Sidi Yedder, un lieu de pèlerinage et de recueillement où se mêlent croyances populaires et tradition soufie. La légende raconte qu''une sainte femme, Yemma ("mère" en kabyle) Gouraya, y repose et protège la cité.

Classée Réserve de la Biosphère par l''UNESCO, elle offre une biodiversité remarquable et des sentiers de randonnée avec des vues spectaculaires sur la baie, le cap Carbon et la Méditerranée. Yemma Gouraya incarne le parfait équilibre entre patrimoine naturel, culturel et spirituel, offrant une expérience envoûtante et unique.', 'monument', ST_SetSRID(ST_MakePoint(5.0809693, 36.7703999), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/47/main_images/site_1756243984_oi6bkaAa.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Place Guidon', 'ساحة 1 نوفمبر بجاية', 'La place Gueydon (ou place Guidon), située en contrebas de la célèbre place du 1er-Novembre, est un lieu charnière dans le centre historique de Béjaïa. Elle forme une agréable esplanade pavée, animée et ombragée, servant de trait d''union entre la ville moderne et la vieille casbah.

Bordée de cafés typiques et de bâtiments aux couleurs ocres, elle dégage une atmosphère détendue et authentique. Son nom rend hommage au gouverneur français de l''Algérie, Charles Gueydon.

Elle est surtout connue pour abriter l''imposante porte de la Casbah, dite Bab El Bounoud, un vestige majeur des remparts hammadides du XIe siècle. Cette place est un point de départ idéal pour flâner dans les ruelles pittoresques, s''imprégner de l''histoire de la ville et sentir le pouls animé de la cité portuaire.', 'monument', ST_SetSRID(ST_MakePoint(5.0849689, 36.7525122), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/48/main_images/site_1756244548_U2h4mFBu.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Cascade Kfrida', 'شلال كفريدة', 'Située non loin de Béjaïa, la cascade de Kfrida (ou chute de Kfrida) est un joyau naturel caché au cœur d’une verdure luxuriante, dans la commune de Timezrit. Accessible par un sentier, ce site offre un spectacle rafraîchissant et paisible, loin de l’agitation de la ville.

L’eau dévale avec force une paroi rocheuse d’une dizaine de mètres de hauteur, pour se jeter dans un bassin naturel aux eaux claires et fraîches, invitant à une baignade revigorante. L’ambiance y est magique, entourée d’une végétation dense et du chant des oiseaux.

Idéale pour une excursion en famille ou entre amis, la cascade de Kfrida est une parfaite escapade pour se ressourcer, pique-niquer au son de l’eau et profiter d’un moment de fraîcheur en communion avec une nature préservée. Un must pour les amoureux de paysages authentiques.', 'nature', ST_SetSRID(ST_MakePoint(5.2887942, 36.5702822), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/49/main_images/site_1756244881_a5DRpyBE.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Cascade Ait Felkay', 'شلال أيت فلكاي', 'Niché au cœur de la commune de Darguina, la cascade d''Aït Felkai est un joyau naturel préservé de la Kabylie. Encore sauvage et peu fréquentée, elle offre un cadre enchanteur où l’eau vive dévale plusieurs gradins rocheux entourés d’une forêt dense de chênes.

Le bassin naturel, aux eaux cristallines et fraîches, invite à une baignade revigorante. L’ambiance y est paisible, bercée par le bruit des chutes d’eau et le chant des oiseaux.

Accessible par un sentier de randonnée, cet écrin de verdure est parfait pour une escapade hors des sentiers battus, un pique-nique en nature ou un moment de détente absolue au calme. Un havre de paix authentique pour ceux qui cherchent à s’immerger dans la beauté brute de la région.', 'nature', ST_SetSRID(ST_MakePoint(5.3747043, 36.5266525), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/50/main_images/site_1756245386_NXY1eTC2.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Sétif' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Ighzer uftis', 'إغزر أوفتيس', 'Niché sur le territoire de la commune de Darguina, Ighzer Ouftis est un canyon sauvage et spectaculaire, sculpté par l’oued dans la roche. Ce site naturel préservé offre un paysage minéral impressionnant, où l’eau turquoise serpente entre des parois verticales et des formations géologiques uniques.

Accessible par un sentier, le site est un paradis pour les randonneurs et les amateurs de canyoning. Il propose des bassins naturels aux eaux cristallines, idéaux pour une baignade rafraîchissante, et des paysages à couper le souffle.

Encadré par une végétation méditerranéenne, Ighzer Ouftis allie aventure, beauté brute et tranquillité, loin de l’affluence. Un joyau secret de la Kabylie, parfait pour une escapade immersive en pleine nature.', 'nature', ST_SetSRID(ST_MakePoint(5.3225973, 36.5415061), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/51/main_images/site_1756245834_Bfq8a1Dh.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Béjaïa' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Chutes de Mimouna- شلال لالة ميمونة', NULL, 'Les chutes de Mimouna, à Hizer (Bouira), sont un trésor caché qui séduit tous ceux qui les découvrent. Imagine un coin de paradis où l’eau s’élance des rochers pour former des cascades cristallines, entourées d’une nature sauvage et verdoyante. Ici, chaque pas réveille un sentiment de liberté et de fraîcheur. L’endroit est parfait pour une pause loin du bruit, un pique-nique en famille ou une escapade entre amis. Facile d’accès après une petite marche, il offre un décor digne d’une carte postale et un air pur qui ressource l’esprit. Les chutes de Mimouna ne sont pas seulement une sortie, mais une expérience à vivre, un moment qui reste gravé et qui donne envie de revenir.', 'nature', ST_SetSRID(ST_MakePoint(4.0723946, 36.4360201), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/52/main_images/site_1756246600_OcnpO73p.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Bouira' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Le Ksar de Tamentit- قصر تامنطيط', NULL, 'Le Ksar de Tamentit, situé à quelques kilomètres d’Adrar au cœur du Gourara, est l’un des plus anciens joyaux architecturaux du Sud algérien. Construit en pisé, il témoigne d’un savoir-faire ancestral adapté au climat saharien. Ses ruelles étroites, ses murs ocre et ses passages voûtés plongent le visiteur dans une atmosphère authentique, reflet de siècles d’histoire et de traditions. Ce ksar, qui servait à la fois d’habitat, de refuge et de centre d’échanges, illustre l’organisation sociale et la solidarité des communautés oasiennes. Entouré de palmeraies verdoyantes et alimenté par les foggaras, il offre un contraste saisissant entre désert aride et vie florissante. Véritable mémoire vivante, Tamentit conserve encore ses valeurs culturelles, religieuses et artisanales, faisant de lui une destination incontournable pour les passionnés d’histoire, de patrimoine et de découvertes sahariennes.', 'monument', ST_SetSRID(ST_MakePoint(1.4142092, 27.7656427), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/53/main_images/site_1756246867_686CDYvG.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'In Salah' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Plateau Lalla Setti', 'لالة ستي', 'Le plateau de Lalla Setti, perché à plus de 1000 mètres d’altitude au-dessus de Tlemcen, est l’un des sites emblématiques de la ville. Offrant une vue panoramique imprenable sur la cité et ses environs, il constitue un lieu de promenade et de détente très apprécié. Accessible par route ou par téléphérique, Lalla Setti allie nature et modernité : son immense esplanade, son lac artificiel, ses jardins aménagés et ses espaces de loisirs en font une destination familiale par excellence. Le site est également empreint de spiritualité, portant le nom d’une sainte vénérée dans la région. Entre fraîcheur, paysages verdoyants et horizon saharien lointain, Lalla Setti séduit autant les habitants que les visiteurs. Véritable balcon suspendu sur Tlemcen, il incarne l’harmonie entre patrimoine naturel et attractivité touristique, invitant à la découverte et à la contemplation.', 'monument', ST_SetSRID(ST_MakePoint(1.3167996, 34.8649747), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/54/main_images/site_1756247338_GBiXUP2h.jpg','https://djawal.bilnov.com/storage/tourist_site_media/62/galleries/gallery_1758750508_0_Or0iMCHM.jpg','https://djawal.bilnov.com/storage/tourist_site_media/62/galleries/gallery_1758750508_1_l5UjUZGw.jpg','https://djawal.bilnov.com/storage/tourist_site_media/62/galleries/gallery_1758750508_2_BUy8BUPr.jpg','https://djawal.bilnov.com/storage/tourist_site_media/62/galleries/gallery_1758750508_3_RA0EudJk.jpg','https://djawal.bilnov.com/storage/tourist_site_media/62/galleries/gallery_1758750508_4_8W9Php9d.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Tiaret' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'La forêt de Bissa', 'غابة بيسة', 'La forêt de Bissa, située sur le mont Bouamoud, est l’un des joyaux naturels de la wilaya de Chlef. Elle se trouve à 10 km au nord de la daïra de Zeboudja et à 30 km au sud du littoral de Beni Haoua, à une altitude de 1 125 m. S’étendant sur une superficie de 1 500 hectares, elle se distingue par la richesse de sa végétation et la densité de ses arbres qui offrent un paysage harmonieux de fraîcheur et de sérénité. C’est un lieu privilégié pour les amateurs de randonnée, de camping et de découvertes en pleine nature. Grâce à sa position, elle combine la beauté des reliefs montagneux et la proximité de la mer, faisant d’elle un espace idéal de détente et d’évasion. Véritable poumon vert de la région, la forêt de Bissa demeure un patrimoine naturel à préserver et à valoriser.', 'nature', ST_SetSRID(ST_MakePoint(1.4576116, 36.4540585), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/55/main_images/site_1756729039_X2zmKwrM.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Le fort colonial', 'القلعة', 'Le fort colonial de Sidi Akacha, situé dans la wilaya de Chlef, est un témoin marquant de l’époque coloniale en Algérie. Construit par les autorités françaises au XIXᵉ siècle, il servait de poste militaire stratégique pour contrôler la région et surveiller les voies de communication reliant l’intérieur aux zones côtières. De par son emplacement dominant, il offrait une vue dégagée sur les plaines et les reliefs environnants, renforçant son rôle défensif. Aujourd’hui, bien que partiellement en ruine, le fort garde les traces de son architecture robuste faite de pierres et de murs épais. Il constitue un repère historique qui suscite l’intérêt des passionnés de patrimoine et d’histoire locale. Entre mémoire douloureuse et richesse culturelle, le site mérite d’être protégé et valorisé comme témoignage du passé et support de réflexion sur l’histoire partagée.', 'monument', ST_SetSRID(ST_MakePoint(1.3976848, 36.4604618), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/56/main_images/site_1756729491_wPM2kjR2.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Le palais romain de Kawa -قصر كاوة الروماني وحمام منتيلة', NULL, 'Le palais romain de Kawa et les thermes de Mentila se dressent au cœur d’une nature enchanteresse, témoins vivants de la grandeur de la civilisation romaine en Algérie. Le palais se distingue par son architecture solide et ses colonnes majestueuses qui reflètent l’art classique et la précision du design, en faisant une œuvre rare ayant résisté au temps. Quant aux thermes de Mentila, ils racontent l’histoire de l’attention romaine portée au bien-être et à l’hygiène, servant autrefois de lieu de rencontre, de détente et de repos. Ces monuments conjuguent histoire et spiritualité, révélant au visiteur des détails de la vie quotidienne de l’époque, et offrant un véritable voyage à travers le temps où se mêlent authenticité du passé et charme des paysages environnants.', 'monument', ST_SetSRID(ST_MakePoint(1.1976407, 35.9189659), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/57/main_images/site_1756730679_1YwhamdI.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Barrage de ouad fodda bni bouatab -شلالات و سد بني بوعتاب', NULL, 'Les cascades et le barrage de Béni Bouattab, dans la wilaya de Chlef, offrent un paysage naturel splendide où se mêlent l’eau douce et la beauté des reliefs environnants. Les cascades s’écoulent dans un décor enchanteur, créant une atmosphère de sérénité qui attire les visiteurs en quête de détente et de contact avec la nature. Le barrage, quant à lui, constitue l’un des ouvrages hydrauliques majeurs de la région : il assure l’approvisionnement en eau potable et en irrigation, tout en jouant un rôle important dans la régulation des crues. Son environnement, riche en diversité végétale et animale, en fait un espace privilégié pour les promenades et les sorties familiales. Par l’harmonie entre ses chutes d’eau et son plan d’eau, le site séduit aussi bien les passionnés de photographie que les amateurs d’aventure, tout en demeurant une ressource écologique et économique précieuse à préserver.', 'nature', ST_SetSRID(ST_MakePoint(1.6054498, 36.0432626), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/58/main_images/site_1756731924_yZfgPBv2.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'La plage de Sidi Merouane- شاطىء سيدي مروان', NULL, 'La plage de Sidi Merouane, à Tenès (wilaya de Chlef), se distingue par son littoral rocheux qui lui confère un charme sauvage et authentique. Contrairement aux plages sablonneuses, elle offre des criques naturelles et des formations rocheuses spectaculaires qui plongent directement dans une mer aux eaux limpides et turquoise. C’est un lieu idéal pour les amateurs de plongée, de pêche et de découverte sous-marine, grâce à la richesse de sa faune et de sa flore marines. Le paysage environnant, dominé par les reliefs et la végétation méditerranéenne, renforce la beauté singulière du site. Appréciée pour son calme et son atmosphère préservée, la plage de Sidi Merouane est une destination privilégiée pour ceux qui recherchent l’évasion, loin des foules, et qui souhaitent savourer la nature dans toute sa pureté.', 'nature', ST_SetSRID(ST_MakePoint(1.3355031, 36.5457615), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/59/main_images/site_1756732333_KoUId6Ay.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Chutes de Taggua- شلالات التراغنية', NULL, 'À Beni Haoua, dans la wilaya de Chlef, les chutes de Taggua, ou "شلالات التراغنية", sont une destination naturelle prisée. Situées sur l''oued éponyme dans l''Ouarsenis, elles forment une série de cascades et de bassins (guelta) au cœur d''un paysage verdoyant.

La chute principale, d''une hauteur notable, offre un spectacle rafraîchissant, especially en période de fonte des neiges ou après les pluies. La végétation luxuriante alentour contraste avec les collines environnantes, créant un cadre idyllique pour les visiteurs.

Proches de la côte méditerranéenne, ces chutes sont facilement accessibles et très fréquentées l''été. Cette popularité entraîne malheureusement des problèmes de pollution, malgré les efforts de préservation locaux.', 'nature', ST_SetSRID(ST_MakePoint(1.3975178, 36.5333325), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/60/main_images/site_1756733439_SUJduQoL.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Phare du Cap Tenes', 'منارة سيدي مروان', 'Le phare du Cap Ténès, également connu sous le nom de منارة سيدي مروان (Menâra Sidi Merouane), est un site historique et emblématique situé sur la côte méditerranéenne de l’Algérie, dans la wilaya de Chlef. Construit en 1861 sous domination française, il guide les navires depuis le cap de Ténès, un promontoire rocheux stratégique.

D’une hauteur de 28,5 mètres, il culmine à 108 mètres au-dessus du niveau de la mer. Sa portée lumineuse est d’environ 45 kilomètres. Le phare est bâti en pierre de taille et présente une architecture typique du XIXe siècle, avec une tour cylindrique et des encadrements en maçonnerie soignée.

Aujourd’hui, il reste en activité sous la gestion de l’Office National de Signalisation Maritime (ONSM) algérien. Le site offre également un panorama exceptionnel sur la Méditerranée et attire visiteurs et photographes.', 'monument', ST_SetSRID(ST_MakePoint(1.3356512, 36.5496605), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/61/main_images/site_1756733719_ag0uIoYy.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;
INSERT INTO sites (destination_id, name, name_ar, description, category, coordinates, images, validated_at)
SELECT id, 'Plage de Beni Haoua', 'بني حواء', 'Située à 70 km au nord de Chlef, la plage de Beni Haoua est une destination balnéaire majeure de la région. Elle combine étendues de sable fin et criques rocheuses, bordée par les contreforts de l''Atlas tellien. Très fréquentée l''été, elle allie activités balnéaires et pêche artisanale. Malgré sa beauté, elle fait face à des défis environnementaux liés à la surfréquentation.

La plage de Beni Haoua constitue un joyau du littoral de Chlef : un espace naturel authentique, d’accès aisé, avec des équipements sécuritaires, des eaux invitantes et un environnement forestier apaisant. Elle allie intimité, beauté et confort. Les projets touristiques en cours promettent une montée en gamme tout en respectant le caractère unique du lieu.', 'nature', ST_SetSRID(ST_MakePoint(1.5722222, 36.5347222), 4326)::geography, ARRAY['https://djawal.bilnov.com/storage/tourist_site/62/main_images/site_1756734493_StguliSp.jpg']::text[], NOW()
FROM destinations WHERE wilaya = 'Chlef' LIMIT 1;

COMMIT;

-- Stats : 20 hôtels, 40 sites, 17 wilayas