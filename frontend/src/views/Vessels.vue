<template>
  <div>
    <div class="header-content-section flex-responsive">
      <div class="header-title">
        <div class="title-icon">🚢 </div>
        <n-h2 class="page-title">Daftar Kapal</n-h2>
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
        Daftarkan Kapal Baru
      </n-button>
    </div>

    <n-space vertical size="large">
      <n-input
        v-model:value="searchQuery"
        placeholder="Cari kapal berdasarkan nama, IMO, atau flag..."
        clearable
      >
        <template #prefix>
          <n-icon :component="SearchIcon" />
        </template>
      </n-input>

      <n-data-table
        :columns="columns"
        :data="filteredVessels"
        :loading="loading"
        :pagination="pagination"
      />
    </n-space>

    <!-- Add Vessel Modal -->
    <n-modal v-model:show="showAddModal" preset="dialog" title="Daftarkan Kapal Baru">
      <n-form :model="newVessel" :rules="rules" ref="formRef">
        <n-form-item label="ID Kapal" path="vesselId">
          <n-input v-model:value="newVessel.vesselId" placeholder="Contoh: VSL001" />
        </n-form-item>
        <n-form-item label="Nama Kapal" path="name">
          <n-input v-model:value="newVessel.name" placeholder="Nama kapal" />
        </n-form-item>
        <n-form-item label="Jenis Kapal" path="type">
          <n-select 
            v-model:value="newVessel.type" 
            :options="vesselTypes"
            placeholder="Pilih jenis kapal"
          />
        </n-form-item>
        <n-form-item label="Nomor IMO" path="imoNumber">
          <n-input v-model:value="newVessel.imoNumber" placeholder="IMO Number" />
        </n-form-item>
        <n-form-item label="Flag" path="flag">
          <n-input v-model:value="newVessel.flag" placeholder="Bendera kapal" />
        </n-form-item>
        <n-form-item label="Tahun Pembuatan" path="buildYear">
          <n-input-number 
            v-model:value="newVessel.buildYear" 
            :min="1900" 
            :max="new Date().getFullYear()"
            style="width: 100%"
          />
        </n-form-item>
        <n-form-item label="Ship Owner" path="shipOwnerId">
          <n-select 
            v-model:value="newVessel.shipOwnerId" 
            :options="shipOwnerOptions"
            placeholder="Pilih ship owner"
            :loading="loadingShipOwners"
          />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showAddModal = false">Batal</n-button>
          <n-button type="primary" @click="handleAddVessel" :loading="submitting">
            Daftarkan
          </n-button>
        </n-space>
      </template>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { NButton, NTag, useMessage } from 'naive-ui'
import { useUserStore } from '@/stores/user'
import { vesselApi, shipOwnerApi } from '@/services/api'
import { SearchOutline as SearchIcon } from '@vicons/ionicons5'
import { format } from 'date-fns'

const userStore = useUserStore()
const message = useMessage()

const loading = ref(true)
const loadingShipOwners = ref(false)
const submitting = ref(false)
const showAddModal = ref(false)
const searchQuery = ref('')
const vessels = ref([])
const shipOwners = ref([])
const formRef = ref(null)

const newVessel = ref({
  vesselId: '',
  name: '',
  type: '',
  imoNumber: '',
  flag: '',
  buildYear: new Date().getFullYear(),
  shipOwnerId: ''
})

const vesselTypes = [
  { label: 'Cargo Ship', value: 'cargo' },
  { label: 'Tanker', value: 'tanker' },
  { label: 'Container Ship', value: 'container' },
  { label: 'Bulk Carrier', value: 'bulk' },
  { label: 'Passenger Ship', value: 'passenger' },
  { label: 'Fishing Vessel', value: 'fishing' },
  { label: 'Offshore Support Vessel', value: 'osv' },
  { label: 'Tugboat', value: 'tugboat' }
]

const rules = {
  vesselId: { required: true, message: 'ID Kapal harus diisi' },
  name: { required: true, message: 'Nama kapal harus diisi' },
  type: { required: true, message: 'Jenis kapal harus dipilih' },
  imoNumber: { required: true, message: 'Nomor IMO harus diisi' },
  flag: { required: true, message: 'Flag harus diisi' },
  buildYear: { required: true, message: 'Tahun pembuatan harus diisi' },
  shipOwnerId: { required: true, message: 'Ship owner harus dipilih' }
}

const pagination = {
  pageSize: 10
}

const columns = computed(() => [
  {
    title: 'ID Kapal',
    key: 'id',
    width: 120
  },
  {
    title: 'Nama Kapal',
    key: 'name',
    width: 200
  },
  {
    title: 'Jenis',
    key: 'type',
    width: 120,
    render: (row) => {
      const typeLabel = vesselTypes.find(t => t.value === row.type)?.label || row.type
      return h(NTag, { type: 'info' }, { default: () => typeLabel })
    }
  },
  {
    title: 'IMO Number',
    key: 'imoNumber',
    width: 150
  },
  {
    title: 'Flag',
    key: 'flag',
    width: 100
  },
  {
    title: 'Tahun',
    key: 'buildYear',
    width: 80
  },
  {
    title: 'Status',
    key: 'status',
    width: 120,
    render: (row) => {
      const statusMap = {
        'registered': { type: 'success', text: 'Terdaftar' },
        'surveyed': { type: 'warning', text: 'Survei' },
        'certified': { type: 'info', text: 'Bersertifikat' }
      }
      const status = statusMap[row.status] || { type: 'default', text: row.status }
      return h(NTag, { type: status.type }, { default: () => status.text })
    }
  },
  {
    title: 'Tanggal Daftar',
    key: 'registeredAt',
    width: 150,
    render: (row) => {
      return row.registeredAt ? format(new Date(row.registeredAt), 'dd/MM/yyyy') : '-'
    }
  }
])

const shipOwnerOptions = computed(() => 
  shipOwners.value.map(owner => ({
    label: `${owner.Record.name} (${owner.Record.companyName})`,
    value: owner.Record.id
  }))
)

const filteredVessels = computed(() => {
  if (!searchQuery.value) return vessels.value
  
  const query = searchQuery.value.toLowerCase()
  return vessels.value.filter(vessel => 
    vessel.name?.toLowerCase().includes(query) ||
    vessel.imoNumber?.toLowerCase().includes(query) ||
    vessel.flag?.toLowerCase().includes(query)
  )
})

const loadVessels = async () => {
  try {
    loading.value = true
    const apiCall = userStore.isShipOwner() ? vesselApi.getMy : vesselApi.getAll;
    const response = await apiCall();
    vessels.value = response.data?.map(item => ({
      ...item.Record,
      key: item.Key
    })) || []
  } catch (error) {
    message.error('Gagal memuat data kapal: ' + error.message)
  } finally {
    loading.value = false
  }
}

const loadShipOwners = async () => {
  try {
    loadingShipOwners.value = true
    const response = await shipOwnerApi.getAll()
    shipOwners.value = response.data || []
  } catch (error) {
    message.error('Gagal memuat data ship owner: ' + error.message)
  } finally {
    loadingShipOwners.value = false
  }
}

const handleAddVessel = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    console.log('Creating vessel:', newVessel.value)
    await vesselApi.create(newVessel.value)
    
    message.success('Kapal berhasil didaftarkan')
    showAddModal.value = false
    resetForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loading.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing vessels list...')
    const originalCount = vessels.value.length
    await loadVessels()
    
    if (vessels.value.length === originalCount) {
      console.log('Record not yet available, retrying in 2 seconds...')
      message.loading('Menunggu data terbaru...', { duration: 0, key: 'refresh' })
      await new Promise(resolve => setTimeout(resolve, 2000))
      await loadVessels()
    }
    
    // Clear loading messages
    message.destroyAll()
    loading.value = false
    console.log('Vessels list refreshed')
  } catch (error) {
    console.error('Error creating vessel:', error)
    message.error('Gagal mendaftarkan kapal: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const resetForm = () => {
  newVessel.value = {
    vesselId: '',
    name: '',
    type: '',
    imoNumber: '',
    flag: '',
    buildYear: new Date().getFullYear(),
    shipOwnerId: ''
  }
}

onMounted(async () => {
  await Promise.all([
    loadVessels(),
    loadShipOwners()
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