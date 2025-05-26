-- Inserir um usuário de teste
INSERT INTO public.users (name, phone, password)
VALUES ('Usuário Teste', '900000000', 'senha123')
RETURNING id, name, phone;

-- Após executar a consulta acima, copie o ID retornado para usar abaixo
-- Substitua o UUID_DO_USUARIO_INSERIDO pelo ID retornado

/*
-- Inserir um cão de teste
INSERT INTO public.dogs (
    user_id, 
    nome, 
    raca, 
    idade, 
    sexo, 
    porte, 
    estado, 
    endereco, 
    contacto, 
    location
)
VALUES (
    'UUID_DO_USUARIO_INSERIDO', -- Substituir pelo ID retornado da consulta anterior
    'Rex', 
    'Labrador', 
    '0-5', 
    'male', 
    'medium', 
    'encontrado', 
    'Rua de Teste, 123', 
    '900000000',
    '{"lat": 38.7223, "lng": -9.1393}'
)
RETURNING id;

-- Inserir um abrigo de teste
INSERT INTO public.shelters (
    user_id, 
    endereco, 
    location, 
    aceita_porte, 
    aceita_idade, 
    aceita_sexo
)
VALUES (
    'UUID_DO_USUARIO_INSERIDO', -- Substituir pelo ID retornado da consulta de inserção do usuário
    'Rua do Abrigo, 456', 
    '{"lat": 38.7223, "lng": -9.1393}',
    ARRAY['small', 'medium'],
    ARRAY['0-5', '5-10'],
    ARRAY['male', 'female']
)
RETURNING id;
*/

-- INSTRUÇÕES:
-- 1. Execute apenas a consulta de inserção do usuário primeiro
-- 2. Copie o ID UUID retornado
-- 3. Substitua UUID_DO_USUARIO_INSERIDO pelo valor copiado
-- 4. Descomente e execute as outras consultas 