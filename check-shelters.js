// Script para verificar abrigos no Supabase
console.log('=== VERIFICAÇÃO DE ABRIGOS ===');

// Verificar localStorage (dados antigos)
const localShelters = localStorage.getItem('shelters');
if (localShelters) {
    const shelters = JSON.parse(localShelters);
    console.log('Abrigos no localStorage:', shelters.length);
    console.log('Dados:', shelters);
} else {
    console.log('Nenhum abrigo encontrado no localStorage');
}

// Verificar Supabase (dados novos)
async function checkSupabaseShelters() {
    try {
        // Inicializar Supabase
        const supabaseUrl = 'https://jwyzbfbzxbedjskumgli.supabase.co';
        const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eXpiZmJ6eGJlZGpza3VtZ2xpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc3NjA4MDksImV4cCI6MjA2MzMzNjgwOX0.8GEehgGUF-9zv1WwneYZBs1K3VLEZtxB9v0R6An0GIc';
        
        if (typeof supabase !== 'undefined') {
            const { createClient } = supabase;
            const client = createClient(supabaseUrl, supabaseKey);
            
            // Buscar abrigos
            const { data, error } = await client
                .from('shelters')
                .select('*, users(name, phone)');
            
            if (error) {
                console.error('Erro ao buscar abrigos no Supabase:', error);
            } else {
                console.log('Abrigos no Supabase:', data.length);
                console.log('Dados:', data);
                
                // Mostrar IDs dos abrigos para teste
                if (data.length > 0) {
                    console.log('IDs dos abrigos para teste:');
                    data.forEach(shelter => {
                        console.log(`- ID: ${shelter.id} | Nome: ${shelter.users?.name || 'Sem nome'} | Endereço: ${shelter.endereco}`);
                        console.log(`  Link de teste: shelter-details.html?id=${shelter.id}`);
                    });
                }
            }
        } else {
            console.log('Supabase não está carregado. Carregue esta página em uma página que tenha o Supabase.');
        }
    } catch (error) {
        console.error('Erro ao verificar Supabase:', error);
    }
}

// Executar verificação do Supabase se disponível
if (typeof supabase !== 'undefined') {
    checkSupabaseShelters();
} else {
    console.log('Para verificar dados do Supabase, execute este script em uma página que tenha o Supabase carregado.');
}
