<template>
  <div>
    <h1 class="title is-3 mb-5">
      <i class="fas fa-list mr-2"></i>
      Mis Cursos
    </h1>

    <div v-if="loading" class="has-text-centered py-5">
      <i class="fas fa-spinner fa-spin fa-2x"></i>
    </div>
    <div v-else-if="misCursos.length === 0" class="has-text-centered py-5">
      <p class="has-text-grey mb-4">No tienes cursos matriculados</p>
      <router-link to="/matriculas" class="button is-primary">
        <i class="fas fa-plus mr-2"></i>
        Matricularme en un Curso
      </router-link>
    </div>
    <div v-else class="columns is-multiline">
      <div v-for="curso in misCursos" :key="curso.id" class="column is-4">
        <div class="card">
          <div class="card-header">
            <p class="card-header-title">{{ curso.nombre }}</p>
          </div>
          <div class="card-content">
            <div class="content">
              <p><strong>Grado:</strong> <span class="tag is-info">{{ curso.grado }}° Grado</span></p>
              <p><strong>Docente:</strong> {{ curso.docente_nombre }}</p>
              <p><strong>Horario:</strong> {{ curso.dia_semana }} de {{ curso.hora_inicio }} a {{ curso.hora_fin }}</p>
              <p v-if="curso.descripcion"><strong>Descripción:</strong> {{ curso.descripcion }}</p>
              <p><strong>Fecha de Matrícula:</strong> {{ formatDate(curso.fecha_matricula) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/config/supabase'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const misCursos = ref([])
const loading = ref(true)

const loadMisCursos = async () => {
  try {
    const { data: alumnoData } = await supabase
      .from('alumnos')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (!alumnoData) {
      loading.value = false
      return
    }

    const { data, error: err } = await supabase
      .from('matriculas')
      .select(`
        id,
        fecha_matricula,
        cursos (
          id,
          nombre,
          descripcion,
          grado,
          dia_semana,
          hora_inicio,
          hora_fin,
          docentes (nombre, apellido)
        )
      `)
      .eq('alumno_id', alumnoData.id)
      .order('fecha_matricula', { ascending: false })

    if (err) throw err

    misCursos.value = (data || []).map(m => ({
      id: m.cursos.id,
      nombre: m.cursos.nombre,
      descripcion: m.cursos.descripcion,
      grado: m.cursos.grado,
      dia_semana: m.cursos.dia_semana,
      hora_inicio: m.cursos.hora_inicio,
      hora_fin: m.cursos.hora_fin,
      docente_nombre: m.cursos.docentes ? `${m.cursos.docentes.nombre} ${m.cursos.docentes.apellido}` : null,
      fecha_matricula: m.fecha_matricula
    }))
  } catch (err) {
    console.error('Error loading mis cursos:', err)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

onMounted(() => {
  loadMisCursos()
})
</script>


