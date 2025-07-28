#!/usr/bin/env bash
#
# monitor.sh - Envia Embead personalizado via webhook
#
# Autor:      Arthur Henrike L.M Gomes
# Manutenção: Arthur Henrike L.M Gomes
#
# ------------------------------------------------------------------------ #
#  Este programa irá cotar o último valor do Bitcoin com base na API xxxx
#
#  Exemplos:
#      $ ./setup.sh
#      Neste exemplo o script será executado e caso não tenha os arquivos ira criar
# ------------------------------------------------------------------------ #
# Histórico:
#
#   v1.0 21/07/2025, Arthur:
#       - Início do programa
#       - Conta com a funcionalidade VerificarStautsCode e ObterCor
# ------------------------------------------------------------------------ #
# Testado em:
#   bash 5.1.16
# ------------------------------------------------------------------------ #

# ------------------------------- VARIÁVEIS ----------------------------------------- #

TARGET_DIR="../"
# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #


# ------------------------------------------------------------------------ #

# ------------------------------- FUNÇÕES ----------------------------------------- #
CriarMonitor(){
    [ ! -e "$TARGET_DIR/monitor.sh" ] && cat <<'EOF' > "$TARGET_DIR/monitor.sh"
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
        HOST='http://localhost'
        STATUS_CODES=$(curl -s -o /dev/null -w "%{http_code}" "$HOST")
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

        export -f VerificarStatusCode

        ObterCor() {
        case $STATUS_CODES in
            2*) COR=3066993           ;;                   # Sucesso (Verde)
            4*|5*|000) COR=15158332  ;;                   # Erro (Vermelho)
            3*) COR=16776960         ;;                   # Redirecionamento (Amarelo)
            *)  COR=8359053          ;;                   # Outro (Cinza)
        esac
        }

        export -f ObterCor

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
                    "name": "Host Verificado",
                    "value": "\`http://localhost:80\`",
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
        export -f EnviarMensagem

        # ------------------------------------------------------------------------ #

        # ------------------------------- EXECUÇÃO ----------------------------------------- #
        VerificarStatusCode
        ObterCor
        EnviarMensagem
        # ------------------------------------------------------------------------ #
EOF
    chmod +x "$TARGET_DIR/monitor.sh"
}

CriarTest(){
    [ ! -e "$TARGET_DIR/test.sh" ] && cat <<'EOF' > "$TARGET_DIR/test.sh"
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
    export -f IniciarCrontab

    # ------------------------------------------------------------------------ #

    # ------------------------------- EXECUÇÃO ----------------------------------------- #

    # ------------------------------------------------------------------------ #
EOF
    chmod +x "$TARGET_DIR/test.sh"
}

CriarHtml(){
    [ -e "/var/www/html/index.html" ] && cat <<'EOF' > "/var/www/html/index.html"
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Currículo - Arthur Henrike L. M. Gomes</title>
        <link rel="stylesheet" href="css/style.css">
        <!-- Importando a biblioteca de ícones Font Awesome -->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
        <!-- Importando a fonte do Google Fonts -->
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
    </head>
    <body>

        <div class="container">
            <!-- CABEÇALHO -->
            <header class="header">
                <div class="header-info">
                    <h1>Arthur Henrike Lacerda Modesto Gomes</h1>
                    <h2>Estágio AWS e DevSecOps</h2>
                </div>
                <div class="contact-info">
                    <a href="mailto:arthurgomeslacerda123@gmail.com" target="_blank"><i class="fas fa-envelope"></i> arthurgomeslacerda123@gmail.com</a>
                    <a href="https://github.com/ArthurGomes11" target="_blank"><i class="fab fa-github"></i> ArthurGomes11</a>
                    <a href="https://www.linkedin.com/in/arthur-gomes-243413210/" target="_blank"><i class="fab fa-linkedin"></i> arthur-gomes-243413210</a>
                    <a href="tel:+5569981170723"><i class="fas fa-phone"></i> (69) 98117-0723</a>
                    <p><i class="fas fa-map-marker-alt"></i> Vilhena, Rondônia</p>
                </div>
            </header>

            <main>
                <!-- SEÇÃO SOBRE MIM -->
                <section class="card">
                    <h3>Sobre Mim</h3>
                    <p>
                        Trabalhando com infraestrutura de TI e suporte técnico desde 2024, atuo diretamente na manutenção e segurança de sistemas críticos em ambiente hospitalar, com foco em estabilidade, desempenho e proteção de dados. Tenho experiência com redes, servidores, virtualização, políticas de segurança e suporte de 1º e 2º nível. Sou motivado pela busca contínua por soluções eficientes, seguras e alinhadas às boas práticas da área, além de aplicar princípios da LGPD no tratamento de informações sensíveis. Também colaboro com a modernização de processos internos e integração entre áreas, atualmente atuando no programa de bolsa da Compass UOL com foco para a área de DevSecOps, aprendendo os mais diversos conteúdos como Linux e servidores, Docker, Kubernetes, WSL, Scrum e Agile, AWS e FinOps.
                    </p>
                </section>

                <!-- SEÇÃO EXPERIÊNCIA PROFISSIONAL -->
                <section class="card">
                    <h3>Experiência Profissional</h3>
                    <div class="experience-item">
                        <h4>DevSecOps <span class="company">| Compass UOL</span></h4>
                        <p class="date">Jul 2025 - Atual</p>
                        <p>Atuação em programa de capacitação focado em práticas DevSecOps, com as seguintes responsabilidades:</p>
                        <ul>
                            <li>Gerenciamento e otimização de ambientes em Linux e servidores.</li>
                            <li>Implementação e orquestração de Docker e Kubernetes.</li>
                            <li>Utilização de WSL (Windows Subsystem for Linux).</li>
                            <li>Aplicação de metodologias Scrum e Agile para otimização de fluxos de trabalho e entrega contínua.</li>
                            <li>Administração de serviços em AWS, com foco em otimização de custos através de princípios de FinOps.</li>
                        </ul>
                    </div>
                    <div class="experience-item">
                        <h4>Técnico em Informática <span class="company">| Hospital Cooperar Unimed</span></h4>
                        <p class="date">Jan 2024 - Jun 2025</p>
                        <p>O Hospital Cooperar Unimed é uma instituição da área da saúde que oferece atendimento médico especializado, contando com infraestrutura tecnológica de ponta para suporte clínico e administrativo. No período em que atuei na instituição, tive as seguintes responsabilidades:</p>
                        <ul>
                            <li>Instalação, configuração e manutenção de equipamentos de TI e dispositivos médicos de alta tecnologia.</li>
                            <li>Administração de servidores, redes estruturadas, acesso remoto e serviços como DHCP e GPO.</li>
                            <li>Implementação de políticas de segurança, virtualização com VMware e suporte técnico de 1º e 2º nível.</li>
                            <li>Aplicação de boas práticas da LGPD no tratamento de dados administrativos e de beneficiários.</li>
                            <li>Colaboração com áreas internas para integração de soluções e modernização de processos.</li>
                        </ul>
                    </div>
                </section>

                <!-- SEÇÃO FORMAÇÃO -->
                <section class="card">
                    <h3>Formação Acadêmica</h3>
                    <div class="education-item">
                        <h4>Análise e Desenvolvimento de Sistemas <span class="institution">| IFRO Campus Vilhena</span></h4>
                        <p class="date">Jan 2024 - Cursando</p>
                        <p>Atualmente na graduação, desenvolvi habilidades em programação com TypeScript, JavaScript e Kotlin, além de conhecimentos em sistemas Linux, versionamento com Git/GitHub/GitLab e metodologias ágeis como Scrum e Kanban. O curso de ADS proporcionou uma base sólida em desenvolvimento, infraestrutura e trabalho em equipe em projetos.</p>
                    </div>
                    <div class="education-item">
                        <h4>Técnico em Informática <span class="institution">| IFRO Campus Vilhena</span></h4>
                        <p class="date">Jan 2021 - 2023</p>
                        <p>Formação técnica com foco em manutenção de computadores e linguagens diversas de programação (MYSQL, C#, PYTHON), onde tive a oportunidade de me aprofundar em programação e ter conhecimento sobre hardware no geral.</p>
                    </div>
                </section>

                <!-- SEÇÃO SKILLS -->
                <section class="card">
                    <h3>Habilidades</h3>
                    <div class="skills-container">
                        <div class="skills-column">
                            <h4>Hard Skills</h4>
                            <ul>
                                <li>Redes (Switches, Roteadores)</li>
                                <li>GPO (Group Policy Object)</li>
                                <li>DHCP & Servidores</li>
                                <li>VMware & Virtualização</li>
                                <li>Segurança da Informação</li>
                                <li>Infraestrutura de TI</li>
                                <li>Linux & WSL</li>
                                <li>Docker & Kubernetes</li>
                                <li>AWS & FinOps</li>
                                <li>Git / GitHub / GitLab</li>
                                <li>MongoDB, TypeScript, JavaScript, Kotlin</li>
                            </ul>
                        </div>
                        <div class="skills-column">
                            <h4>Soft Skills</h4>
                            <ul>
                                <li>Trabalho em Equipe</li>
                                <li>Comunicação Sociável</li>
                                <li>Resolução de Problemas</li>
                                <li>Aprendizado Contínuo</li>
                                <li>Adaptabilidade</li>
                                <li>Proatividade</li>
                            </ul>
                        </div>
                    </div>
                </section>
            </main>

            <footer>
                <p>Arthur Henrike L. M. Gomes &copy; 2025</p>
            </footer>
        </div>

    </body>
    </html>

EOF
}

CriarStyle(){
    [ -e "/var/www/html/css/style.css" ] && cat <<'EOF' > "/var/www/html/css/style.css"
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    body {
        font-family: 'Poppins', sans-serif;
        background-color: #f8f7ff; /* Um lavanda bem claro para o fundo */
        color: #333;
        line-height: 1.6;
    }

    .container {
        max-width: 960px;
        margin: 2rem auto;
        padding: 0 1.5rem;
    }

    h1, h2, h3, h4 {
        color: #483D8B; /* Roxo-azulado escuro para os títulos principais */
        line-height: 1.2;
    }

    h1 {
        font-size: 2.2rem;
        font-weight: 700;
    }

    h2 {
        font-size: 1.5rem;
        font-weight: 400;
        color: #6A5ACD; /* Um tom de roxo mais vibrante para o subtítulo */
        margin-bottom: 1rem;
    }

    h3 {
        font-size: 1.4rem;
        font-weight: 600;
        border-bottom: 2px solid #E6E6FA; /* Linha lavanda sutil abaixo dos títulos de seção */
        padding-bottom: 0.5rem;
        margin-bottom: 1.5rem;
    }

    h4 {
        font-size: 1.1rem;
        font-weight: 600;
        color: #333;
    }

    a {
        color: #6A5ACD; /* Roxo para links */
        text-decoration: none;
        transition: color 0.3s ease;
    }

    a:hover {
        color: #836FFF; /* Um tom mais claro de roxo para o hover */
    }

    /* --- CARD PADRÃO PARA SEÇÕES --- */
    .card {
        background-color: #ffffff;
        border-radius: 8px;
        padding: 2rem;
        margin-bottom: 2rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    }

    /* --- CABEÇALHO --- */
    .header {
        text-align: center;
        margin-bottom: 3rem;
    }

    .header-info {
        margin-bottom: 1.5rem;
    }

    .contact-info {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 1rem 2rem; /* Espaçamento entre os itens */
        font-size: 0.95rem;
    }

    .contact-info a, .contact-info p {
        color: #555;
        display: flex;
        align-items: center;
        gap: 0.5rem; /* Espaço entre o ícone e o texto */
    }

    .contact-info a:hover {
        color: #6A5ACD;
    }

    /* --- SEÇÃO EXPERIÊNCIA E FORMAÇÃO --- */
    .experience-item, .education-item {
        margin-bottom: 2rem;
    }

    .experience-item:last-child, .education-item:last-child {
        margin-bottom: 0;
    }

    .company, .institution {
        font-weight: 400;
        color: #555;
    }

    .date {
        font-size: 0.9rem;
        color: #777;
        margin-bottom: 0.5rem;
    }

    ul {
        list-style-position: inside;
        padding-left: 1rem;
    }

    li {
        margin-bottom: 0.5rem;
    }

    /* --- SEÇÃO SKILLS --- */
    .skills-container {
        display: flex;
        justify-content: space-between;
        gap: 2rem;
    }

    .skills-column {
        width: 48%;
    }

    .skills-column h4 {
        margin-bottom: 1rem;
        color: #483D8B;
    }

    /* --- RODAPÉ --- */
    footer {
        text-align: center;
        padding: 1.5rem 0;
        color: #888;
        font-size: 0.9rem;
    }

    /* --- RESPONSIVIDADE PARA CELULARES --- */
    @media (max-width: 768px) {
        .container {
            margin: 1rem auto;
            padding: 0 1rem;
        }

        h1 {
            font-size: 1.8rem;
        }

        h2 {
            font-size: 1.3rem;
        }

        .contact-info {
            flex-direction: column;
            align-items: center;
            gap: 0.8rem;
        }

        .skills-container {
            flex-direction: column;
        }

        .skills-column {
            width: 100%;
        }
    }
EOF
}
# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #

CriarMonitor
CriarTest

# ------------------------------------------------------------------------ #
