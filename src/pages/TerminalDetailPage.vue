<template>
  <div class="min-h-screen bg-gray-50">
    <!-- 导航栏 -->
    <nav class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center space-x-4">
            <router-link to="/terminals" class="text-gray-500 hover:text-gray-700">
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </router-link>
            <h1 class="text-xl font-semibold text-gray-900">
              终端详情 - {{ terminal?.name || terminalId }}
            </h1>
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
        <svg class="animate-spin mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="mt-2 text-sm text-gray-500">加载中...</p>
      </div>

      <div v-else-if="terminal" class="space-y-6">
        <!-- 终端基本信息 -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">基本信息</h3>
            <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
              <div>
                <dt class="text-sm font-medium text-gray-500">终端ID</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ terminal.id }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">终端名称</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ terminal.name }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">状态</dt>
                <dd class="mt-1">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium" :class="{
                    'bg-green-100 text-green-800': terminal.status === 'online',
                    'bg-red-100 text-red-800': terminal.status === 'offline'
                  }">
                    <div class="h-1.5 w-1.5 rounded-full mr-1" :class="{
                      'bg-green-400': terminal.status === 'online',
                      'bg-red-400': terminal.status === 'offline'
                    }"></div>
                    {{ terminal.status === 'online' ? '在线' : '离线' }}
                  </span>
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">最后心跳</dt>
                <dd class="mt-1 text-sm text-gray-900">
                  {{ terminal.last_heartbeat ? formatDate(terminal.last_heartbeat) : '无' }}
                </dd>
              </div>
              <div class="sm:col-span-2">
                <dt class="text-sm font-medium text-gray-500">描述</dt>
                <dd class="mt-1 text-sm text-gray-900">
                  {{ terminal.description || '无描述' }}
                </dd>
              </div>
              <!-- 系统信息 -->
              <div v-if="terminal.config" class="sm:col-span-2">
                <dt class="text-sm font-medium text-gray-500">系统信息</dt>
                <dd class="mt-1">
                  <div class="bg-gray-50 rounded-lg p-4 space-y-2">
                    <div v-if="terminal.config.os" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">操作系统:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.os }}</span>
                    </div>
                    <div v-if="terminal.config.version" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">版本:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.version }}</span>
                    </div>
                    <div v-if="terminal.config.cpu" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">处理器:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.cpu }}</span>
                    </div>
                    <div v-if="terminal.config.memory" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">内存:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.memory }}</span>
                    </div>
                    <!-- 自动上报的系统信息 -->
                    <div v-if="terminal.config.system_version" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">系统版本:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.system_version }}</span>
                    </div>
                    <div v-if="terminal.config.device_model" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">设备型号:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.device_model }}</span>
                    </div>
                    <div v-if="terminal.config.device_brand" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">设备品牌:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.device_brand }}</span>
                    </div>
                    <div v-if="terminal.config.imei" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">IMEI:</span>
                      <span class="text-sm text-gray-900">{{ terminal.config.imei }}</span>
                    </div>
                    <div v-if="terminal.config.is_rooted !== undefined" class="flex justify-between">
                      <span class="text-sm font-medium text-gray-600">Root状态:</span>
                      <span class="text-sm" :class="terminal.config.is_rooted ? 'text-red-600' : 'text-green-600'">
                        {{ terminal.config.is_rooted ? '已Root' : '未Root' }}
                      </span>
                    </div>
                  </div>
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">创建时间</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ formatDate(terminal.created_at) }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">更新时间</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ formatDate(terminal.updated_at) }}</dd>
              </div>
            </dl>
          </div>
        </div>

        <!-- 任务执行历史 -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg leading-6 font-medium text-gray-900">任务执行历史</h3>
              <button
                @click="loadExecutions"
                :disabled="isLoadingExecutions"
                class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-md text-sm font-medium disabled:opacity-50"
              >
                <svg v-if="isLoadingExecutions" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                刷新
              </button>
            </div>
            
            <div v-if="executions.length === 0" class="text-center py-8">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">暂无执行记录</h3>
              <p class="mt-1 text-sm text-gray-500">该终端还没有执行过任何任务</p>
            </div>
            
            <div v-else class="overflow-hidden">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">任务ID</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">状态</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">开始时间</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">完成时间</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="execution in executions" :key="execution.id">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {{ execution.task_id }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium" :class="{
                        'bg-yellow-100 text-yellow-800': execution.status === 'pending',
                        'bg-blue-100 text-blue-800': execution.status === 'running',
                        'bg-green-100 text-green-800': execution.status === 'completed',
                        'bg-red-100 text-red-800': execution.status === 'failed'
                      }">
                        {{ getStatusText(execution.status) }}
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {{ execution.started_at ? formatDate(execution.started_at) : '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {{ execution.completed_at ? formatDate(execution.completed_at) : '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        @click="viewExecutionDetail(execution)"
                        class="text-indigo-600 hover:text-indigo-900"
                      >
                        查看详情
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">终端不存在</h3>
        <p class="mt-1 text-sm text-gray-500">找不到指定的终端设备</p>
      </div>
    </div>

    <!-- 执行详情模态框 -->
    <div v-if="selectedExecution" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-3/4 max-w-4xl shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-gray-900">
              执行详情 - 任务 {{ selectedExecution.task_id }}
            </h3>
            <button
              @click="selectedExecution = null"
              class="text-gray-400 hover:text-gray-600"
            >
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">执行ID</label>
                <p class="mt-1 text-sm text-gray-900">{{ selectedExecution.id }}</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700">状态</label>
                <span class="mt-1 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium" :class="{
                  'bg-yellow-100 text-yellow-800': selectedExecution.status === 'pending',
                  'bg-blue-100 text-blue-800': selectedExecution.status === 'running',
                  'bg-green-100 text-green-800': selectedExecution.status === 'completed',
                  'bg-red-100 text-red-800': selectedExecution.status === 'failed'
                }">
                  {{ getStatusText(selectedExecution.status) }}
                </span>
              </div>
            </div>
            
            <div v-if="selectedExecution.result" class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">执行结果</label>
              <pre class="bg-gray-100 p-3 rounded-md text-sm overflow-auto max-h-64">{{ selectedExecution.result }}</pre>
            </div>
            
            <div v-if="selectedExecution.error_message" class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">错误信息</label>
              <pre class="bg-red-50 p-3 rounded-md text-sm text-red-700 overflow-auto max-h-64">{{ selectedExecution.error_message }}</pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { ApiService, type Terminal, type TaskExecution } from '@/lib/api'

const route = useRoute()
const { user, logout } = useAuth()

const terminalId = parseInt(route.params.id as string, 10)
const terminal = ref<Terminal | null>(null)
const executions = ref<TaskExecution[]>([])
const selectedExecution = ref<TaskExecution | null>(null)
const isLoading = ref(false)
const isLoadingExecutions = ref(false)

const handleLogout = async () => {
  await logout()
}

const loadTerminal = async () => {
  try {
    isLoading.value = true
    terminal.value = await ApiService.getTerminal(terminalId)
  } catch (error) {
    console.error('加载终端详情失败:', error)
  } finally {
    isLoading.value = false
  }
}

const loadExecutions = async () => {
  try {
    isLoadingExecutions.value = true
    executions.value = await ApiService.getTaskExecutions(undefined, terminalId.toString())
  } catch (error) {
    console.error('加载执行历史失败:', error)
  } finally {
    isLoadingExecutions.value = false
  }
}

const viewExecutionDetail = (execution: TaskExecution) => {
  selectedExecution.value = execution
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    running: '运行中',
    completed: '已完成',
    failed: '失败'
  }
  return statusMap[status] || status
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(() => {
  loadTerminal()
  loadExecutions()
})
</script>