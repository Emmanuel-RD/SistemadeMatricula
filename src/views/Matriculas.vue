<template>
  <div>
    <div class="level mb-5">
      <div class="level-left">
        <div class="level-item">
          <h1 class="title is-3">
            <i class="fas fa-clipboard-list mr-2"></i>
            Gestión de Matrículas
          </h1>
        </div>
      </div>
      <div class="level-right" v-if="authStore.isAdmin || authStore.isAlumno">
        <div class="level-item">
          <button class="button is-primary" @click="showModal = true">
            <i class="fas fa-plus mr-2"></i>
            Nueva Matrícula
          </button>
        </div>
      </div>
    </div>

    <div v-if="validationError" class="notification is-danger mb-4">
      <button class="delete" @click="validationError = ''"></button>
      {{ validationError }}
    </div>

    <div class="card">
      <div class="card-content">
        <div v-if="periodosAbiertos.length === 0" class="notification is-warning is-light">
          Debes crear y abrir un periodo antes de registrar matrículas. Ve a <strong>Periodos</strong> y actívalo.
        </div>
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>ID</th>
                <th>Alumno</th>
                <th>Período</th>
                <th>Cursos</th>
                <th>Grado</th>
                <th>Fecha Matrícula</th>
                <th>Estado</th>
                <th v-if="authStore.isAdmin">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="matricula in matriculas" :key="matricula.id">
                <td>{{ matricula.id }}</td>
                <td><strong>{{ matricula.alumno_nombre }}</strong></td>
                <td><span class="tag">{{ matricula.periodo_nombre }}</span></td>
                <td>
                  <ul>
                    <li v-for="curso in matricula.cursos" :key="curso">{{ curso }}</li>
                  </ul>
                </td>
                <td>
                  <span class="tag is-info">{{ matricula.grado }}º Grado</span>
                </td>
                <td>{{ formatDate(matricula.fecha_matricula) }}</td>
                <td>
                  <span class="tag is-success">{{ matricula.estado }}</span>
                </td>
                <td v-if="authStore.isAdmin">
                  <button class="button is-small is-danger" @click="deleteMatricula(matricula.id)">
                    <i class="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal para crear matrícula -->
    <div class="modal" :class="{ 'is-active': showModal }">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">Nueva Matrícula</p>
          <button class="delete" @click="closeModal"></button>
        </header>
        <section class="modal-card-body">
          <div v-if="!authStore.isAlumno" class="field">
            <label class="label">Alumno</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.alumno_id" required>
                  <option value="">Seleccionar alumno</option>
                  <option v-for="alumno in alumnos" :key="alumno.id" :value="alumno.id">
                    {{ alumno.nombre }} {{ alumno.apellido }} - {{ alumno.grado }}º Grado
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div v-if="authStore.isAlumno && alumnoActual" class="notification is-info">
            <p><strong>Alumno:</strong> {{ alumnoActual.nombre }} {{ alumnoActual.apellido }} - {{ alumnoActual.grado }}º Grado</p>
          </div>

          <div class="field">
            <label class="label">Período</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.periodo_id" required>
                  <option value="">Seleccionar período</option>
                  <option v-for="periodo in periodosAbiertos" :key="periodo.id" :value="periodo.id">
                    {{ periodo.nombre }} - {{ periodo.anio }} ({{ periodo.estado }})
                  </option>
                </select>
              </div>
            </div>
            <p class="help">Solo se puede matricular en períodos abiertos.</p>
          </div>

          <div class="field">
            <label class="label">Selecciona los cursos</label>
            <div class="table-container" style="max-height: 280px; overflow: auto;">
              <table class="table is-fullwidth is-hoverable is-size-7">
                <thead>
                  <tr>
                    <th></th>
                    <th>Curso</th>
                    <th>Grado</th>
                    <th>Horario</th>
                    <th>Docente</th>
                    <th>Capacidad</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="curso in cursosDisponibles" :key="curso.id">
                    <td>
                      <input type="checkbox" :value="curso.id" v-model="form.cursos_ids" />
                    </td>
                    <td>{{ curso.nombre }}</td>
                    <td>{{ curso.grado }}º</td>
                    <td>{{ curso.dia_semana }} {{ curso.hora_inicio }} - {{ curso.hora_fin }}</td>
                    <td>{{ curso.docente_nombre || 'Sin docente' }}</td>
                    <td>{{ curso.capacidad }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p class="help" v-if="authStore.isAlumno">Solo ves cursos de tu grado.</p>
          </div>

          <div v-if="form.cursos_ids.length === 0" class="notification is-warning is-light">
            Selecciona al menos un curso para la matrícula.
          </div>

          <div v-if="error" class="notification is-danger mt-3">
            {{ error }}
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" @click="saveMatricula" :disabled="saving">
            {{ saving ? 'Guardando...' : 'Guardar' }}
          </button>
          <button class="button" @click="closeModal">Cancelar</button>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/config/supabase'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const matriculas = ref([])
const alumnos = ref([])
const cursos = ref([])
const periodos = ref([])
const loading = ref(true)
const showModal = ref(false)
const saving = ref(false)
const error = ref('')
const validationError = ref('')

const form = ref({
  alumno_id: '',
  periodo_id: '',
  cursos_ids: []
})

const alumnoActual = ref(null)

const cursosDisponibles = computed(() => {
  const grado = authStore.isAlumno
    ? alumnoActual.value?.grado
    : alumnos.value.find((a) => a.id === form.value.alumno_id)?.grado

  if (!grado) return []
  return cursos.value.filter((c) => c.grado === grado)
})

const periodosAbiertos = computed(() => periodos.value.filter((p) => p.estado === 'abierto'))

const loadMatriculas = async () => {
  try {
    let query = supabase
      .from('matriculas_periodo')
      .select(`
        *,
        alumnos (id, nombre, apellido, grado),
        periodos (nombre, anio),
        matricula_cursos (curso_nombre_snapshot)
      `)
      .order('fecha_matricula', { ascending: false })

    if (authStore.isAlumno) {
      const { data: alumnoData } = await supabase
        .from('alumnos')
        .select('id')
        .eq('email', authStore.user.email)
        .single()

      if (alumnoData) {
        query = query.eq('alumno_id', alumnoData.id)
      }
    }

    const { data, error: err } = await query
    if (err) throw err

    matriculas.value = (data || []).map((m) => ({
      id: m.id,
      alumno_nombre: `${m.alumnos?.nombre || ''} ${m.alumnos?.apellido || ''}`,
      periodo_nombre: m.periodos ? `${m.periodos.nombre} ${m.periodos.anio}` : 'Sin período',
      grado: m.alumnos?.grado || '',
      fecha_matricula: m.fecha_matricula,
      estado: m.estado || 'activa',
      cursos: (m.matricula_cursos || []).map((c) => c.curso_nombre_snapshot)
    }))
  } catch (err) {
    console.error('Error loading matriculas:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const loadAlumnos = async () => {
  try {
    let query = supabase.from('alumnos').select('*').order('nombre')

    if (authStore.isAlumno) {
      query = query.eq('email', authStore.user.email)
    }

    const { data, error: err } = await query
    if (err) throw err
    alumnos.value = data || []

    if (authStore.isAlumno && alumnos.value.length > 0) {
      alumnoActual.value = alumnos.value[0]
      form.value.alumno_id = alumnos.value[0].id
    }
  } catch (err) {
    console.error('Error loading alumnos:', err)
  }
}

const loadCursos = async () => {
  try {
    const { data, error: err } = await supabase
      .from('cursos')
      .select(`
        *,
        docentes (nombre, apellido)
      `)
      .order('nombre')

    if (err) throw err

    cursos.value = (data || []).map((curso) => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null
    }))
  } catch (err) {
    console.error('Error loading cursos:', err)
  }
}

const loadPeriodos = async () => {
  try {
    const { data, error: err } = await supabase
      .from('periodos')
      .select('*')
      .order('anio', { ascending: false })
      .order('fecha_inicio', { ascending: false })

    if (err) throw err
    periodos.value = data || []
  } catch (err) {
    console.error('Error loading periodos:', err)
  }
}

const validateMatricula = async () => {
  if (!form.value.alumno_id || !form.value.periodo_id) {
    return { valid: false, error: 'Debe seleccionar alumno y período' }
  }
  if (!form.value.cursos_ids || form.value.cursos_ids.length === 0) {
    return { valid: false, error: 'Seleccione al menos un curso' }
  }

  const alumno = alumnos.value.find((a) => a.id === form.value.alumno_id)
  if (!alumno) return { valid: false, error: 'Alumno inválido' }

  const { count: existeMatricula } = await supabase
    .from('matriculas_periodo')
    .select('*', { count: 'exact', head: true })
    .eq('alumno_id', form.value.alumno_id)
    .eq('periodo_id', form.value.periodo_id)

  if (existeMatricula && existeMatricula > 0) {
    return { valid: false, error: 'El alumno ya tiene una matrícula en este período' }
  }

  for (const cursoId of form.value.cursos_ids) {
    const curso = cursos.value.find((c) => c.id === cursoId)
    if (!curso) return { valid: false, error: 'Curso inválido' }
    if (curso.grado !== alumno.grado) {
      return { valid: false, error: `El curso ${curso.nombre} es para grado ${curso.grado} y el alumno está en ${alumno.grado}` }
    }

    // No permitir al alumno repetir el mismo curso (aunque sea otro período)
    const { count: yaMatriculado, error: dupErr } = await supabase
      .from('matricula_cursos')
      .select('id, matriculas_periodo!inner (alumno_id)', { count: 'exact', head: true })
      .eq('curso_id', cursoId)
      .eq('matriculas_periodo.alumno_id', form.value.alumno_id)

    if (dupErr) return { valid: false, error: dupErr.message }
    if (yaMatriculado && yaMatriculado > 0) {
      return { valid: false, error: `El alumno ya cursó ${curso.nombre}` }
    }

    const { data: mcData, error: mcErr } = await supabase
      .from('matricula_cursos')
      .select('id, matriculas_periodo!inner(periodo_id)')
      .eq('curso_id', cursoId)

    if (mcErr) return { valid: false, error: mcErr.message }

    const inscritosPeriodo = (mcData || []).filter(
      (mc) => mc.matriculas_periodo && mc.matriculas_periodo.periodo_id === form.value.periodo_id
    ).length
    if (inscritosPeriodo >= curso.capacidad) {
      return { valid: false, error: `El curso ${curso.nombre} ha alcanzado su capacidad` }
    }
  }

  return { valid: true }
}

const saveMatricula = async () => {
  saving.value = true
  error.value = ''
  validationError.value = ''

  const validation = await validateMatricula()
  if (!validation.valid) {
    error.value = validation.error
    saving.value = false
    return
  }

  try {
    const alumno = alumnos.value.find((a) => a.id === form.value.alumno_id)
    const payloadMatricula = {
      alumno_id: form.value.alumno_id,
      periodo_id: form.value.periodo_id,
      grado: alumno.grado,
      fecha_matricula: new Date().toISOString(),
      estado: 'activa'
    }

    const { data: matriculaInserted, error: errMat } = await supabase
      .from('matriculas_periodo')
      .insert([payloadMatricula])
      .select('id')
      .single()

    if (errMat) throw errMat
    const matriculaId = matriculaInserted.id

    const cursosRows = form.value.cursos_ids.map((id) => {
      const curso = cursos.value.find((c) => c.id === id)
      return {
        matricula_id: matriculaId,
        curso_id: curso.id,
        curso_nombre_snapshot: curso.nombre,
        docente_id_snapshot: curso.docente_id || null,
        docente_nombre_snapshot: curso.docente_nombre || null,
        grado_snapshot: curso.grado,
        dia_semana_snapshot: curso.dia_semana,
        hora_inicio_snapshot: curso.hora_inicio,
        hora_fin_snapshot: curso.hora_fin,
        capacidad_snapshot: curso.capacidad
      }
    })

    const { error: errCursos } = await supabase.from('matricula_cursos').insert(cursosRows)
    if (errCursos) throw errCursos

    await loadMatriculas()
    closeModal()
  } catch (err) {
    error.value = err.message
  } finally {
    saving.value = false
  }
}

const deleteMatricula = async (id) => {
  if (!confirm('¿Estás seguro de eliminar esta matrícula?')) return

  try {
    const { error: err } = await supabase.from('matriculas_periodo').delete().eq('id', id)
    if (err) throw err
    await loadMatriculas()
  } catch (err) {
    alert('Error al eliminar: ' + err.message)
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

const closeModal = () => {
  showModal.value = false
  form.value = {
    alumno_id: authStore.isAlumno && alumnoActual.value ? alumnoActual.value.id : '',
    periodo_id: '',
    cursos_ids: []
  }
  error.value = ''
}

onMounted(async () => {
  await loadAlumnos()
  await loadCursos()
  await loadPeriodos()
  await loadMatriculas()
})
</script>
