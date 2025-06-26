# DogList - Sistema de Mapeamento de Cães

O DogList é uma aplicação web para gerir e visualizar a localização de cães encontrados e procurados num mapa interativo. A aplicação permite que utilizadores cadastrem cães, especificando a sua localização, características e estado (procurado ou encontrado).

## Estrutura do Projeto

- **Páginas principais:**
  - `index.html` - Página de login
  - `register.html` - Cadastro de utilizadores
  - `home.html` - Mapa principal mostrando cães cadastrados
  - `add-dog.html` - Formulário para adicionar novos cães
  - `account.html` - Gestão de conta do utilizador
  - `search.html` - Busca de cães por características
  - `clinics.html` - Mapa de clínicas veterinárias
  - `animal-details.html` - Detalhes de um animal específico

## Funcionamento do Mapa

- **Marcadores no Mapa:**
  - Vermelho: Cães procurados
  - Verde: Cães encontrados 
  - Azul: Sua localização atual

- **Interação:**
  - Clique em um marcador para ver detalhes do cão
  - Use a legenda para ativar/desativar grupos de marcadores

## Armazenamento de Dados

A aplicação utiliza o localStorage do navegador para armazenar:

- **Utilizadores cadastrados** - Informações de login e perfil
- **Cães cadastrados** - Incluindo localização, características e estado
- **Preferências do utilizador** - Como a última posição no mapa


## Desenvolvimento

O projeto é desenvolvido em HTML, CSS e JavaScript puro, utilizando:

- API do Google Maps para geocodificação e visualização de mapas
- localStorage para persistência de dados
- Design responsivo para funcionar em dispositivos móveis e desktop 
