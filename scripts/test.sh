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

# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #


# Testa o crontab e arquivo log    
[ ! -e "$LOG" ] && touch "$LOG" # Existe?
[ ! -x "$(which cron)" ] && apt-get install cron # Esta instalado?
systemctl status cron > "$TEMP"
[ -e "$TEMP" ] && egrep -q "inactive" $TEMP && systemctl start cron # Esta ativo?
[ -e "$TEMP" ] && egrep -q "disabled" $TEMP && systemctl enable cron # Esta para iniciar com o sistema?


# Test nginx
[ ! -x "$(which nginx)" ] && apt install nginx # Esta instalado?
systemctl status nginx > "$TEMP"
[ -e "$TEMP" ] && egrep -q "inactive" $TEMP && systemctl -q start nginx # Esta ativo?
[ -e "$TEMP" ] && egrep "disabled" $TEMP && systemctl -q enable nginx # Esta para iniciar com o sistema?

# Test html e css
[ ! -e "/var/www/html" ] && mkdir /var/www/html
[ -e "/var/www/html/*" ] && rm "/var/www/html/*" && touch "/var/www/html/index.html" # Tem algo na pasta?
[ ! -e "/var/www/html/css" ] && mkdir /var/www/html/css # Verifica se a pasta css existe
[ -e "/var/www/html/css" ] && touch "/var/www/html/css/style.css" # Tem algo na pasta?


# Test firewall

ufw status > "$TEMP"
[ -e "$TEMP" ] && egrep -q "Nginx.*HTTP" $TEMP |  grep -q 'DENY' $TEM && echo "$(ufw allow 'Nginx HTTP')" #Nginx esta DENY?

# ------------------------------------------------------------------------ #

# ------------------------------- FUNÇÕES ----------------------------------------- #
   
IniciarCrontab(){
    local SETUP_DIR
    SETUP_DIR=$(dirname "$(realpath "$0")")
    local MONITOR_PATH="$SETUP_DIR/monitor.sh"
    # Verifica se cron existe E (||) se a tarefa não existe, então a adiciona.
    [ -x "$(which cron)" ] && \
    (crontab -l 2>/dev/null | grep -qF "$MONITOR_PATH" || \
    (crontab -l 2>/dev/null; echo "* * * * * /usr/bin/flock -n /bin/bash '$MONITOR_PATH'") | crontab -)
}


IniciarCrontab

# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #

# ------------------------------------------------------------------------ #









