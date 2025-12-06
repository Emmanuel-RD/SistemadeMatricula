<template>
  <div>
    <h1 class="title is-3 mb-5">
      <i class="fas fa-calendar-alt mr-2"></i>
      Horarios
    </h1>

    <div v-if="authStore.isAlumno" class="card mb-5">
      <div class="card-content">
        <h2 class="subtitle is-4 mb-4">Mi horario</h2>
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
              <tr v-for="hora in horasAlumno" :key="hora">
                <td><strong>{{ hora }}</strong></td>
                <td v-for="dia in dias" :key="dia">
                  <div v-for="curso in getCursoPorDiaYHora(dia, hora)" :key="curso.id" class="box mb-1 p-2">
                    <p class="is-size-7"><strong>{{ curso.nombre }}</strong></p>
                    <p class="is-size-7 has-text-weight-semibold">{{ curso.hora_inicio }} - {{ curso.hora_fin }}</p>
                    <p class="is-size-7 has-text-grey">{{ curso.docente_nombre }}</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="card" v-if="!authStore.isAlumno">
      <div class="card-content">
        <div class="level mb-4">
          <div class="level-left">
            <h2 class="subtitle is-4 mb-0">
              {{ authStore.isAdmin ? 'Todos los horarios' : authStore.isDocente ? 'Horarios de mis cursos' : 'Horarios de cursos' }}
            </h2>
          </div>
          <div class="level-right">
            <div class="field is-grouped">
              <div class="control">
                <div class="select">
                  <select v-model="filtroGrado">
                    <option value="todos">Todos los grados</option>
                    <option v-for="grado in gradosDisponibles" :key="grado" :value="grado">
                      {{ grado }}° Grado
                    </option>
                  </select>
                </div>
              </div>
              <div class="control" v-if="filtroGrado !== 'todos'">
                <button class="button" @click="filtroGrado = 'todos'">Limpiar</button>
              </div>
            </div>
          </div>
        </div>
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else-if="cursosFiltrados.length === 0">
          <div class="has-text-centered py-5 has-text-grey">
            No hay cursos para el grado seleccionado
          </div>
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
              <tr v-for="hora in horasCursos" :key="hora">
                <td><strong>{{ hora }}</strong></td>
                <td v-for="dia in dias" :key="dia">
                  <div v-for="curso in getCursoPorDiaYHoraTodos(dia, hora)" :key="curso.id" class="box mb-1 p-2">
                    <p class="is-size-7"><strong>{{ curso.nombre }}</strong></p>
                    <p class="is-size-7 has-text-weight-semibold">{{ curso.hora_inicio }} - {{ curso.hora_fin }}</p>
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
const filtroGrado = ref('todos')
const docenteId = ref(null)

const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']

const cursosFiltrados = computed(() => {
  let lista = cursos.value
  if (filtroGrado.value !== 'todos') {
    const gradoFiltro = Number(filtroGrado.value)
    lista = lista.filter((curso) => curso.grado === gradoFiltro)
  }
  return lista
})

const gradosDisponibles = computed(() => {
  const grados = new Set()
  cursos.value.forEach((curso) => grados.add(curso.grado))
  return Array.from(grados).sort()
})

const horasCursos = computed(() => {
  const horasSet = new Set()
  cursosFiltrados.value.forEach((curso) => horasSet.add(curso.hora_inicio))
  return Array.from(horasSet).sort()
})

const horasAlumno = computed(() => {
  const horasSet = new Set()
  miHorario.value.forEach((curso) => horasSet.add(curso.hora_inicio))
  return Array.from(horasSet).sort()
})

const loadDocenteActual = async () => {
  if (!authStore.isDocente) return
  try {
    const { data } = await supabase.from('docentes').select('id').eq('email', authStore.user.email).single()
    docenteId.value = data?.id || null
  } catch (err) {
    console.error('Error obteniendo docente actual:', err)
    docenteId.value = null
  }
}

const loadCursos = async () => {
  loading.value = true
  try {
    let query = supabase
      .from('cursos')
      .select(`
        *,
        docentes (nombre, apellido)
      `)
      .order('hora_inicio')

    if (authStore.isDocente && docenteId.value) {
      query = query.eq('docente_id', docenteId.value)
    }

    const { data, error: err } = await query
    if (err) throw err

    if (authStore.isDocente && !docenteId.value) {
      cursos.value = []
      loading.value = false
      return
    }

    const cursosData =
      data?.map((curso) => ({
        ...curso,
        docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : 'Sin docente'
      })) || []

    for (const curso of cursosData) {
      const { data: inscritos, error: countError } = await supabase
        .from('matricula_cursos')
        .select('id, matriculas_periodo!inner (estado)')
        .eq('curso_id', curso.id)
        .eq('matriculas_periodo.estado', 'activa')

      if (countError) throw countError
      curso.total_alumnos = inscritos?.length || 0
    }

    cursos.value = cursosData
  } catch (err) {
    console.error('Error loading cursos:', err)
  } finally {
    loading.value = false
  }
}

const loadMiHorario = async () => {
  if (!authStore.isAlumno) return
  try {
    const { data: alumnoData, error: alumnoErr } = await supabase
      .from('alumnos')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (alumnoErr) {
      if (alumnoErr.code === 'PGRST116') return
      throw alumnoErr
    }

    if (!alumnoData) return

    const { data, error: err } = await supabase
      .from('matricula_cursos')
      .select(`
        id,
        cursos (
          id,
          nombre,
          dia_semana,
          hora_inicio,
          hora_fin,
          grado,
          docentes (nombre, apellido)
        ),
        matriculas_periodo!inner (
          alumno_id,
          estado
        )
      `)
      .eq('matriculas_periodo.alumno_id', alumnoData.id)
      .eq('matriculas_periodo.estado', 'activa')

    if (err) throw err

    miHorario.value =
      data?.map((m) => ({
        id: m.cursos.id,
        nombre: m.cursos.nombre,
        dia_semana: m.cursos.dia_semana,
        hora_inicio: m.cursos.hora_inicio,
        hora_fin: m.cursos.hora_fin,
        grado: m.cursos.grado,
        docente_nombre: m.cursos.docentes ? `${m.cursos.docentes.nombre} ${m.cursos.docentes.apellido}` : 'Sin docente'
      })) || []
  } catch (err) {
    console.error('Error loading mi horario:', err)
  }
}

const getCursoPorDiaYHora = (dia, hora) => {
  return miHorario.value.filter((curso) => curso.dia_semana === dia && curso.hora_inicio === hora)
}

const getCursoPorDiaYHoraTodos = (dia, hora) => {
  return cursosFiltrados.value.filter((curso) => curso.dia_semana === dia && curso.hora_inicio === hora)
}

onMounted(async () => {
  if (authStore.isDocente) {
    await loadDocenteActual()
  }
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
