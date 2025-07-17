<template>
  <div class="ship-owners-container">
    <!-- Header Section -->
    <div class="page-header card-gradient">
      <div class="header-content-section flex-responsive">
        <div class="header-title">
          <div class="title-icon">👥</div>
          <n-h2 class="page-title">Daftar Ship Owner</n-h2>
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
          Daftarkan Ship Owner Baru
        </n-button>
      </div>
    </div>

    <n-space vertical size="large" class="content-space">
      <!-- Search Section -->
      <div class="search-section card-gradient">
        <n-input
          v-model:value="searchQuery"
          placeholder="Cari ship owner berdasarkan nama atau perusahaan..."
          clearable
          size="large"
          class="search-input"
        >
          <template #prefix>
            <n-icon :component="SearchIcon" />
          </template>
        </n-input>
      </div>

      <!-- Data Table Section -->
      <div class="table-section card-gradient">
        <n-data-table
          :columns="columns"
          :data="filteredShipOwners"
          :loading="loading"
          :pagination="pagination"
          class="responsive-table"
          :scroll-x="800"
        />
      </div>
    </n-space>

    <!-- Add Ship Owner Modal -->
    <n-modal v-model:show="showAddModal" preset="dialog" title="Daftarkan Ship Owner Baru">
      <n-form :model="newShipOwner" :rules="rules" ref="formRef">
        <n-form-item label="ID Ship Owner" path="shipOwnerId">
          <n-input v-model:value="newShipOwner.shipOwnerId" placeholder="Contoh: SO001" />
        </n-form-item>
        <n-form-item label="Email Address" path="address">
          <n-input v-model:value="newShipOwner.address" placeholder="email@example.com" />
        </n-form-item>
        <n-form-item label="Nama Lengkap" path="name">
          <n-input v-model:value="newShipOwner.name" placeholder="Nama lengkap" />
        </n-form-item>
        <n-form-item label="Nama Perusahaan" path="companyName">
          <n-input v-model:value="newShipOwner.companyName" placeholder="Nama perusahaan" />
        </n-form-item>
      </n-form>
      
      <template #action>
        <n-space>
          <n-button @click="showAddModal = false">Batal</n-button>
          <n-button type="primary" @click="handleAddShipOwner" :loading="submitting">
            Daftarkan
          </n-button>
        </n-space>
      </template>
    </n-modal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { NTag, useMessage } from 'naive-ui'
import { useUserStore } from '@/stores/user'
import { shipOwnerApi } from '@/services/api'
import { SearchOutline as SearchIcon } from '@vicons/ionicons5'
import { format, parseISO } from 'date-fns'

const userStore = useUserStore()
const message = useMessage()

const loading = ref(true)
const submitting = ref(false)
const showAddModal = ref(false)
const searchQuery = ref('')
const shipOwners = ref([])
const formRef = ref(null)

const newShipOwner = ref({
  shipOwnerId: '',
  address: '',
  name: '',
  companyName: ''
})

const rules = {
  shipOwnerId: { required: true, message: 'ID Ship Owner harus diisi' },
  address: { 
    required: true, 
    message: 'Email address harus diisi',
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    trigger: 'blur'
  },
  name: { required: true, message: 'Nama lengkap harus diisi' },
  companyName: { required: true, message: 'Nama perusahaan harus diisi' }
}

const pagination = {
  pageSize: 10
}

const columns = [
  {
    title: 'ID Ship Owner',
    key: 'id',
    width: 150
  },
  {
    title: 'Nama Lengkap',
    key: 'name',
    width: 200
  },
  {
    title: 'Nama Perusahaan',
    key: 'companyName',
    width: 250
  },
  {
    title: 'Email Address',
    key: 'address',
    width: 200
  },
  {
    title: 'Status',
    key: 'isActive',
    width: 100,
    render: (row) => {
      return h(
        NTag,
        { type: row.isActive ? 'success' : 'error' },
        { default: () => row.isActive ? 'Aktif' : 'Tidak Aktif' }
      )
    }
  },
  {
    title: 'Tanggal Daftar',
    key: 'registeredAt',
    width: 150,
    render: (row) => {
      return row.registeredAt ? format(parseISO(row.registeredAt), 'dd/MM/yyyy') : '-'
    }
  },
  {
    title: 'Didaftarkan Oleh',
    key: 'registeredBy',
    width: 200,
    ellipsis: {
      tooltip: true
    }
  }
]

const filteredShipOwners = computed(() => {
  if (!searchQuery.value) return shipOwners.value
  
  const query = searchQuery.value.toLowerCase()
  return shipOwners.value.filter(owner => 
    owner.name?.toLowerCase().includes(query) ||
    owner.companyName?.toLowerCase().includes(query) ||
    owner.address?.toLowerCase().includes(query)
  )
})

const loadShipOwners = async () => {
  try {
    loading.value = true
    console.log('Loading ship owners...')
    const response = await shipOwnerApi.getAll()
    console.log('API response:', response)
    shipOwners.value = response.data?.map(item => ({
      ...item.Record,
      key: item.Key
    })) || []
    console.log('Ship owners loaded:', shipOwners.value.length, 'records')
  } catch (error) {
    console.error('Error loading ship owners:', error)
    message.error('Gagal memuat data ship owner: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleAddShipOwner = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    console.log('Creating ship owner:', newShipOwner.value)
    await shipOwnerApi.create(newShipOwner.value)
    
    message.success('Ship Owner berhasil didaftarkan')
    showAddModal.value = false
    resetForm()
    
    // Show loading state and wait for blockchain processing
    console.log('Waiting for blockchain to process...')
    loading.value = true
    message.loading('Memperbarui data...', { duration: 0, key: 'refresh' })
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    console.log('Refreshing ship owners list...')
    const originalCount = shipOwners.value.length
    await loadShipOwners()
    
    // If we didn't get the new record, try again after a longer delay
    if (shipOwners.value.length === originalCount) {
      console.log('Record not yet available, retrying in 2 seconds...')
      message.loading('Menunggu data terbaru...', { duration: 0, key: 'refresh' })
      await new Promise(resolve => setTimeout(resolve, 2000))
      await loadShipOwners()
    }
    
    // Clear loading messages
    message.destroyAll()
    loading.value = false
    console.log('Ship owners list refreshed')
  } catch (error) {
    console.error('Error creating ship owner:', error)
    message.error('Gagal mendaftarkan ship owner: ' + error.message)
  } finally {
    submitting.value = false
  }
}

const resetForm = () => {
  newShipOwner.value = {
    shipOwnerId: '',
    address: '',
    name: '',
    companyName: ''
  }
}

onMounted(() => {
  loadShipOwners()
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