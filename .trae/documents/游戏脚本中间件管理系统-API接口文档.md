# 游戏脚本中间件管理系统 - API接口文档

## 1. 接口概述

### 1.1 基础信息

- **协议**: HTTP/HTTPS
- **数据格式**: JSON
- **字符编码**: UTF-8
- **API版本**: v1.0
- **基础URL**: `http://localhost:8003/api/v1`
- **开放API基础URL**: `http://localhost:8003/open-api/v1`

### 1.2 认证方式

系统采用多种认证方式：

- **内部API**: 使用JWT Token认证
- **开放API**: 使用API Key + Basic Auth认证
  - API Key通过 `X-API-Key` 请求头传递
  - Basic Auth使用用户管理系统的账户和密码

### 1.3 统一响应格式

**成功响应格式**:
```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": 1640995200000
}
```

**错误响应格式**:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  },
  "timestamp": 1640995200000
}
```

**分页响应格式**:
```json
{
  "success": true,
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100,
      "totalPages": 5
    }
  },
  "message": "查询成功",
  "timestamp": 1640995200000
}
```

## 2. 开放API接口

### 2.1 终端设备注册

**接口描述**: 终端设备首次连接时进行注册，上报设备基本信息

```http
POST /open-api/v1/terminals/register
X-API-Key: test_api_key
Authorization: Basic YWRtaW46YWRtaW4xMjM=
Content-Type: application/json

{
  "terminal_id": "TERM_20240115_001",
  "system_version": "Android 13",
  "is_rooted": true,
  "imei": "123456789012345",
  "ip_address": "192.168.1.100",
  "device_model": "Samsung Galaxy S23",
  "device_brand": "Samsung"
}
```

**请求参数说明**:
- `terminal_id`: 终端唯一标识符（必填，字符串，长度1-50字符）
- `system_version`: 系统版本信息（可选，字符串）
- `is_rooted`: 是否已Root/越狱（可选，布尔值，默认false）
- `imei`: 设备IMEI号（可选，字符串，长度15位）
- `ip_address`: IP地址（可选，字符串）
- `device_model`: 设备型号（可选，字符串）
- `device_brand`: 设备品牌（可选，字符串）

**成功响应**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "terminal_id": "TERM_20240115_001",
    "system_version": "Android 13",
    "is_rooted": true,
    "imei": "123456789012345",
    "ip_address": "192.168.1.100",
    "device_model": "Samsung Galaxy S23",
    "device_brand": "Samsung",
    "first_report_time": "2024-01-15T10:30:00Z",
    "last_report_time": "2024-01-15T10:30:00Z",
    "report_count": 1
  },
  "message": "终端注册成功"
}
```

**功能说明**:
- 终端设备自动上报基本信息和状态
- 首次上报会创建新的终端记录
- 重复上报会更新现有终端的上报时间和次数
- 支持Android和iOS设备信息收集
- 自动记录设备的Root/越狱状态

### 2.2 获取登录账号信息

**接口描述**: 基于终端ID获取可用的游戏账号登录凭证

```http
GET /open-api/v1/terminals/{terminal_id}/account
X-API-Key: test_api_key
Authorization: Basic YWRtaW46YWRtaW4xMjM=
```

**路径参数**:
- `terminal_id`: 终端ID（必填，字符串）

**成功响应**:
```json
{
  "success": true,
  "data": {
    "username": "阿泠",
    "password": "abc123456",
    "region_info": {
      "region_id": "server_01", 
      "region_name": "华东一区",
      "server_ip": "192.168.1.100",
      "server_port": 8080
    },
    "account_status": "active",
    "last_login_time": "2024-01-15T10:30:00Z",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  },
  "message": "账号信息获取成功"
}
```

**功能说明**:
- 基于终端注册成功后，使用terminal_id查询可用账户信息
- 返回账户基本信息、登录密码及所属区域信息
- 账户ID格式：{用户名} {数字ID}
- 支持多区域服务器配置

### 2.3 账户登录信息上报

**接口描述**: 游戏账户登录成功后上报登录信息

```http
POST /open-api/v1/terminals/{terminal_id}/login-report
X-API-Key: test_api_key
Authorization: Basic YWRtaW46YWRtaW4xMjM=
Content-Type: application/json

{
  "account_id": "阿泠 19434740304384",
  "region_info": {
    "region_id": "server_01",
    "region_name": "华东一区"
  },
  "login_time": "2024-01-15T10:30:00Z",
  "login_status": "success"
}
```

**请求参数说明**:
- `account_id`: 账户ID（必填，字符串，格式：用户名 数字ID）
- `region_info`: 区域信息（必填，对象）
  - `region_id`: 区域ID（必填，字符串）
  - `region_name`: 区域名称（必填，字符串）
- `login_time`: 登录时间（必填，字符串，ISO 8601格式）
- `login_status`: 登录状态（必填，字符串，success/failed）

**成功响应**:
```json
{
  "success": true,
  "data": {
    "report_id": 1001,
    "account_id": "阿泠 19434740304384",
    "terminal_id": "TERM_20240115_001",
    "region_info": {
      "region_id": "server_01",
      "region_name": "华东一区"
    },
    "login_time": "2024-01-15T10:30:00Z",
    "login_status": "success",
    "report_time": "2024-01-15T10:30:05Z"
  },
  "message": "登录信息上报成功"
}
```

**功能说明**:
- 登录成功后上报账户ID信息和所属区域信息
- 所有上报信息以账户ID作为主键
- 记录登录时间和上报时间
- 支持登录状态跟踪

### 2.4 资产信息上报

**接口描述**: 上报游戏账户的资产信息，包括各种货币和道具

```http
POST /open-api/v1/terminals/{terminal_id}/assets-report
X-API-Key: test_api_key
Authorization: Basic YWRtaW46YWRtaW4xMjM=
Content-Type: application/json

{
  "account_id": "阿泠 19434740304384",
  "assets": {
    "yuan_bao": 50000,
    "gold": 1000000,
    "silver": 500000,
    "other_currency": {
      "points": 2500,
      "tokens": 150
    }
  },
  "report_time": "2024-01-15T10:35:00Z"
}
```

**请求参数说明**:
- `account_id`: 账户ID（必填，字符串）
- `assets`: 资产信息（必填，对象）
  - `yuan_bao`: 元宝数量（可选，整数）
  - `gold`: 金币数量（可选，整数）
  - `silver`: 银币数量（可选，整数）
  - `other_currency`: 其他货币（可选，对象）
- `report_time`: 上报时间（必填，字符串，ISO 8601格式）

**成功响应**:
```json
{
  "success": true,
  "data": {
    "report_id": 1002,
    "account_id": "阿泠 19434740304384",
    "terminal_id": "TERM_20240115_001",
    "assets": {
      "yuan_bao": 50000,
      "gold": 1000000,
      "silver": 500000,
      "other_currency": {
        "points": 2500,
        "tokens": 150
      }
    },
    "report_time": "2024-01-15T10:35:00Z",
    "created_at": "2024-01-15T10:35:05Z"
  },
  "message": "资产信息上报成功"
}
```

**功能说明**:
- 上报账户基础资产信息
- 包括元宝、金币、银币及其他货币信息
- 以账户ID作为主键进行数据关联
- 支持自定义货币类型扩展

### 2.5 背包材料上报

**接口描述**: 上报游戏账户背包内的物品和材料信息

```http
POST /open-api/v1/terminals/{terminal_id}/inventory-report
X-API-Key: test_api_key
Authorization: Basic YWRtaW46YWRtaW4xMjM=
Content-Type: application/json

{
  "account_id": "阿泠 19434740304384",
  "inventory_items": [
    {
      "item_name": "大钱",
      "item_id": "money_001",
      "quantity": 999,
      "item_type": "currency"
    },
    {
      "item_name": "完美精炼石",
      "item_id": "stone_001",
      "quantity": 50,
      "item_type": "material"
    },
    {
      "item_name": "金条",
      "item_id": "gold_bar_001",
      "quantity": 25,
      "item_type": "valuable"
    }
  ],
  "report_time": "2024-01-15T10:40:00Z"
}
```

**请求参数说明**:
- `account_id`: 账户ID（必填，字符串）
- `inventory_items`: 背包物品列表（必填，数组）
  - `item_name`: 物品名称（必填，字符串）
  - `item_id`: 物品ID（必填，字符串）
  - `quantity`: 物品数量（必填，整数）
  - `item_type`: 物品类型（必填，字符串，如：currency/material/valuable/equipment等）
- `report_time`: 上报时间（必填，字符串，ISO 8601格式）

**成功响应**:
```json
{
  "success": true,
  "data": {
    "report_id": 1003,
    "account_id": "阿泠 19434740304384",
    "terminal_id": "TERM_20240115_001",
    "inventory_items": [
      {
        "item_name": "大钱",
        "item_id": "money_001",
        "quantity": 999,
        "item_type": "currency"
      },
      {
        "item_name": "完美精炼石",
        "item_id": "stone_001",
        "quantity": 50,
        "item_type": "material"
      },
      {
        "item_name": "金条",
        "item_id": "gold_bar_001",
        "quantity": 25,
        "item_type": "valuable"
      }
    ],
    "total_items": 3,
    "report_time": "2024-01-15T10:40:00Z",
    "created_at": "2024-01-15T10:40:05Z"
  },
  "message": "背包材料上报成功"
}
```

**功能说明**:
- 上报账户背包内材料明细
- 包括大钱、完美精炼石、金条等物品
- 记录物品名称、ID、数量和类型
- 以账户ID作为主键进行数据关联
- 支持多种物品类型分类

## 3. 数据规范要求

### 3.1 通用规范
- 所有上报信息必须以账户ID作为主键
- 账户ID格式示例：阿泠 19434740304384
- 所有时间字段使用ISO 8601格式（YYYY-MM-DDTHH:mm:ssZ）
- 数量字段必须为非负整数
- 字符串字段不能包含特殊控制字符

### 3.2 认证规范
- API Key通过X-API-Key请求头传递
- Basic Auth使用Base64编码的"username:password"格式
- 所有开放API接口都需要同时提供API Key和Basic Auth认证

### 3.3 错误处理
- 认证失败返回401状态码
- 参数验证失败返回400状态码
- 资源不存在返回404状态码
- 服务器内部错误返回500状态码

## 4. 错误码定义

### 4.1 认证相关错误

| 错误码 | 描述 |
|--------|------|
| AUTH_001 | API Key无效或缺失 |
| AUTH_002 | Basic Auth认证失败 |
| AUTH_003 | 用户账户被禁用 |
| AUTH_004 | 权限不足 |
| AUTH_005 | 认证信息格式错误 |

### 4.2 终端相关错误

| 错误码 | 描述 |
|--------|------|
| TERMINAL_001 | 终端不存在 |
| TERMINAL_002 | 终端ID重复 |
| TERMINAL_003 | 终端状态异常 |
| TERMINAL_004 | 终端离线 |
| TERMINAL_005 | 设备信息验证失败 |

### 4.3 账户相关错误

| 错误码 | 描述 |
|--------|------|
| ACCOUNT_001 | 账户不存在 |
| ACCOUNT_002 | 账户ID格式错误 |
| ACCOUNT_003 | 账户状态异常 |
| ACCOUNT_004 | 账户信息不完整 |
| ACCOUNT_005 | 账户权限不足 |

### 4.4 数据上报相关错误

| 错误码 | 描述 |
|--------|------|
| REPORT_001 | 上报数据格式错误 |
| REPORT_002 | 上报时间格式错误 |
| REPORT_003 | 数据验证失败 |
| REPORT_004 | 上报频率超限 |
| REPORT_005 | 数据保存失败 |

### 4.5 系统相关错误

| 错误码 | 描述 |
|--------|------|
| SYSTEM_001 | 系统维护中 |
| SYSTEM_002 | 请求频率限制 |
| SYSTEM_003 | 数据库连接失败 |
| SYSTEM_004 | 内部服务错误 |
| SYSTEM_005 | 参数验证失败 |

## 5. 使用示例

### 5.1 完整API调用流程

以下是一个完整的API调用流程示例，展示了从设备注册到数据上报的完整过程：

```python
import requests
import json
from datetime import datetime
import base64

class GameScriptAPIClient:
    def __init__(self, base_url, api_key, username, password):
        self.base_url = base_url
        self.api_key = api_key
        self.auth_header = base64.b64encode(f"{username}:{password}".encode()).decode()
        self.terminal_id = "TERM_20240115_001"
    
    def get_headers(self):
        return {
            "X-API-Key": self.api_key,
            "Authorization": f"Basic {self.auth_header}",
            "Content-Type": "application/json"
        }
    
    # 1. 设备注册
    def register_terminal(self):
        url = f"{self.base_url}/open-api/v1/terminals/register"
        data = {
            "terminal_id": self.terminal_id,
            "system_version": "Android 13",
            "is_rooted": True,
            "imei": "123456789012345",
            "ip_address": "192.168.1.100",
            "device_model": "Samsung Galaxy S23",
            "device_brand": "Samsung"
        }
        response = requests.post(url, headers=self.get_headers(), json=data)
        return response.json()
    
    # 2. 获取账户信息
    def get_account_info(self):
        url = f"{self.base_url}/open-api/v1/terminals/{self.terminal_id}/account"
        response = requests.get(url, headers=self.get_headers())
        return response.json()
    
    # 3. 登录信息上报
    def report_login(self, account_id):
        url = f"{self.base_url}/open-api/v1/terminals/{self.terminal_id}/login-report"
        data = {
            "account_id": account_id,
            "region_info": {
                "region_id": "server_01",
                "region_name": "华东一区"
            },
            "login_time": datetime.now().isoformat() + "Z",
            "login_status": "success"
        }
        response = requests.post(url, headers=self.get_headers(), json=data)
        return response.json()
    
    # 4. 资产信息上报
    def report_assets(self, account_id):
        url = f"{self.base_url}/open-api/v1/terminals/{self.terminal_id}/assets-report"
        data = {
            "account_id": account_id,
            "assets": {
                "yuan_bao": 50000,
                "gold": 1000000,
                "silver": 500000,
                "other_currency": {
                    "points": 2500,
                    "tokens": 150
                }
            },
            "report_time": datetime.now().isoformat() + "Z"
        }
        response = requests.post(url, headers=self.get_headers(), json=data)
        return response.json()
    
    # 5. 背包物品上报
    def report_inventory(self, account_id):
        url = f"{self.base_url}/open-api/v1/terminals/{self.terminal_id}/inventory-report"
        data = {
            "account_id": account_id,
            "inventory_items": [
                {
                    "item_name": "大钱",
                    "item_id": "money_001",
                    "quantity": 999,
                    "item_type": "currency"
                },
                {
                    "item_name": "完美精炼石",
                    "item_id": "stone_001",
                    "quantity": 50,
                    "item_type": "material"
                },
                {
                    "item_name": "金条",
                    "item_id": "gold_bar_001",
                    "quantity": 25,
                    "item_type": "valuable"
                }
            ],
            "report_time": datetime.now().isoformat() + "Z"
        }
        response = requests.post(url, headers=self.get_headers(), json=data)
        return response.json()

# 使用示例
client = GameScriptAPIClient(
    base_url="http://localhost:8003",
    api_key="test_api_key",
    username="admin",
    password="admin123"
)

# 执行完整流程
print("1. 注册设备...")
register_result = client.register_terminal()
print(json.dumps(register_result, indent=2, ensure_ascii=False))

print("\n2. 获取账户信息...")
account_result = client.get_account_info()
print(json.dumps(account_result, indent=2, ensure_ascii=False))

if account_result.get("success"):
    account_id = account_result["data"]["account_id"]
    
    print("\n3. 上报登录信息...")
    login_result = client.report_login(account_id)
    print(json.dumps(login_result, indent=2, ensure_ascii=False))
    
    print("\n4. 上报资产信息...")
    assets_result = client.report_assets(account_id)
    print(json.dumps(assets_result, indent=2, ensure_ascii=False))
    
    print("\n5. 上报背包信息...")
    inventory_result = client.report_inventory(account_id)
    print(json.dumps(inventory_result, indent=2, ensure_ascii=False))
```

### 5.2 错误处理示例

```python
def handle_api_response(response):
    """统一处理API响应"""
    try:
        data = response.json()
        if data.get("success"):
            print(f"✅ 操作成功: {data.get('message')}")
            return data["data"]
        else:
            error = data.get("error", {})
            print(f"❌ 操作失败: {error.get('message')}")
            print(f"错误码: {error.get('code')}")
            if error.get("details"):
                print(f"详细信息: {error['details']}")
            return None
    except json.JSONDecodeError:
        print(f"❌ 响应格式错误: {response.text}")
        return None
    except Exception as e:
        print(f"❌ 处理响应时发生错误: {str(e)}")
        return None
```

## 6. 版本更新记录

### v1.0.0 (2024-01-15)
- 初始版本发布
- 实现终端设备注册接口
- 实现账户信息获取接口
- 实现登录信息上报接口
- 实现资产信息上报接口
- 实现背包物品上报接口
- 支持API Key + Basic Auth双重认证
- 完善错误码定义和数据模型

---

**文档最后更新时间**: 2024-01-15  
**API版本**: v1.0  
**服务器地址**: http://localhost:8003  
**技术支持**: 游戏脚本中间件开发团队