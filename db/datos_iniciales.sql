-- Insertar Usuario Campesino de Prueba
INSERT INTO usuarios (nombre, email, password_hash, rol)
VALUES (
    'Don José', 
    'donjose@krop.co', 
    '$2a$10$abcdefghijklmnopqrstuvwxyz123456', -- Hash simulado
    'CAMPESINO'
);

-- Insertar Parcela de Prueba (Cultivo de Papa cerca a Bogotá/Sabana)
INSERT INTO parcelas (usuario_id, nombre_parcela, tipo_cultivo, geometria)
VALUES (
    1, 
    'Lote El Paraíso - Papa Pastusa', 
    'Papa', 
    ST_GeomFromText('POLYGON((-74.1234 4.6543, -74.1200 4.6543, -74.1200 4.6500, -74.1234 4.6500, -74.1234 4.6543))', 4326)
);

-- Insertar Registro Semilla en el Catálogo de Tiles
INSERT INTO catalogo_tiles_procesados (tile_id, scene_id, proveedor, fecha_captura, estado, s3_base_prefix)
VALUES (
    '18NXL', 
    'S2A_MSIL2A_20260828T153000_18NXL', 
    'SENTINEL_2', 
    '2026-08-28 15:30:00', 
    'COMPLETADO', 
    's3://sentinel-cogs/Sentinel-2/18/N/XL/2026/8/28/S2A_18NXL_20260828/'
);

-- Insertar Métrica Semilla para la Parcela
INSERT INTO metricas_parcela (parcela_id, fecha, indices_opticos, datos_radar, datos_rover, s3_recorte_path)
VALUES (
    1, 
    '2026-08-28 15:30:00', 
    '{"ndvi": 0.78, "ndre": 0.65, "ndwi": -0.10, "alerta_estres": false}', 
    '{"humedad_suelo_porcentaje": 38.5, "rugosidad": 0.14}', 
    '{"conteo_plantas": 145, "plaga_detectada": false, "rover_id": "ROVER_PAPA_01"}', 
    's3://krop-storage/parcelas/1/recortes/20260828.png'
);