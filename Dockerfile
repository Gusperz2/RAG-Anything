FROM python:3.10-slim

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/root/.cargo/bin:${PATH}"

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    libreoffice \
    build-essential \
    libmagic1 \
    poppler-utils \
    postgresql-client \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Copiar todos los archivos del repo
COPY . .

# Instalar uv (gestor de paquetes rápido)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Crear entorno virtual e instalar dependencias
RUN uv venv && \
    . .venv/bin/activate && \
    UV_HTTP_TIMEOUT=300 uv sync --all-extras && \
    pip install psycopg2-binary pgvector supabase

# Descargar modelos de MinerU
RUN . .venv/bin/activate && \
    python -c "from raganything import RAGAnything; rag = RAGAnything(); rag.check_parser_installation()" || true

# Exponer puerto
EXPOSE 8501

# Comando de inicio
CMD ["/bin/bash", "-c", "source .venv/bin/activate && streamlit run scripts/webui.py --server.port=8501 --server.address=0.0.0.0"]
