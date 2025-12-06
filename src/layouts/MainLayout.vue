<template>
  <div>
    <nav class="navbar is-primary" role="navigation">
      <div class="navbar-brand">
        <a class="navbar-item" href="/">
          <i class="fas fa-graduation-cap mr-2"></i>
          <strong>Sistema de Matrículas</strong>
        </a>
        <a role="button" class="navbar-burger" :class="{ 'is-active': menuActive }" @click="menuActive = !menuActive">
          <span></span>
          <span></span>
          <span></span>
        </a>
      </div>

      <div class="navbar-menu" :class="{ 'is-active': menuActive }">
        <div class="navbar-start">
          <router-link to="/" class="navbar-item">
            <i class="fas fa-home mr-2"></i> Dashboard
          </router-link>
          
          <router-link v-if="authStore.isAdmin || authStore.isDocente" to="/cursos" class="navbar-item">
            <i class="fas fa-book mr-2"></i> Cursos
          </router-link>
          
          <router-link v-if="authStore.isAdmin" to="/docentes" class="navbar-item">
            <i class="fas fa-chalkboard-teacher mr-2"></i> Docentes
          </router-link>
          
          <router-link v-if="authStore.isAdmin" to="/alumnos" class="navbar-item">
            <i class="fas fa-user-graduate mr-2"></i> Alumnos
          </router-link>
          
          <router-link v-if="authStore.isAdmin" to="/periodos" class="navbar-item">
            <i class="fas fa-calendar-plus mr-2"></i> Periodos
          </router-link>
          
          <router-link v-if="authStore.isAdmin" to="/usuarios" class="navbar-item">
            <i class="fas fa-users-cog mr-2"></i> Usuarios
          </router-link>
          
          <router-link to="/matriculas" class="navbar-item">
            <i class="fas fa-clipboard-list mr-2"></i> Matrículas
          </router-link>
          
          <router-link to="/horarios" class="navbar-item">
            <i class="fas fa-calendar-alt mr-2"></i> Horarios
          </router-link>
          
          <router-link v-if="authStore.isAlumno" to="/mis-cursos" class="navbar-item">
            <i class="fas fa-list mr-2"></i> Mis Cursos
          </router-link>
          
          <router-link v-if="authStore.isDocente" to="/mis-estudiantes" class="navbar-item">
            <i class="fas fa-users mr-2"></i> Mis Estudiantes
          </router-link>
        </div>

        <div class="navbar-end">
          <div class="navbar-item has-dropdown is-hoverable">
            <a class="navbar-link">
              <i class="fas fa-user-circle mr-2"></i>
              {{ authStore.user?.email }}
            </a>
            <div class="navbar-dropdown">
              <div class="navbar-item">
                <small>Rol: {{ authStore.userRole }}</small>
              </div>
              <hr class="navbar-divider">
              <a class="navbar-item" @click="handleLogout">
                <i class="fas fa-sign-out-alt mr-2"></i> Cerrar Sesión
              </a>
            </div>
          </div>
        </div>
      </div>
    </nav>

    <div class="main-content">
      <router-view />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const menuActive = ref(false)

const handleLogout = async () => {
  await authStore.signOut()
  router.push('/login')
}

onMounted(() => {
  authStore.init()
})
</script>
