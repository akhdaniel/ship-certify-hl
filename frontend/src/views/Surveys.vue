<template>
  <div>
    <div class="header-content-section flex-responsive">
      <div class="header-title">
        <div class="title-icon">🚢 </div>
        <n-h2 class="page-title">Daftar Survey</n-h2>
      </div>
      <n-button 
        v-if="userStore.isAuthority()" 
        type="primary" 
        class="btn-gradient-primary add-button"
        @click="showAddModal = true"
      >
        <template #icon>
          <n-icon>
            <svg viewBox="0 0 24 24">
              <path fill="currentColor" d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
            </svg>
          </n-icon>
        </template>
        Daftarkan Survey Baru
      </n-button>
    </div>



    <n-space vertical size="large">
      <n-input
        v-model:value="searchQuery"
        placeholder="Cari survey berdasarkan ID, kapal, atau surveyor..."
        clearable
      >
        <template #prefix>
          <n-icon :component="SearchIcon" />
        </template>
      </n-input>

      <n-data-table
        :columns="columns"
        :data="filteredSurveys"
        :loading="loading"
        :pagination="pagination"
      />
    </n-space>

    <!-- Add Survey Modal -->
    <n-modal v-model:show="showAddModal" preset="dialog" title="Jadwalkan Survey Baru">
      <n-form :model="newSurvey" :rules="rules" ref="formRef">
        <n-form-item label="ID Survey" path="surveyId">
          <n-input v-model:value="newSurvey.surveyId" placeholder="Contoh: SUR001" />
        </n-form-item>
        <n-form-item label="Kapal" path="vesselId">
          <n-select 
            v-model:value="newSurvey.vesselId" 
            :options="vesselOptions"
            placeholder="Pilih kapal"
            :loading="loadingVessels"
          />
        </n-form-item>
        <n-form-item label="Jenis Survey" path="surveyType">
          <n-select 
            v-model:value="newSurvey.surveyType" 
            :options="surveyTypes"
            placeholder="Pilih jenis survey"
          />
        </n-form-item>
        <n-form-item label="Tanggal Dijadwalkan" path="scheduledDate">
          <n-date-picker 
            v-model:formatted-value="newSurvey.scheduledDate"
            value-format="yyyy-MM-dd"
            type="date"
            style="width: 100%"
            placeholder="Pilih tanggal"
          />
        </n-form-item>
        <n-form-item label="Nama Surveyor" path="surveyorName">
          <n-input v-model:value="newSurvey.surveyorName" placeholder="Nama surveyor" />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showAddModal = false">Batal</n-button>
          <n-button type="primary" @click="handleAddSurvey" :loading="submitting">
            Jadwalkan
          </n-button>
        </n-space>
      </template>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { NButton, NTag, NDatePicker, useMessage } from 'naive-ui'
import { useUserStore } from '@/stores/user'
import { surveyApi, vesselApi } from '@/services/api'
import { SearchOutline as SearchIcon } from '@vicons/ionicons5'
import { format, parseISO } from 'date-fns'

const userStore = useUserStore()
const message = useMessage()

const loading = ref(true)
const loadingVessels = ref(false)
const submitting = ref(false)
const showAddModal = ref(false)
const searchQuery = ref('')
const surveys = ref([])
const vessels = ref([])
const formRef = ref(null)

const newSurvey = ref({
  surveyId: '',
  vesselId: '',
  surveyType: '',
  scheduledDate: null,
  surveyorName: ''
})

const surveyTypes = [
  { label: 'Hull Survey', value: 'hull' },
  { label: 'Machinery Survey', value: 'machinery' },
  { label: 'Annual Survey', value: 'annual' },
  { label: 'Intermediate Survey', value: 'intermediate' },
  { label: 'Renewal Survey', value: 'renewal' }
]

const rules = {
  surveyId: { required: true, message: 'ID Survey harus diisi' },
  vesselId: { required: true, message: 'Kapal harus dipilih' },
  surveyType: { required: true, message: 'Jenis survey harus dipilih' },
  scheduledDate: { 
    required: true, 
    message: 'Tanggal harus dipilih',
    validator: (rule, value) => {
      if (!value) {
        return new Error('Tanggal harus dipilih')
      }
      return true
    }
  },
  surveyorName: { required: true, message: 'Nama surveyor harus diisi' }
}

const pagination = {
  pageSize: 10
}

const columns = computed(() => [
  {
    title: 'ID Survey',
    key: 'id',
    width: 120
  },
  {
    title: 'Kapal',
    key: 'vesselId',
    width: 120
  },
  {
    title: 'Jenis Survey',
    key: 'surveyType',
    width: 150,
    render: (row) => {
      const typeLabel = surveyTypes.find(t => t.value === row.surveyType)?.label || row.surveyType
      return h(NTag, { type: 'info' }, { default: () => typeLabel })
    }
  },
  {
    title: 'Surveyor',
    key: 'surveyorName',
    width: 150
  },
  {
    title: 'Tanggal',
    key: 'scheduledDate',
    width: 120,
    render: (row) => formatDate(row.scheduledDate)
  },
  {
    title: 'Status',
    key: 'status',
    width: 120,
    render: (row) => {
      const statusMap = {
        'scheduled': { type: 'warning', text: 'Dijadwalkan' },
        'in-progress': { type: 'info', text: 'Berlangsung' },
        'completed': { type: 'success', text: 'Selesai' }
      }
      const status = statusMap[row.status] || { type: 'default', text: row.status }
      return h(NTag, { type: status.type }, { default: () => status.text })
    }
  },
  {
    title: 'Findings',
    key: 'findingsCount',
    width: 100,
    render: (row) => {
      const count = row.findings?.length || 0
      return h(NTag, { type: count > 0 ? 'warning' : 'success' }, { default: () => count })
    }
  },
  ...(userStore.isAuthority() ? [{
    title: 'Aksi',
    key: 'actions',
    width: 120,
    render: (row) => {
      if (row.status === 'scheduled') {
        return h(
          NButton,
          {
            size: 'small',
            type: 'primary',
            onClick: () => startSurvey(row.id)
          },
          { default: () => 'Mulai' }
        )
      }
      return '-'
    }
  }] : [])
])

const vesselOptions = computed(() => 
  vessels.value.map(vessel => ({
    label: `${vessel.Record.name} (${vessel.Record.id})`,
    value: vessel.Record.id
  }))
)

const filteredSurveys = computed(() => {
  if (!searchQuery.value) return surveys.value
  
  const query = searchQuery.value.toLowerCase()
  return surveys.value.filter(survey => 
    survey.id?.toLowerCase().includes(query) ||
    survey.vesselId?.toLowerCase().includes(query) ||
    survey.surveyorName?.toLowerCase().includes(query)
  )
})

const formatDate = (dateString) => {
  if (!dateString) return '-'
  try {
    return format(parseISO(dateString), 'dd/MM/yyyy')
  } catch {
    return dateString
  }
}

const loadSurveys = async () => {
  try {
    loading.value = true
    const response = await surveyApi.getAll()
    surveys.value = response.data?.map(item => ({
      ...item.Record,
      key: item.Key
    })) || []
  } catch (error) {
    message.error('Gagal memuat data survey: ' + error.message)
  } finally {
    loading.value = false
  }
}

const loadVessels = async () => {
  try {
    loadingVessels.value = true
    const response = await vesselApi.getAll()
    vessels.value = response.data || []
  } catch (error) {
    message.error('Gagal memuat data kapal: ' + error.message)
  } finally {
    loadingVessels.value = false
  }
}

const handleAddSurvey = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    // Prepare data for API call, ensuring dates are properly formatted
    const surveyData = {
      ...newSurvey.value,
      scheduledDate: newSurvey.value.scheduledDate || ''
    }
    
    console.log('Creating survey:', surveyData)
    await surveyApi.create(surveyData)
    
    message.success('Survey berhasil dijadwalkan')
    showAddModal.value = false
    resetForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loading.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing surveys list...')
    const originalCount = surveys.value.length
    await loadSurveys()
    
    if (surveys.value.length === originalCount) {
      console.log('Record not yet available, retrying in 2 seconds...')
      message.loading('Menunggu data terbaru...', { duration: 0, key: 'refresh' })
      await new Promise(resolve => setTimeout(resolve, 2000))
      await loadSurveys()
    }
    
    // Clear loading messages
    message.destroyAll()
    loading.value = false
    console.log('Surveys list refreshed')
  } catch (error) {
    console.error('Error creating survey:', error)
    message.error('Gagal menjadwalkan survey: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const startSurvey = async (surveyId) => {
  try {
    console.log('Starting survey:', surveyId)
    await surveyApi.start(surveyId)
    message.success('Survey berhasil dimulai')
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loading.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing surveys list...')
    await loadSurveys()
    
    // Clear loading messages
    message.destroyAll()
    loading.value = false
    console.log('Surveys list refreshed')
  } catch (error) {
    console.error('Error starting survey:', error)
    message.error('Gagal memulai survey: ' + error.message)
  }
}

const resetForm = () => {
  newSurvey.value = {
    surveyId: '',
    vesselId: '',
    surveyType: '',
    scheduledDate: null,
    surveyorName: ''
  }
}

onMounted(async () => {
  await Promise.all([
    loadSurveys(),
    loadVessels()
  ])
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