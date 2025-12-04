import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

// Manejo de errores globales
app.config.errorHandler = (err, instance, info) => {
  console.error('Error global:', err, info)
}

// Montar la aplicación
app.mount('#app')

