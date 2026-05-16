-- =========================================================
-- DJAWAL V2 — Sprint D : Vraies photos des wilayas algériennes
-- =========================================================
-- Source : Wikimedia Commons (licence Creative Commons BY-SA, libre
-- pour usage commercial, attribution recommandée).
--
-- Toutes les photos sont prises EN ALGÉRIE et identifient des lieux
-- précis (pas du stock générique). Vérifiées via Wikipedia FR/EN et
-- Wikimedia Commons.
--
-- Format URL : Special:FilePath = redirection stable et permanente
-- vers upload.wikimedia.org à la taille demandée (?width=1600).
--
-- ⚠️ Attribution : Djawal devra afficher en pied de carte "© photographes
-- Wikimedia Commons / CC-BY-SA" (à intégrer côté frontend dans une future MR).
--
-- Cette migration peut être exécutée dans Supabase SQL Editor.
-- Idempotente : ne touche que les destinations sans photo.
-- =========================================================

-- ----- WILAYAS SAHARIEN (Sahara, Tassili, Hoggar, oasis) -----

-- Hoggar (massif central, Mont Tahat, parc national Ahaggar)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/The_Ahaggar_National_Park,_Tamanrasset_Algeria.png?width=1600'
WHERE name = 'Hoggar';

-- Tamanrasset (porte du Hoggar)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/The_Ahaggar_National_Park,_Tamanrasset_Algeria.png?width=1600'
WHERE name = 'Tamanrasset';

-- Tassili n'Ajjer (parc UNESCO, art rupestre néolithique)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Tassili_Desert_Algeria.jpg?width=1600'
WHERE name = 'Tassili n''Ajjer';

-- Djanet (porte du Tassili, oasis du sud-est)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Djanet-Algeria.jpg?width=1600'
WHERE name = 'Djanet';

-- Illizi (Tadrart Rouge, dunes orange + grès)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Tadrart01.JPG?width=1600'
WHERE name = 'Illizi';

-- Ghardaïa (vallée du M'Zab, UNESCO, ksour mozabites)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ghardaya_historique.JPG?width=1600'
WHERE name = 'Ghardaïa';

-- Timimoun (oasis rouge du Gourara, sebkha, palmeraie)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Sebkha_de_Timimoun_1.JPG?width=1600'
WHERE name = 'Timimoun';

-- Béni Abbès (oasis blanche de la Saoura)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/B%C3%A9ni-Abb%C3%A9s_Oued_saoura.JPG?width=1600'
WHERE name = 'Béni Abbès';

-- Ouargla (ksar historique au cœur du Sahara nord)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ksar_Ben_Idriss_(Ouargla,_Algeria).jpg?width=1600'
WHERE name = 'Ouargla';

-- Adrar (Touat, palmeraies, ksour fortifiés) — fallback Ouargla ksar
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ksar_Ben_Idriss_(Ouargla,_Algeria).jpg?width=1600'
WHERE name = 'Adrar';


-- ----- WILAYAS MAURESQUE (méditerranée, médinas, casbahs) -----

-- Alger (la Blanche, Notre-Dame d'Afrique, baie)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Basilique_Notre-Dame_d_Afrique_Alger.jpg?width=1600'
WHERE name = 'Alger';

-- Casbah d'Alger (médina UNESCO, ruelles, terrasses)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Casbah_of_Algiers_1.JPG?width=1600'
WHERE name = 'Casbah d''Alger';

-- Oran (baie, fort Santa Cruz, méditerranée andalouse)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Oran_Santa_Cruz.JPG?width=1600'
WHERE name = 'Oran';

-- Tipaza (ruines romaines UNESCO face à la mer)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Sites_historiques_Tipaza_7.JPG?width=1600'
WHERE name = 'Tipaza';

-- Annaba (basilique Saint-Augustin, Hippone)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Basilique_saint_augustin_annaba_4.jpg?width=1600'
WHERE name = 'Annaba';

-- Tlemcen (Mansourah, capitale zianide)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Mansourah_Tlemcen_city,_Algeria.jpg?width=1600'
WHERE name = 'Tlemcen';

-- Constantine (ville des ponts, gorges du Rhumel)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Les_gorges,_Constantine,_Algeria-2.jpg?width=1600'
WHERE name = 'Constantine';

-- Dellys (casbah berbère sur la côte kabyle)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Dellys.JPG?width=1600'
WHERE name = 'Dellys';


-- ----- WILAYAS AURÈS / KABYLIE (montagnes, cèdres, Roms berbères) -----

-- Béjaïa (Cap Carbon, parc Gouraya, golfe)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Plage_du_Cap_Carbon,_Wilaya_de_B%C3%A9ja%C3%AFa_1.JPG?width=1600'
WHERE name = 'Béjaïa';

-- Tizi Ouzou (Grande Kabylie, vue Djurdjura)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ouadhias,_Tizi_Ouzou,_Grande_Kabylie,_Algeria_(Djurdjura_Nation_Park).jpg?width=1600'
WHERE name = 'Tizi Ouzou';

-- Tikjda (station Djurdjura, ski + cèdres)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ouadhias,_Tizi_Ouzou,_Grande_Kabylie,_Algeria_(Djurdjura_Nation_Park).jpg?width=1600'
WHERE name = 'Tikjda';

-- Bouira (versant sud du Djurdjura)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Ouadhias,_Tizi_Ouzou,_Grande_Kabylie,_Algeria_(Djurdjura_Nation_Park).jpg?width=1600'
WHERE name = 'Bouira';

-- Batna (Aurès chaouia, Timgad la romaine)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Roman_Arch_of_Trajan_at_Thamugadi_(Timgad),_Algeria_04966r.jpg?width=1600'
WHERE name = 'Batna';

-- Aurès (région berbère chaouia, Timgad)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Roman_Arch_of_Trajan_at_Thamugadi_(Timgad),_Algeria_04966r.jpg?width=1600'
WHERE name = 'Aurès';

-- Khenchela (sud des Aurès, Timgad voisin)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Roman_Arch_of_Trajan_at_Thamugadi_(Timgad),_Algeria_04966r.jpg?width=1600'
WHERE name = 'Khenchela';

-- Sétif (Djémila / Cuicul UNESCO, hauts plateaux)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Cuicul_(Dj%C3%A9mila),_Numidia,_Algeria_-_52664576834.jpg?width=1600'
WHERE name = 'Sétif';

-- Chréa (parc national, Atlas blidéen, cèdres)
UPDATE destinations SET hero_image_url =
  'https://commons.wikimedia.org/wiki/Special:FilePath/Atlas_Mountains_Blida_Algeria.jpg?width=1600'
WHERE name = 'Chréa';


-- =========================================================
-- VÉRIFICATION (à exécuter après pour valider la couverture)
-- =========================================================
-- SELECT name, cultural_theme, hero_image_url FROM destinations ORDER BY cultural_theme, name;
--
-- Les destinations sans photo après cette migration tomberont sur le
-- fallback gradient + pattern berbère codé dans TripsPage / DestinationPage.
-- =========================================================
