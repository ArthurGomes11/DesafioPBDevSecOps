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

# CORREÇÃO CRÍTICA: Liberar a porta SSH (22) ANTES de ativar o firewall.
sudo ufw allow ssh
sudo ufw allow 'Nginx HTTP'
sudo ufw --force enable
# ------------------------------------------------------------------------ #
# ------------------------------- VARIÁVEIS ----------------------------------------- #
LOG="/var/log/monitoramento.log"
# CORREÇÃO: Caminho absoluto e explícito para os scripts para maior robustez.
# O usuário padrão no Ubuntu da AWS é 'ubuntu'.
TARGET_DIR="/home/ubuntu/scripts"


# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #
# Garante que o diretório de scripts exista e pertence ao usuário correto
mkdir -p "$TARGET_DIR"
sudo chown ubuntu:ubuntu "$TARGET_DIR"

# Cria o arquivo de log
[ ! -e "$LOG" ] && sudo touch "$LOG" && sudo chmod 666 "$LOG"

# (O restante dos testes é bom, mas a configuração inicial já cuida deles)

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
# test.sh - Configura cron para o monitoramento
#

# --- Variáveis ---
LOG="/var/log/monitoramento.log"
TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# --- Funções ---
IniciarCrontab(){
    local MONITOR_PATH="$SCRIPT_DIR/monitor.sh"
    # Adiciona a tarefa ao crontab se ela ainda não existir, usando flock.
    if ! (sudo crontab -l 2>/dev/null | grep -qF "$MONITOR_PATH"); then
        (sudo crontab -l 2>/dev/null; echo "* * * * * /usr/bin/flock -xn $MONITOR_PATH -c \"/bin/bash $MONITOR_PATH\" &>> $LOG") | sudo crontab -
    fi
}

# --- Execução ---
IniciarCrontab
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
