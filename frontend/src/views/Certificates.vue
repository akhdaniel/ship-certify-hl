<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
      <n-h2>Daftar Sertifikat</n-h2>
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