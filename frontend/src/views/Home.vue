<template>
  <div>
    <!-- Top Menu Header -->
    <div class="top-menu-header">
      <div class="menu-container">
        <div class="menu-title">
          <div class="menu-icon">🏠</div>
          <h1 class="menu-text">Dashboard Vessels Certification</h1>
          <h1 class="menu-text-mobile">Dashboard BKI</h1>
        </div>
        <div class="menu-actions">
          <div class="quick-stats">
            <div class="quick-stat">
              <span class="quick-stat-icon">🚢</span>
              <span class="quick-stat-text">{{ statistics.totalVessels }} Kapal</span>
            </div>
            <div class="quick-stat">
              <span class="quick-stat-icon">📜</span>
              <span class="quick-stat-text">{{ statistics.activeCertificates }} Sertifikat</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Navigation Menu Items -->
    <div class="navigation-menu">
      <div class="menu-grid">
        <div class="menu-item" @click="$router.push('/vessels')">
          <div class="menu-item-icon">🚢</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Kapal</div>
            <div class="stat-value" v-if="!loading">{{ statistics.totalVessels }}</div>
                <n-skeleton v-else width="60px" height="28px" />
            <div class="authority-box-action">Kelola dan lihat daftar kapal →</div>
          </div>
        </div>

        <div class="menu-item" @click="$router.push('/certificates')">
          <div class="menu-item-icon">📜</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Sertifikat</div>
                <div class="stat-value" v-if="!loading">{{ statistics.activeCertificates }}</div>
                <n-skeleton v-else width="60px" height="28px" />  
            <div class="authority-box-action">Lihat dan verifikasi sertifikat →</div>
          </div>
        </div>

        <div v-if="userStore.isAuthority() || userStore.isShipOwner()" class="menu-item" @click="$router.push('/surveys')">
          <div class="menu-item-icon">🔍</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Survey</div>
                <div class="stat-value" v-if="!loading">{{ statistics.activeSurveys }}</div>
                <n-skeleton v-else width="60px" height="28px" />

            <div class="authority-box-action">Jadwal dan hasil survey →</div>
          </div>
        </div>

        <div v-if="userStore.isAuthority() || userStore.isShipOwner()" class="menu-item" @click="$router.push('/findings')">
          <div class="menu-item-icon">⚠️</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Findings</div>
                <div class="stat-value" v-if="!loading">{{ statistics.openFindings }}</div>
                <n-skeleton v-else width="60px" height="28px" />

            <div class="authority-box-action">Temuan dan tindak lanjut →</div>
          </div>
        </div>

        <div v-if="userStore.isAuthority()" class="menu-item" @click="$router.push('/shipowners')">
          <div class="menu-item-icon">👥</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Ship Owners</div>
              <div class="authority-box-value">{{ statistics.totalShipOwners }}</div>

            <div class="authority-box-action">Kelola pemilik kapal →</div>
          </div>
        </div>

        <div v-if="userStore.isAuthority()" class="menu-item" @click="$router.push('/authority')">
          <div class="menu-item-icon">🏛️</div>
          <div class="menu-item-content">
            <div class="menu-item-title">Authority</div>
              <div class="authority-box-value">✓</div>
              <div class="authority-box-action">Pengaturan BKI Authority →</div>

          </div>
        </div>
      </div>
    </div>

    <!-- <n-grid x-gap="12" y-gap="12" cols="1 l:2"> -->
      <div class="authority-panel welcome-card card-gradient welcome-content">
        <div class="welcome-header">
          <div class="welcome-title">Selamat Datang</div>
          <div class="welcome-icon">🚢</div>
        </div>
        <div class="welcome-description">
          Sistem Sertifikasi menggunakan teknologi blockchain 
          untuk memastikan transparansi dan keamanan dalam proses sertifikasi kapal.
        </div>
      </div>

      <!-- <n-grid-item>
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
      </n-grid-item> -->
    <!-- </n-grid> -->

    <!-- User Role Section -->
    <div class="user-role-section authority-panel card-gradient role-card role-content">
      <div class="role-header">
      <div class="role-title">Peran Pengguna</div>
      <div class="role-icon">
        {{ userStore.isAuthority() ? '⚓' : userStore.isShipOwner() ? '👤' : '🌐' }}
      </div>
      </div>
      <div class="role-description-wrapper">
      <div class="role-current">
        Peran Saat Ini: {{ currentRoleText }}
      </div>
      <div class="role-description">
        {{ roleDescription }}
      </div>
      </div>
    </div>

    <!-- <n-divider /> -->

    <!-- Role-specific content -->
    <div v-if="userStore.isAuthority()" class="authority-panel card-gradient">
      <!--div class="authority-header">
        <div class="authority-icon">⚓</div>
        <n-h2 class="authority-title">Panel BKI Authority</n-h2>
      </div>
      <div class="authority-content">
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
      </div-->        
    </div>

    <div v-else-if="userStore.isShipOwner()" class="authority-panel card-gradient shipowner-panel">
      <h2 class="shipowner-title">Panel Ship Owner</h2>
      <div class="shipowner-grid">
      <div class="shipowner-card card-gradient" @click="$router.push('/vessels')">
        <div class="shipowner-label">Kapal Saya</div>
        <div class="shipowner-value">{{ statistics.myVessels }}</div>
      </div>
      <div class="shipowner-card card-gradient" @click="$router.push('/findings')">
        <div class="shipowner-label">Findings Pending</div>
        <div class="shipowner-value">{{ statistics.pendingFindings }}</div>
      </div>
      </div>
    </div>

    <div v-else class="authority-panel card-gradient">
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
import { vesselApi, certificateApi, surveyApi, findingApi, shipOwnerApi } from '@/services/api'
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
  pendingFindings: 0,
  totalShipOwners: 0
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
    
    // Public stats
    const [vessels, certificates, surveys, openFindings, shipOwners] = await Promise.all([
      vesselApi.getAll().catch(() => ({ data: [] })),
      certificateApi.getAll().catch(() => ({ data: [] })),
      surveyApi.getAll().catch(() => ({ data: [] })),
      findingApi.getAllOpen().catch(() => ({ data: [] })),
      shipOwnerApi.getAll().catch(() => ({ data: [] }))
    ]);

    statistics.value.totalVessels = vessels.data?.length || 0;
    statistics.value.activeCertificates = certificates.data?.filter(cert => cert.Record?.status === 'active').length || 0;
    statistics.value.activeSurveys = surveys.data?.filter(survey => survey.Record?.status === 'in-progress').length || 0;
    statistics.value.openFindings = openFindings.data?.length || 0;
    statistics.value.issuedCertificates = statistics.value.activeCertificates;
    statistics.value.totalShipOwners = shipOwners.data?.length || 0;

    // Role-specific stats
    if (userStore.isShipOwner()) {
      const [myVessels, myOpenFindings] = await Promise.all([
        vesselApi.getMy().catch(() => ({ data: [] })),
        findingApi.getMyOpen().catch(() => ({ data: [] }))
      ]);
      statistics.value.myVessels = myVessels.data?.length || 0;
      statistics.value.pendingFindings = myOpenFindings.data?.length || 0;
    }

  } catch (error) {
    console.error('Failed to load statistics:', error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  loadStatistics()
})
</script>

<style scoped>
@import '../styles/responsive-gradients.css';

/* Top Menu Header Styles */
.top-menu-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 1rem;
  margin-bottom: 2rem;
  box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
  position: relative;
  overflow: hidden;
}

.top-menu-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
}

.menu-container {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem 2rem;
  color: white;
}

.menu-title {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.menu-icon {
  font-size: 2.5rem;
  animation: float 3s ease-in-out infinite;
}

.menu-text {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0;
  color: #ffffff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5), 0 0 20px rgba(255, 255, 255, 0.3);
  display: block;
  filter: brightness(1.2);
}

.menu-text-mobile {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
  color: #ffffff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5), 0 0 20px rgba(255, 255, 255, 0.3);
  display: none;
  filter: brightness(1.2);
}

.menu-actions {
  display: flex;
  align-items: center;
}

.quick-stats {
  display: flex;
  gap: 1.5rem;
  color: #ffffff;
  filter: brightness(1.1);
}

.quick-stat {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: rgba(255, 255, 255, 0.15);
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  color: #ffffff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
  filter: brightness(1.1);
}

.quick-stat:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-2px);
  filter: brightness(1.2);
}

.quick-stat-icon {
  font-size: 1.25rem;
  color: #ffffff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
  filter: brightness(1.15);
}

.quick-stat-text {
  font-size: 0.875rem;
  font-weight: 600;
  white-space: nowrap;
  color: #ffffff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5), 0 0 15px rgba(255, 255, 255, 0.2);
  filter: brightness(1.2);
}

/* Responsive design for top menu */
@media (max-width: 1024px) {
  .menu-container {
    padding: 1.25rem 1.5rem;
  }
  
  .menu-text {
    font-size: 1.5rem;
  }
  
  .quick-stats {
    gap: 1rem;
  }
  
  .quick-stat {
    padding: 0.375rem 0.75rem;
  }
  
  .quick-stat-text {
    font-size: 0.75rem;
  }
}

@media (max-width: 768px) {
  .menu-container {
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
  }
  
  .menu-text {
    display: none;
  }
  
  .menu-text-mobile {
    display: block;
  }
  
  .menu-icon {
    font-size: 2rem;
  }
  
  .quick-stats {
    gap: 0.75rem;
  }
  
  .quick-stat {
    padding: 0.375rem 0.75rem;
  }
  
  .quick-stat-text {
    font-size: 0.75rem;
  }
}

@media (max-width: 480px) {
  .menu-container {
    padding: 0.75rem;
  }
  
  .menu-title {
    gap: 0.75rem;
  }
  
  .menu-text-mobile {
    font-size: 1rem;
  }
  
  .menu-icon {
    font-size: 1.75rem;
  }
  
  .quick-stats {
    flex-direction: column;
    gap: 0.5rem;
    width: 100%;
  }
  
  .quick-stat {
    justify-content: center;
    padding: 0.5rem;
  }
}

/* Float animation for menu icon */
@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-8px); }
}

/* Shimmer animation */
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

/* Navigation Menu Styles */
.navigation-menu {
  margin-bottom: 2rem;
}

.menu-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
}

.menu-item {
  background: rgba(255, 255, 255, 0.9);
  border-radius: 0.75rem;
  padding: 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  position: relative;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.menu-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
  background: rgba(255, 255, 255, 0.95);
}

.menu-item::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  transition: width 0.3s ease;
}

.menu-item:hover::before {
  width: 8px;
}

.menu-item-icon {
  font-size: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 64px;
  height: 64px;
  border-radius: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(124, 58, 237, 0.4);
  flex-shrink: 0;
  animation: float 3s ease-in-out infinite;
  animation-delay: calc(var(--index, 0) * 0.2s);
}

.menu-item-content {
  flex: 1;
  min-width: 0;
}

.menu-item-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 0.25rem;
}

.menu-item-description {
  font-size: 0.875rem;
  color: #64748b;
  line-height: 1.4;
}

/* Responsive design for navigation menu */
@media (max-width: 768px) {
  .menu-grid {
    grid-template-columns: 1fr;
  }
  
  .menu-item {
    padding: 1rem;
  }
  
  .menu-item-icon {
    width: 56px;
    height: 56px;
    font-size: 2rem;
  }
  
  .menu-item-title {
    font-size: 1.125rem;
  }
  
  .menu-item-description {
    font-size: 0.8rem;
  }
}

@media (max-width: 480px) {
  .menu-item {
    flex-direction: column;
    text-align: center;
    gap: 0.75rem;
  }
  
  .menu-item-content {
    width: 100%;
  }
}

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

/* Welcome Card Styles */
.welcome-content {
  padding: 1.5rem;
  border-radius: 1rem;
  margin-bottom: 1.5rem;
}

.welcome-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.welcome-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e293b;
}

.welcome-icon {
  font-size: 1.5rem;
  color: #1890ff;
}

.welcome-description {
  color: #333;
  font-size: 1rem;
  line-height: 1.6;
}

/* Role Card Styles */
.role-content {
  padding: 1.5rem;
  border-radius: 1rem;
  margin-bottom: 1.5rem;
}

.role-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.role-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e293b;
}

.role-icon {
  font-size: 1.5rem;
}

.role-description-wrapper {
  color: #333;
  font-size: 1rem;
}

.role-current {
  font-weight: bold;
  margin-bottom: 0.5rem;
  color: #1e293b;
}

.role-description {
  color: #64748b;
  line-height: 1.6;
}

/* Ship Owner Panel Styles */
.shipowner-panel {
  padding: 1.5rem;
  border-radius: 1rem;
  margin-bottom: 1.5rem;
}

.shipowner-title {
  font-size: 1.5rem;
  font-weight: 700;
  margin-bottom: 1rem;
  color: #1e293b;
}

.shipowner-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.shipowner-card {
  padding: 1.5rem;
  cursor: pointer;
  border-radius: 1rem;
  transition: all 0.3s ease;
}

.shipowner-card:hover {
  transform: translateY(-2px);
}

.shipowner-label {
  font-size: 1rem;
  color: #64748b;
  margin-bottom: 0.5rem;
}

.shipowner-value {
  font-size: 2rem;
  font-weight: 700;
  color: #1890ff;
}

/* Dark Mode Styles for New Components */
[data-theme="dark"] .welcome-title,
[data-theme="dark"] .role-title,
[data-theme="dark"] .shipowner-title,
[data-theme="dark"] .role-current {
  color: #f1f5f9 !important;
}

[data-theme="dark"] .welcome-description,
[data-theme="dark"] .role-description-wrapper {
  color: #e2e8f0 !important;
}

[data-theme="dark"] .welcome-icon {
  color: #c084fc !important;
}

[data-theme="dark"] .role-description,
[data-theme="dark"] .shipowner-label {
  color: #94a3b8 !important;
}

[data-theme="dark"] .shipowner-value {
  color: #c084fc !important;
}

/* Responsive Design */
@media (max-width: 768px) {
  .shipowner-grid {
    grid-template-columns: 1fr;
  }
  
  .welcome-content,
  .role-content,
  .shipowner-panel {
    padding: 1rem;
  }
  
  .welcome-title,
  .role-title {
    font-size: 1.125rem;
  }
  
  .shipowner-title {
    font-size: 1.25rem;
  }
  
  .shipowner-value {
    font-size: 1.75rem;
  }
}

@media (max-width: 480px) {
  .welcome-header,
  .role-header {
    flex-direction: column;
    text-align: center;
    gap: 0.5rem;
  }
  
  .welcome-description,
  .role-description-wrapper {
    text-align: center;
  }
  
  .shipowner-card {
    padding: 1rem;
    text-align: center;
  }
}

/* Dark Mode Support for Home.vue */

/* Top Menu Header Dark Mode */
[data-theme="dark"] .top-menu-header {
  background: linear-gradient(135deg, #4c1d95 0%, #5b21b6 50%, #6d28d9 100%) !important;
  box-shadow: 0 8px 32px rgba(124, 58, 237, 0.4) !important;
}

[data-theme="dark"] .top-menu-header .menu-text,
[data-theme="dark"] .top-menu-header .menu-text-mobile {
  color: #f1f5f9 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.7), 0 0 20px rgba(139, 92, 246, 0.4) !important;
}

[data-theme="dark"] .top-menu-header .quick-stat {
  background: rgba(255, 255, 255, 0.08) !important;
  color: #f1f5f9 !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

[data-theme="dark"] .top-menu-header .quick-stat:hover {
  background: rgba(255, 255, 255, 0.15) !important;
}

[data-theme="dark"] .top-menu-header .quick-stat-text,
[data-theme="dark"] .top-menu-header .quick-stat-icon {
  color: #f1f5f9 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.7) !important;
}

/* Navigation Menu Dark Mode */
[data-theme="dark"] .menu-item {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

[data-theme="dark"] .menu-item:hover {
  background: rgba(45, 55, 72, 0.9) !important;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.4) !important;
}

[data-theme="dark"] .menu-item::before {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
}

[data-theme="dark"] .menu-item-icon {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  box-shadow: 0 4px 12px rgba(124, 58, 237, 0.4) !important;
}

[data-theme="dark"] .menu-item-title {
  color: #f1f5f9 !important;
}

[data-theme="dark"] .authority-box-action {
  color: #e2e8f0 !important;
}

/* Welcome Card Dark Mode */
[data-theme="dark"] .welcome-card {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .welcome-card:hover {
  box-shadow: 0 8px 25px rgba(124, 58, 237, 0.25) !important;
}

/* Role Card Dark Mode */
[data-theme="dark"] .role-card {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .role-card:hover {
  box-shadow: 0 8px 25px rgba(124, 58, 237, 0.25) !important;
}

/* Card Gradient Dark Mode */
[data-theme="dark"] .card-gradient {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .card-gradient:hover {
  box-shadow: 0 8px 25px rgba(124, 58, 237, 0.25) !important;
}

/* Authority Panel Dark Mode */
[data-theme="dark"] .authority-panel {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .authority-panel::before {
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.03) 50%, transparent 70%) !important;
}

/* Statistics Panel Dark Mode */
[data-theme="dark"] .statistics-panel {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .statistics-panel::before {
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.03) 50%, transparent 70%) !important;
}

[data-theme="dark"] .statistics-title {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

[data-theme="dark"] .stat-icon {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

/* Stat Box Dark Mode */
[data-theme="dark"] .stat-box {
  background: rgba(55, 65, 81, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

[data-theme="dark"] .stat-box:hover {
  background: rgba(55, 65, 81, 0.9) !important;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4) !important;
}

[data-theme="dark"] .stat-box-icon {
  background: rgba(75, 85, 99, 0.8) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .stat-label {
  color: #94a3b8 !important;
}

[data-theme="dark"] .stat-value {
  color: #f1f5f9 !important;
}

/* Authority Box Dark Mode */
[data-theme="dark"] .authority-box {
  background: rgba(55, 65, 81, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

[data-theme="dark"] .authority-box:hover {
  background: rgba(55, 65, 81, 0.9) !important;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.4) !important;
}

[data-theme="dark"] .authority-box-icon {
  background: rgba(75, 85, 99, 0.8) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] .authority-box-label {
  color: #94a3b8 !important;
}

[data-theme="dark"] .authority-box-value {
  color: #f1f5f9 !important;
}

[data-theme="dark"] .authority-box-action {
  color: #c084fc !important;
}

[data-theme="dark"] .authority-box:hover .authority-box-action {
  color: #d8b4fe !important;
}

/* Authority Title Dark Mode */
[data-theme="dark"] .authority-title {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

[data-theme="dark"] .authority-icon {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

/* Ship Owner Cards Dark Mode */
[data-theme="dark"] .shipowner-card {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.15) !important;
  color: #e2e8f0 !important;
}

/* Naive UI Components Dark Mode Overrides */
[data-theme="dark"] :deep(.n-card) {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-card .n-card-header) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-text) {
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-h2),
[data-theme="dark"] :deep(.n-h3) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-steps .n-step .n-step-indicator .n-step-indicator__index) {
  background: rgba(124, 58, 237, 0.8) !important;
  color: white !important;
}

[data-theme="dark"] :deep(.n-steps .n-step .n-step-content .n-step-content-header) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-steps .n-step .n-step-content .n-step-content-description) {
  color: #94a3b8 !important;
}

/* Inline Style Overrides for Dark Mode */
[data-theme="dark"] div[style*="background: #fff"] {
  background: rgba(45, 55, 72, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] div[style*="color: #333"] {
  color: #e2e8f0 !important;
}

[data-theme="dark"] div[style*="color: #64748b"] {
  color: #94a3b8 !important;
}

[data-theme="dark"] div[style*="color: #1890ff"] {
  color: #c084fc !important;
}

/* Responsive Dark Mode Adjustments */
@media (max-width: 768px) {
  [data-theme="dark"] .menu-item {
    background: rgba(45, 55, 72, 0.9) !important;
  }
  
  [data-theme="dark"] .top-menu-header {
    box-shadow: 0 4px 20px rgba(124, 58, 237, 0.3) !important;
  }
}

@media (max-width: 480px) {
  [data-theme="dark"] .authority-box,
  [data-theme="dark"] .stat-box {
    background: rgba(45, 55, 72, 0.85) !important;
  }
}

/* Card Gradient Base Styles */
.card-gradient {
  background: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.card-gradient::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
  pointer-events: none;
}

.card-gradient:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}
</style>