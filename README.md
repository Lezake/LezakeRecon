<p align="center">
  <img src="https://github.com/Lezake/ZakeFinder/blob/eb6f826a1f1e52f2489af88aeb19e2ad706b47b3/zakebanner.png" alt="ZakeFinder Banner" />
</p>

📚 <h2>Como usar</h2>:

chmod +x zakefinder.sh | ./zakefinder.sh

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
Ferramentas Utilizadas

Este script integra as seguintes ferramentas (você deve instalá-las antes de rodar):

subfinder,
chaos,
assetfinder,
findomain,
Amass e
github-subdomains

Obs: jogue todos em /usr/local/bin

-----------------------
Personalização dos Parâmetros:

Todos os comandos usados no script podem ser totalmente personalizados pelo usuário.
Se desejar, você pode editar o arquivo zakefinder.sh e ajustar:

Os parâmetros do subfinder (ex: -silent, -all, -recursive, etc)

A forma como o chaos exporta resultados

Adicionar/remover ferramentas conforme sua metodologia

Alterar animações, cores ou integrar com outras ferramentas

Exemplo: Quer limitar o subfinder apenas a fontes passivas?
Edite a linha do comando correspondente e troque -all por -sources passive
