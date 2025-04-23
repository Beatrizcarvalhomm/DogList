# Doglist - Configuração do Supabase

Este projeto utiliza o Supabase como backend. Siga as instruções abaixo para configurar corretamente o banco de dados e as permissões necessárias.

## Configuração do Supabase

1. **Credenciais do Supabase**
   - URL: https://hvipmhdmppyfslbdnevq.supabase.co
   - Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2aXBtaGRtcHB5ZnNsYmRuZXZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4MjY0NjUsImV4cCI6MjA2MDQwMjQ2NX0.36E2gK-S8zDW4qyI3OaezbllEF7Rg_yKpXafzNbP_I4`

2. **Criação das Tabelas**
   - Acesse o Supabase e navegue até o SQL Editor
   - Execute os scripts SQL contidos neste projeto para criar as tabelas necessárias

## Estrutura das Tabelas

### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  date_created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para busca de usuários por telefone
CREATE INDEX users_phone_idx ON users (phone);
```

### Dogs
```sql
CREATE TABLE dogs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT,
  estado TEXT NOT NULL CHECK (estado IN ('procurado', 'encontrado')),
  location JSONB NOT NULL, -- {lat: number, lng: number, address: string}
  raca TEXT,
  idade TEXT NOT NULL CHECK (idade IN ('0-5', '5-10', '10+', 'desconhecido')),
  sexo TEXT NOT NULL CHECK (sexo IN ('macho', 'femea', 'desconhecido')),
  castrado TEXT NOT NULL CHECK (castrado IN ('sim', 'nao', 'desconhecido')),
  agressivo TEXT NOT NULL CHECK (agressivo IN ('nenhum', 'humanos', 'animais', 'ambos', 'desconhecido')),
  porte TEXT NOT NULL CHECK (porte IN ('pequeno', 'medio', 'grande')),
  contacto TEXT NOT NULL,
  user_name TEXT,
  data_adicao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para busca de animais
CREATE INDEX dogs_user_id_idx ON dogs (user_id);
CREATE INDEX dogs_estado_idx ON dogs (estado);
CREATE INDEX dogs_porte_idx ON dogs (porte);
CREATE INDEX dogs_raca_idx ON dogs (raca);
```

### Clinics
```sql
CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  endereco TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  website TEXT,
  location JSONB NOT NULL, -- {lat: number, lng: number}
  servicos TEXT[],
  avaliacao DECIMAL(3,1),
  horario_funcionamento JSONB, -- {seg: "9:00-18:00", ter: "9:00-18:00", ...}
  fotos TEXT[],
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para busca de clínicas
CREATE INDEX clinics_nome_idx ON clinics (nome);
```

### Configurações do App
```sql
CREATE TABLE configuracoes_app (
  id SERIAL PRIMARY KEY,
  chave TEXT UNIQUE NOT NULL,
  valor JSONB NOT NULL,
  descricao TEXT,
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir configurações iniciais
INSERT INTO configuracoes_app (chave, valor, descricao) VALUES 
('configuracoes_mapa', '{"centro_padrao": {"lat": 38.7223, "lng": -9.1393}, "zoom_padrao": 12}', 'Configurações padrão do mapa'),
('lista_racas', '[
  "Rafeiro Alentejado", "Cão da Serra da Estrela", "Cão de Água Português", "Podengo Português",
  "Castro Laboreiro", "Cão de Fila de São Miguel", "Barbado da Terceira", "Perdigueiro Português",
  "Cão de Gado Transmontano", "Cão do Barrocal Algarvio", "Cão de Serra de Aires",
  "Bulldog Francês", "Labrador Retriever", "Golden Retriever", "Pastor Alemão",
  "Yorkshire Terrier", "Beagle", "Chihuahua", "Boxer", "Jack Russell Terrier",
  "Poodle", "Cocker Spaniel", "Dachshund", "Pug", "Cavalier King Charles Spaniel"
]', 'Lista de raças de cães');
```

## Extensões e Funções Avançadas

### PostGIS (para busca geoespacial)
```sql
-- Habilitar PostGIS para buscas geoespaciais
CREATE EXTENSION IF NOT EXISTS postgis;

-- Adicionar colunas geoespaciais
ALTER TABLE dogs ADD COLUMN geo_location GEOGRAPHY(POINT);
ALTER TABLE clinics ADD COLUMN geo_location GEOGRAPHY(POINT);

-- Índices espaciais
CREATE INDEX dogs_geo_location_idx ON dogs USING GIST(geo_location);
CREATE INDEX clinics_geo_location_idx ON clinics USING GIST(geo_location);
```

### Função para Buscar Clínicas Próximas
```sql
CREATE OR REPLACE FUNCTION nearby_clinics(lat float, lng float, radius_km float)
RETURNS SETOF clinics
LANGUAGE sql
STABLE
AS $$
  SELECT c.*
  FROM clinics c
  WHERE ST_DWithin(
    c.geo_location,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    radius_km * 1000  -- Converter para metros
  )
  ORDER BY ST_Distance(
    c.geo_location,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  );
$$;
```

## Configuração de Storage

1. **Criar Bucket para Imagens**
   - Navegue até Storage no Supabase
   - Crie um novo bucket chamado `pet_images`
   - Configure as permissões para permitir upload e leitura pública

2. **Políticas de Storage**
   ```sql
   -- Permitir acesso público para leitura das imagens
   CREATE POLICY "Pet images are publicly accessible" 
   ON storage.objects FOR SELECT 
   USING (bucket_id = 'pet_images');

   -- Permitir que usuários autenticados façam upload
   CREATE POLICY "Users can upload pet images" 
   ON storage.objects FOR INSERT 
   WITH CHECK (bucket_id = 'pet_images' AND auth.uid() IS NOT NULL);

   -- Permitir que usuários excluam suas próprias imagens
   CREATE POLICY "Users can delete their own pet images" 
   ON storage.objects FOR DELETE 
   USING (bucket_id = 'pet_images' AND (storage.foldername(name))[1] = auth.uid()::text);
   ```

## Row Level Security (RLS)

Configure as políticas de segurança para proteger os dados:

```sql
-- Ativar RLS nas tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;

-- Políticas para users
CREATE POLICY "Users can view their own data" 
ON users FOR SELECT USING (id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can update their own data" 
ON users FOR UPDATE USING (id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Políticas para dogs
CREATE POLICY "Anyone can view dogs" 
ON dogs FOR SELECT USING (true);

CREATE POLICY "Users can insert their own dogs" 
ON dogs FOR INSERT WITH CHECK (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can update their own dogs" 
ON dogs FOR UPDATE USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can delete their own dogs" 
ON dogs FOR DELETE USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Políticas para clinics (apenas admin pode modificar)
CREATE POLICY "Anyone can view clinics" 
ON clinics FOR SELECT USING (true);
```

## Migração de Dados

Para migrar os dados existentes do localStorage para o Supabase, use as funções definidas em `lib/supabase.js`.

## Testes

Após configurar o Supabase, teste a aplicação para garantir que as seguintes funcionalidades estão operando corretamente:

1. Registro e login de usuários
2. Adicionar, visualizar e remover cães
3. Buscar cães com base em filtros
4. Upload e exibição de imagens
5. Buscar clínicas veterinárias próximas 