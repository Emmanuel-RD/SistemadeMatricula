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
              <tr v-for="docente in docentes" :key="docente.id">
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
                  <input v-model="form.nombre" class="input" type="text" required />
                </div>
              </div>
            </div>
            <div class="column">
              <div class="field">
                <label class="label">Apellido</label>
                <div class="control">
                  <input v-model="form.apellido" class="input" type="text" required />
                </div>
              </div>
            </div>
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
              <input v-model="form.telefono" class="input" type="tel" />
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
import { ref, onMounted } from 'vue'
import { supabase } from '@/config/supabase'
import { emailService } from '@/services/email'

const docentes = ref([])
const loading = ref(true)
const showModal = ref(false)
const editingDocente = ref(null)
const saving = ref(false)
const error = ref('')
const success = ref('')

const form = ref({
  nombre: '',
  apellido: '',
  email: '',
  telefono: ''
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
    email: docente.email,
    telefono: docente.telefono || ''
  }
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

const saveDocente = async () => {
  saving.value = true
  error.value = ''
  success.value = ''

  try {
    if (editingDocente.value) {
      // Solo actualizar datos
      const { error: err } = await supabase
        .from('docentes')
        .update(form.value)
        .eq('id', editingDocente.value.id)

      if (err) throw err
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
        p_email: form.value.email,
        p_password: password,
        p_rol_id: rolData.id,
        p_nombre: form.value.nombre,
        p_apellido: form.value.apellido,
        p_dni: null,
        p_telefono: form.value.telefono || null
      })

      if (usuarioError) {
        // Si el usuario ya existe
        if (usuarioError.message.includes('duplicate') || usuarioError.message.includes('unique')) {
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
          ...form.value,
          usuario_id: usuarioId
        }])

      if (err) {
        // Si falla, eliminar el usuario creado
        if (usuarioId) {
          await supabase.from('usuarios').delete().eq('id', usuarioId)
        }
        throw err
      }

      // Enviar email con credenciales
      try {
        await emailService.sendCredentials(
          form.value.email,
          password,
          form.value.nombre,
          form.value.apellido,
          'docente'
        )
        success.value = `Docente creado exitosamente. Las credenciales han sido enviadas al correo: ${form.value.email}`
      } catch (emailErr) {
        console.warn('Error al enviar email:', emailErr)
        // Mostrar credenciales de todas formas
        alert(`✅ Docente creado exitosamente\n\n📧 Email: ${form.value.email}\n🔑 Contraseña: ${password}\n\n⚠️ No se pudo enviar el email automáticamente. Por favor, guarda estas credenciales y envíalas manualmente al usuario.`)
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
    email: '',
    telefono: ''
  }
  error.value = ''
  success.value = ''
}

onMounted(() => {
  loadDocentes()
})
</script>
