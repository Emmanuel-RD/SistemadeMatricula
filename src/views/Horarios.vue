<template>
  <div>
    <h1 class="title is-3 mb-5">
      <i class="fas fa-calendar-alt mr-2"></i>
      Horarios
    </h1>

    <div v-if="authStore.isAlumno" class="card mb-5">
      <div class="card-content">
        <h2 class="subtitle is-4 mb-4">Mi Horario</h2>
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else-if="miHorario.length === 0" class="has-text-centered py-5">
          <p class="has-text-grey">No tienes cursos matriculados</p>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-bordered">
            <thead>
              <tr>
                <th>Hora</th>
                <th>Lunes</th>
                <th>Martes</th>
                <th>Miércoles</th>
                <th>Jueves</th>
                <th>Viernes</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="hora in horas" :key="hora">
                <td><strong>{{ hora }}</strong></td>
                <td v-for="dia in dias" :key="dia">
                  <div v-for="curso in getCursoPorDiaYHora(dia, hora)" :key="curso.id" class="box mb-1 p-2">
                    <p class="is-size-7"><strong>{{ curso.nombre }}</strong></p>
                    <p class="is-size-7 has-text-grey">{{ curso.docente_nombre }}</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-content">
        <h2 class="subtitle is-4 mb-4">
          {{ authStore.isAdmin ? 'Todos los Horarios' : 'Horarios de Cursos' }}
        </h2>
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-bordered">
            <thead>
              <tr>
                <th>Hora</th>
                <th>Lunes</th>
                <th>Martes</th>
                <th>Miércoles</th>
                <th>Jueves</th>
                <th>Viernes</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="hora in horas" :key="hora">
                <td><strong>{{ hora }}</strong></td>
                <td v-for="dia in dias" :key="dia">
                  <div v-for="curso in getCursoPorDiaYHoraTodos(dia, hora)" :key="curso.id" class="box mb-1 p-2">
                    <p class="is-size-7"><strong>{{ curso.nombre }}</strong></p>
                    <p class="is-size-7 has-text-grey">{{ curso.docente_nombre }}</p>
                    <p class="is-size-7">
                      <span class="tag is-small is-info">{{ curso.grado }}°</span>
                      <span class="tag is-small is-success ml-1">{{ curso.total_alumnos }}/{{ curso.capacidad }}</span>
                    </p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/config/supabase'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const cursos = ref([])
const miHorario = ref([])
const loading = ref(true)

const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
const horas = ref([])

const loadCursos = async () => {
  try {
    const { data, error: err } = await supabase
      .from('cursos')
      .select(`
        *,
        docentes (nombre, apellido)
      `)
      .order('hora_inicio')

    if (err) throw err

    const cursosData = (data || []).map(curso => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null
    }))

    // Contar alumnos por curso
    for (let curso of cursosData) {
      const { count } = await supabase
        .from('matriculas')
        .select('*', { count: 'exact', head: true })
        .eq('curso_id', curso.id)
      curso.total_alumnos = count || 0
    }

    cursos.value = cursosData

    // Generar lista de horas únicas
    const horasSet = new Set()
    cursosData.forEach(curso => {
      horasSet.add(curso.hora_inicio)
    })
    horas.value = Array.from(horasSet).sort()
  } catch (err) {
    console.error('Error loading cursos:', err)
  } finally {
    loading.value = false
  }
}

const loadMiHorario = async () => {
  if (!authStore.isAlumno) return

  try {
    const { data: alumnoData } = await supabase
      .from('alumnos')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (!alumnoData) return

    const { data, error: err } = await supabase
      .from('matriculas')
      .select(`
        curso_id,
        cursos (
          id,
          nombre,
          dia_semana,
          hora_inicio,
          hora_fin,
          grado,
          docentes (nombre, apellido)
        )
      `)
      .eq('alumno_id', alumnoData.id)

    if (err) throw err

    miHorario.value = (data || []).map(m => ({
      id: m.cursos.id,
      nombre: m.cursos.nombre,
      dia_semana: m.cursos.dia_semana,
      hora_inicio: m.cursos.hora_inicio,
      hora_fin: m.cursos.hora_fin,
      grado: m.cursos.grado,
      docente_nombre: m.cursos.docentes ? `${m.cursos.docentes.nombre} ${m.cursos.docentes.apellido}` : null
    }))
  } catch (err) {
    console.error('Error loading mi horario:', err)
  }
}

const getCursoPorDiaYHora = (dia, hora) => {
  return miHorario.value.filter(curso => 
    curso.dia_semana === dia && curso.hora_inicio === hora
  )
}

const getCursoPorDiaYHoraTodos = (dia, hora) => {
  return cursos.value.filter(curso => 
    curso.dia_semana === dia && curso.hora_inicio === hora
  )
}

onMounted(async () => {
  await loadCursos()
  await loadMiHorario()
})
</script>

<style scoped>
.box {
  background-color: #f5f5f5;
  border-left: 3px solid #3273dc;
}
</style>


