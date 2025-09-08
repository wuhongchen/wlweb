import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '@/pages/HomePage.vue'
import LoginPage from '@/pages/LoginPage.vue'
import DashboardPage from '@/pages/DashboardPage.vue'
import TerminalsPage from '@/pages/TerminalsPage.vue'
import TerminalDetailPage from '@/pages/TerminalDetailPage.vue'
import TasksPage from '@/pages/TasksPage.vue'
import TaskDetailPage from '@/pages/TaskDetailPage.vue'
import AccountAssetsPage from '@/pages/AccountAssetsPage.vue'
import GameAccountsPage from '@/pages/GameAccountsPage.vue'
import SettingsPage from '@/pages/SettingsPage.vue'
import SystemConfigPage from '@/pages/SystemConfigPage.vue'
import UserManagementPage from '@/pages/UserManagementPage.vue'
import { useAuth } from '@/composables/useAuth'

// 定义路由配置
const routes = [
  {
    path: '/',
    name: 'home',
    component: HomePage,
    meta: { requiresAuth: false }
  },
  {
    path: '/login',
    name: 'login',
    component: LoginPage,
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: DashboardPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/terminals',
    name: 'terminals',
    component: TerminalsPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/terminals/:id',
    name: 'terminal-detail',
    component: TerminalDetailPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/tasks',
    name: 'tasks',
    component: TasksPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/tasks/:id',
    name: 'task-detail',
    component: TaskDetailPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/account-assets',
    name: 'account-assets',
    component: AccountAssetsPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/game-accounts',
    name: 'game-accounts',
    component: GameAccountsPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/settings',
    name: 'settings',
    component: SettingsPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/system-config',
    name: 'system-config',
    component: SystemConfigPage,
    meta: { requiresAuth: true }
  },
  {
    path: '/user-management',
    name: 'user-management',
    component: UserManagementPage,
    meta: { requiresAuth: true, requiresAdmin: true }
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHistory('/'),
  routes,
})

// 路由守卫
router.beforeEach(async (to, from, next) => {
  const { isAuthenticated, isInitialized, initAuth, isAdmin } = useAuth()
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const requiresAdmin = to.matched.some(record => record.meta.requiresAdmin)
  
  // 如果认证状态未初始化，先初始化
  if (!isInitialized.value) {
    try {
      await initAuth()
    } catch (error) {
      console.error('认证状态初始化失败:', error)
    }
  }
  
  if (requiresAuth && !isAuthenticated.value) {
    // 需要认证但未认证，跳转到登录页
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else if (requiresAdmin && !isAdmin.value) {
    // 需要管理员权限但不是管理员，跳转到仪表板
    next({ name: 'dashboard' })
  } else if (to.name === 'login' && isAuthenticated.value) {
    // 已登录用户访问登录页，跳转到仪表板
    next({ name: 'dashboard' })
  } else {
    next()
  }
})

export default router
