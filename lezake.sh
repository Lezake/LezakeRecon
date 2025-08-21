#!/bin/bash
set -eo pipefail
clear

# === Detecta suporte a cores ANSI ===
if tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
  NO_COLOR=false
else
  NO_COLOR=true
fi

# === Códigos de cor ===
if [ "$NO_COLOR" = false ]; then
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'
  MAGENTA='\e[1;35m'; CYAN='\e[1;36m'; BOLD='\e[1m'; RESET='\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; BOLD=''; RESET=''
fi

# === Versão atual do script ===
SCRIPT_VERSION="1.9.1"

# === Verificação de atualização remota ===
verificar_versao_remota() {
  remote_version=$(curl -s https://raw.githubusercontent.com/Lezake/ZakeFinder/refs/heads/main/version.txt)
  [[ -z "$remote_version" ]] && return
  if [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
    echo -e "${YELLOW}[⚠️] Atualização disponível para Lezake (de ${SCRIPT_VERSION} → ${remote_version}).${RESET}"
    exit 1
  fi
}
verificar_versao_remota

# === Funções de animação ===
loading_animation() {
  local chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while :; do
    for c in "${chars[@]}"; do
      echo -ne "\r${CYAN}[⏳] Coletando... $c${RESET}"
      sleep 0.1
    done
  done
}

executar_com_animacao() {
  local comando="$1" label="$2"
  local output_file
  output_file=$(mktemp) # Cria um arquivo temporário para guardar a saída

  loading_animation & pid=$!

  # Executa o comando, redirecionando stdout e stderr para o arquivo temporário
  if eval "$comando" > "$output_file" 2>&1; then
    # Sucesso
    kill "$pid" &> /dev/null || true
    wait "$pid" 2>/dev/null || true
    echo -ne "\r${GREEN}[✅] ${label} concluído!${RESET}\n"
  else
    # Falha
    kill "$pid" &> /dev/null || true
    wait "$pid" 2>/dev/null || true
    echo -ne "\r${RED}[❌] ${label} falhou!   ${RESET}\n"
    # Mostra a saída de erro se o arquivo não estiver vazio
    if [[ -s "$output_file" ]]; then
      echo -e "${YELLOW}--- Causa da falha em '$label' ---${RESET}"
      cat "$output_file"
      echo -e "${YELLOW}---------------------------------${RESET}"
    fi
  fi
  rm -f "$output_file" # Limpa o arquivo temporário
}

# === Banner Lezake (roxo/magenta) ===
echo -e "${MAGENTA}${BOLD}"
cat << 'EOF'
██▓    ▓█████ ▒███████▒ ▄▄▄       ██ ▄█▀▓█████
▓██▒    ▓█   ▀ ▒ ▒ ▒ ▄▀░▒████▄     ██▄█▒ ▓█   ▀
▒██░    ▒███   ░ ▒ ▄▀▒░ ▒██  ▀█▄  ▓███▄░ ▒███
▒██░    ▒▓█  ▄   ▄▀▒   ░░██▄▄▄▄██ ▓██ █▄ ▒▓█  ▄
░██████▒░▒████▒▒███████▒ ▓█   ▓██▒▒██▒ █▄░▒████▒
░ ▒░▓  ░░░ ▒░ ░░▒▒ ▓░▒░▒ ▒▒   ▓▒█░▒ ▒▒ ▓▒░░ ▒░ ░
░ ░ ▒  ░ ░ ░  ░░░▒ ▒ ░ ▒  ▒   ▒▒ ░░ ░▒ ▒░ ░ ░  ░
  ░ ░      ░   ░ ░ ░ ░ ░  ░   ▒   ░ ░░ ░    ░
    ░  ░   ░  ░  ░ ░          ░  ░░  ░      ░  ░
               ░
EOF
echo -e "$(printf '%50s' '@leo_zmns')${RESET}"
echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# === Verificação e instalação automática de dependências ===
verificar_instalar_dependencias() {
  declare -A ferramentas=(
    ["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    ["chaos"]="go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
    ["assetfinder"]="go install -v github.com/tomnomnom/assetfinder@latest"
    ["github-subdomains"]="go install -v github.com/gwen001/github-subdomains@latest"
    ["amass"]="go install -v github.com/owasp-amass/amass/v4/...@latest"
    ["gau"]="go install -v github.com/lc/gau/v2/cmd/gau@latest"
    ["unfurl"]="go install -v github.com/tomnomnom/unfurl@latest"
  )

  for tool in "${!ferramentas[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo -e "${YELLOW}[!] Instalando dependência ausente: $tool...${RESET}"
      eval "${ferramentas[$tool]}"
      bin_path="$HOME/go/bin/$tool"
      if [[ -f "$bin_path" ]]; then
        sudo mv "$bin_path" /usr/local/bin/
        echo -e "${GREEN}[+] $tool instalado com sucesso!${RESET}"
      else
        echo -e "${RED}[X] Erro ao instalar $tool. Instale manualmente.${RESET}"; exit 1
      fi
    fi
  done

  if ! command -v findomain &> /dev/null; then
    echo -e "${YELLOW}[!] Instalando findomain...${RESET}"
    temp_dir=$(mktemp -d)
    wget -q https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip -O "$temp_dir/findomain.zip"
    unzip -qq "$temp_dir/findomain.zip" -d "$temp_dir"
    chmod +x "$temp_dir/findomain"
    sudo mv "$temp_dir/findomain" /usr/local/bin/
    rm -rf "$temp_dir"
    echo -e "${GREEN}[+] findomain instalado com sucesso!${RESET}"
  fi
}
verificar_instalar_dependencias

# === Função Subdomain Discovery ===
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

  GITHUB_TOKEN_FILE="$HOME/.github_token"
  PDCP_API_KEY_FILE="$HOME/.pdcp_api_key"
  echo -ne "${CYAN}[?] Digite o domínio alvo: ${RESET}"
  read alvo

  validar_github_token() {
    status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $1" https://api.github.com/user)
    [[ $status == "200" ]]
  }

  while true; do
    if [[ -f "$GITHUB_TOKEN_FILE" ]]; then
      ghtoken=$(<"$GITHUB_TOKEN_FILE")
      echo -e "${BLUE}[+] Usando GitHub Token salvo.${RESET}"
    else
      echo -ne "${CYAN}[?] Digite seu GitHub Token: ${RESET}"
      read ghtoken
      echo -ne "${YELLOW}[?] Deseja salvar esse token? (s/n): ${RESET}"
      read save
      [[ $save == "s" ]] && echo "$ghtoken" > "$GITHUB_TOKEN_FILE"
    fi

    if validar_github_token "$ghtoken"; then
      echo -e "${GREEN}[✅] GitHub Token válido!${RESET}"
      break
    else
      echo -e "${RED}[❌] Token inválido.${RESET}"
      rm -f "$GITHUB_TOKEN_FILE"
    fi
  done

  validar_chaos_token() {
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: $1" "https://dns.projectdiscovery.io/dns/$alvo/subdomains")
    [[ $code == "200" ]]
  }

  while true; do
    if [[ -f "$PDCP_API_KEY_FILE" ]]; then
      pdcp_api_key=$(<"$PDCP_API_KEY_FILE")
      echo -e "${BLUE}[+] Usando Chaos API Key salva.${RESET}"
    else
      echo -ne "${CYAN}[?] Digite sua PDCP_API_KEY do Chaos: ${RESET}"
      read pdcp_api_key
      echo -ne "${YELLOW}[?] Deseja salvar essa chave? (s/n): ${RESET}"
      read save
      [[ $save == "s" ]] && echo "$pdcp_api_key" > "$PDCP_API_KEY_FILE"
    fi

    if validar_chaos_token "$pdcp_api_key"; then
      export PDCP_API_KEY="$pdcp_api_key"
      echo -e "${GREEN}[✅] Chaos API Key válida!${RESET}"
      break
    else
      echo -e "${RED}[❌] Chaos key inválida.${RESET}"
      rm -f "$PDCP_API_KEY_FILE"
    fi
  done

  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  # --- Execução Otimizada em Paralelo com Output Limpo ---
  loading_animation & pid=$!
  trap 'kill "$pid" &> /dev/null; wait "$pid" 2>/dev/null || true' EXIT

  output_dir=$(mktemp -d)
  trap 'rm -rf "$output_dir"; kill "$pid" &> /dev/null; wait "$pid" 2>/dev/null || true' EXIT

  tools=("subfinder" "chaos" "assetfinder" "findomain" "amass" "github-subdomains" "gau")

  printf "%s\n" "${tools[@]}" | xargs -P 3 -I {} bash -c '
    tool_name="{}"
    output_dir="'$output_dir'"
    alvo="'$alvo'"
    ghtoken="'$ghtoken'"
    GREEN="'$GREEN'"
    RED="'$RED'"
    RESET="'$RESET'"

    case "$tool_name" in
      "subfinder") cmd="subfinder -d $alvo -all -silent -o $output_dir/subs_subfinder.txt" ;;
      "chaos") cmd="chaos -d $alvo -silent -o $output_dir/subs_chaos.txt" ;;
      "assetfinder") cmd="assetfinder --subs-only $alvo > $output_dir/subs_assetfinder.txt" ;;
      "findomain") cmd="findomain -t $alvo -q -u $output_dir/subs_findomain.txt" ;;
      "amass") cmd="amass enum -passive -config amass_config.yaml -d $alvo -silent -timeout 4 -o $output_dir/subs_amass.txt" ;;
      "github-subdomains") cmd="github-subdomains -d $alvo -t $ghtoken -o $output_dir/subs_github.txt" ;;
      "gau") cmd="gau $alvo --subs --o $output_dir/subs_gau.txt --threads 50 --timeout 20" ;;
      *) exit 1 ;;
    esac

    if ! eval "$cmd" > "$output_dir/${tool_name}.log" 2>&1; then
      # Se o comando falhar, limpa a animação, mostra o erro e sai
      echo -e "\r${RED}[❌] Erro fatal ao executar ${tool_name}! Causa:${RESET}\n"
      cat "$output_dir/${tool_name}.log"
      echo -e "\n"
      # Usa exit 255 para fazer o xargs parar
      exit 255
    fi
    # Se o comando for bem-sucedido, apenas mostra a mensagem de conclusão
    echo -e "\r${GREEN}[✅] ${tool_name} concluído.${RESET}"
  '
  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  kill "$pid" &> /dev/null
  wait "$pid" 2>/dev/null || true
  trap - EXIT
  echo -e "${BLUE}[+] Juntando, limpando e ordenando resultados...${RESET}"
  
  # Junta todos os arquivos de resultado, processa e salva
  cat "$output_dir"/subs_*.txt 2>/dev/null | unfurl -u domains | sed 's/^\*\.//g' | sort -u > subs.txt

  # Limpa o arquivo de configuração do Amass
  rm -f amass_config.yaml

  echo -e "${GREEN}[✔️] Finalizado! Subdomínios únicos salvos em ${BOLD}subs.txt${RESET}"
  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# === Menu principal Lezake (clean, elegante) ===
while true; do
  clear
  # Banner e identidade
  echo -e "${MAGENTA}${BOLD}"
  cat << 'EOF'
██▓    ▓█████ ▒███████▒ ▄▄▄       ██ ▄█▀▓█████
▓██▒    ▓█   ▀ ▒ ▒ ▒ ▄▀░▒████▄     ██▄█▒ ▓█   ▀
▒██░    ▒███   ░ ▒ ▄▀▒░ ▒██  ▀█▄  ▓███▄░ ▒███
▒██░    ▒▓█  ▄   ▄▀▒   ░░██▄▄▄▄██ ▓██ █▄ ▒▓█  ▄
░██████▒░▒████▒▒███████▒ ▓█   ▓██▒▒██▒ █▄░▒████▒
░ ▒░▓  ░░░ ▒░ ░░▒▒ ▓░▒░▒ ▒▒   ▓▒█░▒ ▒▒ ▓▒░░ ▒░ ░
░ ░ ▒  ░ ░ ░  ░░░▒ ▒ ░ ▒  ▒   ▒▒ ░░ ░▒ ▒░ ░ ░  ░
  ░ ░      ░   ░ ░ ░ ░ ░  ░   ▒   ░ ░░ ░    ░
    ░  ░   ░  ░  ░ ░          ░  ░░  ░      ░  ░
               ░
EOF
  echo -e "$(printf '%50s' '@leo_zmns')${RESET}"
  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  # Menu opções no estilo horizontal
  echo -e "${CYAN}[1] Subdomain Discovery${RESET}    ${RED}[0] Sair${RESET}\n"
  echo -ne "${YELLOW}[?] Escolha uma opção: ${RESET}"

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
      echo -e "${RED}[!] Opção inválida.${RESET}"
      sleep 1.5
      ;;
  esac
done
