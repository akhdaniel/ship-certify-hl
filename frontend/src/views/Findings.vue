<template>
  <div>
    <n-h2>Findings Management</n-h2>
    
    <n-space vertical size="large">
      <n-card title="Filter Survey">
        <n-select
          v-model:value="selectedSurveyId"
          :options="surveyOptions"
          placeholder="Pilih survey untuk melihat findings"
          clearable
          @update:value="loadFindings"
        />
      </n-card>

      <div v-if="selectedSurveyId">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
          <n-h3>Findings untuk Survey: {{ selectedSurveyId }}</n-h3>
          <n-button 
            v-if="userStore.isAuthority()" 
            type="primary" 
            @click="showAddModal = true"
          >
            Tambah Finding
          </n-button>
        </div>

        <n-data-table
          :columns="columns"
          :data="findings"
          :loading="loadingFindings"
          :pagination="pagination"
        />
      </div>
    </n-space>

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
    
    await findingApi.create(selectedSurveyId.value, newFinding.value)
    
    message.success('Finding berhasil ditambahkan')
    showAddModal.value = false
    resetAddForm()
    await loadFindings()
  } catch (error) {
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
    
    await findingApi.resolve(selectedSurveyId.value, selectedFindingId.value, resolutionData.value)
    
    message.success('Finding berhasil diselesaikan')
    showResolveModal.value = false
    resetResolveForm()
    await loadFindings()
  } catch (error) {
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
    
    await findingApi.verify(selectedSurveyId.value, selectedFindingId.value, verificationData.value)
    
    message.success('Finding berhasil diverifikasi')
    showVerifyModal.value = false
    resetVerifyForm()
    await loadFindings()
  } catch (error) {
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