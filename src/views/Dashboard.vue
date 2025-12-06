<template>
  <div>
    <h1 class="title is-3 mb-5">
      <i class="fas fa-tachometer-alt mr-2"></i>
      Dashboard
    </h1>

    <div class="columns is-multiline">
      <div class="column is-3">
        <div class="card stats-card">
          <div class="card-content">
            <div class="media">
              <div class="media-left">
                <figure class="image is-48x48">
                  <i class="fas fa-book fa-2x has-text-primary"></i>
                </figure>
              </div>
              <div class="media-content">
                <p class="heading">Total Cursos</p>
                <p class="title is-4">{{ stats.totalCursos }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="column is-3">
        <div class="card stats-card">
          <div class="card-content">
            <div class="media">
              <div class="media-left">
                <figure class="image is-48x48">
                  <i class="fas fa-user-graduate fa-2x has-text-info"></i>
                </figure>
              </div>
              <div class="media-content">
                <p class="heading">Total Alumnos</p>
                <p class="title is-4">{{ stats.totalAlumnos }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="column is-3">
        <div class="card stats-card">
          <div class="card-content">
            <div class="media">
              <div class="media-left">
                <figure class="image is-48x48">
                  <i class="fas fa-chalkboard-teacher fa-2x has-text-success"></i>
                </figure>
              </div>
              <div class="media-content">
                <p class="heading">Total Docentes</p>
                <p class="title is-4">{{ stats.totalDocentes }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="column is-3">
        <div class="card stats-card">
          <div class="card-content">
            <div class="media">
              <div class="media-left">
                <figure class="image is-48x48">
                  <i class="fas fa-clipboard-list fa-2x has-text-warning"></i>
                </figure>
              </div>
              <div class="media-content">
                <p class="heading">Total Matriculas</p>
                <p class="title is-4">{{ stats.totalMatriculas }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="columns mt-5">
      <div class="column is-6">
        <div class="card">
          <div class="card-header">
            <p class="card-header-title">
              <i class="fas fa-chart-line mr-2"></i>
              Cursos mas populares
            </p>
          </div>
          <div class="card-content">
            <div v-if="loading" class="has-text-centered py-5">
              <i class="fas fa-spinner fa-spin fa-2x"></i>
            </div>
            <div v-else-if="cursosPopulares.length === 0" class="has-text-centered py-5">
              <p class="has-text-grey">No hay datos disponibles</p>
            </div>
            <div v-else>
              <div v-for="curso in cursosPopulares" :key="curso.id" class="mb-3">
                <div class="level">
                  <div class="level-left">
                    <div class="level-item">
                      <strong>{{ curso.nombre }}</strong>
                    </div>
                  </div>
                  <div class="level-right">
                    <div class="level-item">
                      <span class="tag is-primary">{{ curso.total_matriculas }} alumnos</span>
                    </div>
                  </div>
                </div>
                <progress
                  class="progress is-primary"
                  :value="curso.total_matriculas"
                  :max="Math.max(stats.totalAlumnos || 1, cursosPopulares[0]?.total_matriculas || 1)"
                ></progress>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="column is-6">
        <div class="card">
          <div class="card-header">
            <p class="card-header-title">
              <i class="fas fa-calendar-check mr-2"></i>
              Matriculas recientes
            </p>
          </div>
          <div class="card-content">
            <div v-if="loading" class="has-text-centered py-5">
              <i class="fas fa-spinner fa-spin fa-2x"></i>
            </div>
            <div v-else-if="matriculasRecientes.length === 0" class="has-text-centered py-5">
              <p class="has-text-grey">No hay matriculas recientes</p>
            </div>
            <div v-else>
              <div v-for="matricula in matriculasRecientes" :key="matricula.id" class="box mb-2">
                <div class="level">
                  <div class="level-left">
                    <div>
                      <strong>{{ matricula.alumno_nombre }}</strong>
                      <br />
                      <small class="has-text-grey">{{ matricula.periodo_nombre }}</small>
                      <div class="tags mt-2" v-if="matricula.cursos.length">
                        <span v-for="curso in matricula.cursos" :key="curso" class="tag is-info is-light">{{ curso }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="level-right">
                    <div class="level-item">
                      <small>{{ formatDate(matricula.fecha_matricula) }}</small>
                    </div>
                  </div>
                </div>
              </div>
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

const stats = ref({
  totalCursos: 0,
  totalAlumnos: 0,
  totalDocentes: 0,
  totalMatriculas: 0
})

const cursosPopulares = ref([])
const matriculasRecientes = ref([])
const loading = ref(true)

const loadStats = async () => {
  try {
    const { count: cursosCount } = await supabase.from('cursos').select('*', { count: 'exact', head: true })
    stats.value.totalCursos = cursosCount || 0

    const { count: alumnosCount } = await supabase.from('alumnos').select('*', { count: 'exact', head: true })
    stats.value.totalAlumnos = alumnosCount || 0

    const { count: docentesCount } = await supabase.from('docentes').select('*', { count: 'exact', head: true })
    stats.value.totalDocentes = docentesCount || 0

    const { count: matriculasCount } = await supabase
      .from('matriculas_periodo')
      .select('*', { count: 'exact', head: true })
    stats.value.totalMatriculas = matriculasCount || 0

    const { data: cursosData, error: cursosErr } = await supabase
      .from('matricula_cursos')
      .select(`
        curso_id,
        cursos (id, nombre),
        matriculas_periodo!inner (estado)
      `)
      .eq('matriculas_periodo.estado', 'activa')

    if (cursosErr) throw cursosErr

    const cursoCounts = {}
    ;(cursosData || []).forEach((m) => {
      const cursoId = m.curso_id
      const cursoNombre = m.cursos?.nombre || 'Sin nombre'
      if (!cursoCounts[cursoId]) {
        cursoCounts[cursoId] = { id: cursoId, nombre: cursoNombre, total_matriculas: 0 }
      }
      cursoCounts[cursoId].total_matriculas++
    })

    cursosPopulares.value = Object.values(cursoCounts)
      .sort((a, b) => b.total_matriculas - a.total_matriculas)
      .slice(0, 5)

    const { data: matriculasData, error: matErr } = await supabase
      .from('matriculas_periodo')
      .select(`
        id,
        fecha_matricula,
        alumnos (nombre, apellido),
        periodos (nombre, anio),
        matricula_cursos (curso_nombre_snapshot)
      `)
      .order('fecha_matricula', { ascending: false })
      .limit(5)

    if (matErr) throw matErr

    matriculasRecientes.value = (matriculasData || []).map((m) => ({
      id: m.id,
      alumno_nombre: `${m.alumnos?.nombre || ''} ${m.alumnos?.apellido || ''}`.trim(),
      periodo_nombre: m.periodos ? `${m.periodos.nombre} ${m.periodos.anio}` : 'Sin periodo',
      cursos: (m.matricula_cursos || []).map((c) => c.curso_nombre_snapshot),
      fecha_matricula: m.fecha_matricula
    }))
  } catch (error) {
    console.error('Error loading stats:', error)
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
  loadStats()
})
</script>
