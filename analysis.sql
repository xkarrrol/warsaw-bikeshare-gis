CREATE INDEX IF NOT EXISTS idx_dzielnice_geom ON warszawa_dzielnice USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_stacje_geom ON stacje_rowerowe USING GIST (geom);

-- 2. Widok analityczny: zagregowana gęstość stacji na dzielnicę
CREATE OR REPLACE VIEW v_analiza_dzielnice AS
SELECT 
    wd.id,
    wd.name AS dzielnica,
    COUNT(sr.id) AS liczba_stacji,
    ROUND((ST_Area(wd.geom) / 1000000.0)::numeric, 2) AS pow_km2,
    ROUND((COUNT(sr.id) / (ST_Area(wd.geom) / 1000000.0))::numeric, 2) AS gestosc_na_km2,
    wd.geom
FROM warszawa_dzielnice wd
LEFT JOIN stacje_rowerowe sr 
       ON ST_Contains(wd.geom, sr.geom)
WHERE ST_Area(wd.geom) > 100000
GROUP BY wd.id, wd.name, wd.geom
ORDER BY liczba_stacji DESC;
