<template>
  <div>
    <div class="level mb-5">
      <div class="level-left">
        <div class="level-item">
          <h1 class="title is-3">
            <i class="fas fa-calendar-plus mr-2"></i>
            Gestión de Periodos
          </h1>
        </div>
      </div>
      <div class="level-right">
        <div class="level-item">
          <button class="button is-primary" @click="showModal = true">
            <i class="fas fa-plus mr-2"></i>
            Nuevo periodo
          </button>
        </div>
      </div>
    </div>

    <div v-if="error" class="notification is-danger">
      <button class="delete" @click="error = ''"></button>
      {{ error }}
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
                <th>Nombre</th>
                <th>Año</th>
                <th>Fechas</th>
                <th>Estado</th>
                <th>Creado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="periodo in periodos" :key="periodo.id">
                <td><strong>{{ periodo.nombre }}</strong></td>
                <td>{{ periodo.anio }}</td>
                <td>{{ formatDate(periodo.fecha_inicio) }} - {{ formatDate(periodo.fecha_fin) }}</td>
                <td>
                  <span class="tag"
                    :class="{
                      'is-info': periodo.estado === 'borrador',
                      'is-success': periodo.estado === 'abierto',
                      'is-dark': periodo.estado === 'cerrado'
                    }"
                  >
                    {{ periodo.estado }}
                  </span>
                </td>
                <td>{{ formatDate(periodo.created_at) }}</td>
                <td class="buttons">
                  <button class="button is-small" @click="openEdit(periodo)">
                    <i class="fas fa-edit"></i>
                  </button>
                  <button
                    class="button is-small is-success"
                    :disabled="periodo.estado === 'abierto'"
                    @click="cambiarEstado(periodo, 'abierto')"
                  >
                    Abrir
                  </button>
                  <button
                    class="button is-small is-warning"
                    :disabled="periodo.estado === 'borrador'"
                    @click="cambiarEstado(periodo, 'cerrado')"
                  >
                    Cerrar
                  </button>
                </td>
              </tr>
              <tr v-if="periodos.length === 0">
                <td colspan="6" class="has-text-centered has-text-grey">No hay periodos creados</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="modal" :class="{ 'is-active': showModal }">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ editing ? 'Editar periodo' : 'Nuevo periodo' }}</p>
          <button class="delete" aria-label="close" @click="closeModal"></button>
        </header>
        <section class="modal-card-body">
          <div class="columns">
            <div class="column">
              <div class="field">
                <label class="label">Nombre</label>
                <div class="control">
                  <input v-model="form.nombre" class="input" type="text" placeholder="Ej: Año 2025" />
                </div>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Año</label>
                <div class="control">
                  <input v-model.number="form.anio" class="input" type="number" min="2000" />
                </div>
              </div>
            </div>
          </div>

          <div class="columns">
            <div class="column">
              <div class="field">
                <label class="label">Fecha inicio</label>
                <div class="control">
                  <input v-model="form.fecha_inicio" class="input" type="date" />
                </div>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Fecha fin</label>
                <div class="control">
                  <input v-model="form.fecha_fin" class="input" type="date" />
                </div>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Estado</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.estado">
                  <option value="borrador">Borrador</option>
                  <option value="abierto">Abierto</option>
                  <option value="cerrado">Cerrado</option>
                </select>
              </div>
            </div>
          </div>

          <div v-if="modalError" class="notification is-danger">
            <button class="delete" @click="modalError = ''"></button>
            {{ modalError }}
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" :disabled="saving" @click="savePeriodo">
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

const periodos = ref([])
const loading = ref(true)
const error = ref('')
const showModal = ref(false)
const modalError = ref('')
const saving = ref(false)
const editing = ref(null)

const today = new Date()
const form = ref({
  nombre: '',
  anio: today.getFullYear(),
  fecha_inicio: '',
  fecha_fin: '',
  estado: 'borrador'
})

const loadPeriodos = async () => {
  loading.value = true
  error.value = ''
  try {
    const { data, error: err } = await supabase
      .from('periodos')
      .select('*')
      .order('anio', { ascending: false })
      .order('fecha_inicio', { ascending: false })

    if (err) throw err
    periodos.value = data || []
  } catch (err) {
    error.value = err.message || 'No se pudieron cargar los periodos'
  } finally {
    loading.value = false
  }
}

const validateForm = () => {
  if (!form.value.nombre.trim() || !form.value.anio || !form.value.fecha_inicio || !form.value.fecha_fin) {
    return 'Completa todos los campos'
  }
  if (form.value.fecha_inicio > form.value.fecha_fin) {
    return 'La fecha fin debe ser mayor a la fecha inicio'
  }
  return ''
}

const savePeriodo = async () => {
  modalError.value = ''
  saving.value = true
  try {
    const validation = validateForm()
    if (validation) {
      modalError.value = validation
      saving.value = false
      return
    }

    const payload = {
      nombre: form.value.nombre.trim(),
      anio: Number(form.value.anio),
      fecha_inicio: form.value.fecha_inicio,
      fecha_fin: form.value.fecha_fin,
      estado: form.value.estado
    }

    if (editing.value) {
      const { error: err } = await supabase.from('periodos').update(payload).eq('id', editing.value.id)
      if (err) throw err
    } else {
      const { error: err } = await supabase.from('periodos').insert([payload])
      if (err) throw err
    }

    await loadPeriodos()
    closeModal()
  } catch (err) {
    modalError.value = err.message || 'No se pudo guardar el periodo'
  } finally {
    saving.value = false
  }
}

const cambiarEstado = async (periodo, estado) => {
  try {
    const { error: err } = await supabase.from('periodos').update({ estado }).eq('id', periodo.id)
    if (err) throw err
    await loadPeriodos()
  } catch (err) {
    alert(err.message || 'No se pudo actualizar el estado')
  }
}

const openEdit = (periodo) => {
  editing.value = periodo
  form.value = {
    nombre: periodo.nombre,
    anio: periodo.anio,
    fecha_inicio: periodo.fecha_inicio?.slice(0, 10) || '',
    fecha_fin: periodo.fecha_fin?.slice(0, 10) || '',
    estado: periodo.estado
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  editing.value = null
  modalError.value = ''
  form.value = {
    nombre: '',
    anio: today.getFullYear(),
    fecha_inicio: '',
    fecha_fin: '',
    estado: 'borrador'
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
  loadPeriodos()
})
</script>
