// Supabase Client Integration
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.4/+esm'

// Configuração do cliente Supabase
const SUPABASE_URL = 'https://hvipmhdmppyfslbdnevq.supabase.co'
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2aXBtaGRtcHB5ZnNsYmRuZXZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4MjY0NjUsImV4cCI6MjA2MDQwMjQ2NX0.36E2gK-S8zDW4qyI3OaezbllEF7Rg_yKpXafzNbP_I4'

// Criar e exportar a instância do Supabase
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

// Helper para checar se bcrypt está disponível
const isBcryptAvailable = () => {
  return typeof window !== 'undefined' && typeof window.bcrypt !== 'undefined';
}

/**
 * Inicializa o cliente Supabase
 * @returns {Object} Cliente Supabase inicializado
 */
export function initSupabase() {
  return supabase
}

/**
 * Encripta senha com bcrypt se disponível
 * @param {string} password - Senha a ser encriptada
 * @returns {Promise<string>} Senha encriptada ou original
 */
async function hashPassword(password) {
  if (isBcryptAvailable()) {
    try {
      // Usar window.bcrypt pois estamos em ambiente de navegador
      const hashedPassword = await window.bcrypt.hash(password, 10);
      console.log('Senha encriptada com bcrypt');
      return hashedPassword;
    } catch (hashError) {
      console.error('Erro ao encriptar senha com bcrypt:', hashError);
      return password; // Fallback
    }
  } else {
    console.warn('Bcrypt não disponível, usando senha sem encriptação');
    return password;
  }
}

/**
 * Verifica senha com bcrypt se disponível
 * @param {string} password - Senha fornecida
 * @param {string} hashedPassword - Hash armazenado da senha
 * @returns {Promise<boolean>} Resultado da comparação
 */
async function comparePassword(password, hashedPassword) {
  if (isBcryptAvailable()) {
    try {
      // Usar window.bcrypt em ambiente de navegador
      return await window.bcrypt.compare(password, hashedPassword);
    } catch (compareError) {
      console.error('Erro ao validar senha com bcrypt:', compareError);
      return password === hashedPassword; // Fallback
    }
  } else {
    console.warn('Bcrypt não disponível, comparando senhas diretamente');
    return password === hashedPassword;
  }
}

/**
 * Registra um novo usuário no sistema
 * @param {Object} userData - Dados do usuário (nome, telefone, password)
 * @returns {Object} Status da operação e dados do usuário registrado
 */
export async function registerUser(userData) {
  try {
    console.log('Iniciando registro de usuário:', { nome: userData.nome, telefone: userData.telefone });
    
    if (!userData.telefone || !userData.nome || !userData.password) {
      console.error('Dados de usuário incompletos');
      return { success: false, error: 'Por favor, preencha todos os campos' };
    }

    // Verificar se o telefone já existe
    console.log('Verificando disponibilidade do telefone:', userData.telefone);
    const { data: existingUser, error: searchError } = await supabase
      .from('users')
      .select('telefone')
      .eq('telefone', userData.telefone)
      .maybeSingle();
    
    if (searchError) {
      console.error('Erro ao verificar telefone:', searchError);
      return { 
        success: false, 
        error: 'Erro ao verificar disponibilidade de telefone: ' + searchError.message 
      };
    }
    
    if (existingUser) {
      console.log('Telefone já registrado:', userData.telefone);
      return { success: false, error: 'Telefone já registrado' };
    }
    
    // Encriptar a senha com bcrypt
    console.log('Encriptando senha...');
    const hashedPassword = await hashPassword(userData.password);
    
    // Gerar UUID para o usuário
    const userId = crypto.randomUUID();
    console.log('UUID gerado:', userId);
    
    // Inserir dados na tabela users com senha encriptada
    console.log('Inserindo novo usuário...');
    const { data, error } = await supabase
      .from('users')
      .insert([
        {
          id: userId,
          nome: userData.nome,
          telefone: userData.telefone,
          password: hashedPassword
        }
      ])
      .select();
    
    if (error) {
      console.error('Erro ao inserir usuário:', error);
      return { 
        success: false, 
        error: 'Erro ao criar usuário: ' + error.message 
      };
    }
    
    if (!data || data.length === 0) {
      console.error('Nenhum dado retornado após inserção');
      return { 
        success: false, 
        error: 'Falha ao obter dados do usuário após registro' 
      };
    }
    
    console.log('Usuário registrado com sucesso:', data[0].id);
    
    // Armazenar informações no localStorage para acesso local
    const userInfo = {
      id: data[0].id,
      nome: data[0].nome,
      telefone: data[0].telefone
    };
    
    localStorage.setItem('currentUser', JSON.stringify(userInfo));
    localStorage.setItem('loggedIn', 'true');
    
    return { success: true, user: data[0] };
  } catch (error) {
    console.error('Erro no processo de registro:', error);
    return { 
      success: false, 
      error: 'Erro no processo de registro: ' + error.message 
    };
  }
}

/**
 * Realiza login de um usuário
 * @param {Object} credentials - Credenciais (telefone, password)
 * @returns {Object} Status da operação e dados do usuário logado
 */
export async function loginUser(credentials) {
  try {
    // Buscar usuário pelo telefone
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('telefone', credentials.telefone)
      .single()
    
    if (userError) {
      console.error('Erro ao buscar usuário:', userError)
      return { success: false, error: 'Telefone ou senha incorretos' }
    }
    
    if (!userData) {
      return { success: false, error: 'Usuário não encontrado' }
    }
    
    // Verificar senha com bcrypt
    const senhaCorreta = await comparePassword(credentials.password, userData.password);
    
    if (!senhaCorreta) {
      return { success: false, error: 'Senha incorreta' }
    }
    
    // Login com Supabase Auth - comentado até implementar auth por telefone
    /*
    const { error: authError } = await supabase.auth.signInWithPassword({
      phone: '+351' + credentials.telefone,
      password: credentials.password,
    })
    
    if (authError) {
      console.error('Erro na autenticação do Supabase:', authError)
      // Continuamos mesmo com erro no Auth pois já validamos a senha manualmente
    }
    */
    
    // Armazenar no localStorage para acesso local
    const userInfo = {
      id: userData.id,
      nome: userData.nome,
      telefone: userData.telefone
    };
    
    localStorage.setItem('currentUser', JSON.stringify(userInfo));
    localStorage.setItem('loggedIn', 'true');
    
    return { success: true, user: userData }
  } catch (error) {
    console.error('Erro no login:', error)
    return { success: false, error: 'Erro ao fazer login: ' + error.message }
  }
}

/**
 * Realiza logout do usuário atual
 * @returns {Object} Status da operação
 */
export async function logoutUser() {
  try {
    const { error } = await supabase.auth.signOut()
    
    if (error) {
      console.error('Erro ao fazer logout:', error)
      return { success: false, error: error.message }
    }
    
    // Limpar dados locais
    localStorage.removeItem('currentUser')
    return { success: true }
  } catch (error) {
    console.error('Erro no logout:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Faz upload de uma imagem para o storage do Supabase
 * @param {File} file - Arquivo de imagem
 * @param {string} folder - Pasta para armazenar a imagem
 * @returns {Object} Status da operação e URL da imagem
 */
export async function uploadImage(file, folder = 'dogs') {
  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Math.random().toString(36).substring(2, 15)}.${fileExt}`
    const filePath = `${folder}/${fileName}`
    
    const { data, error } = await supabase.storage
      .from('images')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false
      })
    
    if (error) {
      console.error('Erro no upload da imagem:', error)
      return { success: false, error: error.message }
    }
    
    // Obter URL pública da imagem
    const { data: urlData } = supabase.storage
      .from('images')
      .getPublicUrl(filePath)
    
    return { 
      success: true, 
      url: urlData.publicUrl 
    }
  } catch (error) {
    console.error('Erro no upload:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Salva um registro de cachorro no banco de dados
 * @param {Object} dogData - Dados do cachorro
 * @returns {Object} Status da operação e dados do cachorro
 */
export async function saveDog(dogData) {
  try {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'))
    
    if (!currentUser) {
      return { success: false, error: 'Usuário não autenticado' }
    }
    
    // Preparar dados para inserção
    const newDog = {
      ...dogData,
      user_id: currentUser.id,
      user_name: currentUser.nome,
      contato: dogData.contato || currentUser.telefone
    }
    
    // Inserir na tabela dogs
    const { data, error } = await supabase
      .from('dogs')
      .insert([newDog])
      .select()
    
    if (error) {
      console.error('Erro ao salvar cachorro:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, dog: data[0] }
  } catch (error) {
    console.error('Erro ao salvar:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca todos os cachorros ou filtra por estado
 * @param {string} estado - Estado do cachorro (opcional)
 * @returns {Object} Status da operação e lista de cachorros
 */
export async function getDogs(estado = null) {
  try {
    // Construir query base
    let query = supabase
      .from('dogs')
      .select('*')
    
    // Aplicar filtro de estado se fornecido
    if (estado) {
      query = query.eq('estado', estado)
    }
    
    // Executar query
    const { data, error } = await query.order('data_registro', { ascending: false })
    
    if (error) {
      console.error('Erro ao buscar cachorros:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, dogs: data }
  } catch (error) {
    console.error('Erro na busca:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca cachorros de um usuário específico
 * @param {string} userId - ID do usuário (opcional, usa o usuário atual se não fornecido)
 * @returns {Object} Status da operação e lista de cachorros do usuário
 */
export async function getDogsByUser(userId = null) {
  try {
    // Determinar ID do usuário
    let targetUserId = userId
    if (!targetUserId) {
      const currentUser = JSON.parse(localStorage.getItem('currentUser'))
      if (!currentUser) {
        return { success: false, error: 'Usuário não autenticado' }
      }
      targetUserId = currentUser.id
    }
    
    // Buscar cachorros do usuário
    const { data, error } = await supabase
      .from('dogs')
      .select('*')
      .eq('user_id', targetUserId)
      .order('data_registro', { ascending: false })
    
    if (error) {
      console.error('Erro ao buscar cachorros do usuário:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, dogs: data }
  } catch (error) {
    console.error('Erro na busca por usuário:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Remove um cachorro do banco de dados
 * @param {string} dogId - ID do cachorro a ser removido
 * @returns {Object} Status da operação
 */
export async function removeDog(dogId) {
  try {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'))
    
    if (!currentUser) {
      return { success: false, error: 'Usuário não autenticado' }
    }
    
    // Verificar se o cachorro pertence ao usuário atual
    const { data: dogCheck, error: checkError } = await supabase
      .from('dogs')
      .select('user_id')
      .eq('id', dogId)
      .single()
    
    if (checkError) {
      console.error('Erro ao verificar cachorro:', checkError)
      return { success: false, error: checkError.message }
    }
    
    if (dogCheck.user_id !== currentUser.id) {
      return { success: false, error: 'Você não tem permissão para remover este cachorro' }
    }
    
    // Remover o cachorro
    const { error } = await supabase
      .from('dogs')
      .delete()
      .eq('id', dogId)
    
    if (error) {
      console.error('Erro ao remover cachorro:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true }
  } catch (error) {
    console.error('Erro na remoção:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca clínicas veterinárias próximas a uma localização
 * @param {number} lat - Latitude da localização
 * @param {number} lng - Longitude da localização
 * @param {number} radiusKm - Raio de busca em quilômetros (padrão: 10km)
 * @returns {Object} Status da operação e lista de clínicas
 */
export async function getClinics(lat, lng, radiusKm = 10) {
  try {
    // Usar função SQL personalizada para buscar clínicas próximas
    const { data, error } = await supabase
      .rpc('nearby_clinics', { 
        lat: lat, 
        lng: lng, 
        radius_km: radiusKm 
      })
    
    if (error) {
      console.error('Erro ao buscar clínicas:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, clinics: data }
  } catch (error) {
    console.error('Erro na busca de clínicas:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca a lista de raças de cachorros do sistema
 * @returns {Object} Status da operação e lista de raças
 */
export async function getBreeds() {
  try {
    // Buscar lista de raças das configurações do app
    const { data, error } = await supabase
      .from('configuracoes_app')
      .select('valor')
      .eq('chave', 'lista_racas')
      .single()
    
    if (error) {
      console.error('Erro ao buscar raças:', error)
      // Fallback para lista padrão em caso de erro
      return { 
        success: true, 
        breeds: [
          "Labrador Retriever", "Pastor Alemão", "Golden Retriever", 
          "Bulldog", "Poodle", "Beagle", "Rottweiler", "Yorkshire Terrier", 
          "Boxer", "Dachshund", "Pug", "Shih Tzu", "Husky Siberiano", 
          "Chihuahua", "Doberman", "Schnauzer", "Pit Bull", "Bulldog Francês", "Outro"
        ]
      }
    }
    
    return { success: true, breeds: data.valor }
  } catch (error) {
    console.error('Erro ao buscar raças:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Atualiza os dados de um cachorro
 * @param {string} dogId - ID do cachorro
 * @param {Object} updatedData - Novos dados do cachorro
 * @returns {Object} Status da operação e dados atualizados
 */
export async function updateDog(dogId, updatedData) {
  try {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'))
    
    if (!currentUser) {
      return { success: false, error: 'Usuário não autenticado' }
    }
    
    // Verificar se o cachorro pertence ao usuário atual
    const { data: dogCheck, error: checkError } = await supabase
      .from('dogs')
      .select('user_id')
      .eq('id', dogId)
      .single()
    
    if (checkError) {
      console.error('Erro ao verificar cachorro:', checkError)
      return { success: false, error: checkError.message }
    }
    
    if (dogCheck.user_id !== currentUser.id) {
      return { success: false, error: 'Você não tem permissão para atualizar este cachorro' }
    }
    
    // Atualizar o cachorro
    const { data, error } = await supabase
      .from('dogs')
      .update(updatedData)
      .eq('id', dogId)
      .select()
    
    if (error) {
      console.error('Erro ao atualizar cachorro:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, dog: data[0] }
  } catch (error) {
    console.error('Erro na atualização:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Atualiza os dados do usuário atual
 * @param {Object} userData - Novos dados do usuário
 * @returns {Object} Status da operação e dados atualizados
 */
export async function updateUserProfile(userData) {
  try {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'))
    
    if (!currentUser) {
      return { success: false, error: 'Usuário não autenticado' }
    }
    
    // Atualizar dados do usuário
    const { data, error } = await supabase
      .from('users')
      .update(userData)
      .eq('id', currentUser.id)
      .select()
    
    if (error) {
      console.error('Erro ao atualizar perfil:', error)
      return { success: false, error: error.message }
    }
    
    // Atualizar localStorage
    const updatedUser = {
      ...currentUser,
      ...userData
    }
    localStorage.setItem('currentUser', JSON.stringify(updatedUser))
    
    return { success: true, user: data[0] }
  } catch (error) {
    console.error('Erro na atualização do perfil:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca cachorros com base em critérios de filtro
 * @param {Object} filters - Critérios de filtro (raca, porte, estado, etc.)
 * @returns {Object} Status da operação e lista de cachorros filtrados
 */
export async function searchDogs(filters) {
  try {
    // Construir query base
    let query = supabase
      .from('dogs')
      .select('*')
    
    // Aplicar filtros
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== null && value !== undefined && value !== '') {
        query = query.eq(key, value)
      }
    })
    
    // Executar query
    const { data, error } = await query.order('data_registro', { ascending: false })
    
    if (error) {
      console.error('Erro na busca com filtros:', error)
      return { success: false, error: error.message }
    }
    
    return { success: true, dogs: data }
  } catch (error) {
    console.error('Erro na busca com filtros:', error)
    return { success: false, error: error.message }
  }
}

/**
 * Busca cachorros próximos a uma localização
 * @param {number} lat - Latitude da localização
 * @param {number} lng - Longitude da localização
 * @param {number} radiusKm - Raio de busca em quilômetros (padrão: 5km)
 * @param {Object} filters - Filtros adicionais (opcional)
 * @returns {Object} Status da operação e lista de cachorros próximos
 */
export async function findNearbyDogs(lat, lng, radiusKm = 5, filters = {}) {
  try {
    // Construir query com filtro de localização
    let query = supabase.rpc('find_nearby_dogs', {
      lat: lat,
      lng: lng,
      radius_km: radiusKm
    })
    
    // Aplicar filtros adicionais se houver
    if (Object.keys(filters).length > 0) {
      // Como estamos usando RPC, precisamos refinar os resultados depois
      const { data: initialResults, error: initialError } = await query
      
      if (initialError) {
        console.error('Erro na busca inicial:', initialError)
        return { success: false, error: initialError.message }
      }
      
      // Aplicar filtros aos resultados iniciais
      const filteredResults = initialResults.filter(dog => {
        return Object.entries(filters).every(([key, value]) => {
          return value === null || value === undefined || value === '' || dog[key] === value
        })
      })
      
      return { success: true, dogs: filteredResults }
    } else {
      // Sem filtros adicionais, retornar resultados da RPC diretamente
      const { data, error } = await query
      
      if (error) {
        console.error('Erro na busca por proximidade:', error)
        return { success: false, error: error.message }
      }
      
      return { success: true, dogs: data }
    }
  } catch (error) {
    console.error('Erro na busca por proximidade:', error)
    return { success: false, error: error.message }
  }
}

// Expor funções globalmente
window.supabaseServices = {
  registerUser,
  loginUser,
  logoutUser,
  uploadImage,
  saveDog,
  getDogs,
  getDogsByUser,
  removeDog,
  getClinics,
  getBreeds,
  updateDog,
  updateUserProfile,
  searchDogs,
  findNearbyDogs
} 