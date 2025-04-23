-- Função para buscar clínicas próximas usando PostGIS
CREATE OR REPLACE FUNCTION nearby_clinics(lat float, lng float, radius_km float)
RETURNS SETOF clinics
LANGUAGE sql
STABLE
AS $$
  SELECT c.*
  FROM clinics c
  WHERE ST_DWithin(
    c.geo_location,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    radius_km * 1000  -- Converter para metros
  )
  ORDER BY ST_Distance(
    c.geo_location,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  );
$$; 