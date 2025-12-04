<template>
  <div>
    <h1 class="title is-3 mb-5">
      <i class="fas fa-users mr-2"></i>
      Mis Estudiantes
    </h1>

    <div v-if="loading" class="has-text-centered py-5">
      <i class="fas fa-spinner fa-spin fa-2x"></i>
    </div>
    <div v-else-if="misCursos.length === 0" class="has-text-centered py-5">
      <p class="has-text-grey">No tienes cursos asignados</p>
    </div>
    <div v-else>
      <div v-for="curso in misCursos" :key="curso.id" class="card mb-5">
        <div class="card-header">
          <p class="card-header-title">
            {{ curso.nombre }} - {{ curso.grado }}° Grado
          </p>
          <div class="card-header-icon">
            <span class="tag is-primary">{{ curso.total_estudiantes }} estudiantes</span>
          </div>
        </div>
        <div class="card-content">
          <p class="mb-3">
            <strong>Horario:</strong> {{ curso.dia_semana }} de {{ curso.hora_inicio }} a {{ curso.hora_fin }}
          </p>
          <div v-if="curso.estudiantes.length === 0" class="has-text-grey">
            No hay estudiantes matriculados en este curso
          </div>
          <div v-else>
            <table class="table is-fullwidth is-striped">
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Apellido</th>
                  <th>Email</th>
                  <th>Grado</th>
                  <th>Fecha Matrícula</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="estudiante in curso.estudiantes" :key="estudiante.id">
                  <td><strong>{{ estudiante.nombre }}</strong></td>
                  <td>{{ estudiante.apellido }}</td>
                  <td>{{ estudiante.email }}</td>
                  <td>
                    <span class="tag is-info">{{ estudiante.grado }}° Grado</span>
                  </td>
                  <td>{{ formatDate(estudiante.fecha_matricula) }}</td>
                </tr>
              </tbody>
            </table>
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

const loadMisEstudiantes = async () => {
  try {
    // Obtener el docente actual
    const { data: docenteData } = await supabase
      .from('docentes')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (!docenteData) {
      loading.value = false
      return
    }

    // Obtener cursos del docente
    const { data: cursosData, error: cursosErr } = await supabase
      .from('cursos')
      .select('*')
      .eq('docente_id', docenteData.id)

    if (cursosErr) throw cursosErr

    // Para cada curso, obtener los estudiantes
    const cursosConEstudiantes = await Promise.all(
      (cursosData || []).map(async (curso) => {
        const { data: matriculasData } = await supabase
          .from('matriculas')
          .select(`
            fecha_matricula,
            alumnos (id, nombre, apellido, email, grado)
          `)
          .eq('curso_id', curso.id)

        const estudiantes = (matriculasData || []).map(m => ({
          id: m.alumnos.id,
          nombre: m.alumnos.nombre,
          apellido: m.alumnos.apellido,
          email: m.alumnos.email,
          grado: m.alumnos.grado,
          fecha_matricula: m.fecha_matricula
        }))

        return {
          ...curso,
          estudiantes,
          total_estudiantes: estudiantes.length
        }
      })
    )

    misCursos.value = cursosConEstudiantes
  } catch (err) {
    console.error('Error loading mis estudiantes:', err)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

onMounted(() => {
  loadMisEstudiantes()
})
</script>


