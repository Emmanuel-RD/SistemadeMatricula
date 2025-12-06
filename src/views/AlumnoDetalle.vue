<template>
  <div>
    <div class="level mb-4">
      <div class="level-left">
        <h1 class="title is-3 mb-0">
          <i class="fas fa-user-graduate mr-2"></i>
          Detalle de Alumno
        </h1>
      </div>
      <div class="level-right buttons">
        <button class="button" @click="goBack">
          <i class="fas fa-arrow-left mr-1"></i>
          Regresar
        </button>
        <button class="button is-info" @click="generarReporte">
          <i class="fas fa-file-alt mr-1"></i>
          Generar reporte de notas
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
      <div class="columns">
        <div class="column is-4">
          <div class="card">
            <div class="card-content">
              <h2 class="title is-5">Información</h2>
              <p><strong>Nombre:</strong> {{ alumno.nombre }} {{ alumno.apellido }}</p>
              <p><strong>DNI:</strong> {{ alumno.dni }}</p>
              <p><strong>Email:</strong> {{ alumno.email }}</p>
              <p><strong>Grado:</strong> {{ alumno.grado }}</p>
            </div>
          </div>

          <div class="card mt-4">
            <div class="card-content">
              <h2 class="title is-5">Foto carnet</h2>
              <figure v-if="alumno.foto_carnet" class="image" style="max-width: 260px;">
                <img :src="alumno.foto_carnet" alt="Foto carnet" />
              </figure>
              <p v-else class="has-text-grey">No hay foto</p>
            </div>
          </div>

          <div class="card mt-4">
            <div class="card-content">
              <h2 class="title is-5">Constancia de estudios</h2>
              <figure v-if="isImage(alumno.constancia_estudios)" class="image" style="max-width: 260px;">
                <img :src="alumno.constancia_estudios" alt="Constancia de estudios" />
              </figure>
              <div v-else-if="alumno.constancia_estudios">
                <a :href="alumno.constancia_estudios" target="_blank" rel="noopener">Ver constancia</a>
              </div>
              <p v-else class="has-text-grey">No hay constancia</p>
            </div>
          </div>
        </div>

        <div class="column is-8">
          <div class="card">
            <div class="card-content">
              <div class="level mb-3">
                <div class="level-left">
                  <h2 class="title is-5 mb-0">Cursos matriculados</h2>
                </div>
                <div class="level-right">
                  <div class="field">
                    <div class="control">
                      <div class="select">
                        <select v-model="periodoSeleccionado">
                          <option value="todos">Todos los períodos</option>
                          <option v-for="p in periodosAlumno" :key="p.id" :value="p.id">
                            {{ p.nombre }}
                          </option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div v-if="filteredCursos.length === 0" class="has-text-grey">
                No tiene cursos matriculados para el período seleccionado.
              </div>

              <div v-else class="table-container">
                <table class="table is-fullwidth is-striped is-bordered is-hoverable is-size-7">
                  <thead>
                    <tr>
                      <th>Curso</th>
                      <th>Horario</th>
                      <th class="has-text-centered">Grado</th>
                      <th class="has-text-centered">B1</th>
                      <th class="has-text-centered">B2</th>
                      <th class="has-text-centered">B3</th>
                      <th class="has-text-centered">B4</th>
                      <th class="has-text-centered">Prom</th>
                      <th class="has-text-centered">Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="curso in filteredCursos" :key="curso.matricula_curso_id">
                      <td>
                        <p class="has-text-weight-semibold">{{ curso.nombre }}</p>
                        <p class="is-size-7 has-text-grey">{{ curso.dia_semana }}</p>
                        <p class="is-size-7 has-text-info">{{ curso.periodo?.label }}</p>
                      </td>
                      <td class="is-size-7">{{ curso.hora_inicio }} - {{ curso.hora_fin }}</td>
                      <td class="has-text-centered">{{ curso.grado }}</td>

                      <td v-for="b in [1,2,3,4]" :key="b" class="has-text-centered">
                        {{ notas[curso.matricula_curso_id]?.[b] ?? '-' }}
                      </td>

                      <td class="has-text-centered">
                        {{ promedios[curso.matricula_curso_id] ?? '-' }}
                      </td>

                      <td class="has-text-centered">
                        <span
                          v-if="promedios[curso.matricula_curso_id] !== undefined"
                          class="tag"
                          :class="promedios[curso.matricula_curso_id] >= 12 ? 'is-success' : 'is-danger'"
                        >
                          {{ promedios[curso.matricula_curso_id] >= 12 ? 'Aprobado' : 'Desaprobado' }}
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
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/config/supabase'

const route = useRoute()
const router = useRouter()
const alumnoId = route.params.id

const loading = ref(true)
const error = ref('')
const alumno = ref(null)
const cursos = ref([])
const notas = ref({})
const periodoSeleccionado = ref('todos')

const periodosAlumno = computed(() => {
  const map = {}
  cursos.value.forEach((c) => {
    if (c.periodo) map[c.periodo.id] = c.periodo.label
  })
  return Object.entries(map).map(([id, label]) => ({ id: String(id), nombre: label }))
})

const filteredCursos = computed(() => {
  if (periodoSeleccionado.value === 'todos') return cursos.value
  return cursos.value.filter((c) => c.periodo && String(c.periodo.id) === periodoSeleccionado.value)
})

const promedios = computed(() => {
  const result = {}
  Object.entries(notas.value || {}).forEach(([mcId, notaObj]) => {
    const valores = [1, 2, 3, 4]
      .map((b) => notaObj[b])
      .filter((v) => v !== undefined && v !== null && v !== '')
      .map(Number)

    if (valores.length === 0) return

    const prom = (valores.reduce((a, b) => a + b, 0) / valores.length).toFixed(2)
    result[mcId] = Number(prom)
  })
  return result
})

const isImage = (value) => {
  if (!value) return false
  return value.startsWith('data:image') || value.match(/\.(png|jpg|jpeg|gif)$/i)
}

const goBack = () => router.back()

// ===============================
//   >>>>  REPARADO AQUÍ  <<<<
// ===============================

const generarReporte = () => {
  const colegio = {
    nombre: 'Colegio Nacional San Martín',
    direccion: 'Av. Principal 123, Ciudad',
    telefono: '(01) 555-1234',
    correo: 'info@colegiosanmartin.edu.pe'
  }

  const fecha = new Date().toLocaleDateString('es-ES')

  const periodoLabel =
    periodoSeleccionado.value === 'todos'
      ? 'Todos los períodos'
      : periodosAlumno.value.find((p) => p.id === periodoSeleccionado.value)?.nombre

  const rows = filteredCursos.value
    .map((curso) => {
      const b = notas.value?.[curso.matricula_curso_id] ?? {}
      const prom = promedios.value?.[curso.matricula_curso_id] ?? '-'
      const estado = prom !== '-' ? (prom >= 12 ? 'Aprobado' : 'Desaprobado') : '-'

      return `
        <tr>
          <td>${curso.nombre}</td>
          <td>${curso.dia_semana} · ${curso.hora_inicio} - ${curso.hora_fin}</td>
          <td class="center">${curso.grado}</td>
          <td class="center">${b[1] ?? '-'}</td>
          <td class="center">${b[2] ?? '-'}</td>
          <td class="center">${b[3] ?? '-'}</td>
          <td class="center">${b[4] ?? '-'}</td>
          <td class="center">${prom}</td>
          <td class="center">${estado}</td>
        </tr>
      `
    })
    .join('')

  const html = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; margin: 32px; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #000; padding-bottom: 12px; }
    .school { font-size: 14px; }
    .badge { background: #1d4ed8; color: #fff; padding: 6px 12px; border-radius: 6px; font-weight: bold; }
    .section { margin-top: 24px; }
    table { width: 100%; border-collapse: collapse; margin-top: 12px; }
    th, td { border: 1px solid #ddd; padding: 8px; font-size: 12px; }
    th { background: #f3f4f6; }
    .center { text-align: center; }
    .footer { margin-top: 24px; font-size: 12px; color: #777; display: flex; justify-content: space-between; }
  </style>
</head>

<body>
  <div class="header">
    <div>
      <h1>${colegio.nombre}</h1>
      <div class="school">
        <div>${colegio.direccion}</div>
        <div>${colegio.telefono} · ${colegio.correo}</div>
      </div>
    </div>
    <div class="badge">Reporte de Notas</div>
  </div>

  <div class="section">
    <h2>Alumno</h2>
    <p><strong>Nombre:</strong> ${alumno.value.nombre} ${alumno.value.apellido}</p>
    <p><strong>DNI:</strong> ${alumno.value.dni}</p>
    <p><strong>Email:</strong> ${alumno.value.email}</p>
    <p><strong>Grado:</strong> ${alumno.value.grado}</p>
    <p><strong>Período:</strong> ${periodoLabel}</p>
  </div>

  <div class="section">
    <h2>Cursos y notas</h2>
    <table>
      <thead>
        <tr>
          <th>Curso</th>
          <th>Horario</th>
          <th>Grado</th>
          <th>B1</th>
          <th>B2</th>
          <th>B3</th>
          <th>B4</th>
          <th>Prom</th>
          <th>Estado</th>
        </tr>
      </thead>
      <tbody>
        ${rows}
      </tbody>
    </table>
  </div>

  <div class="footer">
    <div>Generado el ${fecha}</div>
    <div>Firma del docente ____________________</div>
  </div>

  <script>
    window.onload = () => { window.print(); window.close(); };
  <\/script>
<\/body>
<\/html>
  `

  const printWindow = window.open('', '_blank')
  if (printWindow) {
    printWindow.document.write(html)
    printWindow.document.close()
  } else {
    alert('No se pudo abrir la ventana de impresión.')
  }
}

const loadAlumno = async () => {
  loading.value = true
  error.value = ''

  try {
    const { data: alumnoData, error: errAlumno } = await supabase
      .from('alumnos')
      .select('*')
      .eq('id', alumnoId)
      .single()

    if (errAlumno) throw errAlumno
    alumno.value = alumnoData

    const { data: mcData, error: errMat } = await supabase
      .from('matricula_cursos')
      .select(`
        id,
        curso_id,
        cursos ( id, nombre, grado, dia_semana, hora_inicio, hora_fin ),
        matriculas_periodo!inner (
          id,
          periodo_id,
          periodos (id, nombre, anio),
          alumno_id
        )
      `)
      .eq('matriculas_periodo.alumno_id', alumnoId)

    if (errMat) throw errMat

    cursos.value = (mcData || []).map((mc) => ({
      matricula_curso_id: mc.id,
      curso_id: mc.curso_id,
      ...mc.cursos,
      periodo: mc.matriculas_periodo?.periodos
        ? {
            id: String(mc.matriculas_periodo.periodos.id),
            label: `${mc.matriculas_periodo.periodos.nombre} ${mc.matriculas_periodo.periodos.anio}`
          }
        : null
    }))

    if (periodosAlumno.value.length > 0) {
      periodoSeleccionado.value = periodosAlumno.value[0].id
    }

    const mcIds = cursos.value.map((c) => c.matricula_curso_id)

    if (mcIds.length > 0) {
      const { data: notasData, error: errNotas } = await supabase
        .from('notas')
        .select('matricula_curso_id, bimestre, nota')
        .in('matricula_curso_id', mcIds)

      if (errNotas) throw errNotas

      const map = {}
      notasData?.forEach((n) => {
        if (!map[n.matricula_curso_id]) map[n.matricula_curso_id] = {}
        map[n.matricula_curso_id][n.bimestre] = n.nota
      })
      notas.value = map
    } else {
      notas.value = {}
    }
  } catch (err) {
    console.error(err)
    error.value = err.message || 'No se pudo cargar el alumno'
  } finally {
    loading.value = false
  }
}

onMounted(loadAlumno)
</script>
