<template>
  <div>


    <div class="header-content-section flex-responsive">
      <div class="header-title">
        <div class="title-icon">🚢 </div>
        <n-h2 class="page-title">Daftar Temuan</n-h2>
      </div>
    </div>

      <div>
        <n-card title="Filter Survey" >
          <n-select
          v-model:value="selectedSurveyId"
          :options="surveyOptions"
          placeholder="Pilih survey untuk melihat temuan"
          clearable
          @update:value="loadFindings"
          />
        </n-card>
      </div>

      <div v-if="selectedSurveyId">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
        <n-h3>Findings untuk Survey: {{ selectedSurveyId }}</n-h3>
        <n-button 
        v-if="userStore.isAuthority()" 
        type="primary" class="btn-gradient-primary add-button"
        @click="showAddModal = true"
        >
        Tambah Temuan
        </n-button>
      </div>

      <n-data-table
        :columns="columns"
        :data="findings"
        :loading="loadingFindings"
        :pagination="pagination"
      />
      </div>

    <!-- Add Finding Modal -->
    <n-modal v-model:show="showAddModal" preset="dialog" title="Tambah Finding">
      <n-form :model="newFinding" :rules="findingRules" ref="formRef">
        <n-form-item label="ID Finding" path="findingId">
          <n-input v-model:value="newFinding.findingId" placeholder="Contoh: FND001" />
        </n-form-item>
        <n-form-item label="Deskripsi" path="description">
          <n-input 
            v-model:value="newFinding.description" 
            type="textarea"
            placeholder="Deskripsi temuan"
            :rows="3"
          />
        </n-form-item>
        <n-form-item label="Tingkat Keparahan" path="severity">
          <n-select 
            v-model:value="newFinding.severity" 
            :options="severityOptions"
            placeholder="Pilih tingkat keparahan"
          />
        </n-form-item>
        <n-form-item label="Lokasi" path="location">
          <n-input v-model:value="newFinding.location" placeholder="Lokasi temuan" />
        </n-form-item>
        <n-form-item label="Persyaratan" path="requirement">
          <n-input v-model:value="newFinding.requirement" placeholder="Persyaratan yang dilanggar" />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showAddModal = false">Batal</n-button>
          <n-button type="primary" @click="handleAddFinding" :loading="submitting">
            Tambah
          </n-button>
        </n-space>
      </template>
    </n-modal>

    <!-- Resolve Finding Modal -->
    <n-modal v-model:show="showResolveModal" preset="dialog" title="Selesaikan Finding">
      <n-form :model="resolutionData" :rules="resolutionRules" ref="resolveFormRef">
        <n-form-item label="Deskripsi Penyelesaian" path="resolutionDescription">
          <n-input 
            v-model:value="resolutionData.resolutionDescription" 
            type="textarea"
            placeholder="Jelaskan bagaimana finding ini diselesaikan"
            :rows="4"
          />
        </n-form-item>
        <n-form-item label="URL Bukti (Opsional)" path="evidenceUrl">
          <n-input 
            v-model:value="resolutionData.evidenceUrl" 
            placeholder="Link ke dokumen atau foto bukti"
          />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showResolveModal = false">Batal</n-button>
          <n-button type="primary" @click="handleResolveFinding" :loading="submitting">
            Selesaikan
          </n-button>
        </n-space>
      </template>
    </n-modal>

    <!-- Verify Finding Modal -->
    <n-modal v-model:show="showVerifyModal" preset="dialog" title="Verifikasi Finding">
      <n-form :model="verificationData" ref="verifyFormRef">
        <n-form-item label="Catatan Verifikasi">
          <n-input 
            v-model:value="verificationData.verificationNotes" 
            type="textarea"
            placeholder="Catatan verifikasi (opsional)"
            :rows="3"
          />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showVerifyModal = false">Batal</n-button>
          <n-button type="primary" @click="handleVerifyFinding" :loading="submitting">
            Verifikasi
          </n-button>
        </n-space>
      </template>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { NButton, NTag, NSpace, useMessage } from 'naive-ui'
import { useUserStore } from '@/stores/user'
import { findingApi, surveyApi } from '@/services/api'
import { format, parseISO } from 'date-fns'

const userStore = useUserStore()
const message = useMessage()

const loadingSurveys = ref(true)
const loadingFindings = ref(false)
const submitting = ref(false)
const showAddModal = ref(false)
const showResolveModal = ref(false)
const showVerifyModal = ref(false)

const surveys = ref([])
const findings = ref([])
const selectedSurveyId = ref('')
const selectedFindingId = ref('')

const formRef = ref(null)
const resolveFormRef = ref(null)
const verifyFormRef = ref(null)

const newFinding = ref({
  findingId: '',
  description: '',
  severity: '',
  location: '',
  requirement: ''
})

const resolutionData = ref({
  resolutionDescription: '',
  evidenceUrl: ''
})

const verificationData = ref({
  verificationNotes: ''
})

const severityOptions = [
  { label: 'Minor', value: 'minor' },
  { label: 'Major', value: 'major' },
  { label: 'Critical', value: 'critical' }
]

const findingRules = {
  findingId: { required: true, message: 'ID Finding harus diisi' },
  description: { required: true, message: 'Deskripsi harus diisi' },
  severity: { required: true, message: 'Tingkat keparahan harus dipilih' },
  location: { required: true, message: 'Lokasi harus diisi' },
  requirement: { required: true, message: 'Persyaratan harus diisi' }
}

const resolutionRules = {
  resolutionDescription: { required: true, message: 'Deskripsi penyelesaian harus diisi' }
}

const pagination = {
  pageSize: 10
}

const columns = computed(() => [
  {
    title: 'ID Finding',
    key: 'id',
    width: 120
  },
  {
    title: 'Deskripsi',
    key: 'description',
    width: 300,
    ellipsis: {
      tooltip: true
    }
  },
  {
    title: 'Tingkat Keparahan',
    key: 'severity',
    width: 120,
    render: (row) => {
      const severityMap = {
        'minor': { type: 'info', text: 'Minor' },
        'major': { type: 'warning', text: 'Major' },
        'critical': { type: 'error', text: 'Critical' }
      }
      const severity = severityMap[row.severity] || { type: 'default', text: row.severity }
      return h(NTag, { type: severity.type }, { default: () => severity.text })
    }
  },
  {
    title: 'Lokasi',
    key: 'location',
    width: 150
  },
  {
    title: 'Status',
    key: 'status',
    width: 120,
    render: (row) => {
      const statusMap = {
        'open': { type: 'error', text: 'Terbuka' },
        'resolved': { type: 'warning', text: 'Diselesaikan' },
        'verified': { type: 'success', text: 'Diverifikasi' }
      }
      const status = statusMap[row.status] || { type: 'default', text: row.status }
      return h(NTag, { type: status.type }, { default: () => status.text })
    }
  },
  {
    title: 'Tanggal Ditambahkan',
    key: 'addedAt',
    width: 130,
    render: (row) => formatDate(row.addedAt)
  },
  {
    title: 'Aksi',
    key: 'actions',
    width: 200,
    render: (row) => {
      const buttons = []
      
      if (row.status === 'open' && (userStore.isShipOwner() || userStore.isAuthority())) {
        buttons.push(
          h(
            NButton,
            {
              size: 'small',
              type: 'warning',
              onClick: () => openResolveModal(row.id),
              style: { marginRight: '8px' }
            },
            { default: () => 'Selesaikan' }
          )
        )
      }
      
      if (row.status === 'resolved' && userStore.isAuthority()) {
        buttons.push(
          h(
            NButton,
            {
              size: 'small',
              type: 'primary',
              onClick: () => openVerifyModal(row.id)
            },
            { default: () => 'Verifikasi' }
          )
        )
      }
      
      return h(NSpace, {}, { default: () => buttons })
    }
  }
])

const surveyOptions = computed(() => 
  surveys.value.map(survey => ({
    label: `${survey.Record.id} - ${survey.Record.vesselId} (${survey.Record.status})`,
    value: survey.Record.id
  }))
)

const formatDate = (dateString) => {
  if (!dateString) return '-'
  try {
    return format(parseISO(dateString), 'dd/MM/yyyy HH:mm')
  } catch {
    return dateString
  }
}

const loadSurveys = async () => {
  try {
    loadingSurveys.value = true
    const response = await surveyApi.getAll()
    surveys.value = response.data || []
  } catch (error) {
    message.error('Gagal memuat data survey: ' + error.message)
  } finally {
    loadingSurveys.value = false
  }
}

const loadFindings = async () => {
  if (!selectedSurveyId.value) {
    findings.value = []
    return
  }
  
  try {
    loadingFindings.value = true
    const response = await findingApi.getBySurvey(selectedSurveyId.value)
    findings.value = response.data || []
  } catch (error) {
    message.error('Gagal memuat data findings: ' + error.message)
    findings.value = []
  } finally {
    loadingFindings.value = false
  }
}

const handleAddFinding = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    console.log('Creating finding:', newFinding.value)
    await findingApi.create(selectedSurveyId.value, newFinding.value)
    
    message.success('Finding berhasil ditambahkan')
    showAddModal.value = false
    resetAddForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loadingFindings.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing findings list...')
    const originalCount = findings.value.length
    await loadFindings()
    
    if (findings.value.length === originalCount) {
      console.log('Record not yet available, retrying in 2 seconds...')
      message.loading('Menunggu data terbaru...', { duration: 0, key: 'refresh' })
      await new Promise(resolve => setTimeout(resolve, 2000))
      await loadFindings()
    }
    
    // Clear loading messages
    message.destroyAll()
    loadingFindings.value = false
    console.log('Findings list refreshed')
  } catch (error) {
    console.error('Error creating finding:', error)
    message.error('Gagal menambahkan finding: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const openResolveModal = (findingId) => {
  selectedFindingId.value = findingId
  showResolveModal.value = true
}

const handleResolveFinding = async () => {
  try {
    await resolveFormRef.value?.validate()
    submitting.value = true
    
    console.log('Resolving finding:', selectedFindingId.value)
    await findingApi.resolve(selectedSurveyId.value, selectedFindingId.value, resolutionData.value)
    
    message.success('Finding berhasil diselesaikan')
    showResolveModal.value = false
    resetResolveForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loadingFindings.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing findings list...')
    await loadFindings()
    
    // Clear loading messages
    message.destroyAll()
    loadingFindings.value = false
    console.log('Findings list refreshed')
  } catch (error) {
    console.error('Error resolving finding:', error)
    message.error('Gagal menyelesaikan finding: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const openVerifyModal = (findingId) => {
  selectedFindingId.value = findingId
  showVerifyModal.value = true
}

const handleVerifyFinding = async () => {
  try {
    submitting.value = true
    
    console.log('Verifying finding:', selectedFindingId.value)
    await findingApi.verify(selectedSurveyId.value, selectedFindingId.value, verificationData.value)
    
    message.success('Finding berhasil diverifikasi')
    showVerifyModal.value = false
    resetVerifyForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loadingFindings.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing findings list...')
    await loadFindings()
    
    // Clear loading messages
    message.destroyAll()
    loadingFindings.value = false
    console.log('Findings list refreshed')
  } catch (error) {
    console.error('Error verifying finding:', error)
    message.error('Gagal memverifikasi finding: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const resetAddForm = () => {
  newFinding.value = {
    findingId: '',
    description: '',
    severity: '',
    location: '',
    requirement: ''
  }
}

const resetResolveForm = () => {
  resolutionData.value = {
    resolutionDescription: '',
    evidenceUrl: ''
  }
}

const resetVerifyForm = () => {
  verificationData.value = {
    verificationNotes: ''
  }
}

onMounted(() => {
  loadSurveys()
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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: float 3s ease-in-out infinite;
}

.page-title {
  margin: 0 !important;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-size: 2rem;
  font-weight: 700;
}

.add-button {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
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

/* Dark Mode Styles moved to end of file for proper precedence */

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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
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
  background: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%) !important;
  border-radius: 1rem !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05) !important;
}

[data-theme="dark"] .n-card,
html[data-theme="dark"] .n-card,
body[data-theme="dark"] .n-card {
  background: linear-gradient(145deg, #232946 0%, #1a1a2e 100%) !important;
  border-radius: 1rem !important;
  border: 1px solid rgba(124, 58, 237, 0.2) !important;
  box-shadow: 0 4px 16px rgba(124, 58, 237, 0.08) !important;
}

/* =================================================================== */
/* COMPREHENSIVE DARK MODE STYLES - HIGHEST SPECIFICITY - DO NOT MOVE */
/* =================================================================== */

/* Header Section Dark Mode */
[data-theme="dark"] .header-content-section,
html[data-theme="dark"] .header-content-section,
body[data-theme="dark"] .header-content-section {
  color: #e2e8f0 !important;
}

[data-theme="dark"] .title-icon,
html[data-theme="dark"] .title-icon,
body[data-theme="dark"] .title-icon {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

[data-theme="dark"] .page-title,
html[data-theme="dark"] .page-title,
body[data-theme="dark"] .page-title {
  background: linear-gradient(135deg, #7c3aed 0%, #a855f7 100%) !important;
  background-clip: text !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
}

/* Button Dark Mode */
[data-theme="dark"] .add-button,
html[data-theme="dark"] .add-button,
body[data-theme="dark"] .add-button {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  box-shadow: 0 4px 12px rgba(124, 58, 237, 0.4) !important;
}

[data-theme="dark"] .add-button:hover,
html[data-theme="dark"] .add-button:hover,
body[data-theme="dark"] .add-button:hover {
  box-shadow: 0 8px 20px rgba(124, 58, 237, 0.5) !important;
}

[data-theme="dark"] :deep(.n-button),
html[data-theme="dark"] :deep(.n-button),
body[data-theme="dark"] :deep(.n-button) {
  background: rgba(124, 58, 237, 0.8) !important;
  border: 1px solid rgba(124, 58, 237, 0.6) !important;
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-button:hover),
html[data-theme="dark"] :deep(.n-button:hover),
body[data-theme="dark"] :deep(.n-button:hover) {
  background: rgba(124, 58, 237, 0.9) !important;
  border-color: rgba(124, 58, 237, 0.8) !important;
}

[data-theme="dark"] :deep(.n-button--primary-type),
html[data-theme="dark"] :deep(.n-button--primary-type),
body[data-theme="dark"] :deep(.n-button--primary-type) {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  border: none !important;
}

/* Dropdown Options Dark Mode */
[data-theme="dark"] :deep(.n-popover),
html[data-theme="dark"] :deep(.n-popover),
body[data-theme="dark"] :deep(.n-popover) {
  background: rgba(45, 55, 72, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  backdrop-filter: blur(10px) !important;
}

[data-theme="dark"] :deep(.n-select-menu),
html[data-theme="dark"] :deep(.n-select-menu),
body[data-theme="dark"] :deep(.n-select-menu) {
  background: rgba(45, 55, 72, 0.95) !important;
}

[data-theme="dark"] :deep(.n-select-option),
html[data-theme="dark"] :deep(.n-select-option),
body[data-theme="dark"] :deep(.n-select-option) {
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-select-option:hover),
html[data-theme="dark"] :deep(.n-select-option:hover),
body[data-theme="dark"] :deep(.n-select-option:hover) {
  background: rgba(124, 58, 237, 0.2) !important;
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-select-option.n-select-option--selected),
html[data-theme="dark"] :deep(.n-select-option.n-select-option--selected),
body[data-theme="dark"] :deep(.n-select-option.n-select-option--selected) {
  background: rgba(124, 58, 237, 0.3) !important;
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-select .n-base-selection .n-base-suffix),
html[data-theme="dark"] :deep(.n-select .n-base-selection .n-base-suffix),
body[data-theme="dark"] :deep(.n-select .n-base-selection .n-base-suffix) {
  color: #94a3b8 !important;
}

/* H3 Heading Dark Mode */
[data-theme="dark"] :deep(.n-h3),
html[data-theme="dark"] :deep(.n-h3),
body[data-theme="dark"] :deep(.n-h3) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-data-table-tr:hover .n-data-table-td),
html[data-theme="dark"] :deep(.n-data-table-tr:hover .n-data-table-td),
body[data-theme="dark"] :deep(.n-data-table-tr:hover .n-data-table-td) {
  background: rgba(124, 58, 237, 0.1) !important;
}

[data-theme="dark"] :deep(.n-data-table-empty),
html[data-theme="dark"] :deep(.n-data-table-empty),
body[data-theme="dark"] :deep(.n-data-table-empty) {
  color: #94a3b8 !important;
}

/* Modal Dark Mode */
[data-theme="dark"] :deep(.n-modal),
html[data-theme="dark"] :deep(.n-modal),
body[data-theme="dark"] :deep(.n-modal) {
  background: rgba(45, 55, 72, 0.95) !important;
}

[data-theme="dark"] :deep(.n-dialog .n-dialog__title),
html[data-theme="dark"] :deep(.n-dialog .n-dialog__title),
body[data-theme="dark"] :deep(.n-dialog .n-dialog__title) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-dialog .n-dialog__content),
html[data-theme="dark"] :deep(.n-dialog .n-dialog__content),
body[data-theme="dark"] :deep(.n-dialog .n-dialog__content) {
  background: transparent !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-dialog .n-dialog__action),
html[data-theme="dark"] :deep(.n-dialog .n-dialog__action),
body[data-theme="dark"] :deep(.n-dialog .n-dialog__action) {
  background: transparent !important;
  border-top: 1px solid rgba(255, 255, 255, 0.1) !important;
}

/* Form Components Dark Mode */
[data-theme="dark"] :deep(.n-form-item-label),
html[data-theme="dark"] :deep(.n-form-item-label),
body[data-theme="dark"] :deep(.n-form-item-label) {
  color: #f1f5f9 !important;
}

[data-theme="dark"] :deep(.n-input:hover),
html[data-theme="dark"] :deep(.n-input:hover),
body[data-theme="dark"] :deep(.n-input:hover) {
  border-color: rgba(124, 58, 237, 0.6) !important;
}

[data-theme="dark"] :deep(.n-input__input-el),
html[data-theme="dark"] :deep(.n-input__input-el),
body[data-theme="dark"] :deep(.n-input__input-el) {
  color: #e2e8f0 !important;
  background: transparent !important;
}

[data-theme="dark"] :deep(.n-input__placeholder),
html[data-theme="dark"] :deep(.n-input__placeholder),
body[data-theme="dark"] :deep(.n-input__placeholder) {
  color: #94a3b8 !important;
}

/* Textarea Dark Mode */
[data-theme="dark"] :deep(.n-input[type="textarea"]),
html[data-theme="dark"] :deep(.n-input[type="textarea"]),
body[data-theme="dark"] :deep(.n-input[type="textarea"]) {
  background: rgba(55, 65, 81, 0.8) !important;
}

[data-theme="dark"] :deep(.n-input[type="textarea"] .n-input__input-el),
html[data-theme="dark"] :deep(.n-input[type="textarea"] .n-input__input-el),
body[data-theme="dark"] :deep(.n-input[type="textarea"] .n-input__input-el) {
  background: transparent !important;
  color: #e2e8f0 !important;
}

/* Tag Components Dark Mode */
[data-theme="dark"] :deep(.n-tag),
html[data-theme="dark"] :deep(.n-tag),
body[data-theme="dark"] :deep(.n-tag) {
  background: rgba(75, 85, 99, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-tag--info-type),
html[data-theme="dark"] :deep(.n-tag--info-type),
body[data-theme="dark"] :deep(.n-tag--info-type) {
  background: rgba(59, 130, 246, 0.3) !important;
  border-color: rgba(59, 130, 246, 0.5) !important;
  color: #93c5fd !important;
}

[data-theme="dark"] :deep(.n-tag--warning-type),
html[data-theme="dark"] :deep(.n-tag--warning-type),
body[data-theme="dark"] :deep(.n-tag--warning-type) {
  background: rgba(245, 158, 11, 0.3) !important;
  border-color: rgba(245, 158, 11, 0.5) !important;
  color: #fcd34d !important;
}

[data-theme="dark"] :deep(.n-tag--error-type),
html[data-theme="dark"] :deep(.n-tag--error-type),
body[data-theme="dark"] :deep(.n-tag--error-type) {
  background: rgba(239, 68, 68, 0.3) !important;
  border-color: rgba(239, 68, 68, 0.5) !important;
  color: #fca5a5 !important;
}

[data-theme="dark"] :deep(.n-tag--success-type),
html[data-theme="dark"] :deep(.n-tag--success-type),
body[data-theme="dark"] :deep(.n-tag--success-type) {
  background: rgba(34, 197, 94, 0.3) !important;
  border-color: rgba(34, 197, 94, 0.5) !important;
  color: #86efac !important;
}

/* Space Component Dark Mode */
[data-theme="dark"] :deep(.n-space),
html[data-theme="dark"] :deep(.n-space),
body[data-theme="dark"] :deep(.n-space) {
  color: #e2e8f0 !important;
}

/* Loading and Message Dark Mode */
[data-theme="dark"] :deep(.n-message),
html[data-theme="dark"] :deep(.n-message),
body[data-theme="dark"] :deep(.n-message) {
  background: rgba(45, 55, 72, 0.95) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-loading-bar),
html[data-theme="dark"] :deep(.n-loading-bar),
body[data-theme="dark"] :deep(.n-loading-bar) {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
}

/* Pagination Dark Mode */
[data-theme="dark"] :deep(.n-pagination),
html[data-theme="dark"] :deep(.n-pagination),
body[data-theme="dark"] :deep(.n-pagination) {
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-pagination .n-pagination-item),
html[data-theme="dark"] :deep(.n-pagination .n-pagination-item),
body[data-theme="dark"] :deep(.n-pagination .n-pagination-item) {
  background: rgba(55, 65, 81, 0.8) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  color: #e2e8f0 !important;
}

[data-theme="dark"] :deep(.n-pagination .n-pagination-item:hover),
html[data-theme="dark"] :deep(.n-pagination .n-pagination-item:hover),
body[data-theme="dark"] :deep(.n-pagination .n-pagination-item:hover) {
  background: rgba(124, 58, 237, 0.3) !important;
  border-color: rgba(124, 58, 237, 0.5) !important;
}

[data-theme="dark"] :deep(.n-pagination .n-pagination-item--active),
html[data-theme="dark"] :deep(.n-pagination .n-pagination-item--active),
body[data-theme="dark"] :deep(.n-pagination .n-pagination-item--active) {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  border-color: #7c3aed !important;
  color: white !important;
}

/* Scrollbar Dark Mode */
[data-theme="dark"] ::-webkit-scrollbar,
html[data-theme="dark"] ::-webkit-scrollbar,
body[data-theme="dark"] ::-webkit-scrollbar {
  width: 8px;
}

[data-theme="dark"] ::-webkit-scrollbar-track,
html[data-theme="dark"] ::-webkit-scrollbar-track,
body[data-theme="dark"] ::-webkit-scrollbar-track {
  background: #2d3748 !important;
}

[data-theme="dark"] ::-webkit-scrollbar-thumb,
html[data-theme="dark"] ::-webkit-scrollbar-thumb,
body[data-theme="dark"] ::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%) !important;
  border-radius: 4px;
}

[data-theme="dark"] ::-webkit-scrollbar-thumb:hover,
html[data-theme="dark"] ::-webkit-scrollbar-thumb:hover,
body[data-theme="dark"] ::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #5b21b6 0%, #8b5cf6 100%) !important;
}
</style>