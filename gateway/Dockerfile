FROM python:alpine

WORKDIR /app

RUN pip install --no-cache-dir paho-mqtt

COPY bridge.py .

CMD ["python", "bridge.py"]
