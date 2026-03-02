# Lezake 🔍

> Automação Inteligente para Recon em Pentests

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)]()

---

## 📖 Sobre

Lezake automatiza a fase de reconhecimento em pentests. A ferramenta instala e configura automaticamente todas as dependências, integra múltiplas fontes de dados e consolida os resultados — tudo com poucos cliques.

- ✅ Instalação automática de ferramentas
- ✅ Interface interativa via menu
- ✅ Fluxo de trabalho simplificado

---

## 🔐 Configuração

Alguns módulos requerem tokens de API. O próprio script solicita e valida as credenciais durante a execução.

### GitHub Token

Utilizado para consultas à API do GitHub.

**Como gerar:**

1. Acesse: https://github.com/settings/tokens
2. Clique em **"Generate new token (classic)"**
3. **Nenhuma permissão necessária**
4. Cole quando solicitado pelo script

### Chaos API Key (ProjectDiscovery)

Utilizado para consultas ao banco de dados do Chaos.

**Como obter:**

1. Crie uma conta em: https://chaos.projectdiscovery.io/
2. Acesse o dashboard
3. Gere sua API Key
4. Cole quando solicitado pelo script

---

## 💻 Uso

```bash
# Clonar o repositório
git clone https://github.com/Lezake/Lezake.git

# Acessar o diretório
cd Lezake

# Executar
./lezake.sh
