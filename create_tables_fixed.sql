-- Ative a extensão uuid-ossp
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Desativar RLS temporariamente para todas as tabelas (para garantir permissão total durante o setup)
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dogs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shelters DISABLE ROW LEVEL SECURITY;

-- Criar tabela de utilizadores
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de cães
CREATE TABLE IF NOT EXISTS public.dogs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    nome TEXT,
    raca TEXT,
    idade TEXT,
    sexo TEXT,
    porte TEXT,
    estado TEXT NOT NULL,
    descricao TEXT,
    caracteristicas TEXT,
    castrado BOOLEAN,
    agressivo TEXT,
    endereco TEXT,
    contato TEXT,
    image TEXT,
    location JSONB,
    data_adicao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de abrigos temporários
CREATE TABLE IF NOT EXISTS public.shelters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    endereco TEXT,
    location JSONB,
    aceita_porte TEXT[],
    aceita_idade TEXT[],
    aceita_sexo TEXT[],
    aceita_castrado TEXT[],
    aceita_agressivo TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garantir que o papel anon tenha acesso às tabelas
GRANT ALL ON public.users TO anon;
GRANT ALL ON public.dogs TO anon;
GRANT ALL ON public.shelters TO anon;

-- Garantir que o papel service_role tenha acesso às tabelas
GRANT ALL ON public.users TO service_role;
GRANT ALL ON public.dogs TO service_role;
GRANT ALL ON public.shelters TO service_role;

-- Garantir que o esquema public tenha as permissões corretas
GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;

-- Remover todas as políticas RLS existentes
DROP POLICY IF EXISTS users_policy ON public.users;
DROP POLICY IF EXISTS dogs_select_policy ON public.dogs;
DROP POLICY IF EXISTS dogs_insert_policy ON public.dogs;
DROP POLICY IF EXISTS dogs_update_policy ON public.dogs;
DROP POLICY IF EXISTS dogs_delete_policy ON public.dogs;
DROP POLICY IF EXISTS shelters_policy ON public.shelters;

-- Confirmar que RLS está DESATIVADO em todas as tabelas
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dogs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shelters DISABLE ROW LEVEL SECURITY;

-- NÃO HABILITAREMOS RLS AGORA PARA FACILITAR O TESTE
-- Se quiser habilitar depois, use os comandos abaixo:
--
-- -- Habilitar RLS para as tabelas
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.shelters ENABLE ROW LEVEL SECURITY;
-- 
-- -- Criar políticas para utilizadores
-- CREATE POLICY "Acesso total para utilizadores" 
-- ON public.users FOR ALL TO anon, authenticated
-- USING (true) WITH CHECK (true);
-- 
-- -- Criar políticas para cães
-- CREATE POLICY "Acesso total para cães" 
-- ON public.dogs FOR ALL TO anon, authenticated
-- USING (true) WITH CHECK (true);
-- 
-- -- Criar políticas para abrigos
-- CREATE POLICY "Acesso total para abrigos" 
-- ON public.shelters FOR ALL TO anon, authenticated
-- USING (true) WITH CHECK (true);

-- IMPORTANTE: Esta versão simplificada permite acesso total sem autenticação para facilitar o teste.
-- Em produção, você deve implementar políticas RLS mais restritivas. 