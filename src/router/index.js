import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    redirect: '/',
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('@/views/Dashboard.vue'),
        meta: { requiresAuth: true }
      },
      {
        path: 'cursos',
        name: 'Cursos',
        component: () => import('@/views/Cursos.vue'),
        meta: { requiresAuth: true, roles: ['admin', 'docente'] }
      },
      {
        path: 'cursos/:id',
        name: 'CursoDetalle',
        component: () => import('@/views/CursoDetalle.vue'),
        meta: { requiresAuth: true, roles: ['admin', 'docente'] }
      },
      {
        path: 'docentes',
        name: 'Docentes',
        component: () => import('@/views/Docentes.vue'),
        meta: { requiresAuth: true, roles: ['admin'] }
      },
      {
        path: 'alumnos',
        name: 'Alumnos',
        component: () => import('@/views/Alumnos.vue'),
        meta: { requiresAuth: true, roles: ['admin'] }
      },
      {
        path: 'periodos',
        name: 'Periodos',
        component: () => import('@/views/Periodos.vue'),
        meta: { requiresAuth: true, roles: ['admin'] }
      },
      {
        path: 'alumnos/:id',
        name: 'AlumnoDetalle',
        component: () => import('@/views/AlumnoDetalle.vue'),
        meta: { requiresAuth: true, roles: ['admin'] }
      },
      {
        path: 'usuarios',
        name: 'Usuarios',
        component: () => import('@/views/Usuarios.vue'),
        meta: { requiresAuth: true, roles: ['admin'] }
      },
      {
        path: 'matriculas',
        name: 'Matriculas',
        component: () => import('@/views/Matriculas.vue'),
        meta: { requiresAuth: true }
      },
      {
        path: 'horarios',
        name: 'Horarios',
        component: () => import('@/views/Horarios.vue'),
        meta: { requiresAuth: true }
      },
      {
        path: 'mis-cursos',
        name: 'MisCursos',
        component: () => import('@/views/MisCursos.vue'),
        meta: { requiresAuth: true, roles: ['alumno'] }
      },
      {
        path: 'mis-estudiantes',
        name: 'MisEstudiantes',
        component: () => import('@/views/MisEstudiantes.vue'),
        meta: { requiresAuth: true, roles: ['docente'] }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/login'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to, from, next) => {
  try {
    const authStore = useAuthStore()
    
    // Verificar sesión
    await authStore.checkSession()

    // Si la ruta requiere autenticación y el usuario no está autenticado
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
      // Si ya está en login, no redirigir
      if (to.name !== 'Login') {
        next({ name: 'Login' })
      } else {
        next()
      }
    } 
    // Si el usuario está autenticado y trata de ir a login, redirigir al dashboard
    else if (to.name === 'Login' && authStore.isAuthenticated) {
      next({ name: 'Dashboard' })
    }
    // Si la ruta requiere roles específicos
    else if (to.meta.roles && authStore.userRole && !to.meta.roles.includes(authStore.userRole)) {
      next({ name: 'Dashboard' })
    } 
    else {
      next()
    }
  } catch (error) {
    console.error('Error en router guard:', error)
    // En caso de error, permitir acceso a login
    if (to.name !== 'Login') {
      next({ name: 'Login' })
    } else {
      next()
    }
  }
})

export default router
