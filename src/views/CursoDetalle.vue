<template>
  <div>
    <div class="level mb-4">
      <div class="level-left">
        <h1 class="title is-3 mb-0">
          <i class="fas fa-book mr-2"></i>
          Detalle de Curso
        </h1>
      </div>
      <div class="level-right buttons">
        <button class="button" @click="goBack">
          <i class="fas fa-arrow-left mr-1"></i>
          Regresar
        </button>
      </div>
    </div>

    <div v-if="loading" class="has-text-centered py-6">
      <i class="fas fa-spinner fa-spin fa-2x"></i>
    </div>

    <div v-else-if="error" class="notification is-danger">
      {{ error }}
    </div>

    <div v-else>
      <div class="card mb-4">
        <div class="card-content">
          <div class="columns">
            <div class="column">
              <p class="title is-4">{{ curso.nombre }}</p>
              <p class="subtitle is-6 mb-2">{{ curso.descripcion || 'Sin descripción' }}</p>
              <p><strong>Grado:</strong> {{ curso.grado }}</p>
              <p><strong>Horario:</strong> {{ curso.dia_semana }} · {{ curso.hora_inicio }} - {{ curso.hora_fin }}</p>
              <p><strong>Capacidad:</strong> {{ curso.capacidad }}</p>
            </div>
            <div class="column">
              <p><strong>Docente:</strong> {{ curso.docente_nombre || 'Sin docente' }}</p>
              <p><strong>Alumnos matriculados:</strong> {{ alumnos.length }}</p>
              <div class="field mt-3">
                <label class="label">Fecha asistencia</label>
                <div class="control">
                  <input type="date" class="input" v-model="fechaAsistencia" @change="loadAsistencias" />
                </div>
                <p class="help">La lista de asistencia es por fecha.</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-content">
          <div class="level mb-3">
            <div class="level-left">
              <h2 class="title is-4 mb-0">Estudiantes</h2>
            </div>
            <div class="level-right buttons">
              <button class="button is-success" :disabled="savingAsist" @click="saveAsistencias">
                <i class="fas fa-check mr-1"></i> Guardar asistencia
              </button>
              <button class="button is-info" :disabled="savingNotas" @click="saveNotas">
                <i class="fas fa-save mr-1"></i> Guardar notas
              </button>
            </div>
          </div>

          <div v-if="alumnos.length === 0" class="has-text-grey">No hay estudiantes matriculados.</div>

          <div v-else class="table-container">
            <table class="table is-fullwidth is-striped is-bordered is-size-7">
              <thead>
                <tr>
                  <th>Alumno</th>
                  <th class="has-text-centered">Asistencia</th>
                  <th class="has-text-centered">B1</th>
                  <th class="has-text-centered">B2</th>
                  <th class="has-text-centered">B3</th>
                  <th class="has-text-centered">B4</th>
                  <th class="has-text-centered">Prom</th>
                  <th class="has-text-centered">Estado</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="alumno in alumnos" :key="alumno.matricula_curso_id">
                  <td>
                    <p class="has-text-weight-semibold">{{ alumno.nombre }} {{ alumno.apellido }}</p>
                    <p class="is-size-7 has-text-grey">{{ alumno.dni }} · {{ alumno.email }}</p>
                  </td>
                  <td class="has-text-centered">
                    <input type="checkbox" v-model="asistencias[alumno.matricula_curso_id]" />
                  </td>
                  <td v-for="b in [1,2,3,4]" :key="b" class="has-text-centered">
                    <input
                      class="input is-small"
                      type="number"
                      min="0"
                      max="20"
                      step="0.1"
                      :value="notasMap[alumno.matricula_curso_id]?.[b] ?? ''"
                      @input="onNotaChange(alumno.matricula_curso_id, b, $event.target.value)"
                    />
                  </td>
                  <td class="has-text-centered">{{ promedios[alumno.matricula_curso_id] ?? '-' }}</td>
                  <td class="has-text-centered">
                    <span
                      v-if="promedios[alumno.matricula_curso_id] !== undefined"
                      class="tag"
                      :class="promedios[alumno.matricula_curso_id] >= 12 ? 'is-success' : 'is-danger'"
                    >
                      {{ promedios[alumno.matricula_curso_id] >= 12 ? 'Aprobado' : 'Desaprobado' }}
                    </span>
                    <span v-else class="has-text-grey">-</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/config/supabase'

const route = useRoute()
const router = useRouter()
const cursoId = route.params.id

const loading = ref(true)
const error = ref('')
const curso = ref(null)
const alumnos = ref([])
const asistencias = ref({})
const notasMap = ref({})
const savingAsist = ref(false)
const savingNotas = ref(false)
const fechaAsistencia = ref(new Date().toISOString().slice(0, 10))

const matriculaCursoIds = computed(() => alumnos.value.map((a) => a.matricula_curso_id))

const promedios = computed(() => {
  const result = {}
  Object.entries(notasMap.value || {}).forEach(([mcId, notas]) => {
    const valores = [1, 2, 3, 4]
      .map((b) => notas[b])
      .filter((v) => v !== undefined && v !== null && v !== '')
      .map(Number)
    if (valores.length === 0) return
    const prom = (valores.reduce((a, b) => a + b, 0) / valores.length).toFixed(2)
    result[mcId] = Number(prom)
  })
  return result
})

const goBack = () => {
  router.back()
}

const loadCurso = async () => {
  loading.value = true
  error.value = ''
  try {
    const { data: cursoData, error: errCurso } = await supabase
      .from('cursos')
      .select(
        `
        *,
        docentes (nombre, apellido)
      `
      )
      .eq('id', cursoId)
      .single()

    if (errCurso) throw errCurso

    curso.value = {
      ...cursoData,
      docente_nombre: cursoData.docentes ? `${cursoData.docentes.nombre} ${cursoData.docentes.apellido}` : null
    }

    const { data: alumnosData, error: errAlumnos } = await supabase
      .from('matricula_cursos')
      .select(
        `
        id,
        matriculas:matriculas_periodo (
          id,
          alumno_id,
          alumnos (
            id,
            nombre,
            apellido,
            dni,
            email
          )
        )
      `
      )
      .eq('curso_id', cursoId)

    if (errAlumnos) throw errAlumnos

    alumnos.value = (alumnosData || []).map((mc) => ({
      matricula_curso_id: mc.id,
      ...mc.matriculas?.alumnos
    })).filter(a => a && a.id)

    await Promise.all([loadAsistencias(), loadNotas()])
  } catch (err) {
    console.error(err)
    error.value = err.message || 'No se pudo cargar el curso'
  } finally {
    loading.value = false
  }
}

const loadAsistencias = async () => {
  if (!matriculaCursoIds.value.length) return
  try {
    const { data, error: err } = await supabase
      .from('asistencias')
      .select('matricula_curso_id, presente')
      .in('matricula_curso_id', matriculaCursoIds.value)
      .eq('fecha', fechaAsistencia.value)

    if (err) throw err
    const map = {}
    alumnos.value.forEach((a) => {
      map[a.matricula_curso_id] = true
    })
    data?.forEach((row) => {
      map[row.matricula_curso_id] = row.presente
    })
    asistencias.value = map
  } catch (err) {
    console.error('Error cargando asistencias', err)
  }
}

const loadNotas = async () => {
  if (!matriculaCursoIds.value.length) return
  try {
    const { data, error: err } = await supabase
      .from('notas')
      .select('matricula_curso_id, bimestre, nota')
      .in('matricula_curso_id', matriculaCursoIds.value)

    if (err) throw err
    const map = {}
    data?.forEach((n) => {
      if (!map[n.matricula_curso_id]) map[n.matricula_curso_id] = {}
      map[n.matricula_curso_id][n.bimestre] = n.nota
    })
    notasMap.value = map
  } catch (err) {
    console.error('Error cargando notas', err)
  }
}

const saveAsistencias = async () => {
  savingAsist.value = true
  try {
    const rows = alumnos.value.map((a) => ({
      matricula_curso_id: a.matricula_curso_id,
      fecha: fechaAsistencia.value,
      presente: !!asistencias.value[a.matricula_curso_id]
    }))

    const { error: err } = await supabase.from('asistencias').upsert(rows, { onConflict: 'matricula_curso_id,fecha' })
    if (err) throw err
    alert('Asistencias guardadas')
  } catch (err) {
    alert(err.message || 'Error al guardar asistencias')
  } finally {
    savingAsist.value = false
  }
}

const onNotaChange = (mcId, bimestre, value) => {
  if (!notasMap.value[mcId]) notasMap.value[mcId] = {}
  notasMap.value[mcId][bimestre] = value ? Number(value) : ''
}

const saveNotas = async () => {
  savingNotas.value = true
  try {
    const rows = []
    alumnos.value.forEach((a) => {
      for (let b = 1; b <= 4; b++) {
        const val = notasMap.value[a.matricula_curso_id]?.[b]
        if (val === '' || val === undefined || val === null) continue
        const notaNum = Number(val)
        if (isNaN(notaNum) || notaNum < 0 || notaNum > 20) {
          throw new Error('Las notas deben estar entre 0 y 20')
        }
        rows.push({
          matricula_curso_id: a.matricula_curso_id,
          bimestre: b,
          nota: notaNum
        })
      }
    })

    if (!rows.length) {
      alert('No hay notas para guardar')
      savingNotas.value = false
      return
    }

    const { error: err } = await supabase
      .from('notas')
      .upsert(rows, { onConflict: 'matricula_curso_id,bimestre' })

    if (err) throw err
    alert('Notas guardadas')
  } catch (err) {
    alert(err.message || 'Error al guardar notas')
  } finally {
    savingNotas.value = false
  }
}

onMounted(() => {
  loadCurso()
})
</script>
