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
            <h1 class="text-xl font-semibold text-gray-900">用户管理</h1>
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
      <!-- 错误消息 -->
      <div v-if="showErrorAlert" class="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm text-red-800">{{ errorMessage }}</p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button @click="clearMessages" class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100">
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 成功消息 -->
      <div v-if="showSuccessAlert" class="mb-4 bg-green-50 border border-green-200 rounded-md p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm text-green-800">{{ successMessage }}</p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button @click="clearMessages" class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100">
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- 操作栏 -->
      <div class="mb-6 flex justify-between items-center">
        <div class="flex items-center space-x-4">
          <button
            @click="loadUsers"
            :disabled="isLoading"
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
          >
            <svg v-if="isLoading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {{ isLoading ? '加载中...' : '刷新' }}
          </button>
        </div>
        <button
          @click="showCreateModal = true"
          class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium"
        >
          新建用户
        </button>
      </div>

      <!-- 用户列表 -->
      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <div v-if="isLoading && users.length === 0" class="text-center py-12">
          <svg class="animate-spin mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="mt-2 text-sm text-gray-500">加载用户列表中...</p>
        </div>

        <div v-else-if="users.length === 0" class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
          <p class="mt-2 text-sm text-gray-500">暂无用户数据</p>
        </div>

        <ul v-else class="divide-y divide-gray-200">
          <li v-for="userItem in users" :key="userItem.id" class="px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                    <svg class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                </div>
                <div class="ml-4">
                  <div class="flex items-center">
                    <p class="text-sm font-medium text-gray-900">{{ userItem.username }}</p>
                    <span v-if="userItem.is_admin" class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                      管理员
                    </span>
                    <span v-else class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      普通用户
                    </span>
                  </div>
                  <p class="text-sm text-gray-500">ID: {{ userItem.id }}</p>
                  <p v-if="userItem.created_at" class="text-sm text-gray-500">
                    创建时间: {{ formatDate(userItem.created_at) }}
                  </p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  @click="editUser(userItem)"
                  class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                >
                  编辑
                </button>
                <button
                  @click="confirmDeleteUser(userItem)"
                  :disabled="userItem.id === user?.id"
                  class="text-red-600 hover:text-red-900 text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  删除
                </button>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <!-- 创建用户模态框 -->
    <div v-if="showCreateModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">新建用户</h3>
          <form @submit.prevent="createUser">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">用户名</label>
              <input
                v-model="createForm.username"
                type="text"
                required
                :class="[
                  'w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500',
                  createFormErrors.username ? 'border-red-300 text-red-900 placeholder-red-300' : 'border-gray-300'
                ]"
                placeholder="请输入用户名"
              />
              <p v-if="createFormErrors.username" class="mt-1 text-sm text-red-600">{{ createFormErrors.username }}</p>
            </div>

            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">密码</label>
              <input
                v-model="createForm.password"
                type="password"
                required
                :class="[
                  'w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500',
                  createFormErrors.password ? 'border-red-300 text-red-900 placeholder-red-300' : 'border-gray-300'
                ]"
                placeholder="请输入密码"
              />
              <p v-if="createFormErrors.password" class="mt-1 text-sm text-red-600">{{ createFormErrors.password }}</p>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">用户角色</label>
              <select
                v-model="createForm.is_admin"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option :value="false">普通用户</option>
                <option :value="true">管理员</option>
              </select>
            </div>
            <div class="flex justify-end space-x-3">
              <button
                type="button"
                @click="showCreateModal = false"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
              >
                取消
              </button>
              <button
                type="submit"
                :disabled="isCreating"
                class="px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700 disabled:opacity-50"
              >
                {{ isCreating ? '创建中...' : '创建' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- 编辑用户模态框 -->
    <div v-if="showEditModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <h3 class="text-lg font-medium text-gray-900 mb-4">编辑用户</h3>
          <form @submit.prevent="updateUser">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">用户名</label>
              <input
                v-model="editForm.username"
                type="text"
                required
                :class="[
                  'w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500',
                  editFormErrors.username ? 'border-red-300 text-red-900 placeholder-red-300' : 'border-gray-300'
                ]"
                placeholder="请输入用户名"
              />
              <p v-if="editFormErrors.username" class="mt-1 text-sm text-red-600">{{ editFormErrors.username }}</p>
            </div>

            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">新密码（可选）</label>
              <input
                v-model="editForm.password"
                type="password"
                :class="[
                  'w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500',
                  editFormErrors.password ? 'border-red-300 text-red-900 placeholder-red-300' : 'border-gray-300'
                ]"
                placeholder="留空则不修改密码"
              />
              <p v-if="editFormErrors.password" class="mt-1 text-sm text-red-600">{{ editFormErrors.password }}</p>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">用户角色</label>
              <select
                v-model="editForm.is_admin"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option :value="false">普通用户</option>
                <option :value="true">管理员</option>
              </select>
            </div>
            <div class="flex justify-end space-x-3">
              <button
                type="button"
                @click="showEditModal = false"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
              >
                取消
              </button>
              <button
                type="submit"
                :disabled="isUpdating"
                class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 disabled:opacity-50"
              >
                {{ isUpdating ? '更新中...' : '更新' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- 删除确认模态框 -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3 text-center">
          <svg class="mx-auto h-12 w-12 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <h3 class="text-lg font-medium text-gray-900 mt-2">确认删除</h3>
          <p class="text-sm text-gray-500 mt-2">
            确定要删除用户 "{{ userToDelete?.username }}" 吗？此操作不可撤销。
          </p>
          <div class="flex justify-center space-x-3 mt-4">
            <button
              @click="showDeleteModal = false"
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
            >
              取消
            </button>
            <button
              @click="deleteUser"
              :disabled="isDeleting"
              class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700 disabled:opacity-50"
            >
              {{ isDeleting ? '删除中...' : '确认删除' }}
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
import { ApiService } from '@/lib/api'
import type { User } from '@/lib/api'

const { user, logout } = useAuth()

// 状态管理
const users = ref<User[]>([])
const isLoading = ref(false)
const isCreating = ref(false)
const isUpdating = ref(false)
const isDeleting = ref(false)

// 错误和成功消息管理
const errorMessage = ref('')
const successMessage = ref('')
const showErrorAlert = ref(false)
const showSuccessAlert = ref(false)

// 表单验证错误
const createFormErrors = ref<Record<string, string>>({})
const editFormErrors = ref<Record<string, string>>({})

// 模态框状态
const showCreateModal = ref(false)
const showEditModal = ref(false)
const showDeleteModal = ref(false)

// 表单数据
const createForm = ref({
  username: '',
  password: '',
  is_admin: false
})

const editForm = ref({
  id: 0,
  username: '',
  password: '',
  is_admin: false
})

const userToDelete = ref<User | null>(null)

// 消息显示辅助函数
const showError = (message: string) => {
  errorMessage.value = message
  showErrorAlert.value = true
  setTimeout(() => {
    showErrorAlert.value = false
  }, 5000)
}

const showSuccess = (message: string) => {
  successMessage.value = message
  showSuccessAlert.value = true
  setTimeout(() => {
    showSuccessAlert.value = false
  }, 3000)
}

const clearMessages = () => {
  showErrorAlert.value = false
  showSuccessAlert.value = false
  errorMessage.value = ''
  successMessage.value = ''
}

// 表单验证函数
const validateCreateForm = () => {
  const errors: Record<string, string> = {}
  
  if (!createForm.value.username.trim()) {
    errors.username = '用户名不能为空'
  } else if (createForm.value.username.length < 3) {
    errors.username = '用户名至少需要3个字符'
  }
  

  
  if (!createForm.value.password.trim()) {
    errors.password = '密码不能为空'
  } else if (createForm.value.password.length < 6) {
    errors.password = '密码至少需要6个字符'
  }
  
  createFormErrors.value = errors
  return Object.keys(errors).length === 0
}

const validateEditForm = () => {
  const errors: Record<string, string> = {}
  
  if (!editForm.value.username.trim()) {
    errors.username = '用户名不能为空'
  } else if (editForm.value.username.length < 3) {
    errors.username = '用户名至少需要3个字符'
  }
  

  
  if (editForm.value.password && editForm.value.password.length < 6) {
    errors.password = '密码至少需要6个字符'
  }
  
  editFormErrors.value = errors
  return Object.keys(errors).length === 0
}

// 加载用户列表
const loadUsers = async () => {
  try {
    clearMessages()
    isLoading.value = true
    users.value = await ApiService.getUsers()
  } catch (error: any) {
    console.error('加载用户列表失败:', error)
    const message = error?.response?.data?.detail || error?.message || '加载用户列表失败，请重试'
    showError(message)
  } finally {
    isLoading.value = false
  }
}

// 创建用户
const createUser = async () => {
  // 表单验证
  if (!validateCreateForm()) {
    return
  }
  
  try {
    clearMessages()
    isCreating.value = true
    
    const userData = {
      username: createForm.value.username.trim(),
      password: createForm.value.password,
      role: createForm.value.is_admin ? 'admin' : 'operator'
    }
    
    await ApiService.createUser(userData)
    
    // 成功后的处理
    showCreateModal.value = false
    createForm.value = {
      username: '',
      password: '',
      is_admin: false
    }
    createFormErrors.value = {}
    
    await loadUsers()
    showSuccess('用户创建成功')
    
  } catch (error: any) {
    console.error('创建用户失败:', error)
    const message = error?.response?.data?.detail || error?.message || '创建用户失败，请重试'
    showError(message)
  } finally {
    isCreating.value = false
  }
}

// 编辑用户
const editUser = (userItem: User) => {
  editForm.value = {
    id: userItem.id,
    username: userItem.username,
    password: '',
    is_admin: userItem.is_admin
  }
  showEditModal.value = true
}

// 更新用户
const updateUser = async () => {
  // 表单验证
  if (!validateEditForm()) {
    return
  }
  
  try {
    clearMessages()
    isUpdating.value = true
    
    const updateData: any = {
      username: editForm.value.username.trim(),
      role: editForm.value.is_admin ? 'admin' : 'operator'
    }
    
    // 只有在输入了新密码时才包含密码字段
    if (editForm.value.password.trim()) {
      updateData.password = editForm.value.password
    }
    
    await ApiService.updateUser(editForm.value.id, updateData)
    
    // 成功后的处理
    showEditModal.value = false
    editFormErrors.value = {}
    
    await loadUsers()
    showSuccess('用户更新成功')
    
  } catch (error: any) {
    console.error('更新用户失败:', error)
    const message = error?.response?.data?.detail || error?.message || '更新用户失败，请重试'
    showError(message)
  } finally {
    isUpdating.value = false
  }
}

// 确认删除用户
const confirmDeleteUser = (userItem: User) => {
  userToDelete.value = userItem
  showDeleteModal.value = true
}

// 删除用户
const deleteUser = async () => {
  if (!userToDelete.value) return
  
  try {
    clearMessages()
    isDeleting.value = true
    
    await ApiService.deleteUser(userToDelete.value.id)
    
    // 成功后的处理
    showDeleteModal.value = false
    userToDelete.value = null
    
    await loadUsers()
    showSuccess('用户删除成功')
    
  } catch (error: any) {
    console.error('删除用户失败:', error)
    const message = error?.response?.data?.detail || error?.message || '删除用户失败，请重试'
    showError(message)
  } finally {
    isDeleting.value = false
  }
}

// 格式化日期
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

// 处理退出登录
const handleLogout = async () => {
  await logout()
}

// 组件挂载时加载数据
onMounted(() => {
  loadUsers()
})
</script>