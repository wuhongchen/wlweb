<template>
  <div class="min-h-screen bg-gray-50">
    <!-- 导航栏 -->
    <nav class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center space-x-4">
            <router-link to="/dashboard" class="text-gray-500 hover:text-gray-700">
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </router-link>
            <h1 class="text-xl font-semibold text-gray-900">账号资产管理</h1>
          </div>
          <div class="flex items-center space-x-4">
            <span class="text-sm text-gray-700">{{ user?.username }}</span>
            <button
              @click="handleLogout"
              class="bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded-md text-sm font-medium"
            >
              退出登录
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- 主要内容 -->
    <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <!-- 操作栏 -->
      <div class="mb-6 flex justify-between items-center">
        <div class="flex items-center space-x-4">
          <button
            @click="loadAccountAssets"
            :disabled="isLoading"
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
          >
            <svg v-if="isLoading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            刷新
          </button>
          <button
            @click="showCreateModal = true"
            class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium"
          >
            添加账号
          </button>
        </div>
        
        <!-- 筛选器 -->
        <div class="flex items-center space-x-4">
          <select
            v-model="selectedRegion"
            @change="loadAccountAssets"
            class="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            <option value="">所有游戏区域</option>
            <option v-for="region in regions" :key="region.id" :value="region.region_code">{{ region.region_name }} ({{ region.region_code }})</option>
          </select>
          
          <select
            v-model="selectedTerminalId"
            @change="loadAccountAssets"
            class="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            <option value="">所有终端</option>
            <option v-for="terminal in terminals" :key="terminal.id" :value="terminal.id">{{ terminal.name }}</option>
          </select>
          
          <div class="text-sm text-gray-500">
            总计: {{ accountAssets.length }} 个账号
          </div>
        </div>
      </div>

      <!-- 账号资产列表 -->
      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul class="divide-y divide-gray-200">
          <li v-for="asset in accountAssets" :key="asset.id" class="px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                    <svg class="h-6 w-6 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                </div>
                <div class="ml-4">
                  <div class="flex items-center">
                    <p class="text-sm font-medium text-gray-900">{{ asset.account }}</p>
                    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {{ asset.region_code }}
                    </span>
                  </div>
                  <p class="text-sm text-gray-500">密码: {{ visiblePasswords.has(asset.id) ? asset.password : maskPassword(asset.password) }}</p>
                  <div class="flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-500">
                    <p v-if="asset.server_name">服务器: {{ asset.server_name }}</p>
                    <p v-if="asset.level">等级: {{ asset.level }}</p>
                    <p v-if="asset.character_name">角色名: {{ asset.character_name }}</p>
                    <p v-if="asset.character_id">角色ID: {{ asset.character_id }}</p>
                  </div>
                  <p v-if="asset.terminal" class="text-sm text-gray-500">
                    绑定终端: {{ asset.terminal.name }}
                    <span class="ml-1 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium" :class="{
                      'bg-green-100 text-green-800': asset.terminal.status === 'online',
                      'bg-red-100 text-red-800': asset.terminal.status === 'offline'
                    }">
                      {{ asset.terminal.status === 'online' ? '在线' : '离线' }}
                    </span>
                  </p>
                  <p v-else class="text-sm text-gray-500">未绑定终端</p>
                  <p v-if="asset.description" class="text-sm text-gray-500">{{ asset.description }}</p>
                  <p class="text-xs text-gray-400">
                    创建时间: {{ formatDate(asset.created_at) }}
                  </p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  @click="togglePasswordVisibility(asset.id)"
                  class="text-gray-600 hover:text-gray-900 text-sm font-medium"
                >
                  {{ visiblePasswords.has(asset.id) ? '隐藏' : '显示' }}密码
                </button>
                <button
                  @click="editAccountAsset(asset)"
                  class="text-blue-600 hover:text-blue-900 text-sm font-medium"
                >
                  编辑
                </button>
                <button
                  @click="deleteAccountAsset(asset)"
                  class="text-red-600 hover:text-red-900 text-sm font-medium"
                >删除</button>
              </div>
            </div>
          </li>
        </ul>
        
        <div v-if="accountAssets.length === 0" class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">暂无账号资产</h3>
          <p class="mt-1 text-sm text-gray-500">开始添加第一个账号资产</p>
        </div>
      </div>
    </div>

    <!-- 创建/编辑账号资产模态框 -->
    <div v-if="showCreateModal || showEditModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            {{ showCreateModal ? '添加账号资产' : '编辑账号资产' }}
          </h3>
          <form @submit.prevent="submitForm">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">账号</label>
              <input
                v-model="form.account"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入账号"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">密码</label>
              <input
                v-model="form.password"
                type="password"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入密码"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">所属游戏区域</label>
              <select
                v-model="form.region_code"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="">请选择游戏区域</option>
                <option v-for="region in regions" :key="region.id" :value="region.region_code">{{ region.region_name }} ({{ region.region_code }})</option>
              </select>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">绑定终端</label>
              <select
                v-model="form.terminal_id"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="">不绑定终端</option>
                <option v-for="terminal in terminals" :key="terminal.id" :value="terminal.id">{{ terminal.name }}</option>
              </select>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">服务器名称</label>
              <input
                v-model="form.server_name"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入服务器名称（如：先锋1区）"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">角色等级</label>
              <input
                v-model.number="form.level"
                type="number"
                min="1"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入角色等级"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">角色名称</label>
              <input
                v-model="form.character_name"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入角色名称"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">角色ID</label>
              <input
                v-model="form.character_id"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入角色ID"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">备注描述</label>
              <textarea
                v-model="form.description"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入备注描述（可选）"
              ></textarea>
            </div>
            <div class="flex justify-end space-x-3">
              <button
                type="button"
                @click="closeModal"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
              >
                取消
              </button>
              <button
                type="submit"
                :disabled="isSubmitting"
                class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 disabled:opacity-50"
              >
                {{ isSubmitting ? '保存中...' : '保存' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- 删除确认对话框 -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
            <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <div class="mt-2 text-center">
            <h3 class="text-lg font-medium text-gray-900">确认删除</h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500">
                确定要删除账号 "{{ deletingAsset?.account }}" 吗？
              </p>
              <p class="text-sm text-gray-400 mt-1">
                此操作无法撤销。
              </p>
            </div>
            <div class="flex justify-center space-x-4 px-4 py-3">
              <button
                @click="cancelDelete"
                class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                取消
              </button>
              <button
                @click="confirmDelete"
                class="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                删除
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { ApiService, type AccountAssetWithTerminal, type Terminal, type Region } from '@/lib/api'

const { user, logout } = useAuth()
const accountAssets = ref<AccountAssetWithTerminal[]>([])
const terminals = ref<Terminal[]>([])
const regions = ref<Region[]>([])
const isLoading = ref(false)
const isSubmitting = ref(false)
const showCreateModal = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editingAsset = ref<AccountAssetWithTerminal | null>(null)
const deletingAsset = ref<AccountAssetWithTerminal | null>(null)
const selectedRegion = ref('')
const selectedTerminalId = ref('')
const visiblePasswords = ref(new Set<number>())

const form = ref({
  account: '',
  password: '',
  region_code: '',
  terminal_id: '',
  description: '',
  server_name: '',
  level: null as number | null,
  character_name: '',
  character_id: ''
})

const handleLogout = async () => {
  await logout()
}

const loadAccountAssets = async () => {
  try {
    isLoading.value = true
    const regionCode = selectedRegion.value || undefined
    const terminalId = selectedTerminalId.value ? parseInt(selectedTerminalId.value) : undefined
    accountAssets.value = await ApiService.getAccountAssets(regionCode, terminalId)
  } catch (error) {
    console.error('加载账号资产列表失败:', error)
    alert('加载账号资产列表失败')
  } finally {
    isLoading.value = false
  }
}

const loadTerminals = async () => {
  try {
    terminals.value = await ApiService.getTerminals()
  } catch (error) {
    console.error('加载终端列表失败:', error)
  }
}

const loadRegions = async () => {
  try {
    regions.value = await ApiService.getRegionConfigs()
  } catch (error) {
    console.error('加载区域列表失败:', error)
  }
}

const editAccountAsset = (asset: AccountAssetWithTerminal) => {
  editingAsset.value = asset
  form.value = {
    account: asset.account,
    password: asset.password,
    region_code: asset.region_code,
    terminal_id: asset.terminal_id?.toString() || '',
    description: asset.description || '',
    server_name: asset.server_name || '',
    level: asset.level || null,
    character_name: asset.character_name || '',
    character_id: asset.character_id || ''
  }
  showEditModal.value = true
}

const deleteAccountAsset = (asset: AccountAssetWithTerminal) => {
  deletingAsset.value = asset
  showDeleteModal.value = true
}

const confirmDelete = async () => {
  if (!deletingAsset.value) return
  
  try {
    await ApiService.deleteAccountAsset(deletingAsset.value.id)
    await loadAccountAssets()
    await loadRegions()
    showDeleteModal.value = false
    deletingAsset.value = null
  } catch (error) {
    console.error('删除账号资产失败:', error)
    alert('删除账号资产失败')
  }
}

const cancelDelete = () => {
  showDeleteModal.value = false
  deletingAsset.value = null
}

const submitForm = async () => {
  try {
    isSubmitting.value = true
    
    const formData = {
      account: form.value.account,
      password: form.value.password,
      region_code: form.value.region_code,
      terminal_id: form.value.terminal_id ? parseInt(form.value.terminal_id) : undefined,
      description: form.value.description || undefined
    }
    
    if (showCreateModal.value) {
      await ApiService.createAccountAsset(formData)
    } else if (showEditModal.value && editingAsset.value) {
      await ApiService.updateAccountAsset(editingAsset.value.id, formData)
    }
    
    await loadAccountAssets()
    await loadRegions()
    closeModal()
  } catch (error) {
    console.error('保存账号资产失败:', error)
    alert('保存账号资产失败')
  } finally {
    isSubmitting.value = false
  }
}

const closeModal = () => {
  showCreateModal.value = false
  showEditModal.value = false
  editingAsset.value = null
  form.value = {
    account: '',
    password: '',
    region_code: '',
    terminal_id: '',
    description: '',
    server_name: '',
    level: null,
    character_name: '',
    character_id: ''
  }
}

const togglePasswordVisibility = (assetId: number) => {
  if (visiblePasswords.value.has(assetId)) {
    visiblePasswords.value.delete(assetId)
  } else {
    visiblePasswords.value.add(assetId)
  }
}

const maskPassword = (password: string) => {
  return '*'.repeat(password.length)
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(async () => {
  await Promise.all([
    loadAccountAssets(),
    loadTerminals(),
    loadRegions()
  ])
})
</script>