<template>
  <div>
    <div class="level mb-5">
      <div class="level-left">
        <div class="level-item">
          <h1 class="title is-3">
            <i class="fas fa-users-cog mr-2"></i>
            Administración de Usuarios
          </h1>
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
                <th>Nombre</th>
                <th>Email</th>
                <th>Rol</th>
                <th>Estado</th>
                <th>Último Acceso</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="usuario in usuarios" :key="usuario.id">
                <td><strong>{{ usuario.nombre }} {{ usuario.apellido }}</strong></td>
                <td>{{ usuario.email }}</td>
                <td>
                  <span class="tag" :class="getRoleClass(usuario.rol_nombre)">
                    {{ usuario.rol_nombre || 'Sin rol' }}
                  </span>
                </td>
                <td>
                  <span class="tag" :class="usuario.activo ? 'is-success' : 'is-danger'">
                    {{ usuario.activo ? 'Activo' : 'Inactivo' }}
                  </span>
                </td>
                <td>{{ formatDate(usuario.ultimo_acceso) }}</td>
                <td>
                  <button class="button is-small is-info" @click="editUsuario(usuario)" title="Editar rol">
                    <i class="fas fa-edit"></i>
                  </button>
                  <button class="button is-small is-warning ml-2" @click="toggleActivo(usuario)" :title="usuario.activo ? 'Desactivar' : 'Activar'">
                    <i class="fas" :class="usuario.activo ? 'fa-ban' : 'fa-check'"></i>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Modal para editar usuario -->
    <div class="modal" :class="{ 'is-active': showModal }">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">Editar Usuario</p>
          <button class="delete" @click="closeModal"></button>
        </header>
        <section class="modal-card-body">
          <div class="field">
            <label class="label">Usuario</label>
            <div class="control">
              <input :value="`${editingUsuario?.nombre || ''} ${editingUsuario?.apellido || ''} (${editingUsuario?.email || ''})`" class="input" type="text" disabled />
            </div>
          </div>

          <div class="field">
            <label class="label">Rol</label>
            <div class="control">
              <div class="select is-fullwidth">
                <select v-model="form.rol_id" required>
                  <option value="">Seleccionar rol</option>
                  <option v-for="rol in roles" :key="rol.id" :value="rol.id">
                    {{ rol.nombre }} - {{ rol.descripcion }}
                  </option>
                </select>
              </div>
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
          <button class="button is-primary" @click="saveUsuario" :disabled="saving">
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

const usuarios = ref([])
const roles = ref([])
const loading = ref(true)
const showModal = ref(false)
const editingUsuario = ref(null)
const saving = ref(false)
const error = ref('')
const success = ref('')

const form = ref({
  rol_id: ''
})

const getRoleClass = (role) => {
  switch (role) {
    case 'admin':
      return 'is-danger'
    case 'docente':
      return 'is-info'
    case 'alumno':
      return 'is-success'
    default:
      return 'is-light'
  }
}

const loadRoles = async () => {
  try {
    const { data, error: err } = await supabase
      .from('roles')
      .select('*')
      .order('id')

    if (err) throw err
    roles.value = data || []
  } catch (err) {
    console.error('Error loading roles:', err)
  }
}

const loadUsuarios = async () => {
  try {
    loading.value = true
    error.value = ''
    
    // Obtener usuarios desde la vista o tabla
    const { data, error: err } = await supabase
      .from('v_usuarios_completos')
      .select('*')
      .order('created_at', { ascending: false })

    if (err) {
      // Si la vista no existe, usar tabla usuarios directamente
      const { data: usuariosData, error: usuariosErr } = await supabase
        .from('usuarios')
        .select(`
          *,
          roles (id, nombre, descripcion)
        `)
        .order('created_at', { ascending: false })

      if (usuariosErr) throw usuariosErr

      usuarios.value = (usuariosData || []).map(u => ({
        id: u.id,
        email: u.email,
        nombre: u.nombre,
        apellido: u.apellido,
        dni: u.dni,
        telefono: u.telefono,
        activo: u.activo,
        email_confirmado: u.email_confirmado,
        ultimo_acceso: u.ultimo_acceso,
        created_at: u.created_at,
        rol_id: u.rol_id,
        rol_nombre: u.roles?.nombre || null,
        rol_descripcion: u.roles?.descripcion || null
      }))
    } else {
      usuarios.value = data || []
    }
  } catch (err) {
    console.error('Error loading usuarios:', err)
    error.value = 'Error al cargar los usuarios: ' + (err.message || 'Error desconocido')
    usuarios.value = []
  } finally {
    loading.value = false
  }
}

const editUsuario = (usuario) => {
  editingUsuario.value = usuario
  form.value = {
    rol_id: usuario.rol_id
  }
  showModal.value = true
}

const saveUsuario = async () => {
  saving.value = true
  error.value = ''
  success.value = ''

  try {
    const { error: err } = await supabase
      .from('usuarios')
      .update({ rol_id: form.value.rol_id })
      .eq('id', editingUsuario.value.id)

    if (err) throw err

    success.value = 'Rol actualizado exitosamente'
    await loadUsuarios()
    setTimeout(() => {
      closeModal()
    }, 2000)
  } catch (err) {
    error.value = err.message || 'Error al actualizar el usuario.'
  } finally {
    saving.value = false
  }
}

const toggleActivo = async (usuario) => {
  const accion = usuario.activo ? 'desactivar' : 'activar'
  if (!confirm(`¿Estás seguro de ${accion} este usuario?`)) return

  try {
    const { error: err } = await supabase
      .from('usuarios')
      .update({ activo: !usuario.activo })
      .eq('id', usuario.id)

    if (err) throw err

    await loadUsuarios()
    success.value = `Usuario ${accion === 'activar' ? 'activado' : 'desactivado'} exitosamente`
    setTimeout(() => {
      success.value = ''
    }, 3000)
  } catch (err) {
    alert('Error al actualizar usuario: ' + err.message)
  }
}

const formatDate = (dateString) => {
  if (!dateString) return 'Nunca'
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const closeModal = () => {
  showModal.value = false
  editingUsuario.value = null
  form.value = {
    rol_id: ''
  }
  error.value = ''
  success.value = ''
}

onMounted(async () => {
  await loadRoles()
  await loadUsuarios()
})
</script>
