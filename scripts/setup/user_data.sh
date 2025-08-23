#!/usr/bin/env bash
#
# user.sh - Envia código via user-data via aws
#
# Autor:      Arthur Henrike L.M Gomes
# Manutenção: Arthur Henrike L.M Gomes
#
# ------------------------------------------------------------------------ #
#  Este programa irá criar automaticamente os arquivos monitor.sh, test.sh, index.html e style.css
# ------------------------------------------------------------------------ #

# ------------------------------- SETUP INICIAL DO SISTEMA ----------------------------------------- #
# Instalação de dependências.
sudo apt-get update -y
sudo apt-get install -y curl cron nginx ufw

# Garante permissões corretas para o diretório web
sudo mkdir -p /var/www/html/css
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Inicia e habilita cron e nginx
sudo systemctl start cron || true
sudo systemctl enable cron || true
sudo systemctl start nginx || true
sudo systemctl enable nginx || true

# Libera a porta ssh para conecxão 
sudo ufw allow ssh
sudo ufw allow 'Nginx HTTP'
sudo ufw --force enable
# ------------------------------------------------------------------------ #
# ------------------------------- VARIÁVEIS ----------------------------------------- #
LOG="/var/log/monitoramento.log"
TARGET_DIR="/home/ubuntu/scripts"


# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #

mkdir -p "$TARGET_DIR"
sudo chown ubuntu:ubuntu "$TARGET_DIR"

# Cria o arquivo de log
[ ! -e "$LOG" ] && sudo touch "$LOG" && sudo chmod 666 "$LOG"


# --------------------------------------------------------------------------------- #



# ------------------------------- FUNÇÕES ----------------------------------------- #
CriarMonitor() {
    cat <<'EOF' > "$TARGET_DIR/monitor.sh"
#!/usr/bin/env bash
#
# monitor.sh - Envia mensagem Embed personalizada via webhook
#

# --- Variáveis ---
TARGET_DIR="/home/ubuntu/scripts" # Confirme que este caminho é o mesmo que no user-data.sh
source "$TARGET_DIR/.env" # Carrega WEBHOOK_URL
COR=0
MENSAGEM=""
DATA=$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')

STATUS_CODES=$(curl -s -o /dev/null -w "%{http_code}" "$URL_SERVIDOR")
URL_IMAGEM="https://cdn.futura-sciences.com/buildsv6/images/largeoriginal/c/f/b/cfb0ad9812_72314_http.jpg"
LOG="/var/log/monitoramento.log"

# --- Funções ---
VerificarStatusCode() {
    case $STATUS_CODES in
        000) MENSAGEM="Servidor Nginx está fora do ar. Erro de rede/serviço inalcançável." ;;
        200) MENSAGEM="Servidor Nginx está funcionando." ;;
        201) MENSAGEM="Criado: A requisição foi bem-sucedida e um novo recurso foi criado." ;;
        202) MENSAGEM="Aceito: A requisição foi aceita para processamento." ;;
        204) MENSAGEM="Sem conteúdo: O servidor processou a requisição com sucesso, mas não há conteúdo para enviar." ;;
        301) MENSAGEM="Movido permanentemente: O recurso solicitado foi movido permanentemente para uma nova URL." ;;
        302) MENSAGEM="Encontrado (Redirecionamento temporário): O recurso solicitado está temporariamente em uma URL diferente." ;;
        304) MENSAGEM="Não modificado: O recurso solicitado não foi modificado desde a última requisição." ;;
        400) MENSAGEM="Requisição inválida: Erro do cliente." ;;
        404) MENSAGEM="Rota não encontrada." ;;
        500) MENSAGEM="Erro interno do servidor." ;;
        504) MENSAGEM="Gateway Timeout: O servidor não recebeu uma resposta a tempo." ;;
        *) MENSAGEM="Código de status HTTP não reconhecido: $STATUS_CODES" ;;
    esac
    echo "$(date): Status code: $STATUS_CODES - $MENSAGEM" >> "$LOG"
}

ObterCor() {
    case $STATUS_CODES in
        2*) COR=3066993        ;;
        4*|5*|000) COR=15158332 ;;
        3*) COR=16776960       ;;
        *)  COR=8359053        ;;
    esac
}

EnviarMensagem() {
    if [ -z "$WEBHOOK_URL" ] || [ "$WEBHOOK_URL" == "COLOQUE_SEU_WEBHOOK_DO_DISCORD_AQUI" ]; then
        return 1
    fi

    JSON=$(cat <<_EOF_
{
    "embeds": [
    {
        "title": "RELATÓRIO DE DISPONIBILIDADE DO SERVIDOR",
        "description": "Verificação do Status HTTP do Host",
        "color": $COR,
        "author": {
            "name": "Monitoramento Automático EC2"
        },
        "fields": [
        {
            "name": "Host Verificado",
            "value": "\`http://$URL_SERVIDOR\`",
            "inline": false
        },
        {
            "name": "Status Code",
            "value": "**$STATUS_CODES**",
            "inline": true
        },
        {
            "name": "Mensagem",
            "value": "$MENSAGEM",
            "inline": false
        },
        {
            "name": "Origem da Verificação",
            "value": "🇧🇷 Vilhena, Brasil (EC2)",
            "inline": false
        }
        ],
        "image": {
        "url": "$URL_IMAGEM"
        },
        "thumbnail": {
        "url": "https://cdn.futura-sciences.com/buildsv6/images/largeoriginal/c/f/b/cfb0ad9812_72314_http.jpg"
        },
        "timestamp": "$DATA"
    }
    ]
}
_EOF_
)
    curl -X POST -H "Content-Type: application/json" -d "$JSON" "$WEBHOOK_URL" &>> "$LOG"
}

# --- Execução ---
VerificarStatusCode
ObterCor
EnviarMensagem
EOF
    chmod +x "$TARGET_DIR/monitor.sh"
}

CriarTest() {
    cat <<'EOF' > "$TARGET_DIR/test.sh"
#!/usr/bin/env bash
# test.sh - Instala as dependências necessárias
#
# Autor:      Arthur Henrike L.M Gomes
# Manutenção: Arthur Henrike L.M Gomes
#
# ------------------------------------------------------------------------ #
#  Este programa verifica e instala as dependências necessárias para a
#  correta execução dos scripts de monitoramento.
#
#  Exemplos:
#      $ ./test.sh
#      Neste exemplo, o script será executado e, se alguma dependência
#      estiver faltando, ela será instalada automaticamente.
# ------------------------------------------------------------------------ #
# Histórico:
#
#   v1.0 21/07/2025, Arthur:
#       - Início do programa
#       - Conta com a funcionalidade de configurar o crontab
# ------------------------------------------------------------------------ #
# Testado em:
#   bash 5.1.16
# ------------------------------------------------------------------------ #

# ------------------------------- VARIÁVEIS ----------------------------------------- #
LOG="/var/log/monitoramento.log"
TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #



# Testa o crontab e arquivo log
[ ! -e "$LOG" ] && touch "$LOG" # Existe?
# Instala cron de forma universal
[ ! -x "$(which cron)" ] && apt-get install cron # Esta instalado?
systemctl status cron > "$TEMP"
[ -e "$TEMP" ] && egrep -q "inactive" "$TEMP" && systemctl "start" "cron"
[ -e "$TEMP" ] && egrep -q "disabled" "$TEMP" && systemctl "enable" "cron"

# Test nginx
[ ! -x "$(which nginx)" ] && sudo apt install nginx # Esta instalado?
systemctl status nginx > "$TEMP"
[ -e "$TEMP" ] && egrep -q "inactive" "$TEMP" && systemctl "start" "nginx"
[ -e "$TEMP" ] && egrep -q "disabled" "$TEMP" && systemctl "enable" "nginx"

# Test html e css
[ ! -e "/var/www/html" ] && mkdir -p /var/www/html
[ ! -e "/var/www/html/css" ] && mkdir -p /var/www/html/css
[ ! -e "/var/www/html/index.html" ] && touch "/var/www/html/index.html"
[ ! -e "/var/www/html/css/style.css" ] && touch "/var/www/html/css/style.css"

# Test firewall
ufw status > "$TEMP"
[ -e "$TEMP" ] && egrep -q "Nginx.*HTTP" $TEMP |  grep -q 'DENY' $TEM && echo "$(ufw allow 'Nginx HTTP')" #Nginx esta DENY?

# ------------------------------------------------------------------------ #

# ------------------------------- FUNÇÕES ----------------------------------------- #
   
IniciarCrontab(){
    local SETUP_DIR
    SETUP_DIR=$(dirname "$(realpath "$0")")
    local MONITOR_PATH="$SETUP_DIR/monitor.sh"
    [ -x "$(which cron)" ] && \
    (crontab -l 2>/dev/null | grep -qF "$MONITOR_PATH" || \
    (crontab -l 2>/dev/null; echo "* * * * * /usr/bin/flock -n /bin/bash '$MONITOR_PATH'") | crontab -)
}



# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #

IniciarCrontab


# ------------------------------------------------------------------------ #
EOF
    chmod +x "$TARGET_DIR/test.sh"
}

CriarHtml() {
    cat <<'EOF' | sudo tee "/var/www/html/index.html" > /dev/null
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Status - Arthur Henrike L. M. Gomes</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <h1>Servidor Nginx em Funcionamento!</h1>
    <p>Esta página está sendo servida pela sua instância EC2.</p>
</body>
</html>
EOF
}

CriarStyle() {
    cat <<'EOF' | sudo tee "/var/www/html/css/style.css" > /dev/null
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Poppins', sans-serif;
    background-color: #f8f7ff;
    color: #333;
    line-height: 1.6;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    text-align: center;
}

h1 {
    color: #4a4a4a;
    margin-bottom: 20px;
}

p {
    color: #666;
    font-size: 1.1em;
}
EOF
}

CriarEnv() {
    # Cria o .env apenas se não existir.
    [ ! -e "$TARGET_DIR/.env" ] && cat <<EOF > "$TARGET_DIR/.env"
WEBHOOK_URL="COLOQUE_SEU_WEBHOOK_DO_DISCORD_AQUI"
URL_SERVIDOR="COLOQUE O IP PUBLICO DA EC2 AQUI"
EOF
}




# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #

CriarMonitor
CriarTest
CriarHtml
CriarStyle
CriarEnv

# ------------------------------------------------------------------------ #
