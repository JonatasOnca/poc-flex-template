# Dockerfile
FROM gcr.io/dataflow-templates-base/python3-template-launcher-base

# Define o diretório de trabalho dentro do container
ARG WORKDIR=/template
WORKDIR $WORKDIR

# Copia os arquivos de dependência e código para o container
COPY requirements.txt .
COPY main.py .

# Instala as dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Define a variável de ambiente que a imagem base usa para encontrar o arquivo Python principal
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="${WORKDIR}/main.py"