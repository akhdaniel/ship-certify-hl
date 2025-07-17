<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
      <n-h2>Daftar Survey</n-h2>
      <n-button 
        v-if="userStore.isAuthority()" 
        type="primary" 
        @click="showAddModal = true"
      >
        Jadwalkan Survey Baru
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
  scheduledDate: '',
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
  scheduledDate: { required: true, message: 'Tanggal harus dipilih' },
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
    
    console.log('Creating survey:', newSurvey.value)
    await surveyApi.create(newSurvey.value)
    
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
    scheduledDate: '',
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