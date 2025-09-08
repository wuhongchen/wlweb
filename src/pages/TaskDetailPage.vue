<template>
  <div class="min-h-screen bg-gray-50">
    <!-- 导航栏 -->
    <nav class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center space-x-4">
            <router-link to="/tasks" class="text-gray-500 hover:text-gray-700">
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </router-link>
            <h1 class="text-xl font-semibold text-gray-900">任务详情</h1>
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
      <div v-if="isLoading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        <p class="mt-2 text-sm text-gray-500">加载中...</p>
      </div>

      <div v-else-if="task" class="space-y-6">
        <!-- 任务基本信息 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">{{ task.name }}</h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">任务ID: {{ task.id }}</p>
            </div>
            <div class="flex space-x-3">
              <button
                @click="showExecuteModal"
                class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                执行任务
              </button>
              <button
                @click="editTask"
                class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                编辑任务
              </button>
            </div>
          </div>
          <div class="border-t border-gray-200">
            <dl>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">描述</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ task.description || '无描述' }}</dd>
              </div>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">创建者</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ task.created_by }}</dd>
              </div>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">创建时间</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ formatDate(task.created_at) }}</dd>
              </div>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">更新时间</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">{{ formatDate(task.updated_at) }}</dd>
              </div>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">脚本内容</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <pre class="bg-gray-100 p-4 rounded-md overflow-x-auto text-sm font-mono whitespace-pre-wrap">{{ task.script_content }}</pre>
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <!-- 执行历史 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">执行历史</h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">该任务的所有执行记录</p>
            </div>
            <button
              @click="loadExecutions"
              :disabled="isLoadingExecutions"
              class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-md text-sm font-medium disabled:opacity-50"
            >
              刷新
            </button>
          </div>
          
          <div v-if="isLoadingExecutions" class="text-center py-8">
            <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
            <p class="mt-2 text-sm text-gray-500">加载执行历史...</p>
          </div>
          
          <div v-else-if="executions.length === 0" class="text-center py-8">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">暂无执行记录</h3>
            <p class="mt-1 text-sm text-gray-500">该任务还没有被执行过</p>
          </div>
          
          <div v-else class="border-t border-gray-200">
            <ul class="divide-y divide-gray-200">
              <li v-for="execution in executions" :key="execution.id" class="px-6 py-4">
                <div class="flex items-center justify-between">
                  <div class="flex-1">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center space-x-3">
                        <span class="text-sm font-medium text-gray-900">执行ID: {{ execution.id }}</span>
                        <span :class="getStatusClass(execution.status)" class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full">
                          {{ getStatusText(execution.status) }}
                        </span>
                      </div>
                      <div class="text-sm text-gray-500">
                        {{ formatDate(execution.started_at) }}
                      </div>
                    </div>
                    <div class="mt-2 flex items-center text-sm text-gray-500">
                      <span>终端: {{ execution.terminal_id }}</span>
                      <span class="mx-2">•</span>
                      <span>执行者: {{ execution.executed_by }}</span>
                      <span v-if="execution.finished_at" class="mx-2">•</span>
                      <span v-if="execution.finished_at">完成时间: {{ formatDate(execution.finished_at) }}</span>
                    </div>
                    <div v-if="execution.result" class="mt-3">
                      <details class="group">
                        <summary class="cursor-pointer text-sm font-medium text-indigo-600 hover:text-indigo-500">
                          查看执行结果
                        </summary>
                        <div class="mt-2 bg-gray-100 p-3 rounded-md">
                          <pre class="text-xs font-mono whitespace-pre-wrap overflow-x-auto">{{ execution.result }}</pre>
                        </div>
                      </details>
                    </div>
                    <div v-if="execution.error" class="mt-3">
                      <details class="group">
                        <summary class="cursor-pointer text-sm font-medium text-red-600 hover:text-red-500">
                          查看错误信息
                        </summary>
                        <div class="mt-2 bg-red-50 p-3 rounded-md">
                          <pre class="text-xs font-mono whitespace-pre-wrap overflow-x-auto text-red-700">{{ execution.error }}</pre>
                        </div>
                      </details>
                    </div>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div v-else class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">任务不存在</h3>
        <p class="mt-1 text-sm text-gray-500">请检查任务ID是否正确</p>
      </div>
    </div>

    <!-- 执行任务模态框 -->
    <div v-if="showExecuteTaskModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            执行任务: {{ task?.name }}
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

    <!-- 编辑任务模态框 -->
    <div v-if="showEditModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-10 mx-auto p-5 border w-3/4 max-w-4xl shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">编辑任务</h3>
          <form @submit.prevent="submitEditForm">
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">任务名称</label>
                <input
                  v-model="editForm.name"
                  type="text"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="输入任务名称"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">任务描述</label>
                <textarea
                  v-model="editForm.description"
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="输入任务描述（可选）"
                ></textarea>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">脚本内容</label>
                <textarea
                  v-model="editForm.script_content"
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
                @click="closeEditModal"
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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { ApiService, type Task, type TaskExecution, type Terminal } from '@/lib/api'

const route = useRoute()
const router = useRouter()
const { user, logout } = useAuth()

const task = ref<Task | null>(null)
const executions = ref<TaskExecution[]>([])
const terminals = ref<Terminal[]>([])
const onlineTerminals = ref<Terminal[]>([])
const isLoading = ref(false)
const isLoadingExecutions = ref(false)
const isSubmitting = ref(false)
const isExecuting = ref(false)
const showExecuteTaskModal = ref(false)
const showEditModal = ref(false)

const executeForm = ref({
  terminal_id: ''
})

const editForm = ref({
  name: '',
  description: '',
  script_content: ''
})

const handleLogout = async () => {
  await logout()
}

const loadTask = async () => {
  try {
    isLoading.value = true
    const taskId = route.params.id as string
    task.value = await ApiService.getTask(taskId)
  } catch (error) {
    console.error('加载任务详情失败:', error)
    alert('加载任务详情失败')
  } finally {
    isLoading.value = false
  }
}

const loadExecutions = async () => {
  try {
    isLoadingExecutions.value = true
    const taskId = route.params.id as string
    executions.value = await ApiService.getTaskExecutions(taskId)
  } catch (error) {
    console.error('加载执行历史失败:', error)
    alert('加载执行历史失败')
  } finally {
    isLoadingExecutions.value = false
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

const showExecuteModal = async () => {
  await loadTerminals()
  showExecuteTaskModal.value = true
}

const executeTask = async () => {
  if (!task.value || !executeForm.value.terminal_id) return
  
  try {
    isExecuting.value = true
    await ApiService.executeTask(task.value.id, executeForm.value.terminal_id)
    alert('任务已提交执行')
    closeExecuteModal()
    await loadExecutions() // 刷新执行历史
  } catch (error) {
    console.error('执行任务失败:', error)
    alert('执行任务失败')
  } finally {
    isExecuting.value = false
  }
}

const editTask = () => {
  if (!task.value) return
  
  editForm.value = {
    name: task.value.name,
    description: task.value.description || '',
    script_content: task.value.script_content
  }
  showEditModal.value = true
}

const submitEditForm = async () => {
  if (!task.value) return
  
  try {
    isSubmitting.value = true
    await ApiService.updateTask(task.value.id, editForm.value)
    await loadTask() // 重新加载任务详情
    closeEditModal()
    alert('任务更新成功')
  } catch (error) {
    console.error('更新任务失败:', error)
    alert('更新任务失败')
  } finally {
    isSubmitting.value = false
  }
}

const closeExecuteModal = () => {
  showExecuteTaskModal.value = false
  executeForm.value = {
    terminal_id: ''
  }
}

const closeEditModal = () => {
  showEditModal.value = false
  editForm.value = {
    name: '',
    description: '',
    script_content: ''
  }
}

const getStatusClass = (status: string) => {
  switch (status) {
    case 'running':
      return 'bg-blue-100 text-blue-800'
    case 'completed':
      return 'bg-green-100 text-green-800'
    case 'failed':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

const getStatusText = (status: string) => {
  switch (status) {
    case 'running':
      return '运行中'
    case 'completed':
      return '已完成'
    case 'failed':
      return '失败'
    default:
      return status
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(() => {
  loadTask()
  loadExecutions()
})
</script>