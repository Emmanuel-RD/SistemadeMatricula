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
                  <th>Período</th>
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
                  <td>
                    <span class="tag is-light is-info">{{ estudiante.periodo || 'Sin período' }}</span>
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
    const { data: docenteData, error: docenteErr } = await supabase
      .from('docentes')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (docenteErr) {
      if (docenteErr.code === 'PGRST116') {
        loading.value = false
        return
      }
      throw docenteErr
    }
    if (!docenteData) {
      loading.value = false
      return
    }

    const { data: cursosData, error: cursosErr } = await supabase
      .from('cursos')
      .select(`
        *,
        docentes (nombre, apellido)
      `)
      .eq('docente_id', docenteData.id)
      .order('nombre')

    if (cursosErr) throw cursosErr

    const cursoIds = (cursosData || []).map((c) => c.id)
    let matriculasCurso = []

    if (cursoIds.length > 0) {
      const { data: mcData, error: mcErr } = await supabase
        .from('matricula_cursos')
        .select(`
          id,
          curso_id,
          matriculas_periodo!inner (
            fecha_matricula,
            alumnos (id, nombre, apellido, email, grado),
            periodos (nombre, anio)
          )
        `)
        .in('curso_id', cursoIds)

      if (mcErr) throw mcErr
      matriculasCurso = mcData || []
    }

    const alumnosPorCurso = {}
    matriculasCurso.forEach((mc) => {
      const alumno = mc.matriculas_periodo?.alumnos
      if (!alumno) return
      if (!alumnosPorCurso[mc.curso_id]) alumnosPorCurso[mc.curso_id] = []
      alumnosPorCurso[mc.curso_id].push({
        id: alumno.id,
        nombre: alumno.nombre,
        apellido: alumno.apellido,
        email: alumno.email,
        grado: alumno.grado,
        periodo: mc.matriculas_periodo?.periodos
          ? `${mc.matriculas_periodo.periodos.nombre} ${mc.matriculas_periodo.periodos.anio}`
          : '',
        fecha_matricula: mc.matriculas_periodo?.fecha_matricula
      })
    })

    misCursos.value = (cursosData || []).map((curso) => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null,
      estudiantes: alumnosPorCurso[curso.id] || [],
      total_estudiantes: alumnosPorCurso[curso.id]?.length || 0
    }))
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
