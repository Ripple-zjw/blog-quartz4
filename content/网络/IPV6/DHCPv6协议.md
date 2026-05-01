---
date: 2025-10-16T16:25:43
tags:
  - 网络/IPv6
  - 网络/DHCPv6协议
---


# 一、DHCPv6 是什么？

**全称**：Dynamic Host Configuration Protocol for IPv6  
**标准**：RFC 8415（取代旧版 RFC 3315）  
**功能**：

> 通过中心服务器，给 IPv6 主机分配地址、DNS、域名、时间服务器等网络参数。

📘 对应 IPv4 的 DHCP，但工作机制有一些差异。

---

# 二、为什么还需要 DHCPv6？

IPv6 有 **自动配置机制（SLAAC）**，那为什么还要 DHCPv6 呢？
因为 SLAAC 只能提供：
- IPv6 地址（通过前缀 + IID）；
- 默认网关（由 RA 通告）；
但很多企业网络还需要：
- DNS 服务器；
- 域名搜索后缀；
- NTP、SIP 等服务信息；
- 地址集中管理与审计。
这些是 **DHCPv6** 存在的意义。

---
# 三、DHCPv6 的两种工作模式

|模式|功能|特点|是否分配地址|
|---|---|---|---|
|**Stateful（有状态）**|类似 IPv4 DHCP|由服务器集中分配 IPv6 地址|✅ 是|
|**Stateless（无状态）**|仅提供其他配置信息|地址由 SLAAC 自动生成|❌ 否|

这两种模式的选择由 **RA（Router Advertisement）中的 M/O 标志位** 控制：

|标志|含义|对应行为|
|---|---|---|
|**M=1**|Managed Address Configuration|启用 DHCPv6（Stateful）分配地址|
|**O=1**|Other Configuration|启用 DHCPv6（Stateless）提供额外参数|
|**M=0, O=0**|完全靠 SLAAC|不使用 DHCPv6|

举例：
 - 家用网络通常是 SLAAC + Stateless DHCPv6；
 - 企业网络常用 Stateful DHCPv6 进行集中管理。
## 如果客户端收到M标志位不同的两个ra报文怎么办

客户端的行为（RFC 8415 / RFC 4861 指定）
1. **按 RA 优先顺序处理**
	- 客户端会 **合并前缀信息**；
	- RA 提供的前缀和标志位决定是否发起 DHCPv6 请求。
2. **M=1 优先**
	- 如果收到任意 RA 的 M=1，客户端会 **倾向于使用 Stateful DHCPv6** 获取地址；
	- 即便另一台路由器发送 M=0 的 RA，也不会使用 SLAAC 分配地址。
3. **O=1 用于 Stateless DHCPv6**
	- 如果 M=0，但 O=1，则客户端会使用 SLAAC 生成地址，并向 DHCPv6 请求其他参数（DNS 等）；
	- 如果同时存在 M=1 RA，则客户端只做 Stateful DHCPv6 分配，不再单独使用 O=1 的 Stateless 请求获取地址，但仍可获取额外参数。

---
# 四、DHCPv6 报文格式

DHCPv6 使用 **UDP 协议**：

| 方向        | 端口          |
| --------- | ----------- |
| 客户端 → 服务器 | UDP **546** |
| 服务器 → 客户端 | UDP **547** |
## 基本报文结构
```
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| msg-type |                transaction-id                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|            options (variable length)                          |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

| 字段                 | 含义                           |
| ------------------ | ---------------------------- |
| **msg-type**       | 报文类型（例如 SOLICIT、ADVERTISE 等） |
| **transaction-id** | 用于匹配请求/应答                    |
| **options**        | 携带选项内容（IA、DNS、Server ID 等）   |

---
# 五、常见 DHCPv6 报文类型

| 报文名称                        | 类型码     | 方向                | 说明               |
| --------------------------- | ------- | ----------------- | ---------------- |
| **SOLICIT**                 | 1       | Client → Server   | 客户端发现服务器         |
| **ADVERTISE**               | 2       | Server → Client   | 服务器响应并提供可选配置     |
| **REQUEST**                 | 3       | Client → Server   | 请求分配特定地址或参数      |
| **CONFIRM**                 | 4       | Client → Server   | 确认当前地址是否仍然可用     |
| **RENEW**                   | 5       | Client → Server   | 续租地址             |
| **REBIND**                  | 6       | Client → 任意Server | 当前服务器失联后重新绑定     |
| **REPLY**                   | 7       | Server → Client   | 回复（用于多种场景）       |
| **RELEASE**                 | 8       | Client → Server   | 主动释放地址           |
| **DECLINE**                 | 9       | Client → Server   | 拒绝地址（检测到冲突）      |
| **RECONFIGURE**             | 10      | Server → Client   | 强制客户端重新获取配置      |
| **INFORMATION-REQUEST**     | 11      | Client → Server   | Stateless 模式请求参数 |
| **RELAY-FORW / RELAY-REPL** | 12 / 13 | 中继使用              | 用于跨网段转发请求        |

---
# 🔄 六、DHCPv6 有状态分配流程（Stateful）

## 1️⃣ 流程概览
```
Client                             Server
   |---- SOLICIT ------------------>|
   |<--- ADVERTISE -----------------|
   |---- REQUEST ------------------>|
   |<--- REPLY ---------------------|
```

## 2️⃣ 报文详细说明

| 步骤  | 报文类型      | Client → Server？ | Source IP         | Dest IP                            | UDP 端口    | 作用                       |
| --- | --------- | ---------------- | ----------------- | ---------------------------------- | --------- | ------------------------ |
| 1   | SOLICIT   | ✅                | 客户端 Link-local 地址 | `ff02::1:2`（所有 DHCPv6 服务器）或单播服务器地址 | 546 → 547 | 客户端发现网络中的 DHCPv6 服务器     |
| 2   | ADVERTISE | ❌                | 服务器全局地址或链路本地地址    | 客户端 Link-local 地址                  | 547 → 546 | 服务器响应，提供可用地址池信息、配置参数等    |
| 3   | REQUEST   | ✅                | 客户端 Link-local 地址 | DHCPv6 服务器单播地址                     | 546 → 547 | 客户端请求分配某个 IPv6 地址 + 配置参数 |
| 4   | REPLY     | ❌                | DHCPv6 服务器地址      | 客户端地址                              | 547 → 546 | 服务器确认分配地址及参数，包含租期信息      |

---
# 七、无状态模式（Stateless DHCPv6）

**目标**：客户端通过 SLAAC 自动生成 IPv6 地址，DHCPv6 仅提供其他参数（DNS、NTP、搜索域等）

## 流程概览
```
Client                     Server
   |-- INFORMATION-REQUEST -->|
   |<-- REPLY ----------------|
```

## 报文详细说明

| 步骤  | 报文类型                | Client → Server？ | Source IP                    | Dest IP                            | UDP 端口    | 作用                     |
| --- | ------------------- | ---------------- | ---------------------------- | ---------------------------------- | --------- | ---------------------- |
| 1   | INFORMATION-REQUEST | ✅                | 客户端 Link-local 地址（SLAAC 已生成） | `ff02::1:2`（所有 DHCPv6 服务器）或单播服务器地址 | 546 → 547 | 客户端请求其他网络参数（如 DNS、NTP） |
| 2   | REPLY               | ❌                | DHCPv6 服务器地址                 | 客户端地址                              | 547 → 546 | 服务器返回配置信息（不分配 IPv6 地址） |

---
# 八、DHCPv6 Option

## 报文结构

所有 DHCPv6 选项都遵循统一格式：

| 字段                | 长度（字节） | 含义                                      |
| ----------------- | ------ | --------------------------------------- |
| **Option Code**   | 2      | 标识是哪种选项（如 IA_NA、ServerID、Status Code 等） |
| **Option Length** | 2      | 后续数据（Option Data）的长度（不含前4字节）            |
| **Option Data**   | 可变     | 具体内容，例如地址、时间、子选项等                       |

```
0             1                 2                 3
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Option Code           |         Option Length         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
.                         Option Data                           .
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Option 的嵌套结构（支持层级）
DHCPv6 Option 支持 **嵌套（Nested Options）**，即一个选项内部再包含其他选项。
例如
```
OPTION_IA_NA (Code 3)
 ├─ IAID
 ├─ T1
 ├─ T2
 ├─ OPTION_IAADDR (Code 5)
 │   ├─ IPv6 Address
 │   ├─ Preferred Lifetime
 │   ├─ Valid Lifetime
 │   └─ (可能还有子选项，例如 OPTION_STATUS_CODE)
 └─ OPTION_STATUS_CODE (Code 13)
```

#### DHCPv6 option是如何解析出哪个是子option哪个是数据的？

RFC 8415 定义的所有 DHCPv6 Option 都有统一的**TLV 格式**：
**关键点：没有额外标志位来区分，完全靠 Option Code 来定义结构。**

也就是说——
> DHCPv6 协议的每一个 Option（通过 Option Code 区分）在 RFC 中都有自己固定的内部格式。  
> 你必须根据 Option Code 的定义来解析 Option Data。

举例：Option 3 —— IA_NA（Identity Association for Non-temporary Address）

|字段|长度|说明|
|---|---|---|
|IAID|4|客户端分配的 IA ID|
|T1|4|续租时间|
|T2|4|重新绑定时间|
|IA_NA-options|可变|这里开始是一系列嵌套的 **子 Option**|

注意这里最后一部分是“IA_NA-options”，它自己又是一组 TLV 格式的子 Option。  
常见的子 Option 有：
- **Option 5**（IA Address）
- **Option 13**（Status Code）

所以，当 DHCPv6 客户端或服务器解析到 Option Code = 3 时，它知道：
- 前 12 字节是固定字段（IAID, T1, T2）
- 剩下的部分是嵌套的 Option 列表

总结: 每个option都由**固定长度**加可选部分组成，要根据**Opion Length**判断是否还有可选的子option。

## DHCPv6 常见选项一览表

| 代码 (Option Code) | 名称 (Option Name)         | 类型 / 内容                                                    | 说明                                        | 常见在哪些报文中出现                        |
| ---------------- | ------------------------ | ---------------------------------------------------------- | ----------------------------------------- | --------------------------------- |
| **1**            | **OPTION_CLIENTID**      | 客户端 DUID                                                   | 用于唯一标识客户端。DUID 通常基于 MAC + 时间戳或 UUID。      | Solicit, Request, Renew, Rebind 等 |
| **2**            | **OPTION_SERVERID**      | 服务器 DUID                                                   | 标识 DHCPv6 服务器，客户端通过它区分不同服务器。              | Advertise, Reply                  |
| **3**            | **OPTION_IA_NA**         | IA_NA 结构（Identity Association for Non-temporary Addresses） | 请求或分配非临时 IPv6 地址。内含 IAID、T1/T2 定时器。       | Solicit, Request, Reply           |
| **4**            | **OPTION_IA_TA**         | IA_TA 结构（Temporary Address）                                | 请求临时地址（Privacy Address）。                  | Solicit, Request, Reply           |
| **5**            | **OPTION_IAADDR**        | 地址信息                                                       | 在 IA_NA/IA_TA 内部，用来携带具体 IPv6 地址、首选/有效期。   | Reply, Renew, Rebind              |
| **6**            | **OPTION_ORO**           | Option Request Option                                      | 告诉服务器客户端希望返回哪些 Option（类似请求清单）。            | Solicit, Request                  |
| **7**            | **OPTION_PREFERENCE**    | 数值型（0–255）                                                 | 服务器优先级，值越高优先。客户端据此选择服务器。                  | Advertise                         |
| **8**            | **OPTION_ELAPSED_TIME**  | 毫秒计时器                                                      | 从客户端启动 DHCPv6 流程开始的时间（避免重试过快）。            | Solicit, Request                  |
| **9**            | **OPTION_RELAY_MSG**     | Relay message 封装                                           | 中继代理封装原始 DHCP 报文内容。                       | Relay-forward / Relay-reply       |
| **11**           | **OPTION_AUTH**          | Authentication                                             | DHCPv6 消息认证（很少使用）。                        | 全部可用                              |
| **12**           | **OPTION_UNICAST**       | IPv6 地址                                                    | 告诉客户端后续请求可直接单播到该地址（优化后续通信）。               | Reply                             |
| **13**           | **OPTION_STATUS_CODE**   | 状态码 + 描述                                                   | 表示结果（Success, NoAddrsAvail, NotOnLink 等）。 | Reply, Renew                      |
| **14**           | **OPTION_RAPID_COMMIT**  | 空值                                                         | 指示支持快速分配（两步流程 Solicit → Reply）。           | Solicit, Reply                    |
| **15**           | **OPTION_USER_CLASS**    | 用户分类字符串                                                    | 客户端声明自己的类型（例如“VoIP”或“Printer”）。           | Solicit, Request                  |
| **16**           | **OPTION_VENDOR_CLASS**  | Vendor Class                                               | 客户端厂商标识（OUI + class data）。                | Solicit, Request                  |
| **17**           | **OPTION_VENDOR_OPTS**   | Vendor-specific Options                                    | 厂商自定义字段。                                  | Reply                             |
| **18**           | **OPTION_INTERFACE_ID**  | 中继使用的接口标识                                                  | 让中继在返回时知道对应哪条链路。                          | Relay-forward / Relay-reply       |
| **19**           | **OPTION_RECONF_MSG**    | 重新配置消息类型                                                   | 用于服务器主动通知客户端更新配置。                         | Reconfigure                       |
| **20**           | **OPTION_RECONF_ACCEPT** | 空值                                                         | 客户端声明支持 Reconfigure。                      | Solicit                           |
## 地址相关选项（Prefix / Delegation）
| 代码     | 名称                  | 功能                   | 说明                         |
| ------ | ------------------- | -------------------- | -------------------------- |
| **25** | **OPTION_IA_PD**    | Prefix Delegation IA | 请求前缀委派（PD）。常用于路由器获取下级网段。   |
| **26** | **OPTION_IAPREFIX** | 前缀信息                 | 在 IA_PD 内部，指定分配的前缀、首选/有效期。 |
## 网络参数类选项（DNS / NTP / Domain）

| 代码           | 名称                      | 功能                                         | 来源 RFC                    |
| ------------ | ----------------------- | ------------------------------------------ | ------------------------- |
| **23**       | **OPTION_DNS_SERVERS**  | DNS 服务器地址                                  | RFC 3646                  |
| **24**       | **OPTION_DOMAIN_LIST**  | 搜索域名后缀（如 example.com）                      | RFC 3646                  |
| **31**       | **OPTION_SNTP_SERVERS** | 时间同步服务器                                    | RFC 4075                  |
| **56**       | **OPTION_NTP_SERVER**   | 更通用的 NTP 信息（替代 SNTP）                       | RFC 5908                  |
| **25xx**（范围） | **RDNSS / DNSSL**       | Router Advertisement 选项，对应 DHCPv6 的 DNS 扩展 | RFC 6106（通常不通过 DHCPv6 实现） |

---
# 九、DHCPv6 与 SLAAC/NDP 的关系

| 功能       | SLAAC         | DHCPv6     |
| -------- | ------------- | ---------- |
| 地址分配     | ✅ 自动生成        | ✅ 服务器分配    |
| 网关       | ✅ 由 RA 提供     | ❌ 不提供      |
| DNS / 域名 | ❌（需 RDNSS 扩展） | ✅ 提供       |
| 地址可追踪性   | ❌ 难以集中管理      | ✅ 易于审计     |
| 使用场景     | 家用、轻量环境       | 企业、ISP、云平台 |
