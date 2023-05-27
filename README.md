Essa documentação visa explicar o funcionamento e uso do script em shell Linux que automatiza os processos de conversão e importação de arquivos VMX/VMDK para a AWS como AMI.

# ⚙️ Funcionamento

1. O script irá checar a pasta `$CONVERT_FOLDER` em busca de um arquivo **.7z** para converter;
2. Ao encontrar o arquivo **.7z**, ele será convertido e enviado para a pasta `$EXTRACT_FOLDER`;
3. Após a descompactação do arquivo, o script procurará pelo arquivo **.vmx**, usará o **OVFTool** para converter o arquivo em formato **.ova** e em seguida o moverá para a pasta `$EXPORT_FOLDER`;
4. Com a conversão tendo sido finalizada, será feito o upload do arquivo **.ova** no bucket **S3** `$BUCKET_NAME`;
6. E finalmente, após o upload no **S3**, o arquivo **.ova** será importado como **AMI** com o **MESMO NOME** do arquivo **.7z**;
7. Ao final do processo, **TODOS** os arquivos colocados na pasta `$CONVERT_FOLDER` serão devidamente excluídos.
> É de `EXTREMA` importância deixar claro que o script só funcionará corretamente colocando **APENAS UM** arquivo **.7z** por vez na pasta `$CONVERT_FOLDER`
