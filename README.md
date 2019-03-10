
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

## Provisionamento Docker

Script que cópia arquivos de configuração via Terraform

```bash
#!/bin/bash
yum -y update
yum -y install docker epel-release
cp -R /tmp/docker /home/
cd /home/docker/
docker build -t app-idwall .
docker run -dit --name my-running-app -p 443:443 -p 80:80 app-idwall
exit 0
```

Dockerfile

        FROM php:7.3-apache
        RUN apt-get update
        RUN mkdir /etc/apache2/ssl
        RUN mkdir /var/www/public-html
        COPY ssl/server.crt /etc/apache2/conf/ssl/server.crt
        COPY ssl/server.key /etc/apache2/conf/ssl/server.key
        ADD public-html/index.php /var/www/	
        ADD public-html/index.html /var/www/
        RUN chown -R www:www /var/www
        COPY ssl/vhost.conf /etc/apache2/sites-enabled/vhost.conf
        RUN a2enmod rewrite
        RUN a2enmod ssl
        RUN service apache2 restart
        EXPOSE 80
        EXPOSE 443



### Script
```bash

    #!/bin/bash

    function inicio ()
    {
    if [ "$EUID" -ne 0 ]; then
        echo "Desculpe, você precisa estar logado com usuário root"
		exit 1
    else
            if [ ! -e ~/.aws/ ]; then
            mkdir ~/.aws/
            fi
            CMDS="terraform jq aws ssh-keygen"
            for i in $CMDS
                do
                command -v $i >/dev/null && continue || { echo "$i Comando não encontrado, instale para prosseguir."; exit 1; }
                done
        validaContaAWS

	 fi
    }

    RED='\033[0;31m'
    NC='\033[0m' # Sem cor
    DATA=$(echo $(date +%d-%m-%Y))
    export AWS_DEFAULT_OUTPUT=text
    #${RED} ${NC}
    #Funções de suporte
    function saveKEYVar ()
    {
        echo -e "Salvando como variáveis\nNome da Chave = $KEYNAME\nChave pública = $KEYPUBNAME"
        sed -i '/KEYNAME/d' conf/.config 
        sed -i '/KEYPUBNAME/d' conf/.config
        echo -e "KEYNAME=$KEYNAME\nKEYPUBNAME=$KEYPUBNAME" >> conf/.config
    }

    function varSSHKeys ()
    {
        echo "" > logs/findsshkey.txt
        echo "" > logs/awskeylist.txt
        KEYPUBDIR="logs/findsshkey.txt"
        KEYDIR="logs/awskeylist.txt"
        KEYPUBNAME="$(/bin/cat -n $KEYPUBDIR|sed -n ${KEYPUBNAMEID}p|awk '{print $2}')"
        KEYNAME="$(/bin/cat -n $KEYDIR|sed -n ${KEYNAMEID}p|awk '{print $2}')"
    }

    function searchAndSaveKEYName ()
    {
        if [ -z $KEYPUBNAME ];
                then
                    read -rp "Digite endereço Public-Key Exemplo /root/.ssh/id_rsa.pub: " KEYPUBNAME
                    checaKey VALIDKEY
                fi

        until [[ $SALVAKEY =~ (s|n) ]]; do
            read -rp "A Chave já consta na sua conta AWS? (s/n)?" SALVAKEY
        done
        if [[ "$SALVAKEY" = "s" ]]; then
            echo "Buscando chaves na sua conta AWS..."
            aws ec2 --region=$aws_default_region describe-key-pairs --output json | jq '.KeyPairs[].KeyName'|sed 's/"//g' > $KEYDIR
            /bin/cat -n $KEYDIR
            read -p "Digite número correspondente da sua Key: " KEYNAMEID
                while [ $KEYNAMEID -gt $(cat $KEYDIR|wc -l) ]; do
                    read -p "Digite entre 1-$(cat $KEYDIR|wc -l): " KEYNAMEID
                done
            KEYNAME="$(/bin/cat -n $KEYDIR|sed -n ${KEYNAMEID}p|awk '{print $2}')"
        else
            read -rp "Digite Nome da Key (Exemplo: minha-chave): " KEYNAME > $KEYDIR
            echo -e "Exportando chave para AWS!"
            aws ec2 --region=$aws_default_region import-key-pair --key-name $KEYNAME --public-key-material file://$KEYPUBNAME
        fi
    }

    function checaKey ()

    {
        SEARCHVALIDKEY=$(echo $KEYPUBNAME $(ssh-keygen -l -f $KEYPUBNAME))
            case $SEARCHVALIDKEY in
                *RSA*) echo $SEARCHVALIDKEY >> $KEYPUBDIR;;
            esac

        VALIDKEY=$(ssh-keygen -l -f $KEYPUBNAME|grep RSA)
            while [[ ! -f $KEYPUBNAME || -z $VALIDKEY ]]; do
                read -p "Arquivo ou chave inválida, digite novamente: " KEYPUBNAME
                VALIDKEY=$(ssh-keygen -l -f $KEYPUBNAME|grep RSA)
            done
    }

    function validaIp ()
        {
        valido() {
                    echo "$ADDIP" | egrep -qE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' || return 1
                    echo $ADDIP | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <=255 && $4 <= 255 {print "Y" } ' | grep -q Y || return 1
                    return 0
                    }
                    read -p "Insira o IP: " ADDIP
                        while ! valido "$ADDIP"
                        do
                            read -p "Não é válido, digite novamente: " ADDIP
                        done
                        read -p "Digite conotação CIDR 0-32: " CIDR
                        while [ $CIDR -gt 32 ]; do
                            read -p "Escolha intervalo entre 0-32: " CIDR
                        done
                    echo -e "Utilizando ${RED}$ADDIP/$CIDR${NC}"
                    setaRegiao

    }

    #Inicio
    function validaContaAWS ()
    {
        source  ~/.aws/credentials 2>&1 2>/dev/null
        source ~/.aws/config 2>&1 2>/dev/null
        source conf/.config
        if [[ -z "$aws_access_key_id" || -z "$aws_secret_access_key" ]]; then
            read -p "Digite sua aws_access_key_id: " ACCESSKEY
            export aws_access_key_id=$ACCESSKEY
            read -p "Digite sua aws_secret_access_key: " ACCESSKEYID
            export aws_secret_access_key=$ACCESSKEYID
            until [[ $SALVAKEY =~ (s|n) ]]; do
				read -rp "Deseja salvar aws_access_key_id e aws_secret_access_key no arquivo ~/.aws/credentials? (s/n)?" SALVAKEY
				done
				if [[ "$SALVAKEY" = "n" ]]; then
					checaLoginAWS
                else
                    sed -i '/aws_secret_access_key/d' ~/.aws/credentials
                    sed -i '/aws_access_key_id/d' ~/.aws/credentials
                    echo "aws_access_key_id=$ACCESSKEY" >>  ~/.aws/credentials
                    echo "aws_secret_access_key=$ACCESSKEYID" >>  ~/.aws/credentials
				fi
        fi
        checaLoginAWS

    }

    function checaLoginAWS ()
    {
        rm -f logs/loginaws-error.txt
        aws iam get-user --query User.UserName --output text 2>&1 1>logs/loginaws.txt | tee logs/loginaws-error.txt
            if [[  -s logs/loginaws-error.txt ]];
            then
                echo "-------"
                echo "⚠️ Login incorreto, credências inválidas em ~/.aws/credentials"
                echo "-------"
                echo "   1) Informar novamente as credênciais"
                echo "   2) Continuar desconectado  "
                echo "   3) Sair"
            until [[ "$MENU_LOGIN" =~ ^[1-3]$ ]]; do
                read -rp "Selecione uma opção [1-3]: " MENU_LOGIN
            done

            case $MENU_LOGIN in
                1)
                    sed -i '/aws_secret_access_key/d' ~/.aws/credentials
                    sed -i '/aws_access_key_id/d' ~/.aws/credentials
                    unset aws_access_key_id
                    unset aws_secret_access_key
                    validaContaAWS
                ;;
                2)
                    setaRegiao
                    checaSSHKeys
                ;;
                3)
                    exit 0
                ;;
            esac
            else
                echo "Você está logado com usuário: $(echo -e ${RED}$(aws iam get-user --query User.UserName --output text)${NC})"
                setaRegiao
                checaSSHKeys
            fi

    }

    function setaRegiao ()
    {
        if [ -z $aws_default_region ];
        then
            rm -f logs/regiaoaws-error.txt
            aws ec2 --region=us-west-2 describe-regions --query "Regions[].{Name:RegionName}" --output text > logs/regiaoaws.txt
            echo "Regiões AWS"
            /bin/cat -n logs/regiaoaws.txt
            read -p "Digite número da região AWS: " SETREGIAO
            SETREGIAO="$(sed -n ${SETREGIAO}p logs/regiaoaws.txt)"
            echo "Deseja salvar região [$SETREGIAO] como padrão (s/n)?"
            read SAVEREGIAO
                if [ "$SAVEREGIAO" != "${SAVEREGIAO#[YyEeSsIiMm]}" ] ;
                then
                    sed -i '/aws_default_region/d' ~/.aws/config
                    echo "aws_default_region=$SETREGIAO" >> ~/.aws/config
                fi
        else
            echo "Regiões AWS"
            echo "~/.aws/config com região padrão, utilizando $(echo -e ${RED}[$aws_default_region]${NC})"
            sleep 2
        fi
    setaNomeServidor
    }

    function setaNomeServidor ()
    {
        read -p "Digite nome do servidor: " SERVERNAME
            while grep "${SERVERNAME}.dedicado" conf/lista-servers.txt >/dev/null 2>&1; do
                read -p "Nome já existe, escolha outro: " SERVERNAME
            done
        checaSSHKeys    
    }

    function checaSSHKeys ()
    {
        #Carregando variáveis
        varSSHKeys
        if  grep -e 'KEYNAME=' -e 'KEYPUBNAME=' conf/.config;
        then
            echo "Keys encontradas, usaremos dados salvos em conf/.config"
        else
            rm -f $KEYPUBDIR >/dev/null

            SELECTOPTKEY=("Gerar key SSH" "Buscar key no computador" "Definir Manualmente" "Não alterar")
            echo "Processo de configuração keys SSH:"
                select OPTKEY in "${SELECTOPTKEY[@]}"
                do
                    case $OPTKEY in
                        "Gerar key SSH")
                            echo "Gerando chave SSH"
                            KEYPUBNAME="$(pwd)/conf/ssh/chave-ssh-${DATA}.pub"
                            ssh-keygen -f $(pwd)/conf/ssh/chave-ssh-${DATA}
                            read -p "Defina nome da chave que exportaremos para sua conta AWS: " KEYNAME > $KEYPUBDIR
                            aws ec2 --region=$aws_default_region import-key-pair --key-name $KEYNAME --public-key-material file://$KEYPUBNAME
                            saveKEYVar

                            break
                            ;;
                        "Buscar key no computador")
                                echo "Buscando em $(echo ~/.ssh) e $(pwd)..."
                                sleep 2
                                for KEYPUBNAME in $(/bin/find ~/.ssh/ $(pwd)/conf/ssh -type f \( -iname \*.pub -o -iname \*.pem \))
                                do
                                    checaKey SEARCHKEYVALID
                                done
                            echo -e "Encontramos as seguintes chaves\n$(/bin/cat -n $KEYPUBDIR|awk '{print $1, $2}')"
                            read -p "Selecione número da Key: " KEYPUBNAMEID
                                while [ $KEYPUBNAMEID -gt $(/bin/cat $KEYPUBDIR|wc -l) ]; do
                                    read -p "Digite entre 1-$(/bin/cat $KEYPUBDIR|wc -l): " KEYPUBNAMEID
                                done
                            searchAndSaveKEYName
                            saveKEYVar
                        break
                        ;;
                    "Definir Manualmente")
                            searchAndSaveKEYName
                            saveKEYVar
                        break
                        ;;
                    "Não alterar")
                        break
                        ;;
                    *) echo "Opção inválida";;
                esac
            done
        fi
    fwSSH
    }

    function fwSSH ()
        {
        ADDIP=$(curl -s ifconfig.me)
        ADDIP=$(echo $ADDIP/32)
        SELECTOPTION=("Liberar IP atual $(echo -e ${RED}$ADDIP${NC})" "Personalizar IP" "Sair")
        echo "Selecione IP que conectará ao serviço SSH"
            select OPT in "${SELECTOPTION[@]}"
            do
                case $OPT in
                    "Liberar IP atual $(echo -e ${RED}$ADDIP${NC})")
                        break
                        ;;
                    "Personalizar IP")
                        validaIp
                        sleep 2
                        break
                        ;;
                    "Não alterar")
                        break
                        ;;
                    *) echo "Opção inválida";;
                esac
            done
        initTerraform
    }

    function initTerraform ()
    {
        rm -f $TF_LOG_PATH

        #Condição para OK é retorno de IP - Ainda tenho que trabalhar retorno dos status
        rm -f logs/terraformoutput-error.txt
        IPSERVER=$(terraform output -module=desafio public_ip 2>&1 1>logs/terraformoutput.txt | tee logs/terraformoutput-error.txt)

        terraform apply -var aws_regiao=$SETREGIAO -var ssh-range=$ADDIP -var key_name=$KEYNAME -var instance_name=$SERVERNAME -var public_key_path=$KEYPUBDIR

        if [[ -s logs/terraformoutput-error.txt ]];
        then
            echo -e "\n\n  ⚠️  Saindo! Terraform apresentou erro.\n\n  Saíba mais em: $(echo $TF_LOG_PATH)\n\n"
        else

            echo -e "##################\nData: $DATA\nHora: $(date +%H:%M:%S)\nHost: $(echo $SERVERNAME).example.com\nIP: $IPSERVER" >> conf/lista-servers.txt

            echo "Acesse no seu brother https://$(IPSERVER)"
        fi
        exit 0
    }
    inicio
```
