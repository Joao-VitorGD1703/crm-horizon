<template>
  <div class="login-container">
    <div class="login-card">
      <h2>HorizonAdmin</h2>
      <p>Área restrita</p>
      
      <form @submit.prevent="handleLogin">
        <div class="input-group">
          <label>Email</label>
          <input type="email" v-model="email" required placeholder="Insira seu e-mail" />
        </div>
        <div class="input-group">
          <label>Senha</label>
          <input type="password" v-model="password" required placeholder="Insira sua senha" />
        </div>
        <div v-if="errorMsg" class="error">{{ errorMsg }}</div>
        <button type="submit" :disabled="loading">{{ loading ? 'Entrando...' : 'Acessar' }}</button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const email = ref('')
const password = ref('')
const errorMsg = ref('')
const loading = ref(false)
const router = useRouter()

const handleLogin = async () => {
  if (email.value && password.value) {
    loading.value = true
    errorMsg.value = ''
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })
      if (error) throw error
      router.push('/admin/dashboard')
    } catch (err) {
      errorMsg.value = 'Falha no login. Verifique suas credenciais.'
    } finally {
      loading.value = false
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
}

.login-card {
  background: #ffffff;
  padding: 2.5rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
  width: 100%;
  max-width: 400px;
  text-align: center;
}

.login-card h2 {
  margin-bottom: 0.5rem;
  color: #374151;
}

.login-card p {
  color: #6B7280;
  margin-bottom: 2rem;
}

.input-group {
  text-align: left;
  margin-bottom: 1.5rem;
}

.input-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #374151;
}

.input-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #D1D5DB;
  border-radius: 8px;
  font-size: 1rem;
  background-color: #ffffff;
  color: #374151;
}

button {
  width: 100%;
  padding: 0.75rem;
  background-color: #DC2626;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

button:hover:not(:disabled) {
  background-color: #B91C1C;
}

button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.error {
  color: #DC2626;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}
</style>
