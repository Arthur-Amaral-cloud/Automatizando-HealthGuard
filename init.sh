#!/bin/bash

read -p "Deseja alterar a senha do root? (S/N) " SENHA_ROOT

if [ $SENHA_ROOT = 'S' ]; then 
    sudo passwd root
fi

read -p "Deseja alterar a senha do ubuntu? (S/N) " SENHA_UBUNTU

if [ $SENHA_UBUNTU = 'S' ]; then 
    sudo passwd ubuntu
fi

set -e   #caso algum comando falhar ele para o script 

if [ "$EUID" -ne 0 ]; then
  echo "Erro: Por favor, execute este script como root ou com sudo ."
  exit 1
fi
# Criação dos grupos
echo "+==================================================================+"
echo "Criando grupos..."
groupadd health-guard
echo "Grupo health-guard criado"
groupadd DBA
echo "Grupo DBA criado"
groupadd front-end
echo "Grupo front-end criado"
groupadd back-end 
echo "Grupo back-end criado"
groupadd devops
echo "Grupo devops criado"
echo "Grupos criados."
echo "+==================================================================+"
echo " "

# Criação dos diretórios
echo "+==================================================================+"
echo "Criando diretórios..."
mkdir -p /home/sistema
echo "/home/sistema criado"
mkdir -p /home/sistema/aplicacao-java
echo "/home/sistema/aplicacao-java criado"
mkdir -p /home/sistema/aplicacao-python
echo "/home/sistema/aplicacao-python criado"
mkdir -p /home/sistema/banco
echo "/home/sistema/banco criado"
mkdir -p /home/sistema/site-institucional
echo "/home/sistema/site-institucional criado"
echo "Diretórios criados em /home/sistema"
echo "+==================================================================+"

echo "Atribuindo os diretorios aos seus respectivos grupos..."
chown :health-guard /home/sistema/
echo "Diretório 'sistema' atribuido ao grupo health-guard"
chown -R :DBA /home/sistema/banco/
echo "Diretorio 'banco' atribuido ao grupo DBA"
chown -R :back-end /home/sistema/aplicacao-python/
chown -R :back-end /home/sistema/aplicacao-java/
echo "Diretorios 'aplicacao-python/java' atribuidos ao grupo back-end"
chown -R :front-end /home/sistema/site-institucional/
echo "Diretorio 'site-institucional' atribuido ao grupo front-end"
echo "Concluido"


echo ""
echo "+==================================================================+"
echo "adicionando configurações de permissões de usuario..."
 echo "Instalando ACL('acess control list')"
  apt install acl -y
  chmod 770 /home/sistema/aplicacao-java/
  chmod 770 /home/sistema/aplicacao-python/
  chmod 770 /home/sistema/site-institucional/
  chmod 770 /home/sistema/banco/
  setfacl -m g:health-guard:r-x /home/sistema/site-institucional/
  setfacl -m g:health-guard:r-x /home/sistema/banco/
  setfacl -m g:health-guard:r-x /home/sistema/aplicacao-java/
  setfacl -m g:health-guard:r-x /home/sistema/aplicacao-python/
  echo "permissões configuradas."
  echo ""

echo "Criando usuarios..."
echo ""
echo ""
echo "+========================+"
useradd rafael -m
echo "rafael:rafael23" |  chpasswd

useradd marcela -m
echo "marcela:marcela123" |  chpasswd

useradd arthur -m
echo "arthur:arthur123" |  chpasswd

useradd andre -m
echo "andre:andre123" |  chpasswd

useradd giovanna -m
echo "giovanna:giovanna123" |  chpasswd

useradd davi -m
echo "davi:davi123" |  chpasswd

echo "+========================+"
echo "Usuarios criados com sucesso"
echo "+========================+"
echo " Adicionando Usuarios nos respectivos grupos"
usermod -aG health-guard rafael
usermod -aG health-guard marcela
usermod -aG health-guard arthur
usermod -aG health-guard andre
usermod -aG health-guard davi

usermod -aG devops rafael
usermod -aG devops marcela
usermod -aG back-end marcela
usermod -aG back-end rafael

usermod -aG DBA giovanna
usermod -aG DBA arthur

usermod -aG back-end giovanna
usermod -aG back-end arthur

usermod -aG front-end davi
usermod -aG front-end andre
echo "+========================+"
echo "os usuarios foram adicionados aos grupo"
echo " "
echo "Usuarios criados com sucesso!"

read -p "Deseja configurar o Docker? (S/N) " CONFIG_DOCKER
if [ $CONFIG_DOCKER = 'S' ]; then 
    docker --version
    if [ $? = 0 ]; then 
        echo "Docker já está instalado"
        else
            echo "+==================================================================+"
            echo "Instalação de arquivos e dependencias..."
            echo "atualizando pacotes"
            apt update
            apt upgrade -y
            echo "Pacotes atualizados com sucesso"
            echo "Instalação do Docker na instancia"
            apt install docker.io -y
            echo "Docker instalado com sucesso!"
            echo "+==================================================================+"
    fi
    systemctl start docker
    systemctl enable docker
    sudo docker pull mysql:8
    sudo docker images
fi


    