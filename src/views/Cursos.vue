<template>
  <div>
    <div class="level mb-5">
      <div class="level-left">
        <div class="level-item">
          <h1 class="title is-3">
            <i class="fas fa-book mr-2"></i>
            Gestión de Cursos
          </h1>
        </div>
      </div>
      <div class="level-right" v-if="authStore.isAdmin">
        <div class="level-item">
          <button class="button is-primary" @click="showModal = true">
            <i class="fas fa-plus mr-2"></i>
            Nuevo Curso
          </button>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-content">
        <div class="level mb-4">
          <div class="level-left"></div>
          <div class="level-right">
            <div class="field has-addons">
              <div class="control">
                <input
                  class="input"
                  type="text"
                  placeholder="Buscar por nombre, docente, grado o dia"
                  v-model="search"
                />
              </div>
              <div class="control">
                <button class="button" @click="search = ''" :disabled="!search">
                  Limpiar
                </button>
              </div>
            </div>
          </div>
        </div>
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else>
          <div v-if="filteredCursos.length === 0" class="has-text-centered py-5 has-text-grey">
            No hay cursos registrados
          </div>
          <div v-else class="columns is-multiline">
            <div v-for="curso in filteredCursos" :key="curso.id" class="column is-4">
              <div class="card curso-card">
                <header class="card-header">
                  <p class="card-header-title">
                    {{ curso.nombre }}
                  </p>
                  <div class="card-header-icon">
                    <span class="tag is-info">{{ curso.grado }}º</span>
                  </div>
                </header>
                <div class="card-content">
                  <div class="content">
                    <p class="has-text-weight-semibold mb-2">
                      <i class="fas fa-clock mr-1"></i>
                      {{ curso.dia_semana }} · {{ curso.hora_inicio }} - {{ curso.hora_fin }}
                    </p>
                    <p class="mb-2">
                      <i class="fas fa-chalkboard-teacher mr-1"></i>
                      {{ curso.docente_nombre || 'Sin docente asignado' }}
                    </p>
                    <p class="mb-2">
                      <i class="fas fa-users mr-1"></i>
                      Capacidad: {{ curso.capacidad }} estudiantes
                    </p>
                    <p v-if="curso.descripcion" class="has-text-grey">
                      {{ curso.descripcion }}
                    </p>
                  </div>
                </div>
                <footer class="card-footer">
                  <router-link :to="`/cursos/${curso.id}`" class="card-footer-item">
                    <i class="fas fa-eye mr-1"></i> Detalles
                  </router-link>
                  <a v-if="authStore.isAdmin" class="card-footer-item has-text-info" @click.prevent="editCurso(curso)">
                    <i class="fas fa-edit mr-1"></i> Editar
                  </a>
                  <a v-if="authStore.isAdmin" class="card-footer-item has-text-danger" @click.prevent="deleteCurso(curso.id)">
                    <i class="fas fa-trash mr-1"></i> Eliminar
                  </a>
                </footer>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal para crear/editar curso -->
    <div class="modal" :class="{ 'is-active': showModal }">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">
            {{ editingCurso ? 'Editar Curso' : 'Nuevo Curso' }}
          </p>
          <button class="delete" @click="closeModal"></button>
        </header>
        <section class="modal-card-body">
          <div class="field">
            <label class="label">Nombre</label>
            <div class="control">
              <input v-model="form.nombre" class="input" type="text" required />
            </div>
          </div>

          <div class="field">
            <label class="label">Descripción</label>
            <div class="control">
              <textarea v-model="form.descripcion" class="textarea"></textarea>
            </div>
          </div>

          <div class="field">
            <label class="label">Grado</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model.number="form.grado" required>
                  <option value="">Seleccionar grado</option>
                  <option value="1">1º Grado</option>
                  <option value="2">2º Grado</option>
                  <option value="3">3º Grado</option>
                  <option value="4">4º Grado</option>
                  <option value="5">5º Grado</option>
                  <option value="6">6º Grado</option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Docente</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model.number="form.docente_id" required>
                  <option value="">Seleccionar docente</option>
                  <option v-for="docente in docentes" :key="docente.id" :value="docente.id">
                    {{ docente.nombre }} {{ docente.apellido }}
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="columns">
            <div class="column">
              <div class="field">
                <label class="label">Día de la Semana</label>
                <div class="control">
                  <div class="select is-fullwidth">
                    <select v-model="form.dia_semana" required>
                      <option value="">Seleccionar día</option>
                      <option value="Lunes">Lunes</option>
                      <option value="Martes">Martes</option>
                      <option value="Miércoles">Miércoles</option>
                      <option value="Jueves">Jueves</option>
                      <option value="Viernes">Viernes</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Hora Inicio</label>
                <div class="control">
                  <input v-model="form.hora_inicio" class="input" type="time" required />
                </div>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Hora Fin</label>
                <div class="control">
                  <input v-model="form.hora_fin" class="input" type="time" required />
                </div>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Capacidad</label>
            <div class="control">
              <input v-model.number="form.capacidad" class="input" type="number" min="1" required />
            </div>
          </div>

          <div v-if="error" class="notification is-danger mt-3">
            {{ error }}
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" @click="saveCurso" :disabled="saving">
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
const cursos = ref([])
const docentes = ref([])
const loading = ref(true)
const showModal = ref(false)
const editingCurso = ref(null)
const saving = ref(false)
const error = ref('')
const search = ref('')
const docenteId = ref(null)

const form = ref({
  nombre: '',
  descripcion: '',
  grado: '',
  docente_id: '',
  dia_semana: '',
  hora_inicio: '',
  hora_fin: '',
  capacidad: 30
})

const filteredCursos = computed(() => {
  const term = search.value.trim().toLowerCase()
  let list = cursos.value

  if (authStore.isDocente && docenteId.value) {
    list = list.filter(curso => curso.docente_id === docenteId.value)
  }

  if (!term) return list

  return list.filter(curso => {
    return (
      curso.nombre.toLowerCase().includes(term) ||
      (curso.descripcion && curso.descripcion.toLowerCase().includes(term)) ||
      (curso.docente_nombre && curso.docente_nombre.toLowerCase().includes(term)) ||
      String(curso.grado).includes(term) ||
      curso.dia_semana.toLowerCase().includes(term)
    )
  })
})

const loadDocenteActual = async () => {
  if (!authStore.isDocente) return

  try {
    const { data, error: err } = await supabase
      .from('docentes')
      .select('id')
      .eq('email', authStore.user.email)
      .single()

    if (err) throw err
    docenteId.value = data?.id || null
  } catch (err) {
    console.error('Error obteniendo docente actual:', err)
    docenteId.value = null
  }
}

const loadCursos = async () => {
  loading.value = true
  error.value = ''
  try {
    if (authStore.isDocente && !docenteId.value) {
      cursos.value = []
      loading.value = false
      return
    }

    let query = supabase
      .from('cursos')
      .select(`
        *,
        docentes (id, nombre, apellido)
      `)
      .order('nombre')

    if (authStore.isDocente && docenteId.value) {
      query = query.eq('docente_id', docenteId.value)
    }

    const { data, error: err } = await query

    if (err) throw err

    cursos.value = data?.map(curso => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null
    })) || []
  } catch (err) {
    console.error('Error loading cursos:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const loadDocentes = async () => {
  try {
    const { data, error: err } = await supabase
      .from('docentes')
      .select('*')
      .order('nombre')

    if (err) throw err
    docentes.value = data || []
  } catch (err) {
    console.error('Error loading docentes:', err)
  }
}

const validateCurso = async () => {
  if (
    !form.value.nombre.trim() ||
    !form.value.grado ||
    !form.value.docente_id ||
    !form.value.dia_semana ||
    !form.value.hora_inicio ||
    !form.value.hora_fin
  ) {
    return 'Completa todos los campos obligatorios'
  }

  if (form.value.capacidad <= 0) {
    return 'La capacidad debe ser mayor a cero'
  }

  if (form.value.hora_inicio >= form.value.hora_fin) {
    return 'La hora de fin debe ser mayor a la hora de inicio'
  }

  const { data: sameDayCourses, error: conflictError } = await supabase
    .from('cursos')
    .select('id, hora_inicio, hora_fin')
    .eq('grado', form.value.grado)
    .eq('dia_semana', form.value.dia_semana)

  if (conflictError) throw conflictError

  const hasOverlap = (sameDayCourses || []).some(curso => {
    if (editingCurso.value && curso.id === editingCurso.value.id) return false
    return !(form.value.hora_fin <= curso.hora_inicio || form.value.hora_inicio >= curso.hora_fin)
  })

  if (hasOverlap) {
    return 'Ya existe un curso de este grado que se cruza en horario'
  }

  return ''
}

const editCurso = (curso) => {
  editingCurso.value = curso
  form.value = {
    nombre: curso.nombre,
    descripcion: curso.descripcion || '',
    grado: curso.grado,
    docente_id: curso.docente_id,
    dia_semana: curso.dia_semana,
    hora_inicio: curso.hora_inicio,
    hora_fin: curso.hora_fin,
    capacidad: curso.capacidad
  }
  showModal.value = true
}

const deleteCurso = async (id) => {
  if (!confirm('¿Estás seguro de eliminar este curso?')) return

  try {
    const { error: err } = await supabase
      .from('cursos')
      .delete()
      .eq('id', id)

    if (err) throw err
    await loadCursos()
  } catch (err) {
    alert('Error al eliminar: ' + err.message)
  }
}

const saveCurso = async () => {
  saving.value = true
  error.value = ''

  try {
    const validationMessage = await validateCurso()
    if (validationMessage) {
      error.value = validationMessage
      saving.value = false
      return
    }

    const payload = {
      nombre: form.value.nombre.trim(),
      descripcion: form.value.descripcion?.trim() || null,
      grado: Number(form.value.grado),
      docente_id: form.value.docente_id,
      dia_semana: form.value.dia_semana,
      hora_inicio: form.value.hora_inicio,
      hora_fin: form.value.hora_fin,
      capacidad: Number(form.value.capacidad)
    }

    if (editingCurso.value) {
      const { error: err } = await supabase
        .from('cursos')
        .update(payload)
        .eq('id', editingCurso.value.id)

      if (err) throw err
    } else {
      const { error: err } = await supabase
        .from('cursos')
        .insert([payload])

      if (err) throw err
    }

    await loadCursos()
    closeModal()
  } catch (err) {
    const message = err?.message || 'Error al guardar el curso'
    if (message.toLowerCase().includes('curso de este grado')) {
      error.value = 'Ya existe un curso de este grado que se cruza en horario'
    } else {
      error.value = message
    }
  } finally {
    saving.value = false
  }
}

const closeModal = () => {
  showModal.value = false
  editingCurso.value = null
  form.value = {
    nombre: '',
    descripcion: '',
    grado: '',
    docente_id: '',
    dia_semana: '',
    hora_inicio: '',
    hora_fin: '',
    capacidad: 30
  }
  error.value = ''
}

onMounted(async () => {
  await loadDocentes()
  if (authStore.isDocente) {
    await loadDocenteActual()
  }
  await loadCursos()
})
</script>

<style scoped>
.curso-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}
</style>
