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
            <h1 class="text-xl font-semibold text-gray-900">游戏账户管理</h1>
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
            @click="loadGameAccounts"
            :disabled="isLoading"
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
          >
            <svg v-if="isLoading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            刷新
          </button>
          <div class="relative">
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="搜索账户ID或用户名..."
              class="block w-64 pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            >
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>
        </div>
        <div class="text-sm text-gray-500">
          总计: {{ gameAccounts.length }} 个游戏账户
        </div>
      </div>

      <!-- 游戏账户列表 -->
      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul class="divide-y divide-gray-200">
          <li v-for="account in filteredAccounts" :key="account.id" class="px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center flex-1">
                <div class="flex-shrink-0">
                  <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                    <span class="text-sm font-medium text-indigo-600">{{ account.level || 'N/A' }}</span>
                  </div>
                </div>
                <div class="ml-4 flex-1">
                  <div class="flex items-center">
                    <p class="text-sm font-medium text-gray-900">{{ account.account_id }}</p>
                    <span v-if="account.level" class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      Lv.{{ account.level }}
                    </span>
                    <span v-if="account.server_name" class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      {{ account.server_name }}
                    </span>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2 mt-2">
                    <p v-if="account.username" class="text-sm text-gray-600">
                      <span class="font-medium text-gray-800">角色名称:</span> {{ account.username }}
                    </p>
                    <p v-if="account.account_id" class="text-sm text-gray-600">
                      <span class="font-medium text-gray-800">账户ID:</span> {{ account.account_id }}
                    </p>
                    <p v-if="account.server_name" class="text-sm text-gray-600">
                      <span class="font-medium text-gray-800">服务器:</span> {{ account.server_name }}
                    </p>
                    <p v-if="account.level" class="text-sm text-gray-600">
                      <span class="font-medium text-gray-800">等级:</span> {{ account.level }}
                    </p>
                    <p v-if="account.last_login_time" class="text-xs text-gray-400">
                      最后登录: {{ formatDate(account.last_login_time) }}
                    </p>
                    <p v-if="account.last_terminal_id" class="text-xs text-gray-400">
                      终端: {{ account.last_terminal_id }}
                    </p>
                  </div>
                  <!-- 资产信息 -->
                  <div class="flex items-center space-x-4 mt-2">
                    <div class="flex items-center">
                      <span class="text-xs text-yellow-600 font-medium">💰 金币:</span>
                      <span class="ml-1 text-sm font-medium text-gray-900">{{ account.latestAssets?.gold || 0 }}</span>
                    </div>
                    <div class="flex items-center">
                      <span class="text-xs text-blue-600 font-medium">💎 元宝:</span>
                      <span class="ml-1 text-sm font-medium text-gray-900">{{ account.latestAssets?.diamond || 0 }}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  @click="openAccountModal(account)"
                  class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                >
                  查看详情
                </button>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <!-- 账户详情弹窗 -->
    <div v-if="showModal" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- 背景遮罩 -->
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" @click="closeModal"></div>

        <!-- 弹窗内容 -->
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                {{ selectedAccount?.account_id }} - 详细信息
              </h3>
              <button
                @click="closeModal"
                class="text-gray-400 hover:text-gray-600"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <!-- 标签页导航 -->
            <div class="border-b border-gray-200 mb-4">
              <nav class="-mb-px flex space-x-8" aria-label="Tabs">
                <button
                  v-for="tab in tabs"
                  :key="tab.key"
                  @click="handleTabChange(tab.key)"
                  :class="[
                    activeTab === tab.key
                      ? 'border-indigo-500 text-indigo-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
                    'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                  ]"
                >
                  {{ tab.label }}
                </button>
              </nav>
            </div>

            <!-- 标签页内容 -->
            <div class="max-h-96 overflow-y-auto">
              <!-- 基本信息标签页 -->
              <div v-if="activeTab === 'basic'">
                <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
                  <div>
                    <dt class="text-sm font-medium text-gray-500">账户ID</dt>
                    <dd class="mt-1 text-sm text-gray-900 font-mono">{{ selectedAccount?.account_id }}</dd>
                  </div>
                  <div v-if="selectedAccount?.username">
                    <dt class="text-sm font-medium text-gray-500">角色名称</dt>
                    <dd class="mt-1 text-sm text-gray-900 font-medium">{{ selectedAccount.username }}</dd>
                  </div>
                  <div v-if="selectedAccount?.level">
                    <dt class="text-sm font-medium text-gray-500">等级</dt>
                    <dd class="mt-1 text-sm text-gray-900">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        Lv.{{ selectedAccount.level }}
                      </span>
                    </dd>
                  </div>
                  <div v-if="selectedAccount?.server_name">
                    <dt class="text-sm font-medium text-gray-500">服务器</dt>
                    <dd class="mt-1 text-sm text-gray-900">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        {{ selectedAccount.server_name }}
                      </span>
                    </dd>
                  </div>
                  <div v-if="selectedAccount?.last_terminal_id">
                    <dt class="text-sm font-medium text-gray-500">最后使用终端</dt>
                    <dd class="mt-1 text-sm text-gray-900">{{ selectedAccount.last_terminal_id }}</dd>
                  </div>
                  <div v-if="selectedAccount?.last_login_time">
                    <dt class="text-sm font-medium text-gray-500">最后登录时间</dt>
                    <dd class="mt-1 text-sm text-gray-900">{{ formatDate(selectedAccount.last_login_time) }}</dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-500">创建时间</dt>
                    <dd class="mt-1 text-sm text-gray-900">{{ formatDate(selectedAccount?.created_at) }}</dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-500">更新时间</dt>
                    <dd class="mt-1 text-sm text-gray-900">{{ formatDate(selectedAccount?.updated_at) }}</dd>
                  </div>
                </dl>
              </div>

              <!-- 资产记录标签页 -->
              <div v-else-if="activeTab === 'assets'">
                <div v-if="loadingAssets" class="text-center py-4">
                  <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                  <p class="mt-2 text-sm text-gray-500">加载中...</p>
                </div>
                <div v-else-if="assetRecords.length === 0" class="text-center py-8">
                  <p class="text-gray-500">暂无资产记录</p>
                </div>
                <div v-else class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">时间</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">金币</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">元宝</th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <tr v-for="record in assetRecords" :key="record.id">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ formatDate(record.report_time) }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.gold || '-' }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.diamond || '-' }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- 背包记录标签页 -->
              <div v-else-if="activeTab === 'inventory'">
                <div v-if="loadingInventory" class="text-center py-4">
                  <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                  <p class="mt-2 text-sm text-gray-500">加载中...</p>
                </div>
                <div v-else-if="inventoryRecords.length === 0" class="text-center py-8">
                  <p class="text-gray-500">暂无背包记录</p>
                </div>
                <div v-else class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">时间</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">物品名称</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">类型</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">数量</th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <tr v-for="record in inventoryRecords" :key="record.id">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ formatDate(record.report_time) }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.item_name }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.item_type }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.quantity }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- 登录记录标签页 -->
              <div v-else-if="activeTab === 'login'">
                <div v-if="loadingLogin" class="text-center py-4">
                  <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                  <p class="mt-2 text-sm text-gray-500">加载中...</p>
                </div>
                <div v-else-if="loginRecords.length === 0" class="text-center py-8">
                  <p class="text-gray-500">暂无登录记录</p>
                </div>
                <div v-else class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">终端ID</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">用户名</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">登录时间</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">登录IP</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">登录设备</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">游戏服务器</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">登录状态</th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <tr v-for="record in loginRecords" :key="record.id">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.terminal_id }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.username || '-' }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ formatDate(record.login_time) }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.login_ip || '-' }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.login_device || '-' }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ record.game_server || '-' }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium" :class="record.login_status === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'">
                            {{ record.login_status || 'success' }}
                          </span>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ApiService } from '../lib/api'

const router = useRouter()

// 响应式数据
const gameAccounts = ref([])
const selectedAccount = ref(null)
const searchQuery = ref('')
const activeTab = ref('basic')
const assetRecords = ref([])
const inventoryRecords = ref([])
const loginRecords = ref([])
const loadingAssets = ref(false)
const loadingInventory = ref(false)
const loadingLogin = ref(false)
const isLoading = ref(false)
// 获取用户信息
const getUserInfo = () => {
  try {
    const userInfo = localStorage.getItem('user_info')
    if (userInfo && userInfo !== 'undefined') {
      return JSON.parse(userInfo)
    }
  } catch (error) {
    console.error('解析用户信息失败:', error)
  }
  return { username: 'User' }
}

const user = ref(getUserInfo())

// 标签页配置
const tabs = [
  { key: 'basic', label: '基本信息' },
  { key: 'assets', label: '资产记录' },
  { key: 'inventory', label: '背包记录' },
  { key: 'login', label: '登录记录' }
]

// 计算属性
const filteredAccounts = computed(() => {
  if (!searchQuery.value) return gameAccounts.value
  const query = searchQuery.value.toLowerCase()
  return gameAccounts.value.filter(account => 
    account.account_id.toLowerCase().includes(query) ||
    (account.username && account.username.toLowerCase().includes(query))
  )
})

// 方法
const loadGameAccounts = async () => {
  isLoading.value = true
  try {
    const accounts = await ApiService.getGameAccounts()
    // 为每个账户获取最新的资产数据
    for (const account of accounts) {
      try {
        const assetRecords = await ApiService.getGameAccountAssetRecords(account.account_id)
        // 获取最新的资产记录
        if (assetRecords.length > 0) {
          const latestAsset = assetRecords.sort((a, b) => new Date(b.report_time) - new Date(a.report_time))[0]
          account.latestAssets = {
            gold: latestAsset.gold,
            diamond: latestAsset.diamond
          }
        } else {
          account.latestAssets = {
            gold: 0,
            diamond: 0
          }
        }
      } catch (error) {
        console.error(`获取账户 ${account.account_id} 资产数据失败:`, error)
        account.latestAssets = {
          gold: 0,
          diamond: 0
        }
      }
    }
    gameAccounts.value = accounts
  } catch (error) {
    console.error('加载游戏账户失败:', error)
  } finally {
    isLoading.value = false
  }
}

const handleLogout = () => {
  localStorage.removeItem('access_token')
  localStorage.removeItem('user_info')
  router.push('/login')
}

const showModal = ref(false)

const openAccountModal = async (account) => {
  selectedAccount.value = account
  showModal.value = true
  activeTab.value = 'basic'
  
  // 清空之前的记录
  assetRecords.value = []
  inventoryRecords.value = []
  loginRecords.value = []
}

const closeModal = () => {
  showModal.value = false
  selectedAccount.value = null
}

const loadAssetRecords = async () => {
  if (!selectedAccount.value) return
  
  loadingAssets.value = true
  try {
    assetRecords.value = await ApiService.getGameAccountAssetRecords(selectedAccount.value.account_id)
  } catch (error) {
    console.error('加载资产记录失败:', error)
  } finally {
    loadingAssets.value = false
  }
}

const loadInventoryRecords = async () => {
  if (!selectedAccount.value) return
  
  loadingInventory.value = true
  try {
    inventoryRecords.value = await ApiService.getGameAccountInventoryRecords(selectedAccount.value.account_id)
  } catch (error) {
    console.error('加载背包记录失败:', error)
  } finally {
    loadingInventory.value = false
  }
}

const loadLoginRecords = async () => {
  if (!selectedAccount.value) return
  
  loadingLogin.value = true
  try {
    loginRecords.value = await ApiService.getGameAccountLoginRecords(selectedAccount.value.account_id)
  } catch (error) {
    console.error('加载登录记录失败:', error)
  } finally {
    loadingLogin.value = false
  }
}

const refreshData = async () => {
  await loadGameAccounts()
  if (selectedAccount.value) {
    await openAccountModal(selectedAccount.value)
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString('zh-CN')
}

// 监听标签页切换
const handleTabChange = async (tab) => {
  activeTab.value = tab
  
  if (tab === 'assets' && assetRecords.value.length === 0) {
    await loadAssetRecords()
  } else if (tab === 'inventory' && inventoryRecords.value.length === 0) {
    await loadInventoryRecords()
  } else if (tab === 'login' && loginRecords.value.length === 0) {
    await loadLoginRecords()
  }
}

// 生命周期
onMounted(() => {
  loadGameAccounts()
})
</script>