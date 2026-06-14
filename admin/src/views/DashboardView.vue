<template>
  <div class="dashboard-wrapper">
    <div class="header-section">
      <h2 class="page-title">Dashboard</h2>
      <p class="subtitle">Visão geral e métricas de crescimento</p>
    </div>
    
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Carregando métricas...</p>
    </div>
    <div v-else-if="error" class="error-state">
      <div class="error-icon">⚠️</div>
      <p>{{ error }}</p>
    </div>
    <div v-else class="dashboard-content fade-in">
      <div class="cards-grid">
        <div class="metric-card">
          <div class="card-icon blue">👥</div>
          <div class="card-info">
            <h3>Total de Usuários</h3>
            <p class="value">{{ overview.totalUsers }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="card-icon green">⭐</div>
          <div class="card-info">
            <h3>Assinantes Premium</h3>
            <p class="value">{{ overview.premiumActive }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="card-icon yellow">⏳</div>
          <div class="card-info">
            <h3>Trials Ativos</h3>
            <p class="value">{{ overview.trialsActive }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="card-icon red">📉</div>
          <div class="card-info">
            <h3>Churn do Mês</h3>
            <p class="value">{{ overview.churnThisMonth }}</p>
          </div>
        </div>
      </div>

      <div class="chart-section">
        <div class="chart-header">
          <h3>Cadastros por Mês</h3>
          <span class="chart-badge">Crescimento</span>
        </div>
        <div class="chart-container">
          <Bar v-if="chartData.labels" :data="chartData" :options="chartOptions" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js'
import { supabase } from '../lib/supabase'

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)

const loading = ref(true)
const error = ref('')
const overview = ref({
  totalUsers: 0,
  premiumActive: 0,
  trialsActive: 0,
  churnThisMonth: 0
})

const chartData = ref({})
const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false
    },
    tooltip: {
      backgroundColor: 'rgba(17, 24, 39, 0.9)',
      padding: 12,
      titleFont: { size: 14, family: "'Inter', sans-serif" },
      bodyFont: { size: 14, family: "'Inter', sans-serif" },
      cornerRadius: 8,
      displayColors: false
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: {
        color: 'rgba(243, 244, 246, 1)',
        drawBorder: false,
      },
      ticks: {
        font: { family: "'Inter', sans-serif" },
        color: '#6B7280'
      }
    },
    x: {
      grid: {
        display: false,
        drawBorder: false,
      },
      ticks: {
        font: { family: "'Inter', sans-serif" },
        color: '#6B7280'
      }
    }
  }
}

const fetchData = async () => {
  loading.value = true
  try {
    const [overviewRes, signupsRes] = await Promise.all([
      supabase.rpc('overview_metrics'),
      supabase.rpc('signups_per_month')
    ])
    
    if (overviewRes.error) throw overviewRes.error
    if (signupsRes.error) throw signupsRes.error

    overview.value = overviewRes.data

    const signups = signupsRes.data || {}
    const labels = Object.keys(signups).sort()
    const data = labels.map(label => signups[label])

    // Criando um gradiente linear para as barras não é diretamente possível no setup sem o canvas context,
    // então usaremos uma cor vibrante moderna com borderRadius
    chartData.value = {
      labels,
      datasets: [
        {
          label: 'Novos Cadastros',
          backgroundColor: '#4F46E5', // Indigo 600
          hoverBackgroundColor: '#4338CA', // Indigo 700
          borderRadius: 6,
          barPercentage: 0.6,
          data
        }
      ]
    }
  } catch (err) {
    error.value = 'Erro ao carregar dados do dashboard. Verifique se as RPCs foram criadas no Supabase.'
    console.error(err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

.dashboard-wrapper {
  font-family: 'Inter', sans-serif;
  color: #111827;
  max-width: 1200px;
  margin: 0 auto;
}

.header-section {
  margin-bottom: 2.5rem;
}

.page-title {
  font-size: 2rem;
  font-weight: 700;
  letter-spacing: -0.025em;
  margin-bottom: 0.25rem;
  background: linear-gradient(135deg, #111827 0%, #4B5563 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.subtitle {
  color: #6B7280;
  font-size: 1rem;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2.5rem;
}

.metric-card {
  background: #ffffff;
  padding: 1.5rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03), 0 1px 3px rgba(0,0,0,0.02);
  display: flex;
  align-items: center;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  border: 1px solid rgba(243, 244, 246, 0.8);
}

.metric-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.06), 0 4px 8px rgba(0,0,0,0.04);
}

.card-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  margin-right: 1rem;
}

.card-icon.blue { background: #EEF2FF; color: #4F46E5; }
.card-icon.green { background: #ECFDF5; color: #10B981; }
.card-icon.yellow { background: #FFFBEB; color: #F59E0B; }
.card-icon.red { background: #FEF2F2; color: #EF4444; }

.card-info h3 {
  font-size: 0.875rem;
  font-weight: 500;
  color: #6B7280;
  margin-bottom: 0.25rem;
}

.card-info .value {
  font-size: 1.75rem;
  font-weight: 700;
  color: #111827;
}

.chart-section {
  background: #ffffff;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(243, 244, 246, 0.8);
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.chart-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
}

.chart-badge {
  background: #EEF2FF;
  color: #4F46E5;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.chart-container {
  height: 350px;
  position: relative;
}

.loading-state, .error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  text-align: center;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #EEF2FF;
  border-top-color: #4F46E5;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

.error-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.error-state p {
  color: #EF4444;
  font-weight: 500;
}

.fade-in {
  animation: fadeIn 0.5s ease-out forwards;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
