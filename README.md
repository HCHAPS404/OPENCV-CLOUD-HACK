# OPENCV-CLOUD-HACK
Arquitectura de flujo de procesamiento por pasos

Requerimos extenciones en postgres: 

```sql
-- para geograficos y geometrias
CREATE extension if not exists postgis;
-- Esto es para JSONB avanzado
CREATE extension if NOT EXISTS btree_gin;
```

## Requerimos de un modelo basico de base de datos

Este no representa el final, solo es una pequeña idea: 

```sql
-- Tabla 1: Delimitaciones geograficas de parcelas de campesinos
CREATE TABLE parcelas (
    id SERIAL PRIMARY KEY,
    nombre_campesino VARCHAR(100) NOT NULL,
    tipo_cultivo VARCHAR(50) NOT NULL,
    geometria GEOMETRY(Polygon, 4326) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ejemplo de insercion de datos para una parcela en Cundinamarca
INSERT INTO parcelas (nombre_campesino, tipo_cultivo, geometria) 
VALUES (
    'Don Jose', 
    'Papa', 
    ST_GeomFromText('POLYGON((-74.1234 4.6543, -74.1200 4.6543, -74.1200 4.6500, -74.1234 4.6500, -74.1234 4.6543))', 4326)
);

-- Tabla 2: Catálogo de control para rastrear tiles satelitales procesados
CREATE TABLE catalogo_tiles_procesados (
    id SERIAL PRIMARY KEY,
    tile_id VARCHAR(20) NOT NULL,
    scene_id VARCHAR(100) UNIQUE NOT NULL,
    fecha_captura TIMESTAMP NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, PROCESANDO, COMPLETADO, ERROR
    s3_base_prefix VARCHAR(255) NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ejemplo de datos en catálogo
INSERT INTO catalogo_tiles_procesados (tile_id, scene_id, fecha_captura, estado, s3_base_prefix)
VALUES (
    '18NXL', 
    'S2A_MSIL2A_20260828T153000_18NXL', 
    '2026-08-28 15:30:00', 
    'COMPLETADO', 
    's3://sentinel-cogs/Sentinel-2/18/N/XL/2026/8/28/S2A_18NXL_20260828/' --- Este es den sentinel, publico
);

-- Tabla 3: Metricas consolidadas calculadas por los workers (Gemelo Digital)
CREATE TABLE metricas_parcela (
    id SERIAL PRIMARY KEY,
    parcela_id INT REFERENCES parcelas(id),
    fecha TIMESTAMP NOT NULL,
    indices_opticos JSONB, -- Almacena NDVI, NDRE, NDWI, EVI
    datos_radar JSONB,     -- Almacena humedad y rugosidad
    datos_rover JSONB,     -- Almacena conteo de brotes, plagas
    s3_recorte_path VARCHAR(255),
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ejemplo de estructura de datos consolidados en JSONB
INSERT INTO metricas_parcela (parcela_id, fecha, indices_opticos, datos_radar, datos_rover, s3_recorte_path)
VALUES (
    1, 
    '2026-08-28 15:30:00', 
    '{"ndvi": 0.75, "ndre": 0.62, "ndwi": -0.15, "alerta_estres": false}', 
    '{"humedad_suelo_porcentaje": 42.5, "rugosidad": 0.12}', 
    '{"conteo_plantas": 120, "plaga_detectada": false, "rover_id": "ROVER_01"}', 
    's3://krop-storage/parcelas/1/recortes/20260828.png' -- Este es mio, S3 mio, privado
);
```

## El flujo completo

El flujo paso a paso es: 
### Paso 1 : Se registra la parcela del campsino

1. El usuario dibuja su terreno en la APP o lo puede hacer el dipositivo, o uno mismo desde el panel de administrador
2. La app envía una solicitud HTTP POST a `core-api` que es springboot
3. `core-api` inserta el polígono en la tabla de parcelas en PostGIS

### Paso 2:  Deteccion de nuevas escenas satelitales (Scheduler)
♠
1. UN cron (AWS EventrBridge o `scheduler-service` en python) se ejecuta a un intervalo programado
2. Consulta la API pública de satélite (STAC API) filtrando por caudrículas MGRS de interes (como por ejemplo 18NXL)
3. Compara el schende_id obtenido contra la base de datos catalogo_tiles_procesados
4. Si el scene_id no existe en la base de datos, inserta el registro con estado `PENDING | PENDIENTE` y publica el evento en la cola de RabbitMQ

### Paso 3: Procesamiento Masivo e Interseccion (Worker Óptico / Radar)
1. El worker correspondiente (optical-worker o radar-worker) consume el mensaje de RabbitMQ.
2. Actualiza el estado del registro en catalogo_tiles_procesados a 'PROCESANDO'.
3. Consulta PostGIS usando ST_Intersects para identificar qué parcelas registradas están contenidas dentro del delimitador del Tile.
4. Con las rutas derivadas de s3_base_prefix, lee las bandas de imagen directamente desde S3 público usando rasterio.
5. Ejecuta los recortes matriciales para cada parcela identificada y calcula los índices espectrales (NDVI, NDRE, NDWI).
6. Guarda los resultados procesados en la tabla metricas_parcela dentro del campo JSONB indices_opticos.
7. Actualiza el estado de la escena en catalogo_tiles_procesados a 'COMPLETADO'.

### Paso 4: Ingestion de Datos del Rover Terrestre (Visión Proximal)
1. El Rover recopila fotografías y datos de campo durante su recorrido.
2. El Rover realiza una petición HTTP al iot-service para solicitar una URL firmada de S3.
3. El iot-service entrega la Presigned URL. El Rover sube la imagen cruda directamente al bucket S3 privado.
4. El Rover notifica al iot-service mediante HTTP POST confirmando la carga de la imagen.
5. El iot-service publica la notificación en la cola proximal_vision_queue de RabbitMQ.
6. El proximal-vision-worker procesa la foto con algoritmos de visión artificial (OpenCV) y consolida la métrica en la columna JSONB datos_rover de la tabla metricas_parcela.

### Paso 5: Consulta de la Informacion por la App Móvil

1. El usuario abre la aplicación móvil para revisar el estado de su terreno.
2. La App envía una petición HTTP GET al core-api (Spring Boot).
3. El core-api ejecuta una consulta rápida a la tabla metricas_parcela.
4. La respuesta se retorna en formato JSON estructurado listo para ser renderizado en la interfaz.


# Cómo iniciar en local?:

Primero  debemos iniciar los conetenedores de docker: 

```bash
docker compose up --build -d
```

comprobamos que esten los servicios: 
```bash
docker compose ps
```

## Creamos el Bucket S3 en AWS LocalStack

```bash
docker exec -it krop-localstack awslocal s3 mb s3://krop-storage-dev
```

Verificamos su existencia :
```bash
docker exec -it krop-localstack awslocal s3 ls
```