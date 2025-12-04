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
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>ID</th>
                <th>Alumno</th>
                <th>Curso</th>
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
                <td>{{ matricula.curso_nombre }}</td>
                <td>
                  <span class="tag is-info">{{ matricula.grado }}° Grado</span>
                </td>
                <td>{{ formatDate(matricula.fecha_matricula) }}</td>
                <td>
                  <span class="tag is-success">Activa</span>
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
                    {{ alumno.nombre }} {{ alumno.apellido }} - {{ alumno.grado }}° Grado
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div v-if="authStore.isAlumno && alumnoActual" class="notification is-info">
            <p><strong>Alumno:</strong> {{ alumnoActual.nombre }} {{ alumnoActual.apellido }} - {{ alumnoActual.grado }}° Grado</p>
          </div>

          <div class="field">
            <label class="label">Curso</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.curso_id" required @change="onCursoChange">
                  <option value="">Seleccionar curso</option>
                  <option v-for="curso in cursosDisponibles" :key="curso.id" :value="curso.id">
                    {{ curso.nombre }} - {{ curso.grado }}° Grado - {{ curso.dia_semana }} {{ curso.hora_inicio }}-{{ curso.hora_fin }}
                  </option>
                </select>
              </div>
            </div>
            <p v-if="authStore.isAlumno" class="help">Solo se muestran los cursos disponibles para tu grado</p>
          </div>

          <div v-if="cursoSeleccionado" class="notification is-info">
            <p><strong>Horario:</strong> {{ cursoSeleccionado.dia_semana }} de {{ cursoSeleccionado.hora_inicio }} a {{ cursoSeleccionado.hora_fin }}</p>
            <p><strong>Docente:</strong> {{ cursoSeleccionado.docente_nombre }}</p>
            <p><strong>Capacidad:</strong> {{ cursoSeleccionado.capacidad }} alumnos</p>
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
const loading = ref(true)
const showModal = ref(false)
const saving = ref(false)
const error = ref('')
const validationError = ref('')
const cursoSeleccionado = ref(null)

const form = ref({
  alumno_id: '',
  curso_id: ''
})

const alumnoActual = ref(null)

const cursosDisponibles = computed(() => {
  // Si es alumno, usar el alumno actual
  if (authStore.isAlumno && alumnoActual.value) {
    return cursos.value.filter(c => c.grado === alumnoActual.value.grado)
  }
  
  // Si es admin, filtrar por alumno seleccionado
  if (!form.value.alumno_id) return cursos.value
  
  const alumno = alumnos.value.find(a => a.id === form.value.alumno_id)
  if (!alumno) return cursos.value
  
  // Filtrar cursos por grado del alumno
  return cursos.value.filter(c => c.grado === alumno.grado)
})

const loadMatriculas = async () => {
  try {
    let query = supabase
      .from('matriculas')
      .select(`
        *,
        alumnos (id, nombre, apellido, grado),
        cursos (id, nombre, grado)
      `)
      .order('fecha_matricula', { ascending: false })

    // Si es alumno, solo mostrar sus matrículas
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

    matriculas.value = (data || []).map(m => ({
      id: m.id,
      alumno_nombre: `${m.alumnos?.nombre || ''} ${m.alumnos?.apellido || ''}`,
      curso_nombre: m.cursos?.nombre || '',
      grado: m.alumnos?.grado || m.cursos?.grado || '',
      fecha_matricula: m.fecha_matricula
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

    // Si es alumno, solo cargar su propio registro
    if (authStore.isAlumno) {
      query = query.eq('email', authStore.user.email)
    }

    const { data, error: err } = await query
    if (err) throw err
    alumnos.value = data || []

    // Si es alumno, establecer su ID automáticamente y guardar datos del alumno
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

    cursos.value = (data || []).map(curso => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null
    }))
  } catch (err) {
    console.error('Error loading cursos:', err)
  }
}

const onCursoChange = () => {
  cursoSeleccionado.value = cursos.value.find(c => c.id === form.value.curso_id) || null
}

const validateMatricula = async () => {
  if (!form.value.alumno_id || !form.value.curso_id) {
    return { valid: false, error: 'Debe seleccionar alumno y curso' }
  }

  const alumno = alumnos.value.find(a => a.id === form.value.alumno_id)
  const curso = cursos.value.find(c => c.id === form.value.curso_id)

  if (!alumno || !curso) {
    return { valid: false, error: 'Datos inválidos' }
  }

  // Validación 1: No puede matricularse dos veces al mismo curso
  const { data: existingMatricula } = await supabase
    .from('matriculas')
    .select('id')
    .eq('alumno_id', form.value.alumno_id)
    .eq('curso_id', form.value.curso_id)
    .single()

  if (existingMatricula) {
    return { valid: false, error: 'El alumno ya está matriculado en este curso' }
  }

  // Validación 2: No puede matricularse en cursos que no correspondan a su grado
  if (alumno.grado !== curso.grado) {
    return { valid: false, error: `El alumno está en ${alumno.grado}° grado y el curso es para ${curso.grado}° grado` }
  }

  // Validación 3: No puede matricularse en cursos con el mismo horario
  const { data: matriculasAlumno } = await supabase
    .from('matriculas')
    .select(`
      cursos (dia_semana, hora_inicio, hora_fin)
    `)
    .eq('alumno_id', form.value.alumno_id)

  if (matriculasAlumno) {
    const conflictos = matriculasAlumno.filter(m => {
      const cursoMatriculado = m.cursos
      return cursoMatriculado &&
        cursoMatriculado.dia_semana === curso.dia_semana &&
        cursoMatriculado.hora_inicio === curso.hora_inicio &&
        cursoMatriculado.hora_fin === curso.hora_fin
    })

    if (conflictos.length > 0) {
      return { valid: false, error: 'El alumno ya tiene un curso en el mismo horario' }
    }
  }

  // Validación 4: Verificar capacidad del curso
  const { count: matriculasCount } = await supabase
    .from('matriculas')
    .select('*', { count: 'exact', head: true })
    .eq('curso_id', form.value.curso_id)

  if (matriculasCount >= curso.capacidad) {
    return { valid: false, error: 'El curso ha alcanzado su capacidad máxima' }
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
    const { error: err } = await supabase
      .from('matriculas')
      .insert([{
        alumno_id: form.value.alumno_id,
        curso_id: form.value.curso_id,
        fecha_matricula: new Date().toISOString()
      }])

    if (err) throw err

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
    const { error: err } = await supabase
      .from('matriculas')
      .delete()
      .eq('id', id)

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
    curso_id: ''
  }
  cursoSeleccionado.value = null
  error.value = ''
}

onMounted(async () => {
  await loadAlumnos()
  await loadCursos()
  await loadMatriculas()
})
</script>

