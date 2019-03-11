
- Instalação
```
git clone https://github.com/renatoguilhermini/terraforma-scriptinit
cd terraforma-scriptinit
sudo bash install.sh
```

## Script de provisionamento didático utilizando servidores EC2 na Amazon.


**Desenvolvido usando Shell Script, AWS-CLI e Terraform.**

- Recursos:
```
Verifique status da auth
Salve keys em arquivo configuração ou utilize no path da sessão
Exiba usuário logado
Gere chaves SSH e copia para AWS
Utilize chaves existentes
Adicione seu atual IP na regra de acesso remoto SSH
Adicione IP/Range manualmente
Selecione regiões disponíveis para provisionamento
O questionário gerará variáveis que serão utilizadas pelo Terraform
```



- Requisitos:

```
aws-cli - Command line Amazon AWS
jq - Ler saídas em json para Shell Script
terraform - Provisionador de Sistemas
ssh-keygen - Manipulador de chaves OpenSSH
```

- Terraform

***Terraform utiliza modulo com nome de desafio***
```
Dir: terraform/mod/desafio
---
- Variáveis:
    $SETREGIAO = Região AWS
    $ADDIP = IP/CIDR
    $KEYNAME = Nome da Key AWS
    $KEYPUBNAME = Mome da Public Key
    $SERVERNAME = Nome do Servidor
---
terraform/mod/desafio/output.tf
    printa ao finalizar tarefa o IP do servidor.
---
terraform/mod/desafio/main.tf 
    Contém instância idwall
    Copia conf/docker para /tmp do servidor
    Copia conf/conf-install.sh para /tmp
    Executa remotamente /tmp/conf-install.sh
    Obs: Este script provisiona o docker
    Contém grupo de segurança com rules solicitadas no desafio
---
main.tf
    Aponta para modulo desafio
    Aponta váriaveis locais para módulo

```

Script utiliza arquivo de configuração com variáveis fixas.

conf/.config

Exemplo de alguns campos.

- Variável de autenticação.

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

- Variável Região Padrão

AWS_DEFAULT_REGION


## Função - Inicio

- Validações:

Checa se script está sendo executado pelo root

Cria arquivo de configuração se não existe

Checa se os principais softwares utilizados estão instalados

## Função - Login e Checa Login AWS

- Validações:

Checa se variáveis estão carregadas

Checa login AWS

Confere e adiciona keys no arquivo de configuração se aprovado.

## Função - SSH Keys

- Apresentam 3 opções.

1) Gera Chave SSH Local.

- Utilizamos utilizatário ssh-keygen para gerar uma chave local e copiar para AWS.

2) Buscar chaves locais nos diretórios (raíz script) e ~/.ssh/

- Validações:

Pesquisa por extensões e valida se é realmente uma chave.

3) Definir manualmente caminho da chave publica.

## Função - Nome Do Servidor

Checa se nome do servidor consta no log que é gerado ao final do processo.

## Função - Valida IP

Checa se IP atende requisitos e campos.

## Função - Firewall - SSH

Libera IP publico atual no firewall atual ou range que preferir.

## Função - Definir região

Lê arquivo config e carrega automáticamente var.

Define região padrão para instalações AWS.

- Validação

Alerta caso terraform apresente erro

## Função - Terraform

Coleta as variáveis de todo questionario e executa o Apply
