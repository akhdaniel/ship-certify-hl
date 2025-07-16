<template>
  <div>
    <n-grid x-gap="12" y-gap="12" cols="1 m:2 l:3">
      <n-grid-item>
        <n-card title="Selamat Datang" embedded>
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
        <n-card title="Statistik" embedded>
          <n-statistic 
            label="Total Kapal Terdaftar" 
            :value="statistics.totalVessels"
            :loading="loading"
          />
          <n-divider />
          <n-statistic 
            label="Sertifikat Aktif" 
            :value="statistics.activeCertificates"
            :loading="loading"
          />
        </n-card>
      </n-grid-item>

      <n-grid-item>
        <n-card title="Peran Pengguna" embedded>
          <n-space vertical>
            <n-text strong>Peran Saat Ini: {{ currentRoleText }}</n-text>
            <n-text depth="3">{{ roleDescription }}</n-text>
          </n-space>
        </n-card>
      </n-grid-item>
    </n-grid>

    <n-divider />

    <!-- Role-specific content -->
    <div v-if="userStore.isAuthority()">
      <n-h2>Panel BKI Authority</n-h2>
      <n-grid x-gap="12" y-gap="12" cols="1 m:2 l:4">
        <n-grid-item>
          <n-card hoverable @click="$router.push('/vessels')">
            <n-statistic label="Kapal Terdaftar" :value="statistics.totalVessels" />
          </n-card>
        </n-grid-item>
        <n-grid-item>
          <n-card hoverable @click="$router.push('/surveys')">
            <n-statistic label="Survey Aktif" :value="statistics.activeSurveys" />
          </n-card>
        </n-grid-item>
        <n-grid-item>
          <n-card hoverable @click="$router.push('/findings')">
            <n-statistic label="Findings Terbuka" :value="statistics.openFindings" />
          </n-card>
        </n-grid-item>
        <n-grid-item>
          <n-card hoverable @click="$router.push('/certificates')">
            <n-statistic label="Sertifikat Dikeluarkan" :value="statistics.issuedCertificates" />
          </n-card>
        </n-grid-item>
      </n-grid>
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