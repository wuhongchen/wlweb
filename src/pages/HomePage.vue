<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
const { isAuthenticated } = useAuth()

const goToLogin = () => {
  router.push('/login')
}

const goToDashboard = () => {
  router.push('/dashboard')
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
    <!-- 导航栏 -->
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <h1 class="text-xl font-bold text-gray-900">游戏脚本中间件管理系统</h1>
          </div>
          <div class="flex items-center space-x-4">
            <button 
              v-if="!isAuthenticated"
              @click="goToLogin"
              class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
            >
              登录
            </button>
            <button 
              v-else
              @click="goToDashboard"
              class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
            >
              进入控制台
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- 主要内容 -->
    <main class="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
      <!-- Hero Section -->
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
          游戏脚本中间件
          <span class="text-blue-600">管理系统</span>
        </h1>
        <p class="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
          统一管理游戏脚本终端，实时监控运行状态，高效分配任务资源
        </p>
        <div class="mt-5 max-w-md mx-auto sm:flex sm:justify-center md:mt-8">
          <div class="rounded-md shadow">
            <button 
              @click="isAuthenticated ? goToDashboard() : goToLogin()"
              class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 md:py-4 md:text-lg md:px-10 transition-colors"
            >
              {{ isAuthenticated ? '进入控制台' : '开始使用' }}
            </button>
          </div>
        </div>
      </div>

      <!-- 功能特性 -->
      <div class="mt-20">
        <div class="text-center">
          <h2 class="text-3xl font-bold text-gray-900">核心功能</h2>
          <p class="mt-4 text-lg text-gray-600">为游戏脚本管理提供全方位解决方案</p>
        </div>
        
        <div class="mt-12 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          <!-- 终端管理 -->
          <div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-blue-500 text-white mx-auto">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 class="mt-4 text-lg font-medium text-gray-900 text-center">终端管理</h3>
            <p class="mt-2 text-sm text-gray-500 text-center">统一管理所有游戏脚本终端，实时监控运行状态和资源使用情况</p>
          </div>

          <!-- 任务调度 -->
          <div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-green-500 text-white mx-auto">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 class="mt-4 text-lg font-medium text-gray-900 text-center">任务调度</h3>
            <p class="mt-2 text-sm text-gray-500 text-center">智能分配游戏任务，优化资源利用率，提高执行效率</p>
          </div>

          <!-- 数据统计 -->
          <div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-center h-12 w-12 rounded-md bg-purple-500 text-white mx-auto">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h3 class="mt-4 text-lg font-medium text-gray-900 text-center">数据统计</h3>
            <p class="mt-2 text-sm text-gray-500 text-center">详细的运行数据分析，帮助优化脚本性能和资源配置</p>
          </div>
        </div>
      </div>

      <!-- 技术栈 -->
      <div class="mt-20">
        <div class="text-center">
          <h2 class="text-3xl font-bold text-gray-900">技术架构</h2>
          <p class="mt-4 text-lg text-gray-600">基于现代化技术栈构建</p>
        </div>
        
        <div class="mt-12 grid grid-cols-2 gap-8 md:grid-cols-4">
          <div class="text-center">
            <div class="bg-green-100 rounded-lg p-4">
              <h3 class="font-medium text-green-800">Vue 3</h3>
              <p class="text-sm text-green-600">前端框架</p>
            </div>
          </div>
          <div class="text-center">
            <div class="bg-blue-100 rounded-lg p-4">
              <h3 class="font-medium text-blue-800">FastAPI</h3>
              <p class="text-sm text-blue-600">后端API</p>
            </div>
          </div>
          <div class="text-center">
            <div class="bg-orange-100 rounded-lg p-4">
              <h3 class="font-medium text-orange-800">MySQL</h3>
              <p class="text-sm text-orange-600">数据存储</p>
            </div>
          </div>
          <div class="text-center">
            <div class="bg-red-100 rounded-lg p-4">
              <h3 class="font-medium text-red-800">Redis</h3>
              <p class="text-sm text-red-600">缓存系统</p>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 页脚 -->
    <footer class="bg-white border-t">
      <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <div class="text-center text-gray-500">
          <p>&copy; 2024 游戏脚本中间件管理系统. All rights reserved.</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* 添加一些自定义样式 */
.transition-colors {
  transition: background-color 0.2s ease-in-out;
}

.transition-shadow {
  transition: box-shadow 0.2s ease-in-out;
}
</style>
