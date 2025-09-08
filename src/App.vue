<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useRouter } from 'vue-router'

const { initAuth, logout } = useAuth()
const router = useRouter()

// 处理全局登出事件
const handleGlobalLogout = () => {
  logout()
}

// 初始化认证状态和事件监听
onMounted(() => {
  initAuth()
  window.addEventListener('auth:logout', handleGlobalLogout)
})

onUnmounted(() => {
  window.removeEventListener('auth:logout', handleGlobalLogout)
})
</script>

<style>
#app {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #1f2937;
  min-height: 100vh;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
}
</style>