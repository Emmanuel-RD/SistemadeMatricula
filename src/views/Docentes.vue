<template>
  <div>
    <div class="level mb-5">
      <div class="level-left">
        <div class="level-item">
          <h1 class="title is-3">
            <i class="fas fa-chalkboard-teacher mr-2"></i>
            Gestión de Docentes
          </h1>
        </div>
      </div>
      <div class="level-right">
        <div class="level-item">
          <button class="button is-primary" @click="showModal = true">
            <i class="fas fa-plus mr-2"></i>
            Nuevo Docente
          </button>
        </div>
      </div>
    </div>

    <div v-if="error" class="notification is-danger mb-4">
      <button class="delete" @click="error = ''"></button>
      {{ error }}
    </div>

    <div v-if="success" class="notification is-success mb-4">
      <button class="delete" @click="success = ''"></button>
      {{ success }}
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
                  placeholder="Buscar por nombre, apellido, email o teléfono"
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
          <table class="table is-fullwidth is-striped">
            <thead>
              <tr>
                <th>ID</th>
                <th>Nombre</th>
                <th>Apellido</th>
                <th>Email</th>
                <th>Teléfono</th>
                <th>Cursos Asignados</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="docente in filteredDocentes" :key="docente.id">
                <td>{{ docente.id }}</td>
                <td><strong>{{ docente.nombre }}</strong></td>
                <td>{{ docente.apellido }}</td>
                <td>{{ docente.email }}</td>
                <td>{{ docente.telefono || '-' }}</td>
                <td>
                  <span class="tag is-info">{{ docente.total_cursos || 0 }}</span>
                </td>
                <td>
                  <button class="button is-small is-info" @click="editDocente(docente)">
                    <i class="fas fa-edit"></i>
                  </button>
                  <button class="button is-small is-danger ml-2" @click="deleteDocente(docente.id)">
                    <i class="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal para crear/editar docente -->
    <div class="modal" :class="{ 'is-active': showModal }">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">
            {{ editingDocente ? 'Editar Docente' : 'Nuevo Docente' }}
          </p>
          <button class="delete" @click="closeModal"></button>
        </header>
        <section class="modal-card-body">
          <div class="columns">
            <div class="column">
              <div class="field">
                <label class="label">Nombre</label>
                <div class="control">
                  <input v-model="form.nombre" class="input" type="text" required :readonly="nameLocked" />
                </div>
                <p v-if="nameLocked" class="help is-success">Nombre bloqueado desde RENIEC</p>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Apellido</label>
                <div class="control">
                  <input v-model="form.apellido" class="input" type="text" required :readonly="nameLocked" />
                </div>
                <p v-if="nameLocked" class="help is-success">Apellidos bloqueados desde RENIEC</p>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">DNI</label>
            <div class="field has-addons">
              <div class="control is-expanded">
                <input
                  v-model="form.dni"
                  class="input"
                  type="text"
                  placeholder="Ej: 12345678"
                  maxlength="8"
                  inputmode="numeric"
                  pattern="\\d*"
                  required
                />
              </div>
              <div class="control">
                <button class="button is-info" type="button" @click="fetchReniecData" :class="{ 'is-loading': reniecLoading }">
                  Buscar DNI
                </button>
              </div>
            </div>
            <p class="help">Completa nombres automaticamente consultando RENIEC.</p>
            <p v-if="reniecNotice" class="help is-success">{{ reniecNotice }}</p>
            <p v-if="reniecError" class="help is-danger">{{ reniecError }}</p>
          </div>

          <div class="field">
            <label class="label">Email</label>
            <div class="control">
              <input v-model="form.email" class="input" type="email" required />
            </div>
            <p class="help">Este será el correo para iniciar sesión</p>
          </div>

          <div class="field">
            <label class="label">Teléfono</label>
            <div class="control">
              <input v-model="form.telefono" class="input" type="tel" required />
            </div>
          </div>

          <div v-if="error" class="notification is-danger mt-3">
            <button class="delete" @click="error = ''"></button>
            {{ error }}
          </div>
          <div v-if="success" class="notification is-success mt-3">
            <button class="delete" @click="success = ''"></button>
            {{ success }}
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" @click="saveDocente" :disabled="saving">
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
import { emailService } from '@/services/email'
import { reniecService } from '@/services/reniec'

const docentes = ref([])
const loading = ref(true)
const showModal = ref(false)
const editingDocente = ref(null)
const saving = ref(false)
const error = ref('')
const success = ref('')
const nameLocked = ref(false)
const reniecLoading = ref(false)
const reniecNotice = ref('')
const reniecError = ref('')
const search = ref('')

const form = ref({
  nombre: '',
  apellido: '',
  dni: '',
  email: '',
  telefono: ''
})

const filteredDocentes = computed(() => {
  const term = search.value.trim().toLowerCase()
  if (!term) return docentes.value
  return docentes.value.filter(d =>
    d.nombre.toLowerCase().includes(term) ||
    d.apellido.toLowerCase().includes(term) ||
    d.email.toLowerCase().includes(term) ||
    (d.telefono || '').toLowerCase().includes(term)
  )
})

const loadDocentes = async () => {
  try {
    const { data: docentesData, error: err } = await supabase
      .from('docentes')
      .select('*')
      .order('nombre')

    if (err) throw err

    // Contar cursos por docente
    const { data: cursosData } = await supabase
      .from('cursos')
      .select('docente_id')

    const cursoCounts = {}
    cursosData?.forEach(c => {
      cursoCounts[c.docente_id] = (cursoCounts[c.docente_id] || 0) + 1
    })

    docentes.value = (docentesData || []).map(d => ({
      ...d,
      total_cursos: cursoCounts[d.id] || 0
    }))
  } catch (err) {
    console.error('Error loading docentes:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const editDocente = (docente) => {
  editingDocente.value = docente
  form.value = {
    nombre: docente.nombre,
    apellido: docente.apellido,
    dni: docente.dni || '',
    email: docente.email,
    telefono: docente.telefono || ''
  }
  nameLocked.value = false
  reniecNotice.value = ''
  reniecError.value = ''
  showModal.value = true
}

const deleteDocente = async (id) => {
  if (!confirm('¿Estás seguro de eliminar este docente?')) return

  try {
    const { error: err } = await supabase
      .from('docentes')
      .delete()
      .eq('id', id)

    if (err) throw err
    await loadDocentes()
  } catch (err) {
    alert('Error al eliminar: ' + err.message)
  }
}

// Función para generar contraseña aleatoria
const generatePassword = () => {
  const length = 12
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
  let password = ''
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length))
  }
  return password
}

// Consultar RENIEC para autocompletar nombres/apellidos
const fetchReniecData = async () => {
  reniecLoading.value = true
  reniecError.value = ''
  reniecNotice.value = ''

  try {
    const { success, data, error: reniecErr } = await reniecService.fetchByDni(form.value.dni.trim())

    if (!success) {
      reniecError.value = reniecErr || 'No se encontraron datos para el DNI ingresado.'
      nameLocked.value = false
      return
    }

    form.value.nombre = (data.first_name || '').trim()
    form.value.apellido = [data.first_last_name, data.second_last_name].filter(Boolean).join(' ').trim()
    nameLocked.value = true
    reniecNotice.value = 'Datos completados automaticamente desde RENIEC.'
  } catch (err) {
    reniecError.value = err.message || 'Error al consultar RENIEC.'
    nameLocked.value = false
  } finally {
    reniecLoading.value = false
  }
}

const validateDocenteForm = () => {
  const nombre = form.value.nombre.trim()
  const apellido = form.value.apellido.trim()
  const dni = form.value.dni.trim()
  const email = form.value.email.trim().toLowerCase()
  const telefono = form.value.telefono.trim()

  if (!nombre || !apellido || !dni || !email || !telefono) {
    error.value = 'Todos los campos son obligatorios.'
    return null
  }

  if (!/^[0-9]{8}$/.test(dni)) {
    error.value = 'El DNI debe tener 8 dígitos numéricos.'
    return null
  }

  return { nombre, apellido, dni, email, telefono }
}

const saveDocente = async () => {
  saving.value = true
  error.value = ''
  success.value = ''
  reniecError.value = ''

  try {
    const payload = validateDocenteForm()
    if (!payload) {
      saving.value = false
      return
    }

    if (editingDocente.value) {
      // Actualizar datos en usuario y docente
      if (editingDocente.value.usuario_id) {
        const { error: usuarioErr } = await supabase
          .from('usuarios')
          .update({
            nombre: payload.nombre,
            apellido: payload.apellido,
            dni: payload.dni,
            email: payload.email,
            telefono: payload.telefono
          })
          .eq('id', editingDocente.value.usuario_id)

        if (usuarioErr) {
          if (usuarioErr.message.toLowerCase().includes('dni')) {
            throw new Error('El DNI ya está registrado en otro usuario')
          }
          if (usuarioErr.message.toLowerCase().includes('email')) {
            throw new Error('El email ya está registrado en el sistema')
          }
          throw usuarioErr
        }
      }

      const { error: err } = await supabase
        .from('docentes')
        .update({
          nombre: payload.nombre,
          apellido: payload.apellido,
          dni: payload.dni,
          email: payload.email,
          telefono: payload.telefono
        })
        .eq('id', editingDocente.value.id)

      if (err) {
        const lowerMessage = err.message.toLowerCase()
        if (lowerMessage.includes('dni')) {
          throw new Error('El DNI ya está registrado en otro docente')
        }
        if (lowerMessage.includes('email')) {
          throw new Error('El email ya está registrado en el sistema')
        }
        throw err
      }
      success.value = 'Docente actualizado exitosamente'
    } else {
      // Crear nuevo docente con usuario
      const password = generatePassword()
      
      // Obtener ID del rol docente
      const { data: rolData, error: rolError } = await supabase
        .from('roles')
        .select('id')
        .eq('nombre', 'docente')
        .single()

      if (rolError || !rolData) {
        throw new Error('No se encontró el rol de docente')
      }

      // Crear usuario usando la función RPC
      const { data: usuarioId, error: usuarioError } = await supabase.rpc('crear_usuario_con_password', {
        p_email: payload.email,
        p_password: password,
        p_rol_id: rolData.id,
        p_nombre: payload.nombre,
        p_apellido: payload.apellido,
        p_dni: payload.dni,
        p_telefono: payload.telefono
      })

      if (usuarioError) {
        // Si el usuario ya existe
        const lowerMessage = usuarioError.message.toLowerCase()
        if (lowerMessage.includes('dni')) {
          error.value = 'El DNI ya está registrado en el sistema'
          saving.value = false
          return
        }
        if (lowerMessage.includes('duplicate') || lowerMessage.includes('unique') || lowerMessage.includes('email')) {
          error.value = 'El email ya está registrado en el sistema'
          saving.value = false
          return
        }
        throw usuarioError
      }

      // Crear registro en tabla docentes vinculado al usuario
      const { error: err } = await supabase
        .from('docentes')
        .insert([{
          nombre: payload.nombre,
          apellido: payload.apellido,
          dni: payload.dni,
          email: payload.email,
          telefono: payload.telefono,
          usuario_id: usuarioId
        }])

      if (err) {
        // Si falla, eliminar el usuario creado
        if (usuarioId) {
          await supabase.from('usuarios').delete().eq('id', usuarioId)
        }
        const lowerMessage = err.message.toLowerCase()
        if (lowerMessage.includes('dni')) {
          error.value = 'El DNI ya está registrado en el sistema'
          saving.value = false
          return
        }
        if (lowerMessage.includes('email')) {
          error.value = 'El email ya está registrado en el sistema'
          saving.value = false
          return
        }
        throw err
      }

      // Enviar email con credenciales
      try {
        await emailService.sendCredentials(
          payload.email,
          password,
          payload.nombre,
          payload.apellido,
          'docente'
        )
        success.value = `Docente creado exitosamente. Las credenciales han sido enviadas al correo: ${payload.email}`
      } catch (emailErr) {
        console.warn('Error al enviar email:', emailErr)
        // Mostrar credenciales de todas formas
        alert(`✅ Docente creado exitosamente\n\n📧 Email: ${payload.email}\n🔑 Contraseña: ${password}\n\n⚠️ No se pudo enviar el email automáticamente. Por favor, guarda estas credenciales y envíalas manualmente al usuario.`)
        success.value = 'Docente creado exitosamente. Revisa las credenciales mostradas.'
      }
    }

    await loadDocentes()
    if (success.value) {
      setTimeout(() => {
        closeModal()
      }, 2000)
    } else {
      closeModal()
    }
  } catch (err) {
    error.value = err.message || 'Error al guardar el docente'
  } finally {
    saving.value = false
  }
}

const closeModal = () => {
  showModal.value = false
  editingDocente.value = null
  form.value = {
    nombre: '',
    apellido: '',
    dni: '',
    email: '',
    telefono: ''
  }
  error.value = ''
  success.value = ''
  nameLocked.value = false
  reniecNotice.value = ''
  reniecError.value = ''
}

onMounted(() => {
  loadDocentes()
})
</script>
