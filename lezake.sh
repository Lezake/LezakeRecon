#!/bin/bash
set -eo pipefail

# === Códigos de cor ANSI ===
GRAY_LIGHT='\e[37m'      # Cor cinza claro (texto comum)
GRAY_DARK='\e[90m'       # Cor cinza escuro (linhas e detalhes)
PURPLE='\e[1;35m'        # Cor ROXO brilhante (para o banner)
BOLD_ON='\e[1m'          # Ativa o negrito
BOLD_OFF='\e[22m'        # Desativa o negrito explicitamente
RESET='\e[0m'            # Reseta cor e estilo

# === Versão atual do script ===
SCRIPT_VERSION="1.9.9"

# === Verificação de atualização remota ===
verificar_versao_remota() {
  # Mantida a URL original conforme solicitado
  remote_version=$(curl -s https://raw.githubusercontent.com/Lezake/LezakeRecon/refs/heads/main/version.txt  )
  [[ -z "$remote_version" ]] && return
  if [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
    # Aplica cinza claro e desativa negrito explicitamente
    echo -e "${GRAY_LIGHT}${BOLD_OFF}⚠️ Atualização disponível para Lezake (de ${SCRIPT_VERSION} → ${remote_version}).${RESET}"
    exit 1
  fi
}

# === Funções de animação ===
loading_animation() {
  local chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while :; do
    for c in "${chars[@]}"; do
      # Aplica cinza claro e desativa negrito explicitamente
      echo -ne "\r${GRAY_LIGHT}${BOLD_OFF}⏳ Coletando... $c${RESET}"
      sleep 0.1
    done
  done
}

# === Banner Lezake (arte ASCII em ROXO - Versão com ░ substituído - CORRIGIDO) ===
show_banner() {
  clear
  # Exibe o banner na cor ROXA brilhante definida no início
  echo -e "${PURPLE}"
  cat << 'EOF'
 █████                                     █████
░░███                                     ░░███
 ░███         ██████   █████████  ██████   ░███ █████  ██████
 ░███        ███░░███ ░█░░░░███  ░░░░░███  ░███░░███  ███░░███
 ░███       ░███████  ░   ███░    ███████  ░██████░  ░███████
 ░███      █░███░░░     ███░   █ ███░░███  ░███░░███ ░███░░░
 ███████████░░██████   █████████░░████████ ████ █████░░██████
░░░░░░░░░░░  ░░░░░░   ░░░░░░░░░  ░░░░░░░░ ░░░░ ░░░░░  ░░░░░░
EOF
  echo -e "${RESET}"
  # Centraliza o nome de usuário, mantém em cinza para contraste, com @leo_zmns em negrito
  printf '%50s\n' "@leo_zmns" | sed "s/.*/$(echo -e "${GRAY_LIGHT}${BOLD_OFF}")&$(echo -e "${RESET}")/" | sed "s/@leo_zmns/$(echo -e "${BOLD_ON}")@leo_zmns$(echo -e "${RESET}")/"
  # Linha horizontal em cinza escuro para finalizar o cabeçalho
  echo -e "${GRAY_DARK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# === Verificação e instalação automática de dependências ===
verificar_instalar_dependencias() {
  # Verifica primeiro se o Go está instalado
  if ! command -v go &> /dev/null; then
    echo -e "${GRAY_LIGHT}${BOLD_OFF}❌ Erro Crítico: A linguagem Go não está instalada ou não está no PATH.${RESET}"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}    O Lezake depende do Go para instalar suas ferramentas.${RESET}"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}    Por favor, instale o Go e tente novamente.${RESET}"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}    Instruções de instalação: https://go.dev/doc/install    ${RESET}"
    exit 1
  fi

  # Verifica e instala curl, wget, unzip se necessário
  local system_deps=("curl" "wget" "unzip")
  for dep in "${system_deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      if command -v apt-get &> /dev/null; then
        if ! sudo apt-get update &> /dev/null || ! sudo apt-get install -y "$dep" &> /dev/null; then
          echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Falha ao instalar $dep.   ${RESET}"
          echo -e "${GRAY_LIGHT}${BOLD_OFF}    Por favor, instale $dep manualmente e tente novamente.${RESET}"
          exit 1
        fi
      elif command -v yum &> /dev/null; then
        if ! sudo yum install -y "$dep" &> /dev/null; then
          echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Falha ao instalar $dep.   ${RESET}"
          echo -e "${GRAY_LIGHT}${BOLD_OFF}    Por favor, instale $dep manualmente e tente novamente.${RESET}"
          exit 1
        fi
      elif command -v pacman &> /dev/null; then
        if ! sudo pacman -S --noconfirm "$dep" &> /dev/null; then
          echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Falha ao instalar $dep.   ${RESET}"
          echo -e "${GRAY_LIGHT}${BOLD_OFF}    Por favor, instale $dep manualmente e tente novamente.${RESET}"
          exit 1
        fi
      else
        echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Sistema não suportado para instalação automática de $dep.${RESET}"
        echo -e "${GRAY_LIGHT}${BOLD_OFF}    Por favor, instale $dep manualmente e tente novamente.${RESET}"
        exit 1
      fi
      echo -e "\r${GRAY_LIGHT}${BOLD_OFF}✅ $dep instalado com sucesso!${RESET}"
    fi
  done

  # Garante que o diretório de binários do Go exista
  mkdir -p "$HOME/go/bin"

  # Verifica se o PATH precisa ser atualizado e o atualiza para a sessão atual
  local path_needs_update=false
  if [[ ":$PATH:" != ":$HOME/go/bin:"* ]]; then
    path_needs_update=true
    export PATH="$PATH:$HOME/go/bin"
  fi

  declare -A ferramentas=(
    ["subfinder"]="go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    ["chaos"]="go install github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
    ["assetfinder"]="go install github.com/tomnomnom/assetfinder@latest"
    ["github-subdomains"]="go install github.com/gwen001/github-subdomains@latest"
    ["amass"]="go install github.com/owasp-amass/amass/v4/...@latest"
  )

  local tools_installed=false
  for tool in "${!ferramentas[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      tools_installed=true
      if ! eval "${ferramentas[$tool]}" > /dev/null 2>&1; then
        echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Falha ao instalar $tool.   ${RESET}"
        echo -e "${GRAY_LIGHT}${BOLD_OFF}    Verifique sua conexão com a internet e tente novamente.${RESET}"
        exit 1
      fi
      echo -e "\r${GRAY_LIGHT}${BOLD_OFF}✅ $tool instalado com sucesso!${RESET}"
    fi
  done

  if ! command -v findomain &> /dev/null; then
    temp_dir=$(mktemp -d)

    if ! ( wget -q "https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip    " -O "$temp_dir/findomain.zip" && \
           unzip -qq "$temp_dir/findomain.zip" -d "$temp_dir" && \
           chmod +x "$temp_dir/findomain" && \
           mkdir -p "$HOME/go/bin" && \
           mv "$temp_dir/findomain" "$HOME/go/bin/" ); then
        echo -e "\r${GRAY_LIGHT}${BOLD_OFF}[❌] Falha ao instalar findomain.${RESET}"
        rm -rf "$temp_dir"
        exit 1
    fi

    rm -rf "$temp_dir"
    tools_installed=true
    echo -e "\r${GRAY_LIGHT}${BOLD_OFF}✅ findomain instalado com sucesso!${RESET}"
  fi

  # Se alguma ferramenta foi instalada E o PATH do usuário não estava configurado
  if [ "$tools_installed" = true ] && [ "$path_needs_update" = true ]; then
    echo -e "\n${GRAY_LIGHT}${BOLD_OFF}⚠️ Atenção: Para que as ferramentas funcionem permanentemente, seu PATH precisa ser atualizado.${RESET}"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}    Execute o comando abaixo e reinicie seu terminal:${RESET}"

    # Suporte ao Fish Shell para instrução do PATH
    if [[ "$SHELL" == */fish ]]; then
        echo -e "${GRAY_LIGHT}${BOLD_OFF}    fish_add_path \$HOME/go/bin${RESET}"
    else
        echo -e "${GRAY_LIGHT}${BOLD_OFF}    echo 'export PATH=\$PATH:\$HOME/go/bin' >> ~/.bashrc${RESET}"
        echo -e "${GRAY_LIGHT}${BOLD_OFF}    (Se você usa ZSH ou outro shell, ajuste o comando para ~/.zshrc ou equivalente).${RESET}"
    fi
  fi
}

# --- Variáveis Globais e Limpeza ---
declare -g pid=""
declare -g output_dir=""
declare -g alvo=""
declare -g ghtoken=""
declare -g pdcp_api_key=""

# Função de limpeza a ser executada na saída do script
cleanup() {
  # Garante que o processo de animação seja finalizado
  if [[ -n "$pid" ]]; then
    kill "$pid" &> /dev/null
    wait "$pid" 2>/dev/null || true
  fi
  # Remove o diretório temporário se ele foi criado
  if [[ -n "$output_dir" && -d "$output_dir" ]]; then
    rm -rf "$output_dir"
  fi
  # Remove o arquivo de configuração do Amass
  rm -f amass_config.yaml
}
# Registra a função de limpeza para ser executada em qualquer saída do script
trap cleanup EXIT


# === Funções Refatoradas para Descoberta de Subdomínios ===

# Helper para salvar chaves de API de forma permanente no arquivo de configuração do shell
save_key_permanently() {
  local key_name="$1"
  local key_value="$2"
  local shell_config_file=""

  # Suporte ao Fish Shell para identificar o arquivo de config correto
  if [[ "$SHELL" == */zsh ]]; then
    shell_config_file="$HOME/.zshrc"
  elif [[ "$SHELL" == */bash ]]; then
    shell_config_file="$HOME/.bashrc"
  elif [[ "$SHELL" == */fish ]]; then
    shell_config_file="$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"
  else
    echo -e "${GRAY_LIGHT}${BOLD_OFF}⚠️ Shell não suportado para salvamento automático. Configure a variável de ambiente manualmente.${RESET}"
    return
  fi

  # Garante que o arquivo de configuração exista
  touch "$shell_config_file"

  # Verifica se a chave já está definida no arquivo para decidir entre atualizar ou adicionar
  if grep -q "export ${key_name}=" "$shell_config_file"; then
    # A chave existe, então vamos ATUALIZAR a linha existente
    echo -e "${GRAY_LIGHT}${BOLD_OFF}⏳ Chave ${key_name} já existe. Atualizando com o novo valor em ${shell_config_file}...${RESET}"
    # Usa sed para substituir a linha. Cria um backup (.bak) por segurança.
    sed -i.bak "s|^export ${key_name}=.*|export ${key_name}=\"${key_value}\"|" "$shell_config_file"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ Chave atualizada! Por favor, reinicie seu terminal ou execute 'source ${shell_config_file}' para aplicar.${RESET}"
  else
    # A chave não existe, então vamos ADICIONAR
    echo -e "${GRAY_LIGHT}${BOLD_OFF}⏳ Adicionando ${key_name} ao seu ${shell_config_file}...${RESET}"
    # Adiciona o comando de exportação ao final do arquivo
    echo -e "\n# Adicionado pelo script Lezake para automação de chaves de API\nexport ${key_name}=\"${key_value}\"" >> "$shell_config_file"
    echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ Chave salva com sucesso! Por favor, reinicie seu terminal ou execute 'source ${shell_config_file}' para aplicar a mudança.${RESET}"
  fi
}


# Coleta e valida o domínio alvo e os tokens necessários.
get_user_input() {
  while true;
 do
    echo -ne "${GRAY_LIGHT}${BOLD_OFF}🔍 Digite o domínio alvo: ${RESET}"
    read alvo
    if [[ "$alvo" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      break
    else
      echo -e "${GRAY_LIGHT}${BOLD_OFF}! Domínio inválido. Por favor, insira um domínio válido (ex: google.com).${RESET}"
    fi
  done

  validar_github_token() {
    # Retorna 1 se o token for vazio para evitar chamada de API desnecessária
    [[ -z "$1" ]] && return 1
    status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $1" https://api.github.com/user    )
    [[ $status == "200" ]]
  }

  # --- Lógica para GitHub Token ---
  ghtoken_valido=false
  # 1. Tenta usar a variável de ambiente primeiro
  if [[ -n "$GITHUB_TOKEN" ]]; then
    echo -e "${GRAY_LIGHT}${BOLD_OFF}🛠️ Verificando GitHub Token...${RESET}"
    if validar_github_token "$GITHUB_TOKEN"; then
      ghtoken=$GITHUB_TOKEN
      ghtoken_valido=true
      echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ GitHub Token válido!${RESET}"
    else
      echo -e "${GRAY_LIGHT}${BOLD_OFF}❌ O GitHub Token é inválido.${RESET}"
    fi
  fi

  # 2. Se o token não for válido, entra no loop para pedir ao usuário
  if ! $ghtoken_valido; then
    while true; do
      # Mensagem pedindo API do Github em cinza claro
      echo -ne "${GRAY_LIGHT}${BOLD_OFF}🔑 Digite seu GitHub Token (a entrada ficará oculta): ${RESET}"
      read -s ghtoken
      echo

      if validar_github_token "$ghtoken"; then
        echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ GitHub Token válido!${RESET}"
        # Pergunta se quer salvar o novo token válido
        echo -ne "${GRAY_LIGHT}${BOLD_OFF}❔ Deseja salvar este token permanentemente em seu shell para uso futuro? (s/n): ${RESET}"
        read -r save
        if [[ $save == "s" ]]; then
          save_key_permanently "GITHUB_TOKEN" "$ghtoken"
        fi
        break # Sai do loop de entrada do usuário
      else
        echo -e "${GRAY_LIGHT}${BOLD_OFF}❌ GitHub Token inválido. Tente novamente.${RESET}"
      fi
    done
  fi

  validar_chaos_token() {
    [[ -z "$1" ]] && return 1
    # URL CORRIGIDA: Sem espaços extras antes de $alvo
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $1" "https://dns.projectdiscovery.io/dns/$alvo/subdomains")
    [[ $code == "200" ]]
}

  # --- Lógica para Chaos API Key ---
  pdcp_api_key_valido=false
  # 1. Tenta usar a variável de ambiente
  if [[ -n "$PDCP_API_KEY" ]]; then
    echo -e "${GRAY_LIGHT}${BOLD_OFF}🛠️ Verificando Chaos API Key...${RESET}"
    if validar_chaos_token "$PDCP_API_KEY"; then
      pdcp_api_key=$PDCP_API_KEY
      pdcp_api_key_valido=true
      echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ Chaos API Key válida!${RESET}"
    else
      echo -e "${GRAY_LIGHT}${BOLD_OFF}❌ A Chaos key é inválida.${RESET}"
    fi
  fi

  # 2. Se a chave não for válida, entra no loop para pedir ao usuário
  if ! $pdcp_api_key_valido; then
    while true; do
      # Mensagem pedindo API do Chaos em cinza claro
      echo -ne "${GRAY_LIGHT}${BOLD_OFF}🔑 Digite sua PDCP_API_KEY do Chaos (a entrada ficará oculta): ${RESET}"
      read -s pdcp_api_key
      echo

      if validar_chaos_token "$pdcp_api_key"; then
        echo -e "${GRAY_LIGHT}${BOLD_OFF}✅ Chaos API Key válida!${RESET}"
        # Pergunta se quer salvar a nova chave válida
        echo -ne "${GRAY_LIGHT}${BOLD_OFF}❔ Deseja salvar esta chave permanentemente em seu shell para uso futuro? (s/n): ${RESET}"
        read -r save
        if [[ $save == "s" ]]; then
          save_key_permanently "PDCP_API_KEY" "$pdcp_api_key"
        fi
        break # Sai do loop de entrada do usuário
      else
        echo -e "${GRAY_LIGHT}${BOLD_OFF}❌ Chaos key inválida. Tente novamente.${RESET}"
      fi
    done
  fi

  # Exporta a chave final e válida para que as ferramentas a utilizem
  export PDCP_API_KEY="$pdcp_api_key"
}


# Executa as ferramentas de reconhecimento em paralelo, divididas em grupos.
run_recon_tools() {
  echo -e "${GRAY_DARK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  loading_animation & pid=$!

  output_dir=$(mktemp -d)

  run_recon_tool() {
    local tool_name="$1"
    local log_file="$output_dir/${tool_name}.log"
    local command_to_run=""

    case "$tool_name" in
      "subfinder")   command_to_run="subfinder -d $alvo -all -silent -o $output_dir/subs_subfinder.txt" ;;
      "chaos")       command_to_run="chaos -d $alvo -silent -o $output_dir/subs_chaos.txt" ;;
      "assetfinder") command_to_run="assetfinder --subs-only $alvo > $output_dir/subs_assetfinder.txt" ;;
      "findomain")   command_to_run="findomain -t $alvo -q -u $output_dir/subs_findomain.txt" ;;
      "amass")       command_to_run="amass enum -passive -config amass_config.yaml -d $alvo -silent -timeout 10 -o $output_dir/subs_amass.txt" ;;
      "github-subdomains") command_to_run="github-subdomains -d $alvo -t $ghtoken -o $output_dir/subs_github.txt" ;;
      *) return 1 ;;
    esac

    if ! bash -c "$command_to_run" > "$log_file" 2>&1; then
      # Para a animação para não poluir a saída de erro
      if [[ -n "$pid" ]]; then
        kill "$pid" &> /dev/null
        wait "$pid" 2>/dev/null || true
      fi
      echo -e "\r${GRAY_LIGHT}${BOLD_OFF}❌ Erro fatal ao executar ${tool_name}! Causa:${RESET}\n"
      cat "$log_file"
      echo -e "\n"
      exit 255
    fi
    # A animação de loading irá sobrescrever esta mensagem, que piscará brevemente.
    echo -e "\r${GRAY_LIGHT}${BOLD_OFF}✅ ${tool_name} concluído.${RESET}"
  }

  # Grupo 1: Ferramentas rápidas (execução com paralelismo máximo)
  local fast_tools=("subfinder" "assetfinder" "findomain" "github-subdomains" "chaos")
  # Grupo 2: Ferramentas mais pesadas/demoradas (execução com paralelismo limitado)
  local heavy_tools=("amass")

  export alvo ghtoken output_dir GRAY_LIGHT GRAY_DARK BOLD_ON BOLD_OFF RESET
  export -f run_recon_tool

  # As mensagens de execução de grupo foram removidas a pedido do usuário para evitar conflito com a animação.
  printf "%s\n" "${fast_tools[@]}" | xargs -P $(nproc) -I {} bash -c 'run_recon_tool "{}"'
  printf "%s\n" "${heavy_tools[@]}" | xargs -P 1 -I {} bash -c 'run_recon_tool "{}"'

  echo -e "${GRAY_DARK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}


# === Seção de Processamento de Resultados ===
process_results() {
  echo -e "${GRAY_LIGHT}${BOLD_OFF}🗃️ Juntando, limpando e ordenando resultados...${RESET}"

  local base_filename="${alvo}.txt"
  local output_filename="${base_filename}"
  local counter=1

  # Procura por um nome de arquivo que ainda não exista para evitar sobrescrita
  while [[ -f "$output_filename" ]]; do
    output_filename="${alvo}_${counter}.txt"
    ((counter++))
  done

  # Consolida todos os resultados em um único arquivo, remove wildcards e garante unicidade
  cat "$output_dir"/subs_*.txt 2>/dev/null | sed 's/^\*\.//g' | sort -u > "$output_filename"

  echo -e "${GRAY_LIGHT}${BOLD_OFF}☑️ Finalizado! Subdomínios únicos salvos em ${RESET}${GRAY_LIGHT}${BOLD_OFF}${output_filename}${RESET}"

  # Conta quantos subdomínios foram salvos no arquivo final e exibe para o usuário.
  local total_subdominios=$(wc -l < "$output_filename")
  echo -e "${GRAY_LIGHT}${BOLD_OFF}📊 Foram encontrados ${RESET}${GRAY_LIGHT}${BOLD_OFF}${total_subdominios}${RESET}${GRAY_LIGHT}${BOLD_OFF} subdomínios únicos.${RESET}"

  echo -e "${GRAY_DARK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}


# === Função Principal de Orquestração ===
subdomain_discovery() {
  # Cria o arquivo de configuração do Amass dinamicamente
  cat > amass_config.yaml << EOF
resolvers:
  - 1.1.1.1
  - 1.0.0.1
  - 8.8.8.8
  - 8.8.4.4
sources:
  - BGPView
  - IPINFO
  - NetworksDB
  - RADb
  - Robtex
  - ShadowServer
  - Whois
EOF

  get_user_input
  run_recon_tools

  # Finaliza a animação e limpa a linha ANTES de processar os resultados
  if [[ -n "$pid" ]]; then
    kill "$pid" &> /dev/null
    wait "$pid" 2>/dev/null || true
    pid="" # Evita que a função cleanup tente matar o processo novamente
    # Limpa a linha que a animação estava usando
    echo -ne "\r\033[K"
  fi

  process_results
}

# === Menu principal Lezake (clean, elegante) ===
show_menu() {
  while true; do
    # Chama a função que exibe o banner (agora roxo)
    show_banner
    echo -e "\n"

    # Menu opções no estilo horizontal (mantido cinza)
    echo -e "${GRAY_LIGHT}${BOLD_OFF}[1]${RESET} Subdomain Discovery     ${GRAY_LIGHT}${BOLD_OFF}[0] Sair${RESET}\n"
    echo -ne "${GRAY_LIGHT}${BOLD_OFF}[?] Escolha uma opção: ${RESET}"

    read opcao

    case "$opcao" in
      1)
        # Limpa apenas as linhas do menu e prompt antes de prosseguir
        tput cuu 3 # Move o cursor três linhas acima (menu, linha em branco, prompt)
        tput ed   # Limpa da posição do cursor até o final da tela
        subdomain_discovery
        break
        ;;
      0)
        exit 0
        ;;
      *)
        echo -e "${GRAY_LIGHT}${BOLD_OFF}[!] Opção inválida.${RESET}"
        sleep 1.5
        ;;
    esac
  done
}

# === FUNÇÃO MAIN ===
main() {
  # O banner será exibido dentro do loop do menu
  verificar_versao_remota
  verificar_instalar_dependencias
  show_menu
}

# Executa apenas se o script for chamado diretamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
