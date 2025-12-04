<template>
  <div class="login-container">
    <div class="container">
      <div class="columns is-centered">
        <div class="column is-4">
          <div class="card">
            <div class="card-content">
              <div class="has-text-centered mb-5">
                <i class="fas fa-graduation-cap fa-3x has-text-primary"></i>
                <h1 class="title is-3 mt-3">Sistema de Matrículas</h1>
                <p class="subtitle is-6">Inicia sesión para continuar</p>
              </div>

              <div v-if="error" class="notification is-danger">
                {{ error }}
              </div>

              <form @submit.prevent="handleLogin">
                <div class="field">
                  <label class="label">Email</label>
                  <div class="control has-icons-left">
                    <input
                      v-model="email"
                      class="input"
                      type="email"
                      placeholder="tu@email.com"
                      required
                    />
                    <span class="icon is-small is-left">
                      <i class="fas fa-envelope"></i>
                    </span>
                  </div>
                </div>

                <div class="field">
                  <label class="label">Contraseña</label>
                  <div class="control has-icons-left">
                    <input
                      v-model="password"
                      class="input"
                      type="password"
                      placeholder="Contraseña"
                      required
                    />
                    <span class="icon is-small is-left">
                      <i class="fas fa-lock"></i>
                    </span>
                  </div>
                </div>

                <div class="field">
                  <div class="control">
                    <button
                      class="button is-primary is-fullwidth"
                      :class="{ 'is-loading': loading }"
                      type="submit"
                    >
                      Iniciar Sesión
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

const handleLogin = async () => {
  loading.value = true
  error.value = ''
  
  const result = await authStore.signIn(email.value, password.value)
  
  if (result.success) {
    router.push('/')
  } else {
    error.value = result.error || 'Error al iniciar sesión'
  }
  
  loading.value = false
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.card {
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
}
</style>


