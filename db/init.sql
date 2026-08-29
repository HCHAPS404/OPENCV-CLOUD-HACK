-- =============================================================================
-- 1. EXTENSIONES DE POSTGRESQL
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;      -- Habilita tipos de datos espaciales (GEOMETRY, POLYGON, POINT)
CREATE EXTENSION IF NOT EXISTS btree_gin;   -- Optimiza índices combinados con JSONB

-- =============================================================================
-- 2. TABLA DE USUARIOS Y ROLES (Para Core-API / Java Spring Boot)
-- =============================================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) DEFAULT 'CAMPESINO', -- CAMPESINO, AGRONOMO, ADMIN
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. TABLA DE PARCELAS (Delimitación espacial con PostGIS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS parcelas (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre_parcela VARCHAR(100) NOT NULL,
    tipo_cultivo VARCHAR(50) NOT NULL,
    geometria GEOMETRY(Polygon, 4326) NOT NULL, -- Coordenadas GPS WGS84
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice Espacial GIST para acelerar consultas ST_Intersects
CREATE INDEX IF NOT EXISTS idx_parcelas_geometria ON parcelas USING GIST (geometria);

-- =============================================================================
-- 4. CATÁLOGO DE CONTROL DE TILES SATELITALES (Para Scheduler y Workers)
-- =============================================================================
CREATE TABLE IF NOT EXISTS catalogo_tiles_procesados (
    id SERIAL PRIMARY KEY,
    tile_id VARCHAR(20) NOT NULL,            -- Ej: '18NXL' (MGRS Cundinamarca)
    scene_id VARCHAR(100) UNIQUE NOT NULL,   -- ID global de la captura
    proveedor VARCHAR(50) NOT NULL,          -- SENTINEL_2, LANDSAT_9, SENTINEL_1
    fecha_captura TIMESTAMP NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',  -- PENDIENTE, PROCESANDO, COMPLETADO, ERROR
    s3_base_prefix VARCHAR(255) NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. TABLA DE MÉTRICAS CONSOLIDADAS (Gemelo Digital en JSONB)
-- =============================================================================
CREATE TABLE IF NOT EXISTS metricas_parcela (
    id SERIAL PRIMARY KEY,
    parcela_id INT REFERENCES parcelas(id) ON DELETE CASCADE,
    fecha TIMESTAMP NOT NULL,
    indices_opticos JSONB, -- Almacena NDVI, NDRE, NDWI
    datos_radar JSONB,     -- Almacena rugosidad y humedad por radar
    datos_rover JSONB,     -- Almacena conteo de frutos, plagas y fotos
    datos_clima JSONB,     -- Almacena precipitaciones y temperaturas
    s3_recorte_path VARCHAR(255),
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices GIN para acelerar búsquedas avanzadas dentro de las columnas JSONB
CREATE INDEX IF NOT EXISTS idx_metricas_opticas ON metricas_parcela USING GIN (indices_opticos);
CREATE INDEX IF NOT EXISTS idx_metricas_rover ON metricas_parcela USING GIN (datos_rover);