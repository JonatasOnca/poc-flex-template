# Makefile para PoC de Dataflow Flex Template

# --- Configuração ---
# !!! POR FAVOR, EDITE AS VARIÁVEIS ABAIXO !!!
# Você pode sobrescrevê-las na linha de comando, ex: make deploy BUCKET_NAME=meu-outro-bucket

# Tenta obter o ID do projeto automaticamente do gcloud, senão use um valor padrão.
PROJECT_ID   ?= $(shell gcloud config get-value project)
BUCKET_NAME  := seu-bucket-aqui
REGION       := us-central1

# --- Nomes e Caminhos (geralmente não precisam ser alterados) ---
REPO_NAME        := poc-flex-repo
IMAGE_NAME       := poc-flex-template
TEMPLATE_NAME    := poc-uppercase-template
IMAGE_URI        := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO_NAME)/$(IMAGE_NAME):latest
TEMPLATE_PATH    := gs://$(BUCKET_NAME)/$(IMAGE_NAME)/dataflow/templates/$(TEMPLATE_NAME).json

# --- Parâmetros para Execução (edite conforme necessário) ---
INPUT_FILE       := gs://$(BUCKET_NAME)/$(IMAGE_NAME)/dataflow/input/input.txt
OUTPUT_PREFIX    := gs://$(BUCKET_NAME)/$(IMAGE_NAME)/dataflow/output/result
JOB_NAME_PREFIX  := poc-uppercase

# Gera um nome de job único com a data/hora atual
JOB_NAME         := $(JOB_NAME_PREFIX)-$(shell date +%Y%m%d-%H%M%S)

# Nome do arquivo de metadados gerado temporariamente
GENERATED_METADATA := metadata.generated.json

# --- Comandos ---

# O alvo padrão é 'help', para guiar o usuário.
.DEFAULT_GOAL := help

.PHONY: help
help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Cria o repositório no Artifact Registry (executar apenas uma vez)
	@echo "--> Configurando o repositório no Artifact Registry: $(REPO_NAME)"
	@gcloud artifacts repositories create $(REPO_NAME) \
		--repository-format=docker \
		--location=$(REGION) \
		--description="Repositório para PoC de Flex Templates" || echo "Repositório já existe."
	@echo "--> Configurando autenticação do Docker..."
	@gcloud auth configure-docker $(REGION)-docker.pkg.dev

.PHONY: build-image
build-image: ## Constrói a imagem Docker com o Cloud Build e a envia ao Artifact Registry
	@echo "--> Construindo e enviando a imagem Docker: $(IMAGE_URI)"
	@gcloud builds submit . --tag=$(IMAGE_URI)

.PHONY: build-template
build-template: ## Cria a especificação do Flex Template no Cloud Storage
	@echo "--> Gerando arquivo de metadados temporário..."
	@sed 's|GCS_IMAGE_URI_PLACEHOLDER|$(IMAGE_URI)|' metadata.json > $(GENERATED_METADATA)
	@echo "--> Criando a especificação do template em: $(TEMPLATE_PATH)"
	@gcloud dataflow flex-template build $(TEMPLATE_PATH) \
		--image=$(IMAGE_URI) \
		--sdk-language=PYTHON \
		--metadata-file=$(GENERATED_METADATA)
	@echo "--> Limpando metadados temporários."
	@rm -f $(GENERATED_METADATA)

.PHONY: deploy
deploy: build-image build-template ## Constrói a imagem e o template em um só passo
	@echo "\n✅ Deploy do template concluído com sucesso!"
	@echo "   Template disponível em: $(TEMPLATE_PATH)"


.PHONY: upload-input
upload-input: ## Cria um arquivo de entrada de exemplo e o envia para o GCS
	@echo "--> Criando arquivo de entrada local de exemplo..."
	@echo "linha de exemplo um" > input.txt.local
	@echo "linha de exemplo dois" >> input.txt.local
	@echo "MAIS UMA LINHA" >> input.txt.local
	@echo "--> Enviando arquivo para: $(INPUT_FILE)"
	@gsutil cp input.txt.local $(INPUT_FILE)
	@echo "--> Limpando arquivo local."
	@rm -f input.txt.local


.PHONY: run
run: upload-input ## Executa um job do Dataflow usando o template
	@echo "--> Executando o job de Dataflow: $(JOB_NAME)"
	@gcloud dataflow flex-template run $(JOB_NAME) \
		--template-file-gcs-location=$(TEMPLATE_PATH) \
		--region=$(REGION) \
		--parameters input=$(INPUT_FILE) \
		--parameters output=$(OUTPUT_PREFIX)

.PHONY: view-result
view-result: ## Mostra o conteúdo dos arquivos de saída no GCS
	@echo "--> Exibindo resultado de: $(OUTPUT_PREFIX)*"
	@gsutil cat $(OUTPUT_PREFIX)*

.PHONY: clean
clean: ## Remove arquivos gerados localmente
	@echo "--> Limpando arquivos temporários..."
	@rm -f $(GENERATED_METADATA)