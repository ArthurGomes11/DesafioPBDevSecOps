#!/usr/bin/env bash
#
# monitor.sh - Envia mensagem Embed personalizada via webhook
#
# Autor:      Arthur Henrike L.M Gomes
# Manutenção: Arthur Henrike L.M Gomes
#
# ------------------------------------------------------------------------ #
#  Este programa envia uma notificação para o Discord com o status
#  de um serviço web verificado.
#
#  Exemplos:
#      $ ./monitor.sh
#      Neste exemplo, o script será executado e, se estiver correto,
#      seu webhook deve enviar uma mensagem via Discord.
# ------------------------------------------------------------------------ #
# Histórico:
#
#   v1.0 22/07/2025, Arthur:
#       - Início do programa
#       - Conta com as funcionalidades VerificarStatusCode e ObterCor
# ------------------------------------------------------------------------ #
# Testado em:
#   bash 5.1.16
# ------------------------------------------------------------------------ #


# ------------------------------- VARIÁVEIS ----------------------------------------- #

DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$DIR/../.env"
COR=0
MENSAGEM=""
DATA=$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')
STATUS_CODES=$(curl -s -o /dev/null -w "%{http_code}" "$URL_SERVIDOR")
URL=""
LOG="/var/log/monitoramento.log"

# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #

# ------------------------------------------------------------------------ #

# ------------------------------- FUNÇÕES ----------------------------------------- #
VerificarStatusCode() {
  case $STATUS_CODES in
    000) MENSAGEM="Servidor Nginx está fora do ar devido ao erro de rede verifique sua conexão $STATUS_CODES"
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    200) MENSAGEM="Servidor Nginx está funcionando com Status code $STATUS_CODES"
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    201) MENSAGEM="Criado: A requisição foi bem-sucedida e um novo recurso foi criado."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    202) MENSAGEM="Aceito: A requisição foi aceita para processamento."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    204) MENSAGEM="Sem conteúdo: O servidor processou a requisição com sucesso, mas não há conteúdo para enviar."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    301) MENSAGEM="Movido permanentemente: O recurso solicitado foi movido permanentemente para uma nova URL."
          echo "Status code: $STATUS_CODES" >> $LOG
            
        ;;
    302) MENSAGEM="Encontrado (Redirecionamento temporário): O recurso solicitado está temporariamente em uma URL diferente."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    304) MENSAGEM="Não modificado: O recurso solicitado não foi modificado desde a última requisição."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    400) MENSAGEM="Requisição inválida: O servidor não pode ou não irá processar a requisição devido a um erro do cliente."
          echo "Status code: $STATUS_CODES" >> $LOG
       ;;
    404) MENSAGEM="Rota não encontrada: Status code $STATUS_CODES"
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    500) MENSAGEM="Erro interno do servidor: O servidor encontrou uma condição inesperada que o impediu de atender à requisição."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    504) MENSAGEM="Gateway Timeout: O servidor, enquanto atuava como gateway ou proxy, não recebeu uma resposta a tempo do servidor upstream."
          echo "Status code: $STATUS_CODES" >> $LOG
        ;;
    *) MENSAGEM="Código de status HTTP não reconhecido: $STATUS_CODES" echo "Status code: $STATUS_CODES" >> $LOG
        ;;
  esac
}



ObterCor() {
  case $STATUS_CODES in
      2*) COR=3066993           ;;                   # Sucesso (Verde)
      4*|5*|000) COR=15158332  ;;                   # Erro (Vermelho)
      3*) COR=16776960         ;;                   # Redirecionamento (Amarelo)
      *)  COR=8359053          ;;                   # Outro (Cinza)
  esac
}



EnviarMensagem() {
  JSON=$(cat <<EOF
  {
    "embeds": [
      {
        "title": "STATUS CODE",
        "description": "$STATUS_CODES",
        "color": $COR,
        "author": {
          "name": "Relatório de Disponibilidade"
        },
        "fields": [
          {
            "name": " Verificado",
            "value": "\`http://$URL_SERVIDOR:80\`",
            "inline": false
          },
          {
            "name": "Status Code",
            "value": "**\`\`\`$STATUS_CODES\`\`\`**",
            "inline": true
          },
          {
            "name": "Origem da Verificação",
            "value": "🇧🇷 Vilhena, Brasil",
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
EOF
)
  curl -X POST -H "Content-Type: application/json" -d "$JSON" "$WEBHOOK_URL"
}


# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #
VerificarStatusCode
ObterCor
EnviarMensagem


# ------------------------------------------------------------------------ #