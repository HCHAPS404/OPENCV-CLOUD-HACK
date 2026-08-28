FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Arranca el runner local de Python que consulta STAC y ejecuta el bucle
CMD ["python", "src/local_runner.py"]