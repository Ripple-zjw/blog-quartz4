---
date: 2025-10-16T16:25:43
---


#网络/IPv6/ICMPv6协议  

**ICMPv6 是 IPv6 协议栈中最重要的基础协议之一**，它不仅仅是“错误提示”那么简单，还承载了邻居发现（NDP）、组播监听（MLD）、路由器通告（RA/RS）等核心功能。

---

# 🧩 一、ICMPv6 的定位

> ICMPv6（Internet Control Message Protocol for IPv6）  
> 定义于 **RFC 4443**

它相当于 IPv4 的 ICMP，但功能更强大、结构更统一。  
ICMPv6 负责：
- 报告 IPv6 层的错误（比如目的不可达、包太大）
- 发送诊断消息（如 ping）
- 承载其他控制协议（比如 NDP、MLD、RA、RS）

> ✅ IPv6 运行中几乎所有“控制类”操作，都通过 ICMPv6 完成。

---

# 🧱 二、ICMPv6 报文结构

基本格式：

```
+----------------+----------------+----------------+-----------------+
|     Type       |     Code       |               Checksum           |
+----------------+----------------+----------------+-----------------+
|                         Message Body (Data)                        |
+--------------------------------------------------------------------+
```

- **Type**：标识消息类型
- **Code**：进一步区分消息子类型
- **Checksum**：校验和（包含 IPv6 伪首部）
- **Message Body**：实际内容（依类型不同）

---

# ⚠️ 三、ICMPv6 的两大类消息

## 1️⃣ 错误消息（Type < 128）

| Type  | Code | 含义                              |
| ----- | ---- | ------------------------------- |
| **1** | 多种   | 目的地不可达（Destination Unreachable） |
| **2** | 0    | 分组太大（Packet Too Big）            |
| **3** | 多种   | 超时（Time Exceeded）               |
| **4** | 多种   | 参数问题（Parameter Problem）         |
**说明：**

- “Packet Too Big” 是 IPv6 的路径 MTU 发现机制的关键。
	- 因为 IPv6 不支持中间节点分片，这条消息用于告知源主机降低包大小。
- “Parameter Problem” 通常是 IPv6 头或扩展头出错时触发。

### 🧱 Type 1：Destination Unreachable

> 📜 RFC 4443 §3.1  
> 当路由器或主机无法递交数据包时发送。

#### 报文结构

```
Type = 1
Code = 不同的不可达原因
+-------------------------------------------------+
|  Unused (4 bytes, set to zero)                  |
+-------------------------------------------------+
|  As much of invoking packet as will fit         |
+-------------------------------------------------+
```

#### code类型

| Code  | 含义                                                         | 触发场景                           |
| ----- | ---------------------------------------------------------- | ------------------------------ |
| **0** | No route to destination                                    | 没有匹配路由                         |
| **1** | Communication with destination administratively prohibited | 防火墙或策略禁止                       |
| **2** | Beyond scope of source address                             | 地址范围超出（如 link-local 发到 global） |
| **3** | Address unreachable                                        | 目标地址不可达（ARP/NDP 失败）            |
| **4** | Port unreachable                                           | 目标端口无响应（常见于 UDP）               |
| **5** | Source address failed ingress/egress policy                | 源地址策略被拒                        |
| **6** | Reject route to destination                                | 路由被标记为拒绝                       |
### 📦 Type 2：Packet Too Big

> 📜 RFC 4443 §3.2  
> IPv6 不允许中间节点分片，因此必须通知源主机减小包大小。

#### 报文结构
```
Type = 2
Code = 0
+-------------------+
|  MTU (4 bytes)    | ← 指出下一跳链路可支持的最大 MTU
+-------------------+
|  Original Packet  | ← 原始包头部的一部分
+-------------------+
```

#### 功能
- 当路由器发现要转发的 IPv6 包超过链路 MTU，就返回该消息；
- 源主机收到后会执行 **Path MTU Discovery (PMTUD)**；
- 源主机自动调整数据包大小，避免再次触发。
#### 举例
> 源主机发送 1500 字节包，下一跳 MTU 1280 →  
> 路由器返回 Type 2，MTU=1280 → 源主机改发 1280 字节包。

### ⏳ Type 3：Time Exceeded

> 📜 RFC 4443 §3.3  
> 当 IPv6 数据包的 Hop Limit（跳数）耗尽时发送。

#### 报文结构
```
Type = 3
Code = 0 or 1
+-------------------------------------------------+
|  Unused (4 bytes)                               |
+-------------------------------------------------+
|  Original Packet (header + partial payload)     |
+-------------------------------------------------+

```

#### code类型
| Code  | 含义                                | 场景                   |
| ----- | --------------------------------- | -------------------- |
| **0** | Hop limit exceeded in transit     | TTL（Hop Limit）耗尽（常见） |
| **1** | Fragment reassembly time exceeded | 分片重组超时（源节点负责分片）      |
#### 典型用途
- 被 **traceroute6** 工具使用：逐跳减少 Hop Limit，收到 Type 3 Code 0 报文即可获知中间路由。
### ⚙️ Type 4：Parameter Problem

> 📜 RFC 4443 §3.4  
> 表示 IPv6 首部或扩展头字段有错误，无法处理。

#### 报文结构
```
Type = 4
Code = 指示哪类错误
+-------------------+
|  Pointer (4 bytes)| ← 指示错误字段的偏移位置
+-------------------+
|  Original Packet  |
+-------------------+
```

#### code类型
|Code|含义|场景|
|---|---|---|
|**0**|Erroneous header field encountered|IPv6 主头部字段非法|
|**1**|Unrecognized Next Header type|无法识别的 Next Header|
|**2**|Unrecognized IPv6 option|扩展头选项无法识别|
#### 举例：
- IPv6 包中 Next Header = 255（不存在的协议号） → Code 1
- Hop-by-Hop 选项头格式错误 → Code 2
## 2️⃣ 信息类消息（Type ≥ 128）

| Type    | Code | 含义                                              |
| ------- | ---- | ----------------------------------------------- |
| **128** | 0    | 回显请求（Echo Request，ping 请求）                      |
| **129** | 0    | 回显应答（Echo Reply，ping 应答）                        |
| **130** | 0    | Multicast Listener Query (MLDv1/MLDv2协议, 路由器询问) |
| **131** | 0    | Multicast Listener Report(MLDv1协议, 主机加入)        |
| **132** | 0    | Multicast Listener Done(MLDv1协议，主机离开)           |
| **133** | 0    | 路由器请求（Router Solicitation, RS）                  |
| **134** | 0    | 路由器通告（Router Advertisement, RA）                 |
| **135** | 0    | 邻居请求（Neighbor Solicitation, NS）                 |
| **136** | 0    | 邻居通告（Neighbor Advertisement, NA）                |
| **137** | 0    | 重定向（Redirect）                                   |
| **143** | 0    | MLDv2 Listener Report（多播监听报告，主机加入离开或过滤）         |
🚀 从这里可以看出：
- NDP（RS/RA/NS/NA/Redirect）其实都是 ICMPv6 的一部分；
- MLD（多播监听）也在 ICMPv6 范围内。

# 🧭 四、ICMPv6 与 IPv4 对比

| 功能     | IPv4 协议                   | IPv6 协议               |
| ------ | ------------------------- | --------------------- |
| 控制消息   | ICMP                      | ICMPv6                |
| 地址解析   | ARP                       | NDP（基于 ICMPv6）        |
| 路由器发现  | ICMP Router Discovery     | RA/RS（基于 ICMPv6）      |
| 多播管理   | IGMP                      | MLD（基于 ICMPv6）        |
| MTU 探测 | ICMP Fragmentation Needed | ICMPv6 Packet Too Big |

# 🧠 五、ICMPv6 的作用总结

| 功能类别          | 示例消息                         | 说明           |
| ------------- | ---------------------------- | ------------ |
| **错误报告**      | 目的地不可达、包太大、超时等               | 通知上层网络问题     |
| **诊断工具**      | Echo Request / Reply         | 用于 ping 测试   |
| **邻居发现（NDP）** | RS / RA / NS / NA / Redirect | 地址解析与路由器发现   |
| **路径 MTU 发现** | Packet Too Big               | 通知源主机调整包大小   |
| **组播管理**      | MLD 报文                       | 控制主机加入或离开组播组 |

# 🧩 六、一个例子：ping6 流程

当你执行
```
ping6 fe80::1
```

过程：
1. 主机先通过 **NDP (ICMPv6 Type 135)** 解析目标 MAC 地址
2. 然后发送 **Echo Request (Type 128)**
3. 对方回复 **Echo Reply (Type 129)**
4. 若路径过大，会收到 **Packet Too Big (Type 2)** 报文，调整 MTU
