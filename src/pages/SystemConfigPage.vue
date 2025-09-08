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
            <h1 class="text-xl font-semibold text-gray-900">系统配置</h1>
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
    <div class="max-w-6xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="space-y-6">
        <!-- 标签页导航 -->
        <div class="bg-white shadow sm:rounded-lg">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                @click="activeTab = 'regions'"
                :class="[
                  activeTab === 'regions'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
                  'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                ]"
              >
                游戏区域
              </button>
              <button
                @click="activeTab = 'configs'"
                :class="[
                  activeTab === 'configs'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
                  'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                ]"
              >
                系统配置
              </button>
            </nav>
          </div>
        </div>

        <!-- 区域管理 -->
        <div v-if="activeTab === 'regions'" class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">游戏区域管理</h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">管理游戏服务器区域配置（S1-S255）</p>
            </div>
            <button
              @click="showRegionModal = true; editingRegion = null"
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
            >
              添加游戏区域
            </button>
          </div>
          <div class="border-t border-gray-200">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">服务器编号</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">服务器名称</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">描述</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">状态</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="region in regions" :key="region.id">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ region.region_code }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ region.region_name }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ region.description || '-' }}</td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span :class="[
                        region.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800',
                        'inline-flex px-2 py-1 text-xs font-semibold rounded-full'
                      ]">
                        {{ region.is_active ? '启用' : '禁用' }}
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                      <button
                        @click="editRegion(region)"
                        class="text-indigo-600 hover:text-indigo-900"
                      >
                        编辑
                      </button>
                      <button
                        @click="showDeleteRegionConfirm(region)"
                        class="text-red-600 hover:text-red-900"
                      >
                        删除
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- 系统配置 -->
        <div v-if="activeTab === 'configs'" class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">系统配置</h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">管理系统全局配置参数</p>
            </div>
            <button
              @click="showConfigModal = true; editingConfig = null"
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
            >
              添加配置
            </button>
          </div>
          <div class="border-t border-gray-200">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">配置键</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">配置值</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">描述</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">更新时间</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="config in configs" :key="config.id">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ config.config_key }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ config.config_value }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ config.description || '-' }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ formatDate(config.updated_at) }}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                      <button
                        @click="editConfig(config)"
                        class="text-indigo-600 hover:text-indigo-900"
                      >
                        编辑
                      </button>
                      <button
                        @click="showDeleteConfigConfirm(config)"
                        class="text-red-600 hover:text-red-900"
                      >
                        删除
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 区域编辑模态框 -->
    <div v-if="showRegionModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            {{ editingRegion ? '编辑游戏区域' : '添加游戏区域' }}
          </h3>
          <form @submit.prevent="saveRegion">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">服务器编号</label>
                <input
                  v-model="regionForm.region_code"
                  type="text"
                  required
                  :disabled="!!editingRegion"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="如：S1、S2、S100"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">服务器名称</label>
                <input
                  v-model="regionForm.region_name"
                  type="text"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="如：华山之巅、剑侠情缘、天龙八部"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">描述</label>
                <textarea
                  v-model="regionForm.description"
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="游戏服务器区域描述信息"
                ></textarea>
              </div>
              <div class="flex items-center">
                <input
                  v-model="regionForm.is_active"
                  type="checkbox"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                />
                <label class="ml-2 block text-sm text-gray-900">启用此游戏区域</label>
              </div>
            </div>
            <div class="flex justify-end space-x-3 mt-6">
              <button
                type="button"
                @click="showRegionModal = false"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 rounded-md"
              >
                取消
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md"
              >
                保存
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- 配置编辑模态框 -->
    <div v-if="showConfigModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            {{ editingConfig ? '编辑配置' : '添加配置' }}
          </h3>
          <form @submit.prevent="saveConfig">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">配置键</label>
                <input
                  v-model="configForm.config_key"
                  type="text"
                  required
                  :disabled="!!editingConfig"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="如：default_region"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">配置值</label>
                <input
                  v-model="configForm.config_value"
                  type="text"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="配置值"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">描述</label>
                <textarea
                  v-model="configForm.description"
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="配置描述信息"
                ></textarea>
              </div>
            </div>
            <div class="flex justify-end space-x-3 mt-6">
              <button
                type="button"
                @click="showConfigModal = false"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 rounded-md"
              >
                取消
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md"
              >
                保存
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>

  <!-- 删除区域确认对话框 -->
  <div v-if="showDeleteRegionModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
          <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </div>
        <div class="mt-2 text-center">
          <h3 class="text-lg font-medium text-gray-900">确认删除区域</h3>
          <div class="mt-2 px-7 py-3">
            <p class="text-sm text-gray-500">
              确定要删除区域 "{{ deletingRegion?.region_name }}" 吗？
            </p>
            <p class="text-sm text-gray-400 mt-1">
              此操作不可撤销。
            </p>
          </div>
          <div class="flex justify-center space-x-4 px-4 py-3">
            <button
              @click="cancelDeleteRegion"
              class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
            >
              取消
            </button>
            <button
              @click="deleteRegion"
              class="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
            >
              删除
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 删除配置确认对话框 -->
  <div v-if="showDeleteConfigModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
          <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </div>
        <div class="mt-2 text-center">
          <h3 class="text-lg font-medium text-gray-900">确认删除配置</h3>
          <div class="mt-2 px-7 py-3">
            <p class="text-sm text-gray-500">
              确定要删除配置 "{{ deletingConfig?.config_key }}" 吗？
            </p>
            <p class="text-sm text-gray-400 mt-1">
              此操作不可撤销。
            </p>
          </div>
          <div class="flex justify-center space-x-4 px-4 py-3">
            <button
              @click="cancelDeleteConfig"
              class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
            >
              取消
            </button>
            <button
              @click="deleteConfig"
              class="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
            >
              删除
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import api from '../lib/api'

interface Region {
  id: number
  region_code: string
  region_name: string
  description?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

interface SystemConfig {
  id: number
  config_key: string
  config_value: string
  description?: string
  created_at: string
  updated_at: string
}

const router = useRouter()
const { user, logout } = useAuth()

// 状态管理
const activeTab = ref('regions')
const regions = ref<Region[]>([])
const configs = ref<SystemConfig[]>([])
const loading = ref(false)

// 模态框状态
const showRegionModal = ref(false)
const showConfigModal = ref(false)
const showDeleteRegionModal = ref(false)
const showDeleteConfigModal = ref(false)
const editingRegion = ref<Region | null>(null)
const editingConfig = ref<SystemConfig | null>(null)
const deletingRegion = ref<Region | null>(null)
const deletingConfig = ref<SystemConfig | null>(null)

// 表单数据
const regionForm = ref({
  region_code: '',
  region_name: '',
  description: '',
  is_active: true
})

const configForm = ref({
  config_key: '',
  config_value: '',
  description: ''
})

// 加载数据
const loadRegions = async () => {
  try {
    loading.value = true
    const response = await api.get('/system-config/regions')
    regions.value = response.data
  } catch (error) {
    console.error('加载区域列表失败:', error)
  } finally {
    loading.value = false
  }
}

const loadConfigs = async () => {
  try {
    loading.value = true
    const response = await api.get('/system-config/configs')
    configs.value = response.data
  } catch (error) {
    console.error('加载配置列表失败:', error)
  } finally {
    loading.value = false
  }
}

// 区域管理
const editRegion = (region: Region) => {
  editingRegion.value = region
  regionForm.value = {
    region_code: region.region_code,
    region_name: region.region_name,
    description: region.description || '',
    is_active: region.is_active
  }
  showRegionModal.value = true
}

const saveRegion = async () => {
  try {
    if (editingRegion.value) {
      await api.put(`/system-config/regions/${editingRegion.value.id}`, regionForm.value)
    } else {
      await api.post('/system-config/regions', regionForm.value)
    }
    showRegionModal.value = false
    resetRegionForm()
    await loadRegions()
  } catch (error) {
    console.error('保存区域失败:', error)
  }
}

const showDeleteRegionConfirm = (region: Region) => {
  deletingRegion.value = region
  showDeleteRegionModal.value = true
}

const cancelDeleteRegion = () => {
  showDeleteRegionModal.value = false
  deletingRegion.value = null
}

const deleteRegion = async () => {
  if (!deletingRegion.value) return
  
  try {
    await api.delete(`/system-config/regions/${deletingRegion.value.id}`)
    await loadRegions()
    showDeleteRegionModal.value = false
    deletingRegion.value = null
  } catch (error) {
    console.error('删除区域失败:', error)
  }
}

const resetRegionForm = () => {
  regionForm.value = {
    region_code: '',
    region_name: '',
    description: '',
    is_active: true
  }
  editingRegion.value = null
}

// 配置管理
const editConfig = (config: SystemConfig) => {
  editingConfig.value = config
  configForm.value = {
    config_key: config.config_key,
    config_value: config.config_value,
    description: config.description || ''
  }
  showConfigModal.value = true
}

const saveConfig = async () => {
  try {
    if (editingConfig.value) {
      await api.put(`/system-config/configs/${editingConfig.value.id}`, configForm.value)
    } else {
      await api.post('/system-config/configs', configForm.value)
    }
    showConfigModal.value = false
    resetConfigForm()
    await loadConfigs()
  } catch (error) {
    console.error('保存配置失败:', error)
  }
}

const showDeleteConfigConfirm = (config: SystemConfig) => {
  deletingConfig.value = config
  showDeleteConfigModal.value = true
}

const cancelDeleteConfig = () => {
  showDeleteConfigModal.value = false
  deletingConfig.value = null
}

const deleteConfig = async () => {
  if (!deletingConfig.value) return
  
  try {
    await api.delete(`/system-config/configs/${deletingConfig.value.id}`)
    await loadConfigs()
    showDeleteConfigModal.value = false
    deletingConfig.value = null
  } catch (error) {
    console.error('删除配置失败:', error)
  }
}

const resetConfigForm = () => {
  configForm.value = {
    config_key: '',
    config_value: '',
    description: ''
  }
  editingConfig.value = null
}

// 工具函数
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

const handleLogout = async () => {
  await logout()
  router.push('/login')
}

// 生命周期
onMounted(() => {
  loadRegions()
  loadConfigs()
})
</script>