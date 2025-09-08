import { ref, computed, readonly } from 'vue'
import { ApiService, type LoginRequest, type User } from '@/lib/api'
import { useRouter } from 'vue-router'

// 全局状态 - 确保在模块级别定义，所有组件共享同一个实例
const user = ref<User | null>(null)
const isLoading = ref(false)
const error = ref<string | null>(null)
const isInitialized = ref(false)

export function useAuth() {
  const router = useRouter()

  // 计算属性
  const isAuthenticated = computed(() => {
    return !!user.value && !!localStorage.getItem('access_token')
  })

  const isAdmin = computed(() => {
    return user.value?.is_admin || false
  })

  // 登录
  const login = async (credentials: LoginRequest) => {
    try {
      isLoading.value = true
      error.value = null
      
      const response = await ApiService.login(credentials)
      
      // 保存token和用户信息
      localStorage.setItem('access_token', response.access_token)
      localStorage.setItem('user_info', JSON.stringify(response.user))
      user.value = response.user
      
      // 跳转到仪表板或重定向页面
      const redirect = router.currentRoute.value.query.redirect as string
      await router.push(redirect || '/dashboard')
      
      return response
    } catch (err: any) {
      error.value = err.response?.data?.detail || '登录失败'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  // 登出
  const logout = async () => {
    try {
      // 清除本地存储
      localStorage.removeItem('access_token')
      localStorage.removeItem('user_info')
      user.value = null
      
      // 跳转到登录页
      await router.push('/login')
    } catch (err) {
      console.error('登出失败:', err)
    }
  }



  // 初始化认证状态
  const initAuth = async () => {
    if (isInitialized.value) {
      return
    }
    
    try {
      isLoading.value = true
      const token = localStorage.getItem('access_token')
      const userInfo = localStorage.getItem('user_info')
      
      if (token && userInfo && userInfo !== 'undefined') {
        try {
          // 先设置本地用户信息
          user.value = JSON.parse(userInfo)
          
          // 验证token是否有效
          const currentUser = await ApiService.getCurrentUser()
          user.value = currentUser
          localStorage.setItem('user_info', JSON.stringify(currentUser))
        } catch (err) {
          // Token无效，清除本地存储
          console.warn('Token验证失败，清除认证状态')
          await logout()
        }
      }
    } catch (err) {
      console.error('初始化认证状态失败:', err)
      await logout()
    } finally {
      isLoading.value = false
      isInitialized.value = true
    }
  }

  // 刷新用户信息
  const refreshUser = async () => {
    try {
      if (isAuthenticated.value) {
        const currentUser = await ApiService.getCurrentUser()
        user.value = currentUser
        localStorage.setItem('user_info', JSON.stringify(currentUser))
      }
    } catch (err) {
      console.error('刷新用户信息失败:', err)
      await logout()
    }
  }



  return {
    user: readonly(user),
    isLoading: readonly(isLoading),
    error: readonly(error),
    isAuthenticated,
    isAdmin,
    isInitialized: readonly(isInitialized),
    login,
    logout,
    initAuth,
    refreshUser,
    
    // 清除错误
    clearError: () => {
      error.value = null
    }
  }
}