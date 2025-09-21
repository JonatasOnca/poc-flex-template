# Prova de Conceito: Dataflow Flex Template (poc-flex-template)

Este projeto é uma prova de conceito (PoC) que demonstra como criar e executar um pipeline de Dataflow Flex Template.

O pipeline, construído com Apache Beam em Python, lê um arquivo de texto de um bucket do Google Cloud Storage (GCS), converte cada linha para maiúsculas e escreve o resultado em um novo arquivo no GCS. Todo o processo, desde a criação da imagem do contêiner até a execução do job, é automatizado por meio de um `Makefile` para simplificar o desenvolvimento e o deploy.

## Estrutura do Projeto

* **`main.py`**: Contém o código do pipeline Apache Beam que define a lógica de processamento, lendo um arquivo, convertendo seu conteúdo para maiúsculas e salvando o resultado.
* **`Dockerfile`**: Define o ambiente do contêiner para executar o pipeline. Ele copia os arquivos de código e instala as dependências necessárias.
* **`requirements.txt`**: Lista as dependências Python do projeto, neste caso, `apache-beam[gcp]`.
* **`metadata.json`**: Arquivo de metadados que descreve o Flex Template, incluindo seu nome, descrição e os parâmetros de entrada (`input`) e saída (`output`) que o job espera.
* **`Makefile`**: Automatiza todas as tarefas do ciclo de vida do projeto, como configuração do ambiente, construção da imagem, deploy do template e execução do job no Dataflow.

## Pré-requisitos

Antes de começar, garanta que você tenha os seguintes pré-requisitos:

1.  **Projeto GCP:** Um projeto ativo no Google Cloud Platform com o faturamento habilitado.
2.  **gcloud CLI:** A ferramenta de linha de comando `gcloud` instalada e autenticada.
3.  **APIs Habilitadas:** Execute o seguinte comando para garantir que as APIs necessárias estejam ativadas no seu projeto:
    ```bash
    gcloud services enable \
        compute.googleapis.com \
        dataflow.googleapis.com \
        cloudbuild.googleapis.com \
        artifactregistry.googleapis.com \
        cloudresourcemanager.googleapis.com
    ```
4.  **Permissões:** Sua conta de usuário ou de serviço precisa ter permissões adequadas para gerenciar Artifact Registry, Cloud Build, Cloud Storage e Dataflow (papéis como `Editor` ou uma combinação de `roles/dataflow.admin`, `roles/storage.admin`, `roles/cloudbuild.builds.editor` e `roles/artifactregistry.writer` são suficientes).
5.  **Bucket no GCS:** Um bucket no Google Cloud Storage para armazenar os arquivos do template, os dados de entrada e os resultados.
6.  **Docker:** O Docker deve estar instalado e em execução na sua máquina local para autenticação no Artifact Registry.

## Configuração

1.  **Clone o repositório** para sua máquina local.
2.  **Atualize o `Makefile`**: Abra o arquivo `Makefile` e edite a variável `BUCKET_NAME` para o nome do seu bucket no GCS. O `PROJECT_ID` é detectado automaticamente, mas você pode defini-lo manualmente se necessário.

    ```makefile
    # --- Configuração ---
    # !!! POR FAVOR, EDITE AS VARIÁVEIS ABAIXO !!!
    PROJECT_ID   ?= $(shell gcloud config get-value project)
    BUCKET_NAME := seu-bucket-aqui # <-- Altere esta linha
    REGION      := us-central1
    ```

## Como Usar

O `Makefile` automatiza todas as etapas do processo. Os comandos mais comuns estão descritos abaixo. Para ver uma lista completa de comandos, execute `make help`.

### 1. Configuração Inicial do Repositório

Se esta for a primeira vez que você executa o projeto, crie o repositório no Artifact Registry. Este comando só precisa ser executado uma vez.

```bash
make setup
 ```

 ### 2. Construir a Imagem e o Template
O comando **`deploy`** é o fluxo de trabalho principal. Ele constrói a imagem Docker usando o Cloud Build, envia a imagem para o Artifact Registry e, em seguida, cria o arquivo de especificação do template no Cloud Storage.

```bash
make deploy
 ```

Ao final do processo, o caminho para o seu template no GCS será exibido.

 ### 3. Executar o Job no Dataflow
Com o template pronto, você pode executar um job.

```bash
make run
 ```

Este comando inicia um novo job no Dataflow usando a especificação do template armazenada no GCS. Ele utiliza os parâmetros de entrada (**`INPUT_FILE`**) e saída (**`OUTPUT_PREFIX`**) definidos no **`Makefile`**.

 ### 4. Limpeza
Para remover arquivos gerados localmente, como o metadado temporário, use o comando de limpeza.

```bash
make clean
 ```
 