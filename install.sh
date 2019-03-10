#!/usr/bin/env bash
    function inicio ()
    {
    if [ "$EUID" -ne 0 ]; then
        echo "Desculpe, você precisa estar logado com usuário root"
		exit 1
    else
        #Checando e criando diretórios necessários
        DIRS=(
            ~/.aws/
            logs
            conf/ssh
        )
        FILES=(
            ~/.aws/config
            ~/.aws/credentials
            conf/.config
        )
            for d in "${DIRS[@]}"; do
                if [ ! -e $d ]; then
                mkdir $d
                fi
            done
            for f in "${FILES[@]}"; do
                if [ ! -e $f ]; then
                touch $f
                fi
            done
        CREDTAG=$(grep -i \\[[a-z\|\|1-9]\*\\] ~/.aws/credentials)
            if [ -z "$CREDTAG" ];
            then
                echo "Tag faltando em credentials, adicionando"
                printf '%s\n' 0a '[default]' . x | ex  ~/.aws/credentials
            fi
        CONFTAG=$(grep -i \\[[a-z\|\|1-9]\*\\] ~/.aws/config)
            if [ -z "$CONFTAG" ];
            then
                echo "Tag faltando em config, adicionando"
                printf '%s\n' 0a '[default]' . x | ex  ~/.aws/config
        fi
        CMDS="terraform jq aws ssh-keygen"
            for i in $CMDS
            do
                command -v $i >/dev/null && continue || { echo "$i Comando não encontrado, instale para prosseguir."; exit 1;}
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
        echo " " > logs/findsshkey.txt
        echo " " > logs/awskeylist.txt
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
            aws ec2 --region=$region describe-key-pairs --output json | jq '.KeyPairs[].KeyName'|sed 's/"//g' > $KEYDIR
            /bin/cat -n $KEYDIR
            read -p "Digite número correspondente da sua Key: " KEYNAMEID
                while [ $KEYNAMEID -gt $(cat $KEYDIR|wc -l) ]; do
                    read -p "Digite entre 1-$(cat $KEYDIR|wc -l): " KEYNAMEID
                done
            KEYNAME="$(/bin/cat -n $KEYDIR|sed -n ${KEYNAMEID}p|awk '{print $2}')"
        else
            read -rp "Digite Nome da Key (Exemplo: minha-chave): " KEYNAME > $KEYDIR
            echo -e "Exportando chave para AWS!"
            aws ec2 --region=$region import-key-pair --key-name $KEYNAME --public-key-material file://$KEYPUBNAME
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
            echo "Salvando as credênciais em ~/.aws/credentials"
            sed -i '/aws_secret_access_key/d' ~/.aws/credentials
            sed -i '/aws_access_key_id/d' ~/.aws/credentials
            echo "aws_access_key_id=$ACCESSKEY" >>  ~/.aws/credentials
            echo "aws_secret_access_key=$ACCESSKEYID" >>  ~/.aws/credentials
        fi
        checaLoginAWS

    }

    function checaLoginAWS ()
    {
        echo " " > logs/loginaws-error.txt
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
        if [ -z $region ];
        then
            echo " " > logs/regiaoaws-error.txt
            aws ec2 --region=us-west-2 describe-regions --query "Regions[].{Name:RegionName}" --output text > logs/regiaoaws.txt
            echo "Regiões AWS"
            /bin/cat -n logs/regiaoaws.txt
            read -p "Digite número da região AWS: " SETREGIAO
            SETREGIAO="$(sed -n ${SETREGIAO}p logs/regiaoaws.txt)"
            echo "Deseja salvar região [$SETREGIAO] como padrão (s/n)?"
            read SAVEREGIAO
                if [ "$SAVEREGIAO" != "${SAVEREGIAO#[YyEeSsIiMm]}" ] ;
                then
                    sed -i '/region/d' ~/.aws/config
                    echo -e "region=$SETREGIAO" >> ~/.aws/config
                fi
        else
            echo "Regiões AWS"
            echo "~/.aws/config com região padrão, utilizando $(echo -e ${RED}[$region]${NC})"
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
            source conf/.config
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
                            aws ec2 --region=$region import-key-pair --key-name $KEYNAME --public-key-material file://$KEYPUBNAME
                            saveKEYVar

                            break
                            ;;
                        "Buscar key no computador")
                            echo "Buscando em $(echo ~/.ssh) e $(pwd)..."
                            sleep 2
                	            for KEYPUBNAME in $(/bin/find 2> /dev/null ~/.ssh/ $(pwd)/conf/ssh -type f \( -iname \*.pub -o -iname \*.pem \))
                    	        do
                                    checaKey SEARCHKEYVALID
                                done
									if [ -z $KEYPUBNAME ];
									then
										echo "Não encontramos Keys, voltando!"
										checaSSHKeys
									else
	                           			echo -e "Encontramos as seguintes chaves\n$(/bin/cat -n 2> /dev/null $KEYPUBDIR|awk '{print $1, $2}')"
	                            		read -p "Selecione número da Key: " KEYPUBNAMEID
    	                           			while [ $KEYPUBNAMEID -gt $(/bin/cat 2> /dev/null $KEYPUBDIR|wc -l) ]; do
            	                      	 	 read -p "Digite entre 1-$(/bin/cat 2> /dev/null $KEYPUBDIR|wc -l): " KEYPUBNAMEID
        	                       			done
                            searchAndSaveKEYName
                            saveKEYVar
							fi
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
        echo " " > $TF_LOG_PATH

        #Condição para OK é retorno de IP - Ainda tenho que trabalhar retorno dos status
        echo " " > logs/terraformoutput-error.txt
        IPSERVER=$(terraform output -module=desafio public_ip 2>&1 1>logs/terraformoutput.txt | tee logs/terraformoutput-error.txt)
        terraform apply -var aws_regiao=$SETREGIAO -var ssh-range=$ADDIP -var key_name=$KEYNAME -var instance_name=$SERVERNAME -var public_key_path=$KEYPUBNAME

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
