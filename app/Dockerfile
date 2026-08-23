FROM python:3.10-slim-bookworm

WORKDIR /app

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential \
        gcc \
        g++ \
        libc6-dev \
        libpq-dev \
        python3-dev \
        dnsutils && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN python -m pip install --no-cache-dir --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN groupadd -g 10001 appgroup && \
    useradd -r -u 10001 -g appgroup -d /app -s /sbin/nologin appuser && \
    chown -R appuser:appgroup /app

USER 10001

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 --workers 6 pygoat.wsgi"]
