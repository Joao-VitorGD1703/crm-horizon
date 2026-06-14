<template>
  <div class="admin-layout">
    <aside class="sidebar">
      <div class="brand">HorizonAdmin</div>
      <nav>
        <router-link to="/admin/dashboard" class="nav-item">Dashboard</router-link>
        <router-link to="/admin/usuarios" class="nav-item">Usuários</router-link>
      </nav>
      <div class="bottom-nav">
        <button @click="logout" class="logout-btn">Sair</button>
      </div>
    </aside>
    <main class="main-content">
      <router-view></router-view>
    </main>
  </div>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const logout = async () => {
  await authStore.signOut()
  router.push('/admin/login')
}
</script>

<style scoped>
.admin-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 250px;
  background-color: #DC2626;
  color: #ffffff;
  display: flex;
  flex-direction: column;
}

.brand {
  padding: 1.5rem;
  font-size: 1.5rem;
  font-weight: 700;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.nav-item {
  display: block;
  padding: 1rem 1.5rem;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  font-weight: 500;
  transition: all 0.2s;
}

.nav-item:hover, .router-link-active {
  background-color: #B91C1C;
  color: #ffffff;
  border-left: 4px solid #ffffff;
}

.bottom-nav {
  margin-top: auto;
  padding: 1.5rem;
}

.logout-btn {
  width: 100%;
  padding: 0.75rem;
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.5);
  color: #ffffff;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.logout-btn:hover {
  background-color: #B91C1C;
  border-color: #ffffff;
}

.main-content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
}
</style>
