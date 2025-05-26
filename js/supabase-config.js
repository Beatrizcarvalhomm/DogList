// Configuração do Supabase
const SUPABASE_URL = 'https://jwyzbfbzxbedjskumgli.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eXpiZmJ6eGJlZGpza3VtZ2xpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc3NjA4MDksImV4cCI6MjA2MzMzNjgwOX0.8GEehgGUF-9zv1WwneYZBs1K3VLEZtxB9v0R6An0GIc';

// Inicializar cliente Supabase
window.supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

console.log('Supabase configurado com sucesso'); 