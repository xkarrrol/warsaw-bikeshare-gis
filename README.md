# Analiza dostępności stacji rowerów miejskich w Warszawie

Projekt prezentuje analizę przestrzenną infrastruktury rowerowej na terenie Warszawy z wykorzystaniem relacyjnej bazy danych i zapytań przestrzennych. Głównym celem było sprawdzenie, jak stacje rozkładają się w poszczególnych dzielnicach i gdzie występuje ich największe zagęszczenie w przeliczeniu na powierzchnię.

<img width="3507" height="2480" alt="project-03-spatial" src="https://github.com/user-attachments/assets/3203aa97-0e21-4531-a431-91a4b2645f84" />

---

## O projekcie

Częstym problemem przy planowaniu mikromobilności jest nierównomierne rozmieszczenie stacji – skupianie ich wyłącznie w ścisłym centrum kosztem dzielnic ościennych. Zamiast ręcznego przeliczania danych w programie graficznym, cały proces czyszczenia, łączenia warstw i obliczeń zrealizowałem bezpośrednio po stronie silnika bazy danych.

Wynik analizy został przygotowany w formie widoku bazodanowego, który można bezpośrednio podpiąć pod narzędzia analityczne lub oprogramowanie mapowe.

---

## Wykorzystane narzędzia i technologie

* **Baza danych:** PostgreSQL z rozszerzeniem przestrzennym PostGIS
* **Zarządzanie bazą:** DBeaver
* **Wizualizacja i kompozycja:** QGIS
* **Format zapisu danych:** GeoPackage (uniwersalny kontener na dane wektorowe i konfigurację projektu)

---

## Źródła danych

1. **Granice dzielnic Warszawy:** dane wektorowe pozyskane z bazy OpenStreetMap (poziom administracyjny 9).
2. **Stacje rowerowe:** punkty infrastruktury miejskiej z OpenStreetMap (kategoria wypożyczalni rowerów).

Oba zbiory zostały przetransformowane do państwowego układu współrzędnych **PUWG 1992 (EPSG:2180)**, co pozwala na poprawne obliczanie powierzchni w metrach i kilometrach kwadratowych.

---

## Przebieg prac

1. **Struktura bazy danych:**
   * Zaimportowanie warstw wektorowych do schematu publicznego.
   * Utworzenie indeksów przestrzennych na kolumnach geometrii w celu przyspieszenia zapytań.

2. **Przetwarzanie przestrzenne:**
   * Połączenie przestrzenne poligonów dzielnic z punktami stacji za pomocą funkcji sprawdzającej zawieranie obiektów (`ST_Contains`).
   * Zastosowanie złączenia lewostronnego, aby uwzględnić również dzielnice, w których stacji nie ma wcale.
   * Odsianie błędów topologicznych i mikro-poligonów powstałych przy eksporcie granic administracyjnych.
   * Przeliczenie powierzchni dzielnic na kilometry kwadratowe oraz wyznaczenie wskaźnika gęstości (liczba stacji przypadająca na jeden kilometr kwadratowy).

3. **Wdrożenie i wizualizacja:**
   * Zapisanie logiki analitycznej jako stałego widoku w bazie.
   * Przygotowanie kartogramu w QGIS z podziałem na przedziały gęstości oraz wygenerowanie estetycznej kompozycji mapowej z zachowaniem zasad kartograficznych.

---

## Główne zapytanie SQL

```sql
-- 1. Indeksy przestrzenne
CREATE INDEX IF NOT EXISTS idx_dzielnice_geom ON warszawa_dzielnice USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_stacje_geom ON stacje_rowerowe USING GIST (geom);

-- 2. Widok z obliczeniami
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
```

---

## Wyniki analizy

Największe nasycenie stacjami występuje w dzielnicy Śródmieście, gdzie wskaźnik przekracza 1 stację na kilometr kwadratowy. Wraz z oddalaniem się od centrum gęstość wyraźnie spada, osiągając najniższe wartości w zewnętrznych dzielnicach peryferyjnych.

---

## Zawartość repozytorium

* `analysis.sql` – skrypt z zapytaniami tworzącymi indeksy oraz widok analityczny.
* `warszawa_bikeshare.gpkg` – plik z kompletnymi danymi wektorowymi oraz zapisanym projektem QGIS.
* `warszawa_dzielnice.gpkg` – plik z dzielnicami Warszawy
* `rowery_amenity.gpkg` – plik ze stacjami rowerowymi
* `project-03-spatial.jpg` – wyeksportowana kompozycja mapowa w wysokiej rozdzielczości.
