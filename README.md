<p align="center">
  <img src="https://github.com/Lezake/Lezake/blob/df28540458a9a1249cdd020841c0c36d1eab3e3a/lezakebanner.png" alt="Lezake Banner" />
</p>

Lezake – Automação Inteligente para Recon em Pentests 🔍

O Lezake é uma ferramenta projetada para profissionais e entusiastas de CyberSecurity que querem agilidade e precisão na fase inicial do pentest. Seu objetivo é simplificar e acelerar as tarefas repetitivas de reconhecimento e mapeamento de ativos, garantindo resultados organizados, limpos e prontos para uso.

✅ Principais recursos (atual):

Coleta avançada de subdomínios usando as principais ferramentas do mercado (combinação otimizada para máxima cobertura).

Remoção automática de duplicatas para garantir uma lista limpa.

Instalação automatizada de dependências, sem dor de cabeça.

Por que usar o Lezake?

Automatiza tarefas que normalmente levariam horas.

Une eficiência e boa prática, sem comprometer a qualidade.


Pronto para crescer: novas funções como busca de arquivos JS, endpoints sensíveis estão sendo pensadas.

Ideal para quem quer começar o pentest com informações ricas, organizadas e sem esforço manual desnecessário.

-----------------------

## 📘 Como usar:

```bash
# instalação  
git clone https://github.com/Lezake/Lezake.git

# entrar na pasta  
cd Lezake

# executar script  
./lezake.sh
```


-----------------------
Tokens Necessários:

O script requer dois tokens para funcionar com algumas das fontes:

1. GitHub Token
Necessário para a ferramenta github-subdomains

Como gerar:

Vá para: https://github.com/settings/tokens

Clique em "Generate new token"

Marque a permissão: repo (básico já funciona)

Copie e cole no script quando solicitado

2. Chaos API Key (ProjectDiscovery)
Necessário para usar o chaos da ProjectDiscovery

Como obter:

Crie uma conta em: https://chaos.projectdiscovery.io/

Vá até o dashboard e gere uma API key

Cole no script quando solicitado

-----------------------
Personalização dos Parâmetros:

Todos os comandos usados no script podem ser totalmente personalizados pelo usuário.
Se desejar, você pode editar o arquivo lezake.sh e ajustar:

Os parâmetros do subfinder (ex: -silent, -all, -recursive, etc)

A forma como o chaos exporta resultados

Adicionar/remover ferramentas conforme sua metodologia

Alterar animações, cores ou integrar com outras ferramentas

Exemplo: Quer limitar o subfinder apenas a fontes passivas?
Edite a linha do comando correspondente e troque -all por -sources passive
