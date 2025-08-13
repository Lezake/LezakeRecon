#!/bin/bash
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
SCRIPT_VERSION="1.9"

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
  loading_animation & pid=$!
  eval "$comando" &> /dev/null
  kill "$pid" &> /dev/null
  wait "$pid" 2>/dev/null
  echo -ne "\r${GREEN}[✅] ${label} concluído!${RESET}\n"
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
echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

# === Verificação e instalação automática de dependências ===
verificar_instalar_dependencias() {
  declare -A ferramentas=(
    ["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    ["chaos"]="go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
    ["assetfinder"]="go install -v github.com/tomnomnom/assetfinder@latest"
    ["github-subdomains"]="go install -v github.com/gwen001/github-subdomains@latest"
    ["amass"]="go install -v github.com/owasp-amass/amass/v4/...@latest"
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

  executar_com_animacao "subfinder -d \"$alvo\" -all -silent -o subfinder1" "Subfinder"
  executar_com_animacao "chaos -d \"$alvo\" -silent -rl 300 -o chaos1" "Chaos"
  executar_com_animacao "assetfinder --subs-only \"$alvo\" > assetfinder1" "Assetfinder"
  executar_com_animacao "findomain -t \"$alvo\" -q -u findomain1" "Findomain"
  executar_com_animacao "amass enum -passive -norecursive -noalts -d \"$alvo\" -silent -o amass1" "Amass"
  executar_com_animacao "github-subdomains -d \"$alvo\" -t \"$ghtoken\" -o github1" "GitHub Subdomains"

  echo -e "${BLUE}[+] Juntando resultados...${RESET}"
  > todos.tmp
  for f in subfinder1 chaos1 assetfinder1 findomain1 github1 amass1; do
    [[ -f "$f" ]] && cat "$f" >> todos.tmp
  done
  sed 's/^\*\.//g' todos.tmp > subs_sem_curinga.tmp
  sort -u subs_sem_curinga.tmp > subs.txt
  rm -f subfinder1 chaos1 assetfinder1 findomain1 github1 amass1 todos.tmp subs_sem_curinga.tmp

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
