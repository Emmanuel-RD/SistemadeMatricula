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
        <div v-if="loading" class="has-text-centered py-5">
          <i class="fas fa-spinner fa-spin fa-2x"></i>
        </div>
        <div v-else>
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>ID</th>
                <th>Nombre</th>
                <th>Descripción</th>
                <th>Grado</th>
                <th>Docente</th>
                <th>Horario</th>
                <th>Capacidad</th>
                <th v-if="authStore.isAdmin">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="curso in cursos" :key="curso.id">
                <td>{{ curso.id }}</td>
                <td><strong>{{ curso.nombre }}</strong></td>
                <td>{{ curso.descripcion || '-' }}</td>
                <td>
                  <span class="tag is-info">{{ curso.grado }}</span>
                </td>
                <td>{{ curso.docente_nombre || '-' }}</td>
                <td>
                  <span class="tag">{{ curso.dia_semana }} {{ curso.hora_inicio }}-{{ curso.hora_fin }}</span>
                </td>
                <td>{{ curso.capacidad }}</td>
                <td v-if="authStore.isAdmin">
                  <button class="button is-small is-info" @click="editCurso(curso)">
                    <i class="fas fa-edit"></i>
                  </button>
                  <button class="button is-small is-danger ml-2" @click="deleteCurso(curso.id)">
                    <i class="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
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
                <select v-model="form.grado" required>
                  <option value="">Seleccionar grado</option>
                  <option value="1">1° Grado</option>
                  <option value="2">2° Grado</option>
                  <option value="3">3° Grado</option>
                  <option value="4">4° Grado</option>
                  <option value="5">5° Grado</option>
                  <option value="6">6° Grado</option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Docente</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.docente_id" required>
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
import { ref, onMounted } from 'vue'
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

const loadCursos = async () => {
  try {
    const { data, error: err } = await supabase
      .from('cursos')
      .select(`
        *,
        docentes (id, nombre, apellido)
      `)
      .order('nombre')

    if (err) throw err

    cursos.value = data?.map(curso => ({
      ...curso,
      docente_nombre: curso.docentes ? `${curso.docentes.nombre} ${curso.docentes.apellido}` : null
    })) || []
  } catch (err) {
    console.error('Error loading cursos:', err)
  error.value = err.message
  loading.value = false
  return
  }
  loading.value = false
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
    if (editingCurso.value) {
      const { error: err } = await supabase
        .from('cursos')
        .update(form.value)
        .eq('id', editingCurso.value.id)

      if (err) throw err
    } else {
      const { error: err } = await supabase
        .from('cursos')
        .insert([form.value])

      if (err) throw err
    }

    await loadCursos()
    closeModal()
  } catch (err) {
    error.value = err.message
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
  await loadCursos()
})
</script>







