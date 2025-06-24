#!/bin/bash
clear

# === Versão atual do script ===
SCRIPT_VERSION="1.4"

# === Verificação de atualização por version.txt ===
verificar_versao_remota() {
  remote_version=$(curl -s https://raw.githubusercontent.com/Lezake/ZakeFinder/main/version.txt)

  if [[ -z "$remote_version" ]]; then
    echo -e "\e[1;33m[!] Não foi possível verificar a versão mais recente.\e[0m"
    return
  fi

  if [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
    echo -e "\e[1;33m[⚠️] Atualização disponível\e[0m"
    exit 1
  fi
}
verificar_versao_remota

# === Animação aprimorada ===
loading_animation() {
  chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while :; do
    for c in "${chars[@]}"; do
      echo -ne "\r\e[1;36m[⏳] Coletando... $c\e[0m"
      sleep 0.1
    done
  done
}

executar_com_animacao() {
  comando=$1
  saida=$2
  loading_animation &
  pid=$!
  eval "$comando" &> /dev/null
  kill $pid &> /dev/null
  wait $pid 2>/dev/null
  echo -ne "\r\e[1;32m[✅] $saida finalizado!\e[0m\n"
}

# === Banner ===
echo -e "\e[38;2;200;160;255m"
cat << 'EOF'
███████╗ █████╗ ██╗  ██╗███████╗███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ 
╚══███╔╝██╔══██╗██║ ██╔╝██╔════╝██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
  ███╔╝ ███████║█████╔╝ █████╗  █████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
 ███╔╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
███████╗██║  ██║██║  ██╗███████╗██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝╚══════╝╚═╝  ╚═╝
EOF
echo -e "\e[0m"
echo -e "\e[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

# === Caminhos dos tokens ===
GITHUB_TOKEN_FILE="$HOME/.github_token"
PDCP_API_KEY_FILE="$HOME/.pdcp_api_key"

# === Verifica dependências ===
for tool in subfinder chaos assetfinder findomain github-subdomains; do
  if ! command -v "$tool" &> /dev/null; then
    echo -e "\e[1;31m[ERRO] '$tool' não encontrado. Instale antes de continuar.\e[0m"
    exit 1
  fi
done

# === Domínio ===
read -p $'\e[1;36m[?] Digite o domínio alvo: \e[0m' alvo

# === GitHub Token ===
validar_github_token() {
  status=$(curl -s -o /dev/null -w "%{http_code}"     -H "Authorization: token $1" https://api.github.com/user)
  [[ $status == "200" ]]
}

while true; do
  if [ -f "$GITHUB_TOKEN_FILE" ]; then
    ghtoken=$(<"$GITHUB_TOKEN_FILE")
    echo -e "\e[1;34m[+] Usando GitHub Token salvo.\e[0m"
  else
    read -p $'\e[1;36m[?] Digite seu GitHub Token: \e[0m' ghtoken
    read -p $'\e[1;33m[?] Deseja salvar esse token? (s/n): \e[0m' save
    [[ $save == "s" ]] && echo "$ghtoken" > "$GITHUB_TOKEN_FILE"
  fi

  if validar_github_token "$ghtoken"; then
    echo -e "\e[1;32m[✅] GitHub Token válido!\e[0m"
    break
  else
    echo -e "\e[1;31m[❌] Token inválido.\e[0m"
    rm -f "$GITHUB_TOKEN_FILE"
  fi
done

# === Chaos API Key ===
validar_chaos_token() {
  code=$(curl -s -o /dev/null -w "%{http_code}"     -H "Authorization: $1" "https://dns.projectdiscovery.io/dns/$alvo/subdomains")
  [[ $code == "200" ]]
}

while true; do
  if [ -f "$PDCP_API_KEY_FILE" ]; then
    pdcp_api_key=$(<"$PDCP_API_KEY_FILE")
    echo -e "\e[1;34m[+] Usando Chaos API Key salva.\e[0m"
  else
    read -p $'\e[1;36m[?] Digite sua PDCP_API_KEY do Chaos: \e[0m' pdcp_api_key
    read -p $'\e[1;33m[?] Deseja salvar essa chave? (s/n): \e[0m' save
    [[ $save == "s" ]] && echo "$pdcp_api_key" > "$PDCP_API_KEY_FILE"
  fi

  if validar_chaos_token "$pdcp_api_key"; then
    export PDCP_API_KEY="$pdcp_api_key"
    echo -e "\e[1;32m[✅] Chaos API Key válida!\e[0m"
    break
  else
    echo -e "\e[1;31m[❌] Chaos key inválida.\e[0m"
    rm -f "$PDCP_API_KEY_FILE"
  fi
done

# === Execuções com animação ===
executar_com_animacao "subfinder -d \"$alvo\" -all -silent -o subfinder1" "Subfinder"
executar_com_animacao "chaos -d \"$alvo\" -silent -rl 300 -o chaos1" "Chaos"
executar_com_animacao "assetfinder --subs-only \"$alvo\" > assetfinder1" "Assetfinder"
executar_com_animacao "findomain -t \"$alvo\" -q -u findomain1" "Findomain"
executar_com_animacao "github-subdomains -d \"$alvo\" -t \"$ghtoken\" -o github1" "GitHub Subdomains"

# === Junta os resultados ===
echo -e "\e[1;36m[🧪] Juntando resultados...\e[0m"
> todos.tmp
for f in subfinder1 chaos1 assetfinder1 findomain1 github1; do
  [ -f "$f" ] && cat "$f" >> todos.tmp
done

# === Remove curingas e duplicatas ===
sed 's/^\*\.//g' todos.tmp > subs_sem_curinga.tmp
sort -u subs_sem_curinga.tmp > subs.txt
rm -f subfinder1 chaos1 assetfinder1 findomain1 github1 todos.tmp subs_sem_curinga.tmp

# === Finalização ===
echo -e "\e[1;32m[✔️] Finalizado! Subdomínios únicos salvos em \e[1msubs.txt\e[0m"
echo -e "\e[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
