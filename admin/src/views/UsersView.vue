<template>
  <div class="users-view">
    <div class="header-actions">
      <h2 class="page-title">Usuários</h2>
      <button class="btn-primary" @click="openCreateModal">Novo Usuário</button>
    </div>

    <!-- TOAST -->
    <div v-if="toast.show" :class="['toast', toast.type]">
      {{ toast.message }}
    </div>

    <div class="filters">
      <input type="text" v-model="filters.search" placeholder="Buscar por nome ou e-mail..." @input="debouncedFetch" />
      <select v-model="filters.subscriptionStatus" @change="fetchUsers">
        <option value="">Todos os Planos</option>
        <option value="trial">Trial</option>
        <option value="premium">Premium</option>
        <option value="cancelado">Cancelado</option>
      </select>
    </div>

    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Nome</th>
            <th>Email</th>
            <th>Hotel</th>
            <th>Plano</th>
            <th>Status</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="6" class="text-center">Carregando...</td>
          </tr>
          <tr v-else-if="users.length === 0">
            <td colspan="6" class="text-center">Nenhum usuário encontrado.</td>
          </tr>
          <tr v-for="user in users" :key="user.id">
            <td>{{ user.name }}</td>
            <td>{{ user.email }}</td>
            <td>{{ user.hotel_name || '-' }}</td>
            <td><span :class="['badge', user.subscription_status]">{{ user.subscription_status }}</span></td>
            <td>
              <span :class="['badge', user.is_active ? 'active' : 'inactive']">
                {{ user.is_active ? 'Ativo' : 'Inativo' }}
              </span>
            </td>
            <td>
              <button class="btn-edit" @click="openEditModal(user)">Editar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="pagination">
      <button :disabled="page === 1" @click="changePage(-1)">Anterior</button>
      <span>Página {{ page }} de {{ totalPages }}</span>
      <button :disabled="page === totalPages" @click="changePage(1)">Próxima</button>
    </div>

    <!-- MODAL CRIAR/EDITAR -->
    <div class="modal-overlay" v-if="showModal">
      <div class="modal">
        <h3>{{ isEditMode ? 'Editar Usuário' : 'Novo Usuário' }}</h3>
        <form @submit.prevent="saveUser">
          
          <div class="input-group">
            <label>Nome</label>
            <input type="text" v-model="form.name" required />
          </div>

          <div class="input-group">
            <label>Email</label>
            <input type="email" v-model="form.email" :disabled="isEditMode" required />
          </div>

          <div class="input-group">
            <label>Nome do Hotel</label>
            <input type="text" v-model="form.hotel_name" />
          </div>

          <div class="input-group">
            <label>Status da Assinatura</label>
            <select v-model="form.subscription_status">
              <option value="trial">Trial</option>
              <option value="premium">Premium</option>
              <option value="cancelado">Cancelado</option>
            </select>
          </div>

          <!-- Campos extras na edição -->
          <template v-if="isEditMode">
            <div class="input-group">
              <label>Acesso Premium Até</label>
              <input type="date" v-model="form.premium_until" :disabled="form.subscription_status === 'trial'" />
            </div>
            <div class="input-group checkbox-group">
              <label>
                <input type="checkbox" v-model="form.cancel_at_period_end" /> 
                Cancelar ao fim do período
              </label>
            </div>
          </template>

          <!-- Senha na Criação -->
          <template v-if="!isEditMode">
            <div class="input-group">
              <label>Senha Inicial</label>
              <input type="text" v-model="form.password" required @input="checkPasswordStrength(form.password)" />
              <div class="password-strength" v-if="form.password">Força da senha: {{ passwordStrength }}</div>
            </div>
          </template>

          <div class="modal-actions space-between">
            <div>
              <button type="button" class="btn-danger" v-if="isEditMode && form.is_active" @click="deactivateUser">Desativar Conta</button>
              <button type="button" class="btn-success" v-if="isEditMode && !form.is_active" @click="activateUser">Reativar Conta</button>
            </div>
            <div>
              <button type="button" class="btn-cancel" @click="closeModal" :disabled="saving">Cancelar</button>
              <button type="submit" class="btn-save" :disabled="saving">{{ saving ? 'Salvando...' : 'Salvar' }}</button>
            </div>
          </div>
        </form>

        <hr v-if="isEditMode" class="divider" />

        <!-- Redefinir Senha -->
        <div v-if="isEditMode" class="reset-password-section">
          <h4>Redefinir Senha</h4>
          <div class="input-group">
            <input type="password" v-model="resetPasswordVal" placeholder="Nova senha" @input="checkPasswordStrength(resetPasswordVal)" />
            <div class="password-strength" v-if="resetPasswordVal">Força: {{ passwordStrength }}</div>
          </div>
          <button type="button" class="btn-secondary" :disabled="!resetPasswordVal || resetting" @click="handleResetPassword">
            {{ resetting ? 'Alterando...' : 'Confirmar Nova Senha' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../lib/supabase'

const users = ref([])
const loading = ref(false)
const saving = ref(false)
const resetting = ref(false)
const total = ref(0)
const page = ref(1)
const limit = 10

const filters = ref({
  search: '',
  subscriptionStatus: ''
})

const showModal = ref(false)
const isEditMode = ref(false)
const form = ref({})
const resetPasswordVal = ref('')
const passwordStrength = ref('')

const toast = ref({ show: false, message: '', type: 'success' })

const showToast = (message, type = 'success') => {
  toast.value = { show: true, message, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}

let timeout = null
const debouncedFetch = () => {
  clearTimeout(timeout)
  timeout = setTimeout(() => {
    page.value = 1
    fetchUsers()
  }, 500)
}

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / limit)))

const fetchUsers = async () => {
  loading.value = true
  try {
    let query = supabase.from('users').select('*', { count: 'exact' })

    if (filters.value.search) {
      query = query.or(`email.ilike.%${filters.value.search}%,name.ilike.%${filters.value.search}%`)
    }
    
    if (filters.value.subscriptionStatus) {
      query = query.eq('subscription_status', filters.value.subscriptionStatus)
    }

    const from = (page.value - 1) * limit
    const to = from + limit - 1

    query = query.range(from, to).order('created_at', { ascending: false })

    const { data, count, error } = await query

    if (error) throw error

    users.value = data
    total.value = count || 0
  } catch (err) {
    console.error(err)
    showToast('Erro ao buscar usuários', 'error')
  } finally {
    loading.value = false
  }
}

const changePage = (step) => {
  page.value += step
  fetchUsers()
}

const openCreateModal = () => {
  isEditMode.value = false
  form.value = {
    name: '', email: '', hotel_name: '', subscription_status: 'trial', password: '', is_active: true
  }
  resetPasswordVal.value = ''
  passwordStrength.value = ''
  showModal.value = true
}

const openEditModal = (user) => {
  isEditMode.value = true
  // Converte a data do formato de banco (ISO) para o formato do input type="date" (YYYY-MM-DD)
  const premiumDate = user.premium_until ? String(user.premium_until).split('T')[0] : ''
  
  form.value = { ...user, premium_until: premiumDate }
  resetPasswordVal.value = ''
  passwordStrength.value = ''
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const checkPasswordStrength = (pwd) => {
  if (pwd.length < 6) {
    passwordStrength.value = 'Fraca'
  } else if (pwd.length >= 8 && /[A-Z]/.test(pwd) && /[0-9]/.test(pwd)) {
    passwordStrength.value = 'Forte'
  } else {
    passwordStrength.value = 'Média'
  }
}

// Interação com a Edge Function para Admin (Necessita do Auth Token)
const callAdminFunction = async (action, payload) => {
  // A chamada via browser enviará automaticamente o Authorization header com o token da sessão atual
  const res = await supabase.functions.invoke('admin-users', {
    body: { action, payload }
  })
  
  if (res.error) {
    let errMsg = res.error.message || "Erro na Edge Function"
    try {
      const errBody = await res.error.context?.json?.()
      if (errBody && errBody.error) errMsg = errBody.error
    } catch(e) {}
    throw new Error(errMsg)
  }
  
  if (res.data && res.data.error) throw new Error(res.data.error)

  return res.data
}

const saveUser = async () => {
  if (form.value.premium_until) {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    const [year, month, day] = form.value.premium_until.split('-')
    const selectedDate = new Date(year, month - 1, day)
    
    if (selectedDate < today) {
      showToast('A data de acesso Premium não pode ser anterior a hoje.', 'error')
      return
    }
  }

  saving.value = true
  try {
    if (isEditMode.value) {
      // Editar apenas tabela users
      const { error } = await supabase
        .from('users')
        .update({
          name: form.value.name,
          hotel_name: form.value.hotel_name,
          subscription_status: form.value.subscription_status,
          premium_until: form.value.premium_until || null,
          cancel_at_period_end: form.value.cancel_at_period_end,
          is_active: form.value.is_active
        })
        .eq('id', form.value.id)

      if (error) throw error
      showToast('Usuário atualizado com sucesso!')
    } else {
      // Criar usuário (Chama Edge Function)
      await callAdminFunction('create_user', {
        email: form.value.email,
        password: form.value.password,
        name: form.value.name,
        hotel_name: form.value.hotel_name,
        subscription_status: form.value.subscription_status
      })
      showToast('Usuário criado com sucesso!')
    }
    
    closeModal()
    fetchUsers()
  } catch (err) {
    console.error(err)
    showToast(err.message || 'Erro ao salvar usuário', 'error')
  } finally {
    saving.value = false
  }
}

const handleResetPassword = async () => {
  if (!confirm('Deseja realmente alterar a senha deste usuário?')) return
  resetting.value = true
  try {
    await callAdminFunction('reset_password', {
      id: form.value.id,
      password: resetPasswordVal.value
    })
    showToast('Senha redefinida com sucesso!')
    resetPasswordVal.value = ''
  } catch (err) {
    console.error(err)
    showToast(err.message || 'Erro ao redefinir senha', 'error')
  } finally {
    resetting.value = false
  }
}

const deactivateUser = async () => {
  if (!confirm('Tem certeza que deseja DESATIVAR este usuário? O histórico será preservado.')) return
  form.value.is_active = false
  await saveUser()
}

const activateUser = async () => {
  form.value.is_active = true
  await saveUser()
}

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.users-view { position: relative; }
.header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; }
.page-title { margin-bottom: 0; color: #374151; }

.toast {
  position: fixed; top: 20px; right: 20px; padding: 1rem 1.5rem; border-radius: 8px; color: white;
  z-index: 1000; font-weight: 600; box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  animation: slideIn 0.3s ease-out;
}
.toast.success { background-color: #10B981; }
.toast.error { background-color: #EF4444; }

@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

.filters { display: flex; gap: 1rem; margin-bottom: 1.5rem; }
.filters input, .filters select {
  padding: 0.5rem; border: 1px solid #D1D5DB; border-radius: 8px; min-width: 250px; color: #374151; background-color: #ffffff;
}
.table-container { background: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); overflow-x: auto; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 1rem; text-align: left; border-bottom: 1px solid #F3F4F6; color: #374151; }
th { background-color: #F9FAFB; color: #6B7280; font-weight: 600; font-size: 0.875rem; }
.text-center { text-align: center; padding: 2rem !important; color: #6B7280; }
.badge { padding: 0.25rem 0.5rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; text-transform: capitalize; }
.badge.premium { background: #DC2626; color: #ffffff; }
.badge.trial { background: #9CA3AF; color: #ffffff; }
.badge.cancelado { background: #E5E7EB; color: #6B7280; text-decoration: line-through; }
.badge.active { background: #D1D5DB; color: #374151; }
.badge.inactive { background: #F3F4F6; color: #9CA3AF; }

.btn-primary { background: #DC2626; color: white; border: none; padding: 0.5rem 1.5rem; border-radius: 8px; font-weight: 600; cursor: pointer; }
.btn-primary:hover { background: #B91C1C; }
.btn-edit { background: transparent; color: #DC2626; border: 1px solid #DC2626; padding: 0.25rem 0.75rem; border-radius: 8px; cursor: pointer; font-weight: 500; }
.btn-edit:hover { background: #DC2626; color: #ffffff; }
.btn-danger { background: transparent; color: #EF4444; border: 1px solid #EF4444; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; font-weight: 500; }
.btn-danger:hover { background: #EF4444; color: white; }
.btn-success { background: transparent; color: #10B981; border: 1px solid #10B981; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; font-weight: 500; }
.btn-success:hover { background: #10B981; color: white; }
.btn-secondary { background: #4B5563; color: white; border: none; padding: 0.5rem 1rem; border-radius: 8px; font-weight: 500; cursor: pointer; }
.btn-secondary:hover:not(:disabled) { background: #374151; }
.btn-secondary:disabled { opacity: 0.5; cursor: not-allowed; }

.pagination { display: flex; justify-content: center; align-items: center; gap: 1rem; margin-top: 1.5rem; }
.pagination button { padding: 0.5rem 1rem; border: 1px solid #D1D5DB; background: #ffffff; border-radius: 8px; cursor: pointer; color: #374151; font-weight: 500; }
.pagination button:disabled { opacity: 0.5; cursor: not-allowed; }

/* Modal */
.modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 50; }
.modal { background: #ffffff; padding: 2rem; border-radius: 8px; width: 100%; max-width: 500px; max-height: 90vh; overflow-y: auto; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }
.modal h3 { margin-bottom: 1.5rem; color: #374151; }
.input-group { margin-bottom: 1rem; }
.input-group label { display: block; margin-bottom: 0.5rem; font-size: 0.875rem; font-weight: 500; color: #374151; }
.input-group input[type="text"], .input-group input[type="email"], .input-group input[type="date"], .input-group input[type="password"], .input-group select { width: 100%; padding: 0.5rem; border: 1px solid #D1D5DB; border-radius: 8px; color: #374151; background-color: #ffffff; }
.input-group input:disabled { background-color: #F3F4F6; color: #9CA3AF; }
.checkbox-group { display: flex; align-items: center; flex-direction: row; }
.checkbox-group input { margin-right: 0.5rem; width: auto; }
.password-strength { font-size: 0.75rem; color: #6B7280; margin-top: 0.25rem; }

.modal-actions { display: flex; justify-content: flex-end; gap: 1rem; margin-top: 2rem; }
.modal-actions.space-between { justify-content: space-between; }
.modal-actions div { display: flex; gap: 0.5rem; }

.btn-cancel { background: #F3F4F6; border: none; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; font-weight: 500; color: #374151; }
.btn-cancel:hover { background: #E5E7EB; }
.btn-save { background: #DC2626; color: #ffffff; border: none; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; font-weight: 500; }
.btn-save:hover:not(:disabled) { background: #B91C1C; }
.btn-save:disabled { opacity: 0.5; cursor: not-allowed; }

.divider { border: 0; border-top: 1px solid #E5E7EB; margin: 2rem 0; }
.reset-password-section h4 { margin-top: 0; margin-bottom: 1rem; color: #374151; }
</style>
