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
            <h1 class="text-xl font-semibold text-gray-900">终端管理</h1>
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
            @click="loadTerminals"
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
            添加终端
          </button>
        </div>
        <div class="text-sm text-gray-500">
          总计: {{ terminals.length }} 个终端，在线: {{ onlineCount }} 个
        </div>
      </div>

      <!-- 终端列表 -->
      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul class="divide-y divide-gray-200">
          <li v-for="terminal in terminals" :key="terminal.id" class="px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="h-3 w-3 rounded-full" :class="{
                    'bg-green-400': terminal.status === 'online',
                    'bg-red-400': terminal.status === 'offline'
                  }"></div>
                </div>
                <div class="ml-4">
                  <div class="flex items-center">
                    <p class="text-sm font-medium text-gray-900">{{ terminal.name }}</p>
                    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium" :class="{
                      'bg-green-100 text-green-800': terminal.status === 'online',
                      'bg-red-100 text-red-800': terminal.status === 'offline'
                    }">
                      {{ terminal.status === 'online' ? '在线' : '离线' }}
                    </span>
                  </div>
                  <p class="text-sm text-gray-500">ID: {{ terminal.id }}</p>
                  <p v-if="terminal.description" class="text-sm text-gray-500">{{ terminal.description }}</p>
                  <p class="text-xs text-gray-400">
                    最后心跳: {{ terminal.last_heartbeat ? formatDate(terminal.last_heartbeat) : '无' }}
                  </p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <router-link
                  :to="`/terminals/${terminal.id}`"
                  class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                >
                  查看详情
                </router-link>
                <button
                  @click="editTerminal(terminal)"
                  class="text-blue-600 hover:text-blue-900 text-sm font-medium"
                >
                  编辑
                </button>
                <button
                  @click="deleteTerminal(terminal)"
                  class="text-red-600 hover:text-red-900 text-sm font-medium"
                >删除</button>
              </div>
            </div>
          </li>
        </ul>
        
        <div v-if="terminals.length === 0" class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">暂无终端</h3>
          <p class="mt-1 text-sm text-gray-500">开始添加第一个终端设备</p>
        </div>
      </div>
    </div>

    <!-- 创建/编辑终端模态框 -->
    <div v-if="showCreateModal || showEditModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            {{ showCreateModal ? '添加终端' : '编辑终端' }}
          </h3>
          <form @submit.prevent="submitForm">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">终端ID</label>
              <input
                v-model="form.id"
                type="text"
                required
                :disabled="showEditModal"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 disabled:bg-gray-100"
                placeholder="输入终端ID"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">终端名称</label>
              <input
                v-model="form.name"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入终端名称"
              />
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">描述</label>
              <textarea
                v-model="form.description"
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="输入终端描述（可选）"
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
                确定要删除终端 "{{ deletingTerminal?.name }}" 吗？
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
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { ApiService, type Terminal, type TerminalCreate } from '@/lib/api'

const { user, logout } = useAuth()
const terminals = ref<Terminal[]>([])
const isLoading = ref(false)
const isSubmitting = ref(false)
const showCreateModal = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editingTerminal = ref<Terminal | null>(null)
const deletingTerminal = ref<Terminal | null>(null)

const form = ref({
  id: 0,
  name: '',
  description: ''
})

const onlineCount = computed(() => {
  return terminals.value.filter(t => t.status === 'online').length
})

const handleLogout = async () => {
  await logout()
}

const loadTerminals = async () => {
  try {
    isLoading.value = true
    terminals.value = await ApiService.getTerminals()
  } catch (error) {
    console.error('加载终端列表失败:', error)
    alert('加载终端列表失败')
  } finally {
    isLoading.value = false
  }
}

const editTerminal = (terminal: Terminal) => {
  editingTerminal.value = terminal
  form.value = {
    id: terminal.id,
    name: terminal.name,
    description: terminal.description || ''
  }
  showEditModal.value = true
}

const deleteTerminal = (terminal: Terminal) => {
  deletingTerminal.value = terminal
  showDeleteModal.value = true
}

const confirmDelete = async () => {
  if (!deletingTerminal.value) return
  
  try {
    await ApiService.deleteTerminal(deletingTerminal.value.id)
    await loadTerminals()
    showDeleteModal.value = false
    deletingTerminal.value = null
  } catch (error) {
    console.error('删除终端失败:', error)
    alert('删除终端失败')
  }
}

const cancelDelete = () => {
  showDeleteModal.value = false
  deletingTerminal.value = null
}

const submitForm = async () => {
  try {
    isSubmitting.value = true
    
    if (showCreateModal.value) {
      // 创建终端时生成唯一的terminal_id
      const terminalId = `terminal_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      await ApiService.createTerminal({
        terminal_id: terminalId,
        name: form.value.name,
        description: form.value.description
      })
    } else if (showEditModal.value && editingTerminal.value) {
      await ApiService.updateTerminal(editingTerminal.value.id, {
        name: form.value.name,
        description: form.value.description
      })
    }
    
    await loadTerminals()
    closeModal()
  } catch (error) {
    console.error('保存终端失败:', error)
    alert('保存终端失败')
  } finally {
    isSubmitting.value = false
  }
}

const closeModal = () => {
  showCreateModal.value = false
  showEditModal.value = false
  editingTerminal.value = null
  form.value = {
    id: 0,
    name: '',
    description: ''
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(() => {
  loadTerminals()
})
</script>