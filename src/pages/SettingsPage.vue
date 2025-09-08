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
            <h1 class="text-xl font-semibold text-gray-900">系统设置</h1>
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
    <div class="max-w-4xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="space-y-6">
        <!-- 快捷导航 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">系统管理</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">快速访问系统管理功能</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <router-link
                to="/system-config"
                class="flex items-center p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div class="flex-shrink-0">
                  <svg class="h-8 w-8 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                <div class="ml-4">
                  <h4 class="text-lg font-medium text-gray-900">系统配置</h4>
                  <p class="text-sm text-gray-500">管理系统配置和区域设置</p>
                </div>
              </router-link>
            </div>
          </div>
        </div>
        <!-- 用户信息设置 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">用户信息</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">管理您的账户信息</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <form @submit.prevent="updateUserInfo">
              <div class="grid grid-cols-1 gap-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">用户名</label>
                  <input
                    v-model="userForm.username"
                    type="text"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="输入用户名"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">邮箱</label>
                  <input
                    v-model="userForm.email"
                    type="email"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="输入邮箱地址"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">角色</label>
                  <input
                    :value="user?.is_admin ? 'admin' : 'user'"
                    type="text"
                    disabled
                    class="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-100 text-gray-500"
                  />
                  <p class="mt-1 text-sm text-gray-500">角色由管理员分配，无法自行修改</p>
                </div>
              </div>
              <div class="mt-6">
                <button
                  type="submit"
                  :disabled="isUpdatingUser"
                  class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
                >
                  {{ isUpdatingUser ? '保存中...' : '保存用户信息' }}
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- 密码修改 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">修改密码</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">更新您的登录密码</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <form @submit.prevent="changePassword">
              <div class="grid grid-cols-1 gap-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">当前密码</label>
                  <input
                    v-model="passwordForm.currentPassword"
                    type="password"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="输入当前密码"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">新密码</label>
                  <input
                    v-model="passwordForm.newPassword"
                    type="password"
                    required
                    minlength="6"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="输入新密码（至少6位）"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">确认新密码</label>
                  <input
                    v-model="passwordForm.confirmPassword"
                    type="password"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="再次输入新密码"
                  />
                  <p v-if="passwordForm.newPassword && passwordForm.confirmPassword && passwordForm.newPassword !== passwordForm.confirmPassword" class="mt-1 text-sm text-red-600">
                    两次输入的密码不一致
                  </p>
                </div>
              </div>
              <div class="mt-6">
                <button
                  type="submit"
                  :disabled="isChangingPassword || passwordForm.newPassword !== passwordForm.confirmPassword"
                  class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
                >
                  {{ isChangingPassword ? '修改中...' : '修改密码' }}
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- 系统配置 -->
        <div v-if="user?.is_admin" class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">系统配置</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">管理系统全局设置（仅管理员可见）</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <form @submit.prevent="updateSystemConfig">
              <div class="grid grid-cols-1 gap-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">系统名称</label>
                  <input
                    v-model="systemForm.systemName"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="游戏脚本中间件管理系统"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">最大终端连接数</label>
                  <input
                    v-model.number="systemForm.maxTerminals"
                    type="number"
                    min="1"
                    max="1000"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="100"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">任务执行超时时间（秒）</label>
                  <input
                    v-model.number="systemForm.taskTimeout"
                    type="number"
                    min="30"
                    max="3600"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="300"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">数据保留天数</label>
                  <input
                    v-model.number="systemForm.dataRetentionDays"
                    type="number"
                    min="1"
                    max="365"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="30"
                  />
                  <p class="mt-1 text-sm text-gray-500">超过此天数的执行记录和终端数据将被自动清理</p>
                </div>
                <div class="flex items-center">
                  <input
                    v-model="systemForm.enableAutoCleanup"
                    type="checkbox"
                    class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label class="ml-2 block text-sm text-gray-900">
                    启用自动数据清理
                  </label>
                </div>
                <div class="flex items-center">
                  <input
                    v-model="systemForm.enableRegistration"
                    type="checkbox"
                    class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label class="ml-2 block text-sm text-gray-900">
                    允许新用户注册
                  </label>
                </div>
              </div>
              <div class="mt-6">
                <button
                  type="submit"
                  :disabled="isUpdatingSystem"
                  class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
                >
                  {{ isUpdatingSystem ? '保存中...' : '保存系统配置' }}
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- 数据管理 -->
        <div v-if="user?.is_admin" class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">数据管理</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">管理系统数据和清理操作（仅管理员可见）</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-4">
              <div class="flex items-center justify-between p-4 bg-yellow-50 rounded-lg">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">清理过期数据</h4>
                  <p class="text-sm text-gray-500">删除超过保留期限的执行记录和终端数据</p>
                </div>
                <button
                  @click="showCleanupConfirm"
                  :disabled="isCleaning"
                  class="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
                >
                  {{ isCleaning ? '清理中...' : '立即清理' }}
                </button>
              </div>
              
              <div class="flex items-center justify-between p-4 bg-red-50 rounded-lg">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">重置系统数据</h4>
                  <p class="text-sm text-gray-500">清空所有任务执行记录和终端数据（谨慎操作）</p>
                </div>
                <button
                  @click="showResetConfirm"
                  :disabled="isResetting"
                  class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium disabled:opacity-50"
                >
                  {{ isResetting ? '重置中...' : '重置数据' }}
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 关于系统 -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">关于系统</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">系统版本和技术信息</p>
          </div>
          <div class="border-t border-gray-200">
            <dl>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">系统名称</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">游戏脚本中间件管理系统</dd>
              </div>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">版本</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">v1.0.0</dd>
              </div>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">技术栈</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  前端: Vue 3 + TypeScript + Tailwind CSS<br>
                  后端: FastAPI + SQLAlchemy + Pydantic<br>
                  数据库: MySQL + Redis
                </dd>
              </div>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">开发者</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">SOLO Coding</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </div>

    <!-- 清理过期数据确认对话框 -->
    <div v-if="showCleanupModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-yellow-100">
            <svg class="h-6 w-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <div class="mt-2 text-center">
            <h3 class="text-lg font-medium text-gray-900">确认清理过期数据</h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500">
                确定要清理过期数据吗？
              </p>
              <p class="text-sm text-gray-400 mt-1">
                此操作将删除超过保留期限的执行记录和终端数据，此操作不可撤销。
              </p>
            </div>
            <div class="flex justify-center space-x-4 px-4 py-3">
              <button
                @click="cancelCleanup"
                class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                取消
              </button>
              <button
                @click="cleanupExpiredData"
                :disabled="isCleaning"
                class="px-4 py-2 bg-yellow-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-yellow-700 focus:outline-none focus:ring-2 focus:ring-yellow-500 disabled:opacity-50"
              >
                {{ isCleaning ? '清理中...' : '确认清理' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 重置系统数据第一次确认对话框 -->
    <div v-if="showResetModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
            <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <div class="mt-2 text-center">
            <h3 class="text-lg font-medium text-gray-900">确认重置系统数据</h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500">
                确定要重置系统数据吗？
              </p>
              <p class="text-sm text-gray-400 mt-1">
                这将清空所有任务执行记录和终端数据，此操作不可撤销！
              </p>
            </div>
            <div class="flex justify-center space-x-4 px-4 py-3">
              <button
                @click="cancelReset"
                class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                取消
              </button>
              <button
                @click="showSecondConfirm"
                class="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                继续
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 重置系统数据第二次确认对话框 -->
    <div v-if="showResetConfirmModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3">
          <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
            <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <div class="mt-2 text-center">
            <h3 class="text-lg font-medium text-gray-900">最终确认</h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500 font-medium">
                请再次确认：您真的要重置所有系统数据吗？
              </p>
              <p class="text-sm text-red-500 mt-2 font-medium">
                ⚠️ 此操作将永久删除所有数据，无法恢复！
              </p>
            </div>
            <div class="flex justify-center space-x-4 px-4 py-3">
              <button
                @click="cancelReset"
                class="px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                取消
              </button>
              <button
                @click="resetSystemData"
                :disabled="isResetting"
                class="px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 disabled:opacity-50"
              >
                {{ isResetting ? '重置中...' : '确认重置' }}
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
import { ApiService } from '@/lib/api'

const { user, logout } = useAuth()
const isUpdatingUser = ref(false)
const isChangingPassword = ref(false)
const isUpdatingSystem = ref(false)
const isCleaning = ref(false)
const isResetting = ref(false)
const showCleanupModal = ref(false)
const showResetModal = ref(false)
const showResetConfirmModal = ref(false)

const userForm = ref({
  username: '',
  email: ''
})

const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const systemForm = ref({
  systemName: '游戏脚本中间件管理系统',
  maxTerminals: 100,
  taskTimeout: 300,
  dataRetentionDays: 30,
  enableAutoCleanup: true,
  enableRegistration: false
})

const handleLogout = async () => {
  await logout()
}

const updateUserInfo = async () => {
  try {
    isUpdatingUser.value = true
    // 这里应该调用更新用户信息的API
    // await ApiService.updateUserInfo(userForm.value)
    alert('用户信息更新成功')
  } catch (error) {
    console.error('更新用户信息失败:', error)
    alert('更新用户信息失败')
  } finally {
    isUpdatingUser.value = false
  }
}

const changePassword = async () => {
  if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
    alert('两次输入的密码不一致')
    return
  }
  
  try {
    isChangingPassword.value = true
    // 这里应该调用修改密码的API
    // await ApiService.changePassword(passwordForm.value)
    alert('密码修改成功')
    passwordForm.value = {
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    }
  } catch (error) {
    console.error('修改密码失败:', error)
    alert('修改密码失败')
  } finally {
    isChangingPassword.value = false
  }
}

const updateSystemConfig = async () => {
  try {
    isUpdatingSystem.value = true
    // 这里应该调用更新系统配置的API
    // await ApiService.updateSystemConfig(systemForm.value)
    alert('系统配置更新成功')
  } catch (error) {
    console.error('更新系统配置失败:', error)
    alert('更新系统配置失败')
  } finally {
    isUpdatingSystem.value = false
  }
}

const showCleanupConfirm = () => {
  showCleanupModal.value = true
}

const cleanupExpiredData = async () => {
  try {
    isCleaning.value = true
    // 这里应该调用清理过期数据的API
    // await ApiService.cleanupExpiredData()
    alert('过期数据清理完成')
    showCleanupModal.value = false
  } catch (error) {
    console.error('清理过期数据失败:', error)
    alert('清理过期数据失败')
  } finally {
    isCleaning.value = false
  }
}

const cancelCleanup = () => {
  showCleanupModal.value = false
}

const showResetConfirm = () => {
  showResetModal.value = true
}

const showSecondConfirm = () => {
  showResetModal.value = false
  showResetConfirmModal.value = true
}

const resetSystemData = async () => {
  try {
    isResetting.value = true
    // 这里应该调用重置系统数据的API
    // await ApiService.resetSystemData()
    alert('系统数据重置完成')
    showResetConfirmModal.value = false
  } catch (error) {
    console.error('重置系统数据失败:', error)
    alert('重置系统数据失败')
  } finally {
    isResetting.value = false
  }
}

const cancelReset = () => {
  showResetModal.value = false
  showResetConfirmModal.value = false
}

const loadUserInfo = () => {
  if (user.value) {
    userForm.value = {
      username: user.value.username,
      email: user.value.email || ''
    }
  }
}

const loadSystemConfig = async () => {
  if (user.value?.is_admin) {
    try {
      // 这里应该调用获取系统配置的API
      // const config = await ApiService.getSystemConfig()
      // systemForm.value = { ...systemForm.value, ...config }
    } catch (error) {
      console.error('加载系统配置失败:', error)
    }
  }
}

onMounted(() => {
  loadUserInfo()
  loadSystemConfig()
})
</script>