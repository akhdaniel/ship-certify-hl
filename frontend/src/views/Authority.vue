<template>
  <div>
    <n-h2>BKI Authority Management</n-h2>
    
    <n-space vertical size="large">
      <n-card title="Daftarkan Authority Baru">
        <n-form :model="newAuthority" :rules="rules" ref="formRef">
          <n-grid x-gap="12" cols="2">
            <n-grid-item>
              <n-form-item label="ID Authority" path="authorityId">
                <n-input v-model:value="newAuthority.authorityId" placeholder="Contoh: AUTH002" />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="Email Address" path="address">
                <n-input v-model:value="newAuthority.address" placeholder="authority@bki.com" />
              </n-form-item>
            </n-grid-item>
            <n-grid-item span="2">
              <n-form-item label="Nama Authority" path="name">
                <n-input v-model:value="newAuthority.name" placeholder="Nama kantor BKI" />
              </n-form-item>
            </n-grid-item>
            <n-grid-item span="2">
              <n-space>
                <n-button type="primary" @click="handleAddAuthority" :loading="submitting">
                  Daftarkan Authority
                </n-button>
                <n-button @click="resetForm">
                  Reset Form
                </n-button>
              </n-space>
            </n-grid-item>
          </n-grid>
        </n-form>
      </n-card>

      <n-card title="Issue Certificate">
        <n-form :model="newCertificate" :rules="certificateRules" ref="certificateFormRef">
          <n-grid x-gap="12" cols="2">
            <n-grid-item>
              <n-form-item label="ID Sertifikat" path="certificateId">
                <n-input v-model:value="newCertificate.certificateId" placeholder="Contoh: CERT001" />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="Survey" path="surveyId">
                <n-select 
                  v-model:value="newCertificate.surveyId" 
                  :options="completedSurveyOptions"
                  placeholder="Pilih survey yang telah selesai"
                  :loading="loadingSurveys"
                  @update:value="onSurveySelect"
                />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="ID Kapal" path="vesselId">
                <n-input v-model:value="newCertificate.vesselId" placeholder="Akan terisi otomatis" disabled />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="Jenis Sertifikat" path="certificateType">
                <n-select 
                  v-model:value="newCertificate.certificateType" 
                  :options="certificateTypeOptions"
                  placeholder="Pilih jenis sertifikat"
                />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="Berlaku Dari" path="validFrom">
                <n-date-picker 
                  v-model:formatted-value="newCertificate.validFrom"
                  value-format="yyyy-MM-dd"
                  type="date"
                  style="width: 100%"
                  placeholder="Pilih tanggal"
                />
              </n-form-item>
            </n-grid-item>
            <n-grid-item>
              <n-form-item label="Berlaku Sampai" path="validTo">
                <n-date-picker 
                  v-model:formatted-value="newCertificate.validTo"
                  value-format="yyyy-MM-dd"
                  type="date"
                  style="width: 100%"
                  placeholder="Pilih tanggal"
                />
              </n-form-item>
            </n-grid-item>
            <n-grid-item span="2">
              <n-space>
                <n-button type="primary" @click="handleIssueCertificate" :loading="submittingCertificate">
                  Keluarkan Sertifikat
                </n-button>
                <n-button @click="resetCertificateForm">
                  Reset Form
                </n-button>
              </n-space>
            </n-grid-item>
          </n-grid>
        </n-form>
      </n-card>

      <n-card title="System Statistics">
        <n-grid x-gap="12" y-gap="12" cols="2 m:4">
          <n-grid-item>
            <n-statistic label="Total Authorities" :value="statistics.totalAuthorities" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Total Ship Owners" :value="statistics.totalShipOwners" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Total Vessels" :value="statistics.totalVessels" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Total Certificates" :value="statistics.totalCertificates" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Active Surveys" :value="statistics.activeSurveys" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Open Findings" :value="statistics.openFindings" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Completed Surveys" :value="statistics.completedSurveys" />
          </n-grid-item>
          <n-grid-item>
            <n-statistic label="Verified Findings" :value="statistics.verifiedFindings" />
          </n-grid-item>
        </n-grid>
      </n-card>
    </n-space>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useMessage, NDatePicker } from 'naive-ui'
import { authorityApi, certificateApi, surveyApi, vesselApi, shipOwnerApi } from '@/services/api'

const message = useMessage()

const submitting = ref(false)
const submittingCertificate = ref(false)
const loadingSurveys = ref(false)
const surveys = ref([])
const formRef = ref(null)
const certificateFormRef = ref(null)

const newAuthority = ref({
  authorityId: '',
  address: '',
  name: ''
})

const newCertificate = ref({
  certificateId: '',
  vesselId: '',
  surveyId: '',
  certificateType: '',
  validFrom: null,
  validTo: null
})

const statistics = ref({
  totalAuthorities: 0,
  totalShipOwners: 0,
  totalVessels: 0,
  totalCertificates: 0,
  activeSurveys: 0,
  openFindings: 0,
  completedSurveys: 0,
  verifiedFindings: 0
})

const rules = {
  authorityId: { required: true, message: 'ID Authority harus diisi' },
  address: { 
    required: true, 
    message: 'Email address harus diisi',
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    trigger: 'blur'
  },
  name: { required: true, message: 'Nama authority harus diisi' }
}

const certificateRules = {
  certificateId: { required: true, message: 'ID Sertifikat harus diisi' },
  vesselId: { required: true, message: 'ID Kapal harus diisi' },
  surveyId: { required: true, message: 'Survey harus dipilih' },
  certificateType: { required: true, message: 'Jenis sertifikat harus dipilih' },
  validFrom: { 
    required: true, 
    message: 'Tanggal mulai berlaku harus diisi',
    validator: (rule, value) => {
      if (!value) {
        return new Error('Tanggal mulai berlaku harus diisi')
      }
      return true
    }
  },
  validTo: { 
    required: true, 
    message: 'Tanggal berakhir harus diisi',
    validator: (rule, value) => {
      if (!value) {
        return new Error('Tanggal berakhir harus diisi')
      }
      return true
    }
  }
}

const certificateTypeOptions = [
  { label: 'Class Certificate', value: 'class' },
  { label: 'Safety Certificate', value: 'safety' },
  { label: 'Load Line Certificate', value: 'load_line' }
]

const completedSurveyOptions = computed(() => 
  surveys.value
    .filter(survey => survey.Record.status === 'in-progress' || survey.Record.status === 'completed')
    .map(survey => ({
      label: `${survey.Record.id} - ${survey.Record.vesselId} (${survey.Record.surveyType})`,
      value: survey.Record.id,
      vesselId: survey.Record.vesselId
    }))
)

const handleAddAuthority = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    await authorityApi.create(newAuthority.value)
    
    message.success('Authority berhasil didaftarkan')
    resetForm()
    await loadStatistics()
  } catch (error) {
    message.error('Gagal mendaftarkan authority: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const handleIssueCertificate = async () => {
  try {
    await certificateFormRef.value?.validate()
    submittingCertificate.value = true
    
    // Prepare data for API call, ensuring dates are properly formatted
    const certificateData = {
      ...newCertificate.value,
      validFrom: newCertificate.value.validFrom || '',
      validTo: newCertificate.value.validTo || ''
    }
    
    await certificateApi.create(certificateData)
    
    message.success('Sertifikat berhasil dikeluarkan')
    resetCertificateForm()
    await loadStatistics()
  } catch (error) {
    message.error('Gagal mengeluarkan sertifikat: ' + error.message)
  } finally {
    submittingCertificate.value = false
  }
}

const onSurveySelect = (surveyId) => {
  const survey = completedSurveyOptions.value.find(s => s.value === surveyId)
  if (survey) {
    newCertificate.value.vesselId = survey.vesselId
  }
}

const resetForm = () => {
  newAuthority.value = {
    authorityId: '',
    address: '',
    name: ''
  }
}

const resetCertificateForm = () => {
  newCertificate.value = {
    certificateId: '',
    vesselId: '',
    surveyId: '',
    certificateType: '',
    validFrom: null,
    validTo: null
  }
}

const loadSurveys = async () => {
  try {
    loadingSurveys.value = true
    const response = await surveyApi.getAll()
    surveys.value = response.data || []
  } catch (error) {
    console.error('Failed to load surveys:', error)
  } finally {
    loadingSurveys.value = false
  }
}

const loadStatistics = async () => {
  try {
    const [vessels, certificates, shipOwners] = await Promise.all([
      vesselApi.getAll().catch(() => ({ data: [] })),
      certificateApi.getAll().catch(() => ({ data: [] })),
      shipOwnerApi.getAll().catch(() => ({ data: [] })),
    ])

    statistics.value.totalVessels = vessels.data?.length || 0
    statistics.value.totalCertificates = certificates.data?.length || 0
    statistics.value.totalShipOwners = shipOwners.data?.length || 0
    
    // Mock some additional statistics
    statistics.value.totalAuthorities = 3
    statistics.value.activeSurveys = surveys.value.filter(s => s.Record.status === 'in-progress').length
    statistics.value.completedSurveys = surveys.value.filter(s => s.Record.status === 'completed').length
    statistics.value.openFindings = Math.floor(statistics.value.totalVessels * 0.15)
    statistics.value.verifiedFindings = Math.floor(statistics.value.openFindings * 0.7)

  } catch (error) {
    console.error('Failed to load statistics:', error)
  }
}

onMounted(async () => {
  await Promise.all([
    loadSurveys(),
    loadStatistics()
  ])
})
</script>