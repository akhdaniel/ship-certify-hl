<template>
  <div>
    <n-grid x-gap="12" y-gap="12" cols="1 l:2">
      <n-grid-item>
        <n-card title="Selamat Datang" embedded class="welcome-card">
          <template #header-extra>
            <n-icon size="24" color="#1890ff">
              🚢
            </n-icon>
          </template>
          <n-text>
            Sistem Sertifikasi Kapal Biro Klasifikasi Indonesia (BKI) menggunakan teknologi blockchain 
            untuk memastikan transparansi dan keamanan dalam proses sertifikasi kapal.
          </n-text>
        </n-card>
      </n-grid-item>

      <n-grid-item>
        <div class="statistics-panel card-gradient">
          <div class="statistics-header">
            <div class="stat-icon">📊</div>
            <n-h3 class="statistics-title">Statistik Sistem</n-h3>
          </div>
          
          <div class="statistics-grid">
            <div class="stat-box vessels-stat">
              <div class="stat-box-icon">🚢</div>
              <div class="stat-box-content">
                <div class="stat-label">Total Kapal</div>
                <div class="stat-value" v-if="!loading">{{ statistics.totalVessels }}</div>
                <n-skeleton v-else width="60px" height="28px" />
              </div>
            </div>

            <div class="stat-box certificates-stat">
              <div class="stat-box-icon">📜</div>
              <div class="stat-box-content">
                <div class="stat-label">Sertifikat Aktif</div>
                <div class="stat-value" v-if="!loading">{{ statistics.activeCertificates }}</div>
                <n-skeleton v-else width="60px" height="28px" />
              </div>
            </div>

            <div class="stat-box surveys-stat">
              <div class="stat-box-icon">🔍</div>
              <div class="stat-box-content">
                <div class="stat-label">Survey Aktif</div>
                <div class="stat-value" v-if="!loading">{{ statistics.activeSurveys }}</div>
                <n-skeleton v-else width="60px" height="28px" />
              </div>
            </div>

            <div class="stat-box findings-stat">
              <div class="stat-box-icon">⚠️</div>
              <div class="stat-box-content">
                <div class="stat-label">Findings Terbuka</div>
                <div class="stat-value" v-if="!loading">{{ statistics.openFindings }}</div>
                <n-skeleton v-else width="60px" height="28px" />
              </div>
            </div>
          </div>
        </div>
      </n-grid-item>
    </n-grid>

    <!-- User Role Section -->
    <div class="user-role-section">
      <n-card title="Peran Pengguna" embedded class="role-card">
        <template #header-extra>
          <div class="role-icon">
            {{ userStore.isAuthority() ? '⚓' : userStore.isShipOwner() ? '👤' : '🌐' }}
          </div>
        </template>
        <n-space vertical>
          <n-text strong>Peran Saat Ini: {{ currentRoleText }}</n-text>
          <n-text depth="3">{{ roleDescription }}</n-text>
        </n-space>
      </n-card>
    </div>

    <n-divider />

    <!-- Role-specific content -->
    <div v-if="userStore.isAuthority()" class="authority-panel card-gradient">
      <div class="authority-header">
        <div class="authority-icon">⚓</div>
        <n-h2 class="authority-title">Panel BKI Authority</n-h2>
      </div>
      
      <div class="authority-grid">
        <div class="authority-box vessels-box" @click="$router.push('/vessels')">
          <div class="authority-box-icon">🚢</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Kapal Terdaftar</div>
            <div class="authority-box-value">{{ statistics.totalVessels }}</div>
            <div class="authority-box-action">Kelola Kapal →</div>
          </div>
        </div>

        <div class="authority-box surveys-box" @click="$router.push('/surveys')">
          <div class="authority-box-icon">🔍</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Survey Aktif</div>
            <div class="authority-box-value">{{ statistics.activeSurveys }}</div>
            <div class="authority-box-action">Kelola Survey →</div>
          </div>
        </div>

        <div class="authority-box findings-box" @click="$router.push('/findings')">
          <div class="authority-box-icon">⚠️</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Findings Terbuka</div>
            <div class="authority-box-value">{{ statistics.openFindings }}</div>
            <div class="authority-box-action">Kelola Findings →</div>
          </div>
        </div>

        <div class="authority-box certificates-box" @click="$router.push('/certificates')">
          <div class="authority-box-icon">📜</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Sertifikat Dikeluarkan</div>
            <div class="authority-box-value">{{ statistics.issuedCertificates }}</div>
            <div class="authority-box-action">Kelola Sertifikat →</div>
          </div>
        </div>

        <div class="authority-box shipowners-box" @click="$router.push('/shipowners')">
          <div class="authority-box-icon">👥</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Ship Owners</div>
            <div class="authority-box-value">{{ Math.floor(statistics.totalVessels * 0.6) }}</div>
            <div class="authority-box-action">Kelola Ship Owners →</div>
          </div>
        </div>

        <div class="authority-box authority-admin-box" @click="$router.push('/authority')">
          <div class="authority-box-icon">🏛️</div>
          <div class="authority-box-content">
            <div class="authority-box-label">Authority Admin</div>
            <div class="authority-box-value">✓</div>
            <div class="authority-box-action">Pengaturan Admin →</div>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="userStore.isShipOwner()">
      <n-h2>Panel Ship Owner</n-h2>
      <n-grid x-gap="12" y-gap="12" cols="1 m:2">
        <n-grid-item>
          <n-card hoverable @click="$router.push('/vessels')">
            <n-statistic label="Kapal Saya" :value="statistics.myVessels" />
          </n-card>
        </n-grid-item>
        <n-grid-item>
          <n-card hoverable @click="$router.push('/findings')">
            <n-statistic label="Findings Pending" :value="statistics.pendingFindings" />
          </n-card>
        </n-grid-item>
      </n-grid>
    </div>

    <div v-else>
      <n-h2>Informasi Publik</n-h2>
      <n-space vertical size="large">
        <n-card title="Tentang BKI">
          <n-text>
            Biro Klasifikasi Indonesia (BKI) adalah lembaga yang bertanggung jawab dalam melakukan 
            survei dan sertifikasi terhadap kapal-kapal yang beroperasi di wilayah yurisdiksi 
            Indonesia maupun internasional.
          </n-text>
        </n-card>
        
        <n-card title="Proses Sertifikasi">
          <n-steps :current="4" vertical>
            <n-step title="Pendaftaran Kapal" description="Kapal didaftarkan oleh BKI Authority" />
            <n-step title="Penjadwalan Survey" description="Survey dijadwalkan sesuai jenis dan periode" />
            <n-step title="Pelaksanaan Survey" description="Survey dilakukan oleh surveyor BKI" />
            <n-step title="Penyelesaian Findings" description="Ship owner menyelesaikan temuan survey" />
            <n-step title="Penerbitan Sertifikat" description="Sertifikat dikeluarkan setelah semua findings selesai" />
          </n-steps>
        </n-card>
      </n-space>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import { vesselApi, certificateApi, surveyApi } from '@/services/api'
// import { Ship as ShipIcon } from '@vicons/ionicons5'

const userStore = useUserStore()
const loading = ref(true)

const statistics = ref({
  totalVessels: 0,
  activeCertificates: 0,
  activeSurveys: 0,
  openFindings: 0,
  issuedCertificates: 0,
  myVessels: 0,
  pendingFindings: 0
})

const currentRoleText = computed(() => {
  switch (userStore.role) {
    case 'authority': return 'BKI Authority'
    case 'shipowner': return 'Ship Owner'
    case 'public': return 'Public'
    default: return 'Unknown'
  }
})

const roleDescription = computed(() => {
  switch (userStore.role) {
    case 'authority':
      return 'Anda dapat mendaftarkan kapal, menjadwalkan survey, mencatat findings, dan mengeluarkan sertifikat.'
    case 'shipowner':
      return 'Anda dapat melihat findings dan menyelesaikan findings untuk kapal Anda.'
    case 'public':
      return 'Anda dapat melihat informasi publik seperti daftar kapal, sertifikat, dan memverifikasi sertifikat.'
    default:
      return ''
  }
})

const loadStatistics = async () => {
  try {
    loading.value = true
    
    const [vessels, certificates] = await Promise.all([
      vesselApi.getAll().catch(() => ({ data: [] })),
      certificateApi.getAll().catch(() => ({ data: [] }))
    ])

    statistics.value.totalVessels = vessels.data?.length || 0
    statistics.value.activeCertificates = certificates.data?.filter(cert => 
      cert.Record?.status === 'active'
    ).length || 0
    
    // Mock some additional statistics
    statistics.value.activeSurveys = Math.floor(statistics.value.totalVessels * 0.3)
    statistics.value.openFindings = Math.floor(statistics.value.totalVessels * 0.15)
    statistics.value.issuedCertificates = statistics.value.activeCertificates
    statistics.value.myVessels = Math.floor(statistics.value.totalVessels * 0.1)
    statistics.value.pendingFindings = Math.floor(statistics.value.openFindings * 0.2)

  } catch (error) {
    console.error('Failed to load statistics:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadStatistics()
})
</script>

<style scoped>
@import '../styles/responsive-gradients.css';

/* General Card Styles */
.welcome-card, .role-card {
  transition: all 0.3s ease;
}

.welcome-card:hover, .role-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.user-role-section {
  margin: 2rem 0;
}

.role-icon {
  font-size: 1.5rem;
}

/* Statistics Panel Styles */
.statistics-panel {
  padding: 1.5rem;
  border-radius: 1rem;
  position: relative;
  overflow: hidden;
  min-height: 100%;
}

.statistics-panel::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
}

.statistics-header {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.stat-icon {
  font-size: 2rem;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: float 3s ease-in-out infinite;
}

.statistics-title {
  margin: 0 !important;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-size: 1.5rem;
  font-weight: 700;
}

.statistics-grid {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.stat-box {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 0.75rem;
  padding: 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: all 0.3s ease;
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  position: relative;
  overflow: hidden;
}

.stat-box:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
}

.stat-box::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  transition: width 0.3s ease;
}

.stat-box:hover::before {
  width: 8px;
}

.stat-box-icon {
  font-size: 1.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 0.5rem;
  background: rgba(255, 255, 255, 0.8);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.stat-box-content {
  flex: 1;
}

.stat-label {
  font-size: 0.875rem;
  color: #64748b;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.stat-value {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1e293b;
}

/* Individual stat box colors */
.vessels-stat::before {
  background: var(--gradient-ocean);
}

.vessels-stat .stat-box-icon {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 50%);
  color: white;
}

.certificates-stat::before {
  background: var(--gradient-secondary);
}

.certificates-stat .stat-box-icon {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 50%);
  color: white;
}

.surveys-stat::before {
  background: var(--gradient-success);
}

.surveys-stat .stat-box-icon {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 50%);
  color: white;
}

.findings-stat::before {
  background: var(--gradient-warning);
}

.findings-stat .stat-box-icon {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 50%);
  color: white;
}

/* Responsive Design for Statistics */
@media (max-width: 768px) {
  .statistics-grid {
    grid-template-columns: 1fr;
  }
  
  .statistics-panel {
    padding: 1rem;
  }
  
  .statistics-header {
    margin-bottom: 1rem;
  }
  
  .stat-box {
    padding: 1rem;
  }
  
  .stat-box-icon {
    width: 40px;
    height: 40px;
    font-size: 1.5rem;
  }
  
  .stat-value {
    font-size: 1.5rem;
  }
  
  .statistics-title {
    font-size: 1.25rem;
  }
  
  .stat-icon {
    font-size: 1.5rem;
  }
}

@media (max-width: 480px) {
  .stat-box {
    flex-direction: column;
    text-align: center;
    gap: 0.75rem;
  }
  
  .stat-box-content {
    width: 100%;
  }
}

/* Authority Panel Styles */
.authority-panel {
  margin: 2rem 0;
}

.panel-header {
  margin-bottom: 1.5rem;
  border-radius: 1rem;
  position: relative;
  overflow: hidden;
}

.panel-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
}

.panel-title {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
}

.panel-icon {
  font-size: 2.5rem;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: float 3s ease-in-out infinite;
}

.authority-title {
  margin: 0 !important;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-size: 2rem;
  font-weight: 700;
}

/* Authority Buttons Row */
.authority-buttons-row {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
  padding: 0 1rem;
}

.authority-btn {
  flex: 1;
  min-width: 200px;
  max-width: 280px;
  height: 120px !important;
  border-radius: 1rem !important;
  border: none !important;
  padding: 1.5rem !important;
  cursor: pointer !important;
  transition: all 0.3s ease !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: center !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1) !important;
  position: relative;
  overflow: hidden;
}

.authority-btn:hover {
  transform: translateY(-4px) !important;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15) !important;
}

.authority-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 1;
}

.authority-btn:hover::before {
  opacity: 0.1;
}

/* Individual button gradients */
.vessels-btn {
  background: var(--gradient-ocean) !important;
  color: white !important;
}

.vessels-btn::before {
  background: linear-gradient(45deg, rgba(255, 255, 255, 0.2), transparent);
}

.surveys-btn {
  background: var(--gradient-success) !important;
  color: white !important;
}

.surveys-btn::before {
  background: linear-gradient(45deg, rgba(255, 255, 255, 0.2), transparent);
}

.findings-btn {
  background: var(--gradient-warning) !important;
  color: white !important;
}

.findings-btn::before {
  background: linear-gradient(45deg, rgba(255, 255, 255, 0.2), transparent);
}

.certificates-btn {
  background: var(--gradient-secondary) !important;
  color: white !important;
}

.certificates-btn::before {
  background: linear-gradient(45deg, rgba(255, 255, 255, 0.2), transparent);
}

.btn-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
  position: relative;
  z-index: 2;
}

.btn-content {
  text-align: center;
  position: relative;
  z-index: 2;
}

.btn-label {
  font-size: 0.875rem;
  font-weight: 500;
  opacity: 0.9;
  margin-bottom: 0.25rem;
}

.btn-value {
  font-size: 1.5rem;
  font-weight: 700;
}

/* Responsive Design */
@media (max-width: 1024px) {
  .authority-buttons-row {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
  
  .authority-btn {
    min-width: unset;
    max-width: unset;
  }
}

@media (max-width: 768px) {
  .authority-buttons-row {
    grid-template-columns: 1fr;
  }
  
  .authority-btn {
    height: 100px !important;
    padding: 1rem !important;
  }
  
  .btn-icon {
    font-size: 1.5rem;
  }
  
  .btn-value {
    font-size: 1.25rem;
  }
  
  .panel-title {
    flex-direction: column;
    text-align: center;
    padding: 1rem;
  }
  
  .authority-title {
    font-size: 1.5rem;
  }
  
  .panel-icon {
    font-size: 2rem;
  }
}

@media (max-width: 480px) {
  .authority-buttons-row {
    padding: 0 0.5rem;
  }
  
  .authority-btn {
    height: 90px !important;
  }
  
  .btn-label {
    font-size: 0.75rem;
  }
  
  .btn-value {
    font-size: 1.125rem;
  }
}

/* Animation keyframes */
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-8px); }
}

/* Card hover effects */
:deep(.n-card) {
  transition: all 0.3s ease;
}

:deep(.n-card:hover) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}
</style>