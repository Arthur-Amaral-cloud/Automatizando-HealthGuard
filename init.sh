#!/bin/bash

# Verificando se o usuário que está executando é root
if [ "$EUID" -ne 0 ]; 
    then
    exec sudo "$0" "$@"
fi

# CONFIGURAÇÃO DE GRUPOS E USUÁRIOS
read -p "Deseja alterar a senha do root? (S/N) " SENHA_ROOT

if [ "$SENHA_ROOT" = "S" ] || [ "$SENHA_ROOT" = "s" ]; then 
    sudo passwd root
fi

read -p "Deseja alterar a senha do ubuntu? (S/N) " SENHA_UBUNTU

if [ "$SENHA_UBUNTU" = "S" ] || [ "$SENHA_UBUNTU" = "s" ]; then 
    sudo passwd ubuntu
fi

set -e   # caso algum comando falhar ele para o script 

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

# Atribuindo os diretórios aos seus respectivos grupos
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

# Adicionando configurações de permissões de usuário
echo ""
echo "+==================================================================+"
echo "adicionando configurações de permissões de usuário..."
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

# Criando usuarios
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

# Atribuindo os usuários aos seus respectivos grupos
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


# INSTALANDO PYTHON - VERSÃO CORRIGIDA
pip3 --version
if [ $? = 0 ]; 
    then
    echo "O Python já está instalado" 
else 
    echo "Python não instalado"
    read -p "Gostaria de instalar o Python? [S/N] " get
    if [ "$get" = "S" ] || [ "$get" = "s" ]; 
        then
        apt update
        apt install python3 -y
        apt install python3-pip -y
        apt install python3-venv -y
        echo "Python instalado com sucesso!"
        pip3 --version
    else
        echo "Python não será instalado. Algumas funcionalidades podem não funcionar."
    fi
fi

# INSTALANDO O DOCKER E PUXANDO IMAGEM DO MYSQL
read -p "Deseja configurar o Docker? (S/N) " CONFIG_DOCKER
if [ "$CONFIG_DOCKER" = "S" ] || [ "$CONFIG_DOCKER" = "s" ];  
    then
    docker --version
    if [ $? = 0 ]; 
        then 
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

# CONFIGURANDO CONTAINER MYSQL E BANCO DE DADOS
read -p "Deseja configurar o container MySQL e criar o banco? (S/N) " CONFIG_MYSQL
if [ "$CONFIG_MYSQL" = "S" ] || [ "$CONFIG_MYSQL" = "s" ]; then
    
    # Parando e removendo container existente se houver
    echo "Verificando containers MySQL existentes..."
    sudo docker stop mysql-container 2>/dev/null || true
    sudo docker rm mysql-container 2>/dev/null || true
    
    # Criando container MySQL
    echo "Criando container MySQL..."
    sudo docker run -d \
        --name mysql-container \
        -e MYSQL_ROOT_PASSWORD=root123 \
        -e MYSQL_DATABASE=HealthGuard \
        -e MYSQL_USER=logan \
        -e MYSQL_PASSWORD=senha-segura123 \
        -p 3306:3306 \
        mysql:8
    
    echo "Aguardando MySQL inicializar (30 segundos)..."
    sleep 30
    
    # Criando arquivo SQL
    echo "Criando arquivo de schema do banco..."
    cat > setup-database.sql << 'EOF'
DROP DATABASE IF EXISTS HealthGuard;

CREATE DATABASE IF NOT EXISTS HealthGuard;

USE HealthGuard;

-- Label Empresa
CREATE TABLE UnidadeDeAtendimento (

idUnidadeDeAtendimento INT PRIMARY KEY AUTO_INCREMENT,

razaoSocial VARCHAR(100) 			NOT NULL,

nomeFantasia VARCHAR(100) 			DEFAULT NULL,

cnpj CHAR(14) 						NOT NULL,

unidadeGestora VARCHAR(100) 		NOT NULL
);

CREATE TABLE Endereco (

idEndereco 					INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,
CONSTRAINT pkCompostaEndereco PRIMARY KEY (idEndereco, fkUnidadeDeAtendimento),

cep CHAR(8) 				NOT NULL,

uf CHAR(2) 					NOT NULL,

cidade VARCHAR(100) 		NOT NULL,

bairro VARCHAR(100) 		NOT NULL,

logradouro VARCHAR(100) 	NOT NULL,

numero VARCHAR(45) 			NOT NULL,

complemento VARCHAR(45) 	DEFAULT NULL,

CONSTRAINT fkEnderecoUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento)
);

CREATE TABLE ContatoParaAlertas (
idContatoParaAlertas 		INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,
CONSTRAINT pkCompostaContatoParaAlertas PRIMARY KEY (idContatoParaAlertas,fkUnidadeDeAtendimento),

nome VARCHAR(100) 			NOT NULL,

cargo VARCHAR(45) 			NOT NULL,

email VARCHAR(100) 			DEFAULT NULL,

telefone CHAR(11) 			DEFAULT NULL,

disponibilidadeDeHorario 	VARCHAR(45) NOT NULL,

nivelEscalonamento 			VARCHAR(45) NOT NULL,

CONSTRAINT fkContatoParaAlertasUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento)
);

CREATE TABLE CodigoConfiguracao (
idCodigoConfiguracao 		INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,
CONSTRAINT pkCompostaCodigoValidacao PRIMARY KEY (idCodigoConfiguracao,fkUnidadeDeAtendimento),

codigo 						CHAR(20),

dataCriacao 				DATETIME DEFAULT CURRENT_TIMESTAMP,

dataExpiracao 				DATETIME DEFAULT CURRENT_TIMESTAMP,

statusCodigo 				VARCHAR(45) DEFAULT 'Pedente',
CONSTRAINT chkStatusCodigoConfiguracao CHECK (statusCodigo in('Pedente','Aceito','Expirado')),

CONSTRAINT fkCodigoConfiguracaoUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento)
);

-- Label Usuário 

CREATE TABLE Permissoes (
idPermissoes 			INT PRIMARY KEY AUTO_INCREMENT,

nome VARCHAR(100) 		NOT NULL,

descricao VARCHAR(500) 
);

CREATE TABLE CodigoValidacao (
idCodigoValidacao 			INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,

fkPermissoes				INT,

CONSTRAINT pkCompostaCodigoValidacao PRIMARY KEY (idCodigoValidacao,fkUnidadeDeAtendimento,fkPermissoes),

codigo 						CHAR(15),

dataCriacao 				DATETIME DEFAULT CURRENT_TIMESTAMP,

dataExpiracao 				DATETIME DEFAULT CURRENT_TIMESTAMP,

statusCodigo 				VARCHAR(45) DEFAULT 'Pedente',
CONSTRAINT chkStatusCodigoValidacao CHECK (statusCodigo in('Pedente','Aceito','Expirado')),

CONSTRAINT fkCodigoValidacaoUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento),
CONSTRAINT fkCodigoValidacaoPermissoes FOREIGN KEY (fkPermissoes) REFERENCES Permissoes(idPermissoes)
);

CREATE TABLE Usuario (
idUsuario 			INT AUTO_INCREMENT,

fkPermissoes 		INT,
CONSTRAINT pkCompostaUsuario PRIMARY KEY (idUsuario,fkPermissoes),

nome VARCHAR(100) 	NOT NULL,

email VARCHAR(100) 	NOT NULL,

senha VARCHAR(256) 	NOT NULL,

cpf 				CHAR(11),

CONSTRAINT fkUsuarioPermissoes FOREIGN KEY (fkPermissoes) REFERENCES Permissoes(idPermissoes)
);

CREATE TABLE LogAcesso (
idLogAcesso 				INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,

fkUsuario 					INT,
CONSTRAINT pkCompostaLogAcesso PRIMARY KEY (idLogAcesso,fkUnidadeDeAtendimento,fkUsuario),

dataAcesso 					DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fkLogAcessoUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento),
CONSTRAINT fkLogAcessoUsuario FOREIGN KEY (fkUsuario) REFERENCES Usuario(idUsuario)
);

CREATE TABLE LogAcoes (
idLogAcoes 				INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 	INT,

fkUsuario 				INT,

fkLogAcesso 			INT,
CONSTRAINT pkCompostaLogAcoes PRIMARY KEY(idLogAcoes,fkUnidadeDeAtendimento,fkUsuario,fkLogAcesso),

acao VARCHAR(100) 		NOT NULL,

horarioDaAcao 			DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fkLogAcoesUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES LogAcesso(fkUnidadeDeAtendimento),
CONSTRAINT fkLogAcoesUsuario FOREIGN KEY (fkUsuario) REFERENCES LogAcesso(fkUsuario),
CONSTRAINT fkLogAcoesLogAcesso FOREIGN KEY (fkLogAcesso) REFERENCES LogAcesso(idLogAcesso)
);

-- Label Captura

CREATE TABLE Dac (
idDac 						INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,
CONSTRAINT pkCompostaDac PRIMARY KEY (idDac,fkUnidadeDeAtendimento),

nomeDeIdentificacao 		VARCHAR(100) NOT NULL,

statusDac VARCHAR(45) 		DEFAULT 'Inativo',
CONSTRAINT chkStatusDac CHECK (statusDac in('Ativo','Inativo','Excluido')),

codigoValidacao VARCHAR(256) 	NOT NULL,

CONSTRAINT fkDacUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento)
);

CREATE TABLE MedicoesDisponiveis (
idMedicoesDisponiveis 	INT PRIMARY KEY AUTO_INCREMENT,

nomeDaMedicao 			VARCHAR(100) NOT NULL,

unidadeDeMedida 	VARCHAR(45) NOT NULL
);

CREATE TABLE MedicoesSelecionadas (
idMedicoesSelecionadas 	INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 	INT,

fkDac 					INT,

fkMedicoesDisponiveis 	INT,
CONSTRAINT pkCompostaMedicoesSelecionadas PRIMARY KEY (idMedicoesSelecionadas,fkUnidadeDeAtendimento,fkDac,fkMedicoesDisponiveis),

dataConfiguracao 		DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fkMedicoesSelecionadasUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES Dac(fkUnidadeDeAtendimento),
CONSTRAINT fkMedicoesSelecionadasDac FOREIGN KEY (fkDac) REFERENCES Dac(idDac),
CONSTRAINT fkMedicoesSelecionadasMedicoesDisponiveis FOREIGN KEY (fkMedicoesDisponiveis) REFERENCES MedicoesDisponiveis(idMedicoesDisponiveis)
);

CREATE TABLE MetricaAlerta (
idMetricaAlerta 			INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,

fkUnidadeDeAtendimentoDac 	INT,

fkDac 						INT,

fkMedicoesDisponiveis 		INT,
CONSTRAINT pkCompostaMetricaAlerta PRIMARY KEY(idMetricaAlerta,fkUnidadeDeAtendimento,fkMedicoesDisponiveis),

nomeNivel VARCHAR(45) 		NOT NULL,

valorMinimo	 				FLOAT,

valorMaximo 				FLOAT,

dataCriacao 				DATETIME DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fkMetricaAlertaUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES UnidadeDeAtendimento(idUnidadeDeAtendimento),
CONSTRAINT fkMetricaAlertaUnidadeDeAtendimentoDac FOREIGN KEY (fkUnidadeDeAtendimentoDac) REFERENCES Dac(fkUnidadeDeAtendimento),
CONSTRAINT fkMetricaAlertaDac FOREIGN KEY (fkDac) REFERENCES Dac(idDac),
CONSTRAINT fkMetricaAlerta FOREIGN KEY (fkMedicoesDisponiveis) REFERENCES MedicoesDisponiveis(idMedicoesDisponiveis)
);

CREATE TABLE Leitura (
idLeitura 					INT AUTO_INCREMENT,
fkMedicoesDisponiveis 		INT,
fkMedicoesSelecionadas 		INT,
fkDac 						INT,
fkUnidadeDeAtendimento 		INT,
CONSTRAINT pkCompostaLeitura PRIMARY KEY (idLeitura,fkMedicoesDisponiveis,fkMedicoesSelecionadas,fkDac,fkUnidadeDeAtendimento),
medidaCapturada 			VARCHAR(45) NOT NULL,
dataCaptura 				DATETIME DEFAULT CURRENT_TIMESTAMP,
fkAlerta 					INT DEFAULT NULL,
fkMetricaAlerta 			INT DEFAULT NULL,
fkMedicoesDisponiveisAlerta INT DEFAULT NULL,
fkMedicoesSelecionadasAlerta INT DEFAULT NULL,
fkDacAlerta 				INT DEFAULT NULL,
fkUnidadeDeAtendimentoAlerta INT DEFAULT NULL,

-- FOREIGN KEYS das PKS
CONSTRAINT fkLeituraMedicoesDisponiveis FOREIGN KEY (fkMedicoesDisponiveis) REFERENCES MedicoesSelecionadas(fkMedicoesDisponiveis),
CONSTRAINT fkLeituraMedicoesSelecionadas FOREIGN KEY (fkMedicoesSelecionadas) REFERENCES MedicoesSelecionadas(idMedicoesSelecionadas),
CONSTRAINT fkLeituraDac FOREIGN KEY (fkDac) REFERENCES MedicoesSelecionadas(fkDac),
CONSTRAINT fkLeituraUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES MedicoesSelecionadas(fkUnidadeDeAtendimento)
);
CREATE TABLE Alerta (
idAlerta INT AUTO_INCREMENT,

fkUnidadeDeAtendimento 		INT,

fkDac 						INT,

fkMedicoesDisponiveis 		INT,

fkMedicoesSelecionadas 		INT,

fkLeitura 					INT,
CONSTRAINT pkCompostaAlerta PRIMARY KEY (idAlerta,fkUnidadeDeAtendimento,fkDac,fkMedicoesDisponiveis,fkMedicoesSelecionadas,fkLeitura),

dataInicio 					DATETIME DEFAULT CURRENT_TIMESTAMP,

dataTermino 				DATETIME DEFAULT NULL,

CONSTRAINT fkAlertaUnidadeDeAtendimento FOREIGN KEY (fkUnidadeDeAtendimento) REFERENCES Leitura(fkUnidadeDeAtendimento),
CONSTRAINT fkAlertaDac FOREIGN KEY (fkDac) REFERENCES Leitura(fkDac),
CONSTRAINT fkMedicoesDisponiveis FOREIGN KEY (fkMedicoesDisponiveis) REFERENCES Leitura(fkMedicoesDisponiveis),
CONSTRAINT fkAlertaMedicoesSelecionadas FOREIGN KEY (fkMedicoesSelecionadas) REFERENCES Leitura(fkMedicoesSelecionadas),
CONSTRAINT fkAlertaLeitura FOREIGN KEY (fkLeitura) REFERENCES Leitura(idLeitura)
);

DROP USER IF EXISTS logan;
CREATE USER 'logan'@'%' IDENTIFIED BY 'senha-segura123';
GRANT INSERT,SELECT,UPDATE,DELETE ON HealthGuard.* TO 'logan'@'%';
FLUSH PRIVILEGES;

EOF

    # Executando o script SQL no container
    echo "Configurando banco de dados..."
    sudo docker exec -i mysql-container mysql -uroot -proot123 < setup-database.sql
    
    # Verificando se deu certo
    echo "Verificando se as tabelas foram criadas..."
    sudo docker exec mysql-container mysql -uroot -proot123 -e "USE HealthGuard; SHOW TABLES;"
    
    # Limpando arquivo temporário
    rm setup-database.sql
    
    echo "Banco de dados configurado com sucesso!"
    echo "MySQL está rodando em: localhost:3306"
    echo "Usuário: logan"
    echo "Senha: senha-segura123"
    echo "Database: HealthGuard"
fi

# CONFIGURANDO MÁQUINA DE CAPTURA 
# PARA EXECUTAR O SCRIPT DE CAPTURA EM PYTHON
# CLONANDO E CONFIGURANDO APLICAÇÃO PYTHON
echo "Configurando aplicação Python de captura..."

# Clonando o repositório se não existir
if [ ! -d "Aplicacao-Python" ]; then
    echo "Clonando repositório da aplicação Python..."
    git clone https://github.com/HealthGuard-Group/Aplicacao-Python.git
fi

# Entrando no diretório da aplicação
cd Aplicacao-Python

# CONFIGURANDO CREDENCIAIS DO BANCO
echo ''
echo "Configure as credenciais de acesso ao MySQL:"

# Loop até que as credenciais estejam corretas
while true; do
    read -p "Insira o ip do host: " HOST
    read -p "Insira o user para inserção no banco: " USER
    read -p "Insira a senha do user $USER: " SENHA
    echo ''
    read -p "Insira o database: " DATABASE
    echo ''

    # Criando arquivo .env
    cat > '.env' <<EOF
HOST_DB = '$HOST'
USER_DB = '$USER'
PASSWORD_DB = '$SENHA'
DATABASE_DB = '$DATABASE'
EOF

    echo ''
    echo 'As credenciais configuradas são:'
    echo '--------------------------------'
    cat '.env'
    echo '--------------------------------'

    read -p "As credenciais estão corretas? (S/N) " INICIAR_API

    if [ "$INICIAR_API" = "S" ] || [ "$INICIAR_API" = "s" ]; then 
        echo '.env Criado'
        break  # Sai do loop e continua o script
    else 
        echo 'RECONFIGURANDO CREDENCIAIS...'
        echo ''
        # O loop vai repetir automaticamente
    fi
done

# Configurarando ambiente virtual e dependências
echo "Configurando ambiente virtual..."
python3 -m venv venv-ambiente-Captura
source venv-ambiente-Captura/bin/activate

echo "Instalando bibliotecas..."
pip install -r requirements.txt

read -p "Deseja iniciar o programa de captura? (S/N) " START
if [ "$START" = "S" ] || [ "$START" = "s" ]; then
    echo "Iniciando captura de dados em segundo plano..."
    python insertCaptura.py &
    echo "Captura rodando em background! "
    echo "A aplicação web será iniciada a seguir..."
else
    echo "Captura não iniciada. Você pode executar manualmente depois com: python insertCaptura.py"
fi

# Saindo do diretório da aplicação
cd ..


# IMPLEMENTANDO WEB-DATA-VIZ
echo "Configurando aplicação web data-viz..."

# Criando Dockerfile para a aplicação web
cat > Dockerfile-Node << 'EOF'
FROM node:latest
WORKDIR /usr/src/app
RUN git clone https://github.com/BandTec/web-data-viz
WORKDIR /usr/src/app/web-data-viz
RUN npm install
EXPOSE 3333
CMD ["npm", "start"]
EOF

# Construindo imagem
echo "Construindo imagem Docker..."
sudo docker build -f Dockerfile-Node -t imagem-node:v1 .

# Verificando se a imagem foi criada
echo "Imagens Docker disponíveis:"
sudo docker images | grep imagem-node

# Criando e executando container
echo "Iniciando container da aplicação web..."
sudo docker run -d --name ContainerSite -p 3333:3333 imagem-node:v1

echo "Aguardando aplicação inicializar..."
sleep 10

# Verificando se o container está rodando
echo "Status do container:"
sudo docker ps | grep ContainerSite

echo "Aplicação web deve estar disponível em: http://localhost:3333"



    