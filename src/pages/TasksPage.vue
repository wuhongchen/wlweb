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
            <h1 class="text-xl font-semibold text-gray-900">任务管理</h1>
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
            @click="loadTasks"
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
            创建任务
          </button>
        </div>
        <div class="text-sm text-gray-500">
          总计: {{ tasks.length }} 个任务
        </div>
      </div>

      <!-- 任务列表 -->
      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul class="divide-y divide-gray-200">
          <li v-for="task in tasks" :key="task.id" class="px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex-1">
                <div class="flex items-center justify-between">
                  <p class="text-sm font-medium text-gray-900">{{ task.name }}</p>
                  <div class="ml-2 flex-shrink-0 flex">
                    <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                      ID: {{ task.id }}
                    </p>
                  </div>
                </div>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">{{ task.description || '无描述' }}</p>
                </div>
                <div class="mt-2 flex items-center text-sm text-gray-500">
                  <p>创建者: {{ task.created_by }}</p>
                  <span class="mx-2">•</span>
                  <p>创建时间: {{ formatDate(task.created_at) }}</p>
                </div>
              </div>
              <div class="flex items-center space-x-2 ml-4">
                <button
                  @click="showExecuteModal(task)"
                  class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-md text-sm font-medium"
                >
                  执行
                </button>
                <router-link
                  :to="`/tasks/${task.id}`"
                  class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                >
                  查看详情
                </router-link>
                <button
                  @click="editTask(task)"
                  class="text-blue-600 hover:text-blue-900 text-sm font-medium"
                >
                  编辑
                </button>
                <button
                  @click="showDeleteConfirm(task)"
                  class="text-red-600 hover:text-red-900 text-sm font-medium"
                >
                  删除
                </button>
              </div>
            </div>
          </li>
        </ul>
        
        <div v-if="tasks.length === 0" class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">暂无任务</h3>
          <p class="mt-1 text-sm text-gray-500">开始创建第一个脚本任务</p>
        </div>
      </div>
    </div>

    <!-- 创建/编辑任务模态框 -->
    <div v-if="showCreateModal || showEditModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-10 mx-auto p-5 border w-3/4 max-w-4xl shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            {{ showCreateModal ? '创建任务' : '编辑任务' }}
          </h3>
          <form @submit.prevent="submitForm">
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">任务名称</label>
                <input
                  v-model="form.name"
                  type="text"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="输入任务名称"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">任务描述</label>
                <textarea
                  v-model="form.description"
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="输入任务描述（可选）"
                ></textarea>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">脚本内容</label>
                <textarea
                  v-model="form.script_content"
                  rows="10"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 font-mono text-sm"
                  placeholder="输入脚本内容"
                ></textarea>
              </div>
            </div>
            <div class="flex justify-end space-x-3 mt-6">
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

    <!-- 执行任务模态框 -->
    <div v-if="showExecuteTaskModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            执行任务: {{ selectedTask?.name }}
          </h3>
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-2">选择终端</label>
            <select
              v-model="executeForm.terminal_id"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="">请选择终端</option>
              <option v-for="terminal in onlineTerminals" :key="terminal.id" :value="terminal.id">
                {{ terminal.name }} ({{ terminal.id }})
              </option>
            </select>
          </div>
          <div class="flex justify-end space-x-3">
            <button
              type="button"
              @click="closeExecuteModal"
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
            >
              取消
            </button>
            <button
              @click="executeTask"
              :disabled="isExecuting || !executeForm.terminal_id"
              class="px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700 disabled:opacity-50"
            >
              {{ isExecuting ? '执行中...' : '执行' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 删除确认对话框 -->
  <div v-if="showDeleteModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
      <div class="mt-3">
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
          <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </div>
        <div class="mt-2 text-center">
          <h3 class="text-lg font-medium text-gray-900">确认删除任务</h3>
          <div class="mt-2 px-7 py-3">
            <p class="text-sm text-gray-500">
              确定要删除任务 "{{ deletingTask?.name }}" 吗？
            </p>
            <p class="text-sm text-gray-400 mt-1">
              此操作不可撤销。
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
              @click="deleteTask"
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
import { useAuth } from '@/composables/useAuth'
import { ApiService, type Task, type Terminal } from '@/lib/api'

const { user, logout } = useAuth()
const tasks = ref<Task[]>([])
const terminals = ref<Terminal[]>([])
const onlineTerminals = ref<Terminal[]>([])
const isLoading = ref(false)
const isSubmitting = ref(false)
const isExecuting = ref(false)
const showCreateModal = ref(false)
const showEditModal = ref(false)
const showExecuteTaskModal = ref(false)
const showDeleteModal = ref(false)
const editingTask = ref<Task | null>(null)
const selectedTask = ref<Task | null>(null)
const deletingTask = ref<Task | null>(null)

const form = ref({
  name: '',
  description: '',
  script_content: ''
})

const executeForm = ref({
  terminal_id: ''
})

const handleLogout = async () => {
  await logout()
}

const loadTasks = async () => {
  try {
    isLoading.value = true
    tasks.value = await ApiService.getTasks()
  } catch (error) {
    console.error('加载任务列表失败:', error)
    alert('加载任务列表失败')
  } finally {
    isLoading.value = false
  }
}

const loadTerminals = async () => {
  try {
    terminals.value = await ApiService.getTerminals()
    onlineTerminals.value = terminals.value.filter(t => t.status === 'online')
  } catch (error) {
    console.error('加载终端列表失败:', error)
  }
}

const editTask = (task: Task) => {
  editingTask.value = task
  form.value = {
    name: task.name,
    description: task.description || '',
    script_content: task.script_content
  }
  showEditModal.value = true
}

const showDeleteConfirm = (task: Task) => {
  deletingTask.value = task
  showDeleteModal.value = true
}

const cancelDelete = () => {
  showDeleteModal.value = false
  deletingTask.value = null
}

const deleteTask = async () => {
  if (!deletingTask.value) return
  
  try {
    await ApiService.deleteTask(deletingTask.value.id)
    await loadTasks()
    showDeleteModal.value = false
    deletingTask.value = null
  } catch (error) {
    console.error('删除任务失败:', error)
    alert('删除任务失败')
  }
}

const showExecuteModal = async (task: Task) => {
  selectedTask.value = task
  await loadTerminals()
  showExecuteTaskModal.value = true
}

const executeTask = async () => {
  if (!selectedTask.value || !executeForm.value.terminal_id) return
  
  try {
    isExecuting.value = true
    await ApiService.executeTask(selectedTask.value.id, executeForm.value.terminal_id)
    alert('任务已提交执行')
    closeExecuteModal()
  } catch (error) {
    console.error('执行任务失败:', error)
    alert('执行任务失败')
  } finally {
    isExecuting.value = false
  }
}

const submitForm = async () => {
  try {
    isSubmitting.value = true
    
    if (showCreateModal.value) {
      await ApiService.createTask(form.value)
    } else if (showEditModal.value && editingTask.value) {
      await ApiService.updateTask(editingTask.value.id, form.value)
    }
    
    await loadTasks()
    closeModal()
  } catch (error) {
    console.error('保存任务失败:', error)
    alert('保存任务失败')
  } finally {
    isSubmitting.value = false
  }
}

const closeModal = () => {
  showCreateModal.value = false
  showEditModal.value = false
  editingTask.value = null
  form.value = {
    name: '',
    description: '',
    script_content: ''
  }
}

const closeExecuteModal = () => {
  showExecuteTaskModal.value = false
  selectedTask.value = null
  executeForm.value = {
    terminal_id: ''
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(() => {
  loadTasks()
})
</script>