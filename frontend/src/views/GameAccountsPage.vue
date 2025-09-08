<template>
  <div class="game-accounts-page">
    <div class="page-header">
      <h1>游戏账户管理</h1>
      <div class="header-actions">
        <el-button @click="refreshData" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新数据
        </el-button>
      </div>
    </div>

    <!-- 账户列表 -->
    <el-card class="accounts-card">
      <template #header>
        <div class="card-header">
          <span>游戏账户列表</span>
          <el-input
            v-model="searchText"
            placeholder="搜索账户ID"
            style="width: 200px"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>
      </template>
      
      <el-table
        :data="filteredAccounts"
        v-loading="loading"
        @row-click="selectAccount"
        highlight-current-row
      >
        <el-table-column prop="account_id" label="账户ID" width="200" />
        <el-table-column prop="level" label="等级" width="80" />
        <el-table-column prop="last_terminal_id" label="最后登录终端" width="150" />
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="updated_at" label="最后更新" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.updated_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button
              type="primary"
              size="small"
              @click.stop="viewAccountDetails(row)"
            >
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 账户详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      :title="`账户详情 - ${selectedAccount?.account_id}`"
      width="80%"
      top="5vh"
    >
      <el-tabs v-model="activeTab" v-if="selectedAccount">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="账户ID">
              {{ selectedAccount.account_id }}
            </el-descriptions-item>
            <el-descriptions-item label="等级">
              {{ selectedAccount.level || '未知' }}
            </el-descriptions-item>
            <el-descriptions-item label="最后登录终端">
              {{ selectedAccount.last_terminal_id || '无' }}
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">
              {{ formatDateTime(selectedAccount.created_at) }}
            </el-descriptions-item>
            <el-descriptions-item label="最后更新">
              {{ formatDateTime(selectedAccount.updated_at) }}
            </el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 登录记录 -->
        <el-tab-pane label="登录记录" name="login">
          <el-table :data="loginRecords" v-loading="loadingDetails">
            <el-table-column prop="terminal_id" label="终端ID" width="150" />
            <el-table-column prop="region_code" label="区服" width="100" />
            <el-table-column prop="login_time" label="登录时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.login_time) }}
              </template>
            </el-table-column>
            <el-table-column prop="created_at" label="记录时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.created_at) }}
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 资产记录 -->
        <el-tab-pane label="资产记录" name="assets">
          <el-table :data="assetRecords" v-loading="loadingDetails">
            <el-table-column prop="terminal_id" label="终端ID" width="150" />
            <el-table-column prop="gold" label="金子" width="100">
              <template #default="{ row }">
                {{ formatNumber(row.gold) }}
              </template>
            </el-table-column>
            <el-table-column prop="diamond" label="元宝" width="100">
              <template #default="{ row }">
                {{ formatNumber(row.diamond) }}
              </template>
            </el-table-column>
            <el-table-column prop="energy" label="体力" width="80" />
            <el-table-column prop="experience" label="经验" width="100">
              <template #default="{ row }">
                {{ formatNumber(row.experience) }}
              </template>
            </el-table-column>
            <el-table-column prop="level" label="等级" width="80" />
            <el-table-column prop="vip_level" label="VIP等级" width="100" />
            <el-table-column prop="report_time" label="上报时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.report_time) }}
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 背包记录 -->
        <el-tab-pane label="背包记录" name="inventory">
          <el-table :data="inventoryRecords" v-loading="loadingDetails">
            <el-table-column prop="terminal_id" label="终端ID" width="150" />
            <el-table-column prop="item_name" label="物品名称" width="200" />
            <el-table-column prop="item_type" label="物品类型" width="120" />
            <el-table-column prop="quantity" label="数量" width="100">
              <template #default="{ row }">
                {{ formatNumber(row.quantity) }}
              </template>
            </el-table-column>
            <el-table-column prop="report_time" label="上报时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.report_time) }}
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Search } from '@element-plus/icons-vue'
import api from '@/api'

// 响应式数据
const loading = ref(false)
const loadingDetails = ref(false)
const accounts = ref([])
const searchText = ref('')
const detailDialogVisible = ref(false)
const selectedAccount = ref(null)
const activeTab = ref('basic')
const loginRecords = ref([])
const assetRecords = ref([])
const inventoryRecords = ref([])

// 计算属性
const filteredAccounts = computed(() => {
  if (!searchText.value) {
    return accounts.value
  }
  return accounts.value.filter(account => 
    account.account_id.toLowerCase().includes(searchText.value.toLowerCase())
  )
})

// 方法
const loadAccounts = async () => {
  loading.value = true
  try {
    const response = await api.get('/game-accounts')
    accounts.value = response.data
  } catch (error) {
    console.error('加载游戏账户失败:', error)
    ElMessage.error('加载游戏账户失败')
  } finally {
    loading.value = false
  }
}

const refreshData = () => {
  loadAccounts()
}

const handleSearch = () => {
  // 搜索逻辑已在计算属性中处理
}

const selectAccount = (row) => {
  selectedAccount.value = row
}

const viewAccountDetails = async (account) => {
  selectedAccount.value = account
  detailDialogVisible.value = true
  activeTab.value = 'basic'
  
  // 加载详细数据
  await loadAccountDetails(account.account_id)
}

const loadAccountDetails = async (accountId) => {
  loadingDetails.value = true
  try {
    // 并行加载所有详细数据
    const [loginResponse, assetResponse, inventoryResponse] = await Promise.all([
      api.get(`/game-accounts/${accountId}/login-records`),
      api.get(`/game-accounts/${accountId}/asset-records`),
      api.get(`/game-accounts/${accountId}/inventory-records`)
    ])
    
    loginRecords.value = loginResponse.data
    assetRecords.value = assetResponse.data
    inventoryRecords.value = inventoryResponse.data
  } catch (error) {
    console.error('加载账户详情失败:', error)
    ElMessage.error('加载账户详情失败')
  } finally {
    loadingDetails.value = false
  }
}

const formatDateTime = (dateTime) => {
  if (!dateTime) return ''
  return new Date(dateTime).toLocaleString('zh-CN')
}

const formatNumber = (number) => {
  if (number === null || number === undefined) return ''
  return number.toLocaleString()
}

// 生命周期
onMounted(() => {
  loadAccounts()
})
</script>

<style scoped>
.game-accounts-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  color: #303133;
}

.accounts-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.el-table {
  cursor: pointer;
}

.el-table .el-table__row:hover {
  background-color: #f5f7fa;
}

.el-dialog {
  max-height: 90vh;
  overflow-y: auto;
}

.el-descriptions {
  margin-bottom: 20px;
}

.el-tab-pane {
  max-height: 60vh;
  overflow-y: auto;
}
</style>