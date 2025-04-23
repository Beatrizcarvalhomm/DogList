-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome TEXT NOT NULL CHECK (char_length(nome) >= 2),
    telefone TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    date_created TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.users IS 'Tabela de usuários do sistema Doglist';

-- Tabela de animais (cães)
CREATE TABLE IF NOT EXISTS public.dogs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    nome TEXT NOT NULL CHECK (char_length(nome) >= 2),
    raca TEXT NOT NULL,
    image_url TEXT,
    idade TEXT CHECK (idade IN ('0-5', '5-10', '10+', 'desconhecido')),
    sexo TEXT CHECK (sexo IN ('macho', 'femea', 'desconhecido')),
    castrado TEXT CHECK (castrado IN ('sim', 'nao', 'desconhecido')),
    estado TEXT NOT NULL CHECK (estado IN ('procurado', 'encontrado')),
    agressivo TEXT CHECK (agressivo IN ('nenhum', 'humanos', 'animais', 'ambos', 'desconhecido')),
    porte TEXT CHECK (porte IN ('pequeno', 'medio', 'grande')),
    contacto TEXT NOT NULL,
    local JSONB NOT NULL, -- {lat: number, lng: number, address: string}
    data_registro TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.dogs IS 'Tabela de cães registrados no sistema';

-- Tabela de clínicas veterinárias
CREATE TABLE IF NOT EXISTS public.clinics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome TEXT NOT NULL,
    endereco TEXT NOT NULL,
    telefone TEXT,
    email TEXT,
    website TEXT,
    location JSONB NOT NULL, -- {lat: number, lng: number}
    servicos TEXT[],
    avaliacao DECIMAL(3,1) CHECK (avaliacao >= 0 AND avaliacao <= 5),
    horario_funcionamento JSONB, -- {seg: "9:00-18:00", ter: "9:00-18:00", ...}
    fotos TEXT[],
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.clinics IS 'Tabela de clínicas veterinárias';

-- Tabela de configurações do aplicativo
CREATE TABLE IF NOT EXISTS public.configuracoes_app (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chave TEXT NOT NULL UNIQUE,
    valor JSONB NOT NULL,
    descricao TEXT,
    data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.configuracoes_app IS 'Configurações globais do aplicativo';

-- Colunas geoespaciais
ALTER TABLE public.dogs ADD COLUMN IF NOT EXISTS geo_location GEOGRAPHY(POINT, 4326);
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS geo_location GEOGRAPHY(POINT, 4326);

-- Adicionar índices para melhoria de performance
CREATE INDEX IF NOT EXISTS idx_users_telefone ON public.users(telefone);
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON public.dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_dogs_estado ON public.dogs(estado);
CREATE INDEX IF NOT EXISTS idx_dogs_location ON public.dogs USING GIST(geo_location);
CREATE INDEX IF NOT EXISTS idx_clinics_location ON public.clinics USING GIST(geo_location);
CREATE INDEX IF NOT EXISTS idx_clinics_nome ON public.clinics USING GIN(nome gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_dogs_raca ON public.dogs USING GIN(raca gin_trgm_ops);

-- Função para atualizar localização geográfica de objetos
CREATE OR REPLACE FUNCTION update_geo_location_from_jsonb()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.local IS NOT NULL AND 
       (NEW.local->>'lat') IS NOT NULL AND 
       (NEW.local->>'lng') IS NOT NULL THEN
        
        NEW.geo_location = ST_SetSRID(
            ST_MakePoint(
                (NEW.local->>'lng')::float, 
                (NEW.local->>'lat')::float
            ),
            4326
        )::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função similar para clínicas
CREATE OR REPLACE FUNCTION update_clinic_geo_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.location IS NOT NULL AND 
       (NEW.location->>'lat') IS NOT NULL AND 
       (NEW.location->>'lng') IS NOT NULL THEN
        
        NEW.geo_location = ST_SetSRID(
            ST_MakePoint(
                (NEW.location->>'lng')::float, 
                (NEW.location->>'lat')::float
            ),
            4326
        )::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar localização geográfica
DROP TRIGGER IF EXISTS update_dog_location ON public.dogs;
CREATE TRIGGER update_dog_location
BEFORE INSERT OR UPDATE ON public.dogs
FOR EACH ROW
EXECUTE FUNCTION update_geo_location_from_jsonb();

DROP TRIGGER IF EXISTS update_clinic_location ON public.clinics;
CREATE TRIGGER update_clinic_location
BEFORE INSERT OR UPDATE ON public.clinics
FOR EACH ROW
EXECUTE FUNCTION update_clinic_geo_location();

-- Função para encontrar clínicas próximas
CREATE OR REPLACE FUNCTION nearby_clinics(lat float, lng float, radius_km float)
RETURNS SETOF public.clinics AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.clinics
    WHERE ST_DWithin(
        geo_location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
        radius_km * 1000  -- Convertendo km para metros
    )
    ORDER BY ST_Distance(
        geo_location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql;

-- Função para encontrar cães próximos
CREATE OR REPLACE FUNCTION find_nearby_dogs(lat float, lng float, radius_km float)
RETURNS SETOF public.dogs AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.dogs
    WHERE ST_DWithin(
        geo_location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
        radius_km * 1000  -- Convertendo km para metros
    )
    ORDER BY ST_Distance(
        geo_location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql;

-- Configurar RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;

-- Políticas para acesso aos dados (simplificada para nosso sistema)
DROP POLICY IF EXISTS users_policy ON public.users;
CREATE POLICY users_policy ON public.users
    USING (true)  -- Permitir acesso a todos os registros para simplificar
    WITH CHECK (true);

DROP POLICY IF EXISTS dogs_select_policy ON public.dogs;
CREATE POLICY dogs_select_policy ON public.dogs
    FOR SELECT
    USING (true);  -- Qualquer um pode ver os cães

DROP POLICY IF EXISTS dogs_insert_policy ON public.dogs;
CREATE POLICY dogs_insert_policy ON public.dogs
    FOR INSERT
    WITH CHECK (true);  -- Qualquer um pode inserir cães

DROP POLICY IF EXISTS dogs_update_policy ON public.dogs;
CREATE POLICY dogs_update_policy ON public.dogs
    FOR UPDATE
    USING (true)  -- Para simplificar, qualquer usuário pode atualizar
    WITH CHECK (true);

DROP POLICY IF EXISTS dogs_delete_policy ON public.dogs;
CREATE POLICY dogs_delete_policy ON public.dogs
    FOR DELETE
    USING (true);  -- Para simplificar, qualquer usuário pode remover

DROP POLICY IF EXISTS clinics_policy ON public.clinics;
CREATE POLICY clinics_policy ON public.clinics
    USING (true)  -- Qualquer um pode ver clínicas
    WITH CHECK (true);  -- Simplificado para permitir inserções/atualizações

-- Inserir raças de cães na tabela de configurações
INSERT INTO public.configuracoes_app (chave, valor, descricao)
VALUES (
    'lista_racas', 
    '[
        "Rafeiro Alentejado", "Cão da Serra da Estrela", "Cão de Água Português", 
        "Podengo Português", "Castro Laboreiro", "Cão de Fila de São Miguel", 
        "Barbado da Terceira", "Perdigueiro Português", "Cão de Gado Transmontano", 
        "Cão do Barrocal Algarvio", "Cão de Serra de Aires", "Bulldog Francês", 
        "Labrador Retriever", "Golden Retriever", "Pastor Alemão", "Yorkshire Terrier", 
        "Beagle", "Chihuahua", "Boxer", "Jack Russell Terrier", "Poodle", 
        "Cocker Spaniel", "Dachshund", "Pug", "Cavalier King Charles Spaniel", 
        "Shih Tzu", "Border Collie", "Schnauzer Miniatura", "Rottweiler", 
        "Pinscher Miniatura", "Cão de raça mista", "SRD (Sem Raça Definida)"
    ]',
    'Lista de raças de cães disponíveis no sistema'
)
ON CONFLICT (chave) 
DO UPDATE SET valor = EXCLUDED.valor, descricao = EXCLUDED.descricao;

-- Inserir configurações de mapa
INSERT INTO public.configuracoes_app (chave, valor, descricao)
VALUES (
    'configuracoes_mapa',
    '{"centro_padrao": {"lat": 38.7223, "lng": -9.1393}, "zoom_padrao": 12}',
    'Configurações padrão do mapa centrado em Lisboa'
)
ON CONFLICT (chave) 
DO UPDATE SET valor = EXCLUDED.valor, descricao = EXCLUDED.descricao;

-- Inserir algumas clínicas de exemplo (opcional)
INSERT INTO public.clinics 
(nome, endereco, telefone, website, location, servicos, avaliacao)
VALUES 
(
    'Hospital Veterinário de Lisboa', 
    'Av. da Liberdade 123, Lisboa', 
    '212345678', 
    'www.vetlisboa.pt', 
    '{"lat": 38.7223, "lng": -9.1393}', 
    ARRAY['Consultas', 'Cirurgias', 'Exames', 'Internamento'], 
    4.8
),
(
    'Clínica Veterinária do Porto', 
    'Rua Santa Catarina 456, Porto', 
    '222345678', 
    'www.vetporto.pt',
    '{"lat": 41.1579, "lng": -8.6291}',
    ARRAY['Consultas', 'Cirurgias', 'Grooming'], 
    4.5
),
(
    'Centro Veterinário de Faro', 
    'Rua de Santo António 789, Faro', 
    '282345678', 
    'www.vetfaro.pt',
    '{"lat": 37.0193, "lng": -7.9304}',
    ARRAY['Consultas', 'Vacinas', 'Microchip'], 
    4.2
)
ON CONFLICT DO NOTHING; 