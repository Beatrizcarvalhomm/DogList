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

-- Criar políticas RLS para a tabela users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Permitir que utilizadores anónimos possam inserir (registar-se)
CREATE POLICY "Permitir registo para anónimos" 
ON public.users FOR INSERT TO anon 
WITH CHECK (true);

-- Permitir que utilizadores autenticados vejam os seus próprios dados
CREATE POLICY "Utilizadores podem ver os seus próprios dados" 
ON public.users FOR SELECT TO authenticated 
USING (auth.uid() = id);

-- Políticas RLS para a tabela dogs
ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;

-- Permitir que todos possam ver todos os cães
CREATE POLICY "Todos podem ver cães" 
ON public.dogs FOR SELECT 
TO anon, authenticated 
USING (true);

-- Permitir que utilizadores autenticados adicionem cães
CREATE POLICY "Utilizadores autenticados podem adicionar cães" 
ON public.dogs FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Permitir que utilizadores autenticados actualizem os seus próprios cães
CREATE POLICY "Utilizadores podem atualizar os seus próprios cães" 
ON public.dogs FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- Permitir que utilizadores autenticados excluam os seus próprios cães
CREATE POLICY "Utilizadores podem excluir os seus próprios cães" 
ON public.dogs FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- Políticas RLS para a tabela shelters
ALTER TABLE public.shelters ENABLE ROW LEVEL SECURITY;

-- Permitir que todos possam ver todos os abrigos
CREATE POLICY "Todos podem ver abrigos" 
ON public.shelters FOR SELECT 
TO anon, authenticated 
USING (true);

-- Permitir que utilizadores autenticados adicionem abrigos
CREATE POLICY "Utilizadores autenticados podem adicionar abrigos" 
ON public.shelters FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Permitir que utilizadores autenticados actualizem os seus próprios abrigos
CREATE POLICY "Utilizadores podem atualizar os seus próprios abrigos" 
ON public.shelters FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- Permitir que utilizadores autenticados excluam os seus próprios abrigos
CREATE POLICY "Utilizadores podem excluir os seus próprios abrigos" 
ON public.shelters FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- Ative a extensão uuid-ossp se ainda não estiver ativada
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- NOTA IMPORTANTE: Execute essas consultas no SQL Editor do Supabase
-- 1. Vá para o SQL Editor no menu lateral do Supabase
-- 2. Cole este conteúdo completo
-- 3. Clique em "Run" para criar todas as tabelas e políticas de uma vez 