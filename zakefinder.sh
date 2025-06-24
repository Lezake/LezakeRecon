#!/bin/bash

# Função de animação de loading
loading_animation() {
  chars=('/' '-' '\' '|')
  while :; do
    for c in "${chars[@]}"; do
      echo -ne "\r[⏳] Coletando... $c"
      sleep 0.1
    done
  done
}

# Função para executar ferramenta com animação e mensagem de sucesso
executar_com_animacao() {
  comando=$1
  saida=$2
  loading_animation &
  pid=$!
  eval "$comando" &> /dev/null
  kill $pid &> /dev/null
  wait $pid 2>/dev/null
  echo -ne "\r[✅] $saida finalizado.\n"
}

# Cor lavanda suave
echo -e "\e[38;2;200;160;255m"
cat << 'EOF'
███████╗ █████╗ ██╗  ██╗███████╗███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ 
╚══███╔╝██╔══██╗██║ ██╔╝██╔════╝██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
  ███╔╝ ███████║█████╔╝ █████╗  █████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
 ███╔╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
███████╗██║  ██║██║  ██╗███████╗██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝╚══════╝╚═╝  ╚═╝
         ░      ░   ░    ░   ░     ░        ░   ░       ░     ░
           ░    ░  ░   ░    ░  ░     ░       ░    ░        ░
             ░        ░    ░      ░       ░     ░      ░     ░
EOF
echo -e "\e[0m"

# Caminhos para os arquivos de configuração
GITHUB_TOKEN_FILE="$HOME/.github_token"
PDCP_API_KEY_FILE="$HOME/.pdcp_api_key"

# Verifica dependências
for tool in subfinder chaos assetfinder findomain github-subdomains; do
  if ! command -v "$tool" &> /dev/null; then
    echo "[ERRO] '$tool' não encontrado. Instale antes de continuar."
    exit 1
  fi
done

# Solicita o domínio alvo
read -p "Digite o domínio alvo: " alvo

# GitHub Token
if [ -f "$GITHUB_TOKEN_FILE" ]; then
  ghtoken=$(cat "$GITHUB_TOKEN_FILE")
  echo "[+] Usando GitHub Token salvo em $GITHUB_TOKEN_FILE"
else
  if [ -z "$GITHUB_TOKEN" ]; then
    read -p "Digite o GitHub Token: " ghtoken
    read -p "Deseja salvar o token para uso futuro? (s/n): " save_token
    if [ "$save_token" = "s" ]; then
      echo "$ghtoken" > "$GITHUB_TOKEN_FILE"
      echo "[+] Token salvo em $GITHUB_TOKEN_FILE"
    fi
  else
    ghtoken="$GITHUB_TOKEN"
    echo "[+] Usando GITHUB_TOKEN da variável de ambiente"
  fi
fi

# PDCP_API_KEY para chaos
if [ -f "$PDCP_API_KEY_FILE" ]; then
  pdcp_api_key=$(cat "$PDCP_API_KEY_FILE")
  echo "[+] Usando PDCP_API_KEY salvo em $PDCP_API_KEY_FILE"
else
  if [ -z "$PDCP_API_KEY" ]; then
    read -p "Digite a PDCP_API_KEY para o chaos: " pdcp_api_key
    read -p "Deseja salvar a chave para uso futuro? (s/n): " save_key
    if [ "$save_key" = "s" ]; then
      echo "$pdcp_api_key" > "$PDCP_API_KEY_FILE"
      echo "[+] Chave salva em $PDCP_API_KEY_FILE"
    fi
  else
    pdcp_api_key="$PDCP_API_KEY"
    echo "[+] Usando PDCP_API_KEY da variável de ambiente"
  fi
fi

export PDCP_API_KEY="$pdcp_api_key"

# Execução das ferramentas com animação
executar_com_animacao "subfinder -d \"$alvo\" -all -silent -o subfinder1" "Subfinder"
executar_com_animacao "chaos -d \"$alvo\" -silent -o chaos1" "Chaos"
executar_com_animacao "assetfinder --subs-only \"$alvo\" > assetfinder1" "Assetfinder"
executar_com_animacao "findomain -t \"$alvo\" -q -u findomain1" "Findomain"
executar_com_animacao "github-subdomains -d \"$alvo\" -t \"$ghtoken\" -o github1" "GitHub Subdomains"

# Junta resultados existentes
echo -ne "\n[🧪] Juntando resultados...\n"
> todos.tmp
for f in subfinder1 chaos1 assetfinder1 findomain1 github1; do
  [ -f "$f" ] && cat "$f" >> todos.tmp
done

sort -u todos.tmp > subs.txt
rm -f subfinder1 chaos1 assetfinder1 findomain1 github1 todos.tmp

echo -e "[✔️] Finalizado! Subdomínios únicos salvos em \e[1msubs.txt\e[0m"
