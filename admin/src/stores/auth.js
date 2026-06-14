import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '../lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)

  async function checkSession() {
    const { data } = await supabase.auth.getSession()
    user.value = data.session?.user || null
  }

  async function signOut() {
    await supabase.auth.signOut()
    user.value = null
  }

  return { user, checkSession, signOut }
})
