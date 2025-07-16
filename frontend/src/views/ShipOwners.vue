<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px">
      <n-h2>Daftar Ship Owner</n-h2>
      <n-button 
        v-if="userStore.isAuthority()" 
        type="primary" 
        @click="showAddModal = true"
      >
        Daftarkan Ship Owner Baru
      </n-button>
      
      <!-- Debug info -->
      <div style="font-size: 12px; color: #666; margin-top: 8px;">
        Debug: Role={{ userStore.role }}, IsAuthority={{ userStore.isAuthority() }}
      </div>
    </div>

    <n-space vertical size="large">
      <n-input
        v-model:value="searchQuery"
        placeholder="Cari ship owner berdasarkan nama atau perusahaan..."
        clearable
      >
        <template #prefix>
          <n-icon :component="SearchIcon" />
        </template>
      </n-input>

      <n-data-table
        :columns="columns"
        :data="filteredShipOwners"
        :loading="loading"
        :pagination="pagination"
      />
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
    const response = await shipOwnerApi.getAll()
    shipOwners.value = response.data?.map(item => ({
      ...item.Record,
      key: item.Key
    })) || []
  } catch (error) {
    message.error('Gagal memuat data ship owner: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleAddShipOwner = async () => {
  try {
    await formRef.value?.validate()
    submitting.value = true
    
    await shipOwnerApi.create(newShipOwner.value)
    
    message.success('Ship Owner berhasil didaftarkan')
    showAddModal.value = false
    resetForm()
    await loadShipOwners()
  } catch (error) {
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