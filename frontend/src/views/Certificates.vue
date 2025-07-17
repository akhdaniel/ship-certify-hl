<template>
  <div>


    <div class="header-content-section flex-responsive">
      <div class="header-title">
        <div class="title-icon">📜 </div>
        <n-h2 class="page-title">Daftar Sertifikat</n-h2>
      </div>
      <n-space>
        <n-input
          v-model:value="verifyId"
          placeholder="Masukkan ID sertifikat untuk verifikasi"
          style="width: 300px"
        />
        <n-button type="primary" @click="verifyCertificate" :loading="verifying">
          Verifikasi Sertifikat
        </n-button>
      </n-space>
    </div>


    <n-space vertical size="large">
      <n-input
        v-model:value="searchQuery"
        placeholder="Cari sertifikat berdasarkan ID, kapal, atau jenis..."
        clearable
      >
        <template #prefix>
          <n-icon :component="SearchIcon" />
        </template>
      </n-input>

      <n-data-table
        :columns="columns"
        :data="filteredCertificates"
        :loading="loading"
        :pagination="pagination"
      />
    </n-space>

    <!-- Certificate Details Modal -->
    <n-modal v-model:show="showDetailsModal" preset="dialog" title="Detail Sertifikat" style="width: 600px">
      <div v-if="selectedCertificate">
        <n-descriptions :column="2" bordered>
          <n-descriptions-item label="ID Sertifikat">
            {{ selectedCertificate.id }}
          </n-descriptions-item>
          <n-descriptions-item label="ID Kapal">
            {{ selectedCertificate.vesselId }}
          </n-descriptions-item>
          <n-descriptions-item label="Jenis Sertifikat">
            <n-tag :type="getCertificateTypeColor(selectedCertificate.certificateType)">
              {{ getCertificateTypeText(selectedCertificate.certificateType) }}
            </n-tag>
          </n-descriptions-item>
          <n-descriptions-item label="Status">
            <n-tag :type="selectedCertificate.status === 'active' ? 'success' : 'error'">
              {{ selectedCertificate.status === 'active' ? 'Aktif' : 'Tidak Aktif' }}
            </n-tag>
          </n-descriptions-item>
          <n-descriptions-item label="Berlaku Dari">
            {{ formatDate(selectedCertificate.validFrom) }}
          </n-descriptions-item>
          <n-descriptions-item label="Berlaku Sampai">
            {{ formatDate(selectedCertificate.validTo) }}
          </n-descriptions-item>
          <n-descriptions-item label="Dikeluarkan Oleh">
            {{ selectedCertificate.issuedBy }}
          </n-descriptions-item>
          <n-descriptions-item label="Tanggal Terbit">
            {{ formatDate(selectedCertificate.issuedAt) }}
          </n-descriptions-item>
          <n-descriptions-item label="Hash" span="2">
            <n-text code>{{ selectedCertificate.hash }}</n-text>
          </n-descriptions-item>
        </n-descriptions>
      </div>
      
      <template #action>
        <n-button @click="showDetailsModal = false">Tutup</n-button>
      </template>
    </n-modal>

    <!-- Verification Result Modal -->
    <n-modal v-model:show="showVerificationModal" preset="dialog" title="Hasil Verifikasi">
      <div v-if="verificationResult">
        <n-result
          :status="verificationResult.isValid ? 'success' : 'error'"
          :title="verificationResult.isValid ? 'Sertifikat Valid' : 'Sertifikat Tidak Valid'"
        >
          <template #footer>
            <n-space vertical>
              <n-descriptions :column="1" bordered>
                <n-descriptions-item label="ID Sertifikat">
                  {{ verificationResult.certificateId }}
                </n-descriptions-item>
                <n-descriptions-item label="ID Kapal">
                  {{ verificationResult.vesselId }}
                </n-descriptions-item>
                <n-descriptions-item label="Berlaku Sampai">
                  {{ formatDate(verificationResult.validTo) }}
                </n-descriptions-item>
                <n-descriptions-item label="Hash">
                  <n-text code>{{ verificationResult.hash }}</n-text>
                </n-descriptions-item>
              </n-descriptions>
            </n-space>
          </template>
        </n-result>
      </div>
      
      <template #action>
        <n-button @click="showVerificationModal = false">Tutup</n-button>
      </template>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { NButton, NTag, useMessage } from 'naive-ui'
import { useUserStore } from '@/stores/user'
import { certificateApi } from '@/services/api'
import { SearchOutline as SearchIcon } from '@vicons/ionicons5'
import { format, parseISO, isAfter } from 'date-fns'

const userStore = useUserStore()
const message = useMessage()

const loading = ref(true)
const verifying = ref(false)
const searchQuery = ref('')
const verifyId = ref('')
const certificates = ref([])
const showDetailsModal = ref(false)
const showVerificationModal = ref(false)
const selectedCertificate = ref(null)
const verificationResult = ref(null)

const pagination = {
  pageSize: 10
}

const columns = computed(() => [
  {
    title: 'ID Sertifikat',
    key: 'id',
    width: 150,
    render: (row) => {
      return h(
        NButton,
        {
          text: true,
          type: 'primary',
          onClick: () => showDetails(row)
        },
        { default: () => row.id }
      )
    }
  },
  {
    title: 'ID Kapal',
    key: 'vesselId',
    width: 120
  },
  {
    title: 'Jenis Sertifikat',
    key: 'certificateType',
    width: 150,
    render: (row) => {
      return h(
        NTag,
        { type: getCertificateTypeColor(row.certificateType) },
        { default: () => getCertificateTypeText(row.certificateType) }
      )
    }
  },
  {
    title: 'Status',
    key: 'status',
    width: 100,
    render: (row) => {
      const isValid = row.status === 'active' && isAfter(parseISO(row.validTo), new Date())
      return h(
        NTag,
        { type: isValid ? 'success' : 'error' },
        { default: () => isValid ? 'Valid' : 'Expired' }
      )
    }
  },
  {
    title: 'Berlaku Sampai',
    key: 'validTo',
    width: 130,
    render: (row) => formatDate(row.validTo)
  },
  {
    title: 'Tanggal Terbit',
    key: 'issuedAt',
    width: 130,
    render: (row) => formatDate(row.issuedAt)
  },
  {
    title: 'Aksi',
    key: 'actions',
    width: 120,
    render: (row) => {
      return h(
        NButton,
        {
          size: 'small',
          type: 'primary',
          onClick: () => verifyCertificateById(row.id)
        },
        { default: () => 'Verifikasi' }
      )
    }
  }
])

const filteredCertificates = computed(() => {
  if (!searchQuery.value) return certificates.value
  
  const query = searchQuery.value.toLowerCase()
  return certificates.value.filter(cert => 
    cert.id?.toLowerCase().includes(query) ||
    cert.vesselId?.toLowerCase().includes(query) ||
    cert.certificateType?.toLowerCase().includes(query)
  )
})

const getCertificateTypeColor = (type) => {
  const colorMap = {
    'class': 'info',
    'safety': 'warning',
    'load_line': 'success'
  }
  return colorMap[type] || 'default'
}

const getCertificateTypeText = (type) => {
  const textMap = {
    'class': 'Class Certificate',
    'safety': 'Safety Certificate',
    'load_line': 'Load Line Certificate'
  }
  return textMap[type] || type
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  try {
    return format(parseISO(dateString), 'dd/MM/yyyy')
  } catch {
    return dateString
  }
}

const loadCertificates = async () => {
  try {
    loading.value = true
    const response = await certificateApi.getAll()
    certificates.value = response.data?.map(item => ({
      ...item.Record,
      key: item.Key
    })) || []
  } catch (error) {
    message.error('Gagal memuat data sertifikat: ' + error.message)
  } finally {
    loading.value = false
  }
}

const showDetails = (certificate) => {
  selectedCertificate.value = certificate
  showDetailsModal.value = true
}

const verifyCertificate = async () => {
  if (!verifyId.value.trim()) {
    message.warning('Masukkan ID sertifikat yang akan diverifikasi')
    return
  }
  
  await verifyCertificateById(verifyId.value.trim())
}

const verifyCertificateById = async (certificateId) => {
  try {
    verifying.value = true
    const response = await certificateApi.verify(certificateId)
    verificationResult.value = response.data
    showVerificationModal.value = true
    verifyId.value = ''
  } catch (error) {
    message.error('Gagal memverifikasi sertifikat: ' + error.message)
  } finally {
    verifying.value = false
  }
}

onMounted(() => {
  loadCertificates()
})
</script>


<style scoped>
.ship-owners-container {
  padding: 0;
  min-height: 100vh;
}

.page-header {
  margin-bottom: 2rem;
  border-radius: 1rem;
  position: relative;
  overflow: hidden;
}

.page-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.1) 50%, transparent 70%);
  animation: shimmer 3s infinite;
}

.header-content-section {
  position: relative;
  z-index: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
}

.header-title {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.title-icon {
  font-size: 2.5rem;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: float 3s ease-in-out infinite;
}

.page-title {
  margin: 0 !important;
  background: var(--gradient-primary);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-size: 2rem;
  font-weight: 700;
}

.add-button {
  background: var(--gradient-primary) !important;
  border: none !important;
  border-radius: 0.75rem !important;
  padding: 0.75rem 1.5rem !important;
  font-weight: 600 !important;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3) !important;
  transition: all 0.3s ease !important;
}

.add-button:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4) !important;
}

.content-space {
  width: 100%;
}

.search-section {
  padding: 1.5rem;
  border-radius: 1rem;
  margin-bottom: 1rem;
}

.search-input {
  max-width: 500px;
  border-radius: 0.75rem !important;
}

.table-section {
  padding: 1.5rem;
  border-radius: 1rem;
  overflow: hidden;
}

.responsive-table {
  border-radius: 0.75rem !important;
  overflow: hidden !important;
}

/* Responsive Design */
@media (max-width: 768px) {
  .header-content-section {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
    padding: 1rem;
  }
  
  .header-title {
    justify-content: center;
    text-align: center;
  }
  
  .page-title {
    font-size: 1.5rem;
  }
  
  .title-icon {
    font-size: 2rem;
  }
  
  .add-button {
    width: 100%;
    justify-content: center;
  }
  
  .search-section {
    padding: 1rem;
  }
  
  .search-input {
    max-width: 100%;
  }
  
  .table-section {
    padding: 1rem;
  }
}

@media (max-width: 480px) {
  .ship-owners-container {
    padding: 0 0.5rem;
  }
  
  .page-header,
  .search-section,
  .table-section {
    border-radius: 0.5rem;
    margin-left: -0.5rem;
    margin-right: -0.5rem;
  }
  
  .header-content-section {
    padding: 0.75rem;
  }
  
  .page-title {
    font-size: 1.25rem;
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

/* Custom table styles */
:deep(.n-data-table) {
  background: transparent !important;
  border-radius: 0.75rem !important;
}

:deep(.n-data-table-th) {
  background: var(--gradient-primary) !important;
  color: white !important;
  font-weight: 600 !important;
  border: none !important;
}

:deep(.n-data-table-td) {
  border-bottom: 1px solid rgba(102, 126, 234, 0.1) !important;
}

:deep(.n-data-table-tr:hover .n-data-table-td) {
  background: rgba(102, 126, 234, 0.05) !important;
}

/* Custom input styles */
:deep(.n-input) {
  border-radius: 0.75rem !important;
}

:deep(.n-input:focus-within) {
  border-color: #667eea !important;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1) !important;
}

/* Modal styles */
:deep(.n-modal) {
  border-radius: 1rem !important;
  overflow: hidden !important;
}

:deep(.n-card) {
  background: var(--gradient-card) !important;
  border-radius: 1rem !important;
}
</style>