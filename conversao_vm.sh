#!/bin/bash

# Solicitar ao usuário os caminhos das pastas, do bucket, da região e o ID da instância
echo "Digite o caminho da pasta de conversão:"
read CONVERT_FOLDER

echo "Digite o caminho da pasta para extração:"
read EXTRACT_FOLDER

echo "Digite o caminho da pasta para exportação:"
read EXPORT_FOLDER

echo "Digite o nome do bucket S3:"
read BUCKET_NAME

echo "Digite a região da AWS:"
read REGION

echo "Digite o ID da instância:"
read INSTANCE_ID

# Função para fazer upload do arquivo .ova para o bucket S3
upload_to_s3() {
  local ova_name=$(basename "$CONVERT_FOLDER"/*.7z)  # Obtém o nome do arquivo .7z
  ova_name="${ova_name%.*}.ova"  # Remove a extensão .7z e adiciona .ova
  aws s3 cp "$EXPORT_FOLDER"/*.ova s3://$BUCKET_NAME/$ova_name  # Copia o arquivo .ova para o bucket S3
  # Aguarda a existência do arquivo no Amazon S3
  aws s3api wait object-exists --bucket $BUCKET_NAME --key $ova_name
}

# Extrai arquivos compactados, procura por arquivos .vmx e os converte para .ova
extract_and_convert() {
  local archive_file="$1"  # Nome do arquivo compactado
  local extension="${archive_file##*.}"  # Extrai a extensão do arquivo
  case "$extension" in
    7z)
      7z e "$archive_file" -o"$EXTRACT_FOLDER"  # Extrai o arquivo .7z para a pasta de extração
      ;;
    *)
      echo "Formato de arquivo não suportado: $extension"  # Exibe uma mensagem de erro para formatos não suportados
      return 1
      ;;
  esac

  # Converte o arquivo .vmx da pasta para OVA
  ovftool "$EXTRACT_FOLDER"/*.vmx "$EXPORT_FOLDER"/*.ova
}

# Importa .ova como AMI na AWS
import_to_ami() {
  local ami_name=$(basename "$CONVERT_FOLDER"/*.7z)  # Obtém o nome do arquivo .7z
  ami_name="${ami_name%.*}"  # Remove a extensão .7z

  # Importa o arquivo do Amazon S3 como AMI
  json_data='[
    {
      "Description": "'$ami_name'",
      "Format": "ova",
      "Url": "s3://new-ref-env/'"${ami_name%.}.ova"'"
    }
  ]'

  # Importa a AMI
  import_response=$(aws ec2 import-image --description "$ami_name" --license-type BYOL --disk-containers "$json_data" --region us-east-1)

  # Verifica se a importação foi bem-sucedida e obtém o ID da AMI
  import_task_id=$(echo "$import_response" | jq -r '.ImportTaskId')
  if [[ -n "$import_task_id" && "$import_task_id" != "null" ]]; then
    echo "Importação iniciada com o ID da tarefa de importação: $import_task_id"

    # Aguarda a conclusão da importação
    while true; do
      import_status=$(aws ec2 describe-import-image-tasks --import-task-ids "$import_task_id" --query "ImportImageTasks[0].Status" --output text --region us-east-1)
      if [[ "$import_status" == "completed" ]]; then
        break
      elif [[ "$import_status" == "deleted" || "$import_status" == "deleting" || "$import_status" == "cancelled" ]]; then
        echo "A importação da AMI falhou."
        return
      fi
      sleep 10
    done

    # Obtém o ID da AMI
    ami_id=$(aws ec2 describe-import-image-tasks --import-task-ids "$import_task_id" --query "ImportImageTasks[0].ImageId" --output text --region us-east-1)

    # Adiciona a tag "Name" à AMI
    aws ec2 create-tags --resources "$ami_id" --tags "Key=Name,Value=$ami_name" --region us-east-1

    echo "A importação da AMI foi concluída com sucesso."
  else
    echo "A importação da AMI falhou."
  fi
}

# Verifica se a pasta de conversão existe
if [ -d "$CONVERT_FOLDER" ]; then
  # Procura por arquivos compactados e os processa
  for archive_file in "$CONVERT_FOLDER"/*.{7z,zip,rar}; do
    if [ -f "$archive_file" ]; then
      # Extrai arquivos e converte para .ova
      extract_and_convert "$archive_file"

      # Faz upload do arquivo .ova para o S3
      for ova_file in "$EXPORT_FOLDER"/*.ova; do
        if [ -f "$ova_file" ]; then
          upload_to_s3
          # Importa .ova como AMI na AWS
          import_to_ami
        fi
      done
    fi
  done

  # Limpa os arquivo das pastas
  FileName=$(basename "$CONVERT_FOLDER"/*.7z)
  FileName="${FileName%.*}"
  find "$CONVERT_FOLDER" -type f -delete  # Exclui todos os arquivos dentro da pasta de conversão
  cd "$EXTRACT_FOLDER" ; rmdir "$FileName" ; cd # Remove a sub-pasta de extração e volta para a home
else
  echo "Pasta de conversão '$CONVERT_FOLDER' não encontrada."  # Exibe uma mensagem de erro se a pasta de conversão não for encontrada
fi