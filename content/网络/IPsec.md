---
date: 2025-12-05
tags:
  - 网络/VPN
---
# 一、IPSec 是什么

IPsec（Internet Protocol Security）是一组在 IP 层提供机密性、完整性与身份验证的协议集合。它通过建立**安全关联（Security Association, SA）并使用加密与/或认证来保护端点之间的 IP 流量。常见用途包括站点到站点 VPN（路由器/防火墙之间）和远程访问 VPN（客户端到网关）。**

**IP 层的安全框架**，目标是给 IP 提供：
- 加密（Confidentiality）
- 完整性（Integrity）
- 身份认证（Authentication）
- 重放保护（Anti-replay）

它不是一个单独的协议，是一组协议与机制的组合。
## IPsec 的核心由三类协议组成：
1. **AH（Authentication Header）**：只验证，不加密
2. **ESP（Encapsulating Security Payload）**：加密 + 验证
3. **IKE（Internet Key Exchange）**：协商密钥、算法、参数
> 现在实际工作中几乎全部使用 **ESP + IKEv2**。

---

# 二、IKE SA + IPsec SA
## IKE SA = 控制平面的安全隧道

- 在 UDP/500（或 NAT-T 时 4500）
- 用来建立、重键、删除 Child SA（数据 SA）
- IKEv1（Phase 1）和 IKEv2（IKE_SA_INIT + IKE_AUTH）建立这个 SA
## IPsec SA = 数据平面的安全隧道

- 承载真正的数据（ESP）
- 单向：一个方向一条 SA
- 在 SAD 中存放其 key、SPI、算法等

> **先建 IKE SA，再建 IPsec SA。 IKE SA用于协商一个加密隧道（部分加密）， IPsec SA会真正开始传数据（完全加密）。可以理解为一个结构体，里面存储了必要的加密数据。**


---


# 三、IPsec主要组成

## SPD（Security Policy Database）

它是“要不要对某个流量套 IPsec”的决定器。

一条 SPD 项包括：
- 源/目的 IP
- 源/目的 port
- 协议（TCP/UDP/ICMP）
- 动作：
    - **bypass**（直接放行）
    - **discard**（拒绝）
    - **protect**（需要 IPsec 保护）
SPD 会触发 IKE 协商。

## SAD（Security Association Database）

存放已建立的 SA，包括：
- SPI
- 加密算法（AES-CBC/GCM/...）
- 完整性算法（SHA-256/HMAC/...）
- 密钥
- 隧道或传输模式
- 重放窗口
- 生命周期（字节数、时间）
一旦 SAD 安装完，数据就由 ESP/AH 按规则处理。

## PAD（Peer Authorization Database，IKEv2）

用于 IKEv2 验证对端身份与授权（证书/ID 匹配规则）。
（IKEv1 没有 PAD 的正式结构）

## AH（几乎不用）
- 对整个 IP 包认证（包括 IP header）
- 不加密
- 会破坏 NAT（因为 NAT 修改 IP 会导致认证失败）
几乎只在军事设备中出现。

## ESP（实际使用）

ESP 完成：
- 加密（AES-GCM/AES-CBC/...）
- 完整性认证（AES-GCM 内建 + HMAC-SHA）
- 重放保护（序列号 + 窗口）
- 隧道封装（Tunnel Mode）

ESP 报文结构
```
[ ESP Header: SPI + Seq ]
[ Encrypted Payload (IP or Transport layer) ]
[ Integrity Check Value ]
```

## IKE（Internet Key Exchange）

IKE 负责：
- 协商算法（加密/验证/DH）
- 进行 Diffie–Hellman
- 身份认证（PSK/证书/EAP）
- 派生密钥（用于 IPsec SA）
- 管理 SA 生命周期、重键、删除
### 两个版本：
#### IKEv1
分两阶段：
##### Phase 1（建立 IKE SA）
- Main Mode（6 报文）
- Aggressive Mode（3 报文）
##### Phase 2（Quick Mode）
- 3 报文
- 建立 IPsec SA
缺点：
- 模式多、混乱
- NAT 支持弱
- 状态机不清晰
- 容易故障
#### IKEv2
流程极简：
- IKE_SA_INIT（交换 DH + Nonce + SA）
- IKE_AUTH（身份认证 + 建 Child SA）
- CREATE_CHILD_SA（重键或额外 Child SA）
- INFORMATIONAL（删除 SA、DPD 等）
优势：
- 重传机制干净可靠
- 内部支持 NAT、分片、移动性（MOBIKE）
- 消息格式更清晰
- DoS 防护更先进（COOKIE）

## NAT-T（NAT Traversal）

在IKE SA的建立阶段，使用NAT-D(NAT-Discovery)探测双方是否存在nat。NAT-D里包含一个hash值```
```
HASH( IP地址 || UDP端口 || SPI-I || SPI-R )
```

计算两个hash：
- 本端地址/端口的 hash
- 对端地址/端口的 hash
双方比较时发现 hash 对不上 → NAT 存在。

一旦启用NAT-T，双方就会从UDP500改为使用UDP4500,包括后续的IPsec SA都会使用UDP4500。

---

# 四、Tunnel Mode vs Transport Mode

IPsec有两种模式
## **Transport Mode**
- 只加密 L4 payload
- 外层 IP 不变
适合：
- Host-to-Host
- L2TP/IPsec（某些实现）
## **Tunnel Mode（最常用）**

- 整个原始 IP 包被加密并封装在新的 IP header 中
适合：
- VPN
- 路由器互连、企业站点互连（Site-to-Site）

---
# 五、ESP完整性认证

ESP 使用 **HMAC（或其它 AEAD 内建的 Integrity）** 来保证：
- 报文内容是否被篡改
- 报文是否来自正确的对端（合法性）

ESP报文结构
```
ESP Header:
    SPI        4 bytes
    Sequence   4 bytes

Encrypted Payload:
    IV
    Encrypted Payload Data
    Encrypted Padding
    Encrypted Pad Length
    Encrypted Next Header

Authentication Data:
    HMAC (not included in hash input itself)
```
整个 ESP 报文（除了最后的 HMAC 字段本身）都被 HMAC 覆盖。

## HMAC 的算法

常见算法：
- HMAC-SHA1-96（老旧）
- HMAC-SHA256-128（现代）
- AES-GMAC（如果使用 AES-GCM）
- AES-GCM 本身是 AEAD，**加密 + 完整性**一体

如果使用 GCM/CCM，ESP 不会再有 HMAC，而是：
```
ESP Header + Ciphertext + Auth Tag
```
Auth Tag 相当于 HMAC。

## 完整性认证的流程
### 发送端：

1. 构建 ESP Header（SPI + Sequence）
2. 加密 Payload（AES、3DES等）
3. 用密钥计算 HMAC = HMAC(ESP header + ciphertext)
4. 把 HMAC 追加到末尾 → Authentication Data

### 接收端：

1. 用 SPI 查找正确的 SA（Security Association）
2. 使用 SA 中的密钥计算 HMAC'
3. 比较 HMAC' 与 HMAC
4. 不一致 => 报文丢弃（完整性失败）
**完整性失败 ≠ 解密失败。完整性先检查，失败直接丢，不会尝试解密。**

# 六、ESP重放保护

黑客抓到你一个 ESP 包，然后不停重发，让对端重复处理同一包。
IPsec 用 **Sequence Number + 滑动窗口** 来防止重放。

## Sequence Number（发送序号）

- 每个 ESP SA 都有一个 32-bit 序号
- 每发一个 ESP 报文，序号自增 1，不允许回滚
- 用于检测重复报文
序号不能用完，否则必须重新协商 SA（否则溢出是安全隐患）。

## 滑动窗口机制（Replay Window）

接收端维持一个滑动窗口（典型大小：64 或 128）
窗口记录:
- 哪些序号已经收到
- 哪些还能接收
- 哪些必须拒绝

## 重放检查流程

发送端：
- 每次发送时序号+1

接收端做如下检查：
- 序号是否太小（窗口左侧）→ 直接丢弃（旧包）
- 序号是否落在窗口范围内并且已经收到过？→ 重放攻击，丢弃
- 序号比最大序号大？→ 向前移动窗口，接受
- 完整性验证成功 → 接受，失败 → 丢弃

# 七、IPsec工作流程

下面以「主机 A 要给主机 B 发送一个 IP 包」并需要建立 IPsec 隧道为例，说明典型流程。
1. **检查策略（SPD）**  
    发送端网络栈看到要发送的包，查 SPD：如果有匹配的 IPsec 策略（比如“到 B 的流量必须使用 ESP，隧道模式”），就进入 IPsec 路径；否则按正常 IP 路由发送。
2. **查找现有 SA（SAD）**  
    如果已有满足方向和对端的 SA（密钥、SPI 等），进入加密/封装步骤；若没有，则需要建立 SA。
3. **建立 SA — IKE 协商（通常 UDP/500；在 NAT 情况下 UDP/4500）**
    - 发起方和接收方进行密钥交换（Diffie–Hellman）并协商加密、认证算法、密钥寿命等。   
    - 双方进行身份认证（预共享密钥 PSK、证书、公钥等）。
    - IKEv1 分为 phase1（建立 IKE SA）和 phase2（建立 IPsec SA）；IKEv2 把这些步骤合并得更清晰：建立 IKE SA，然后建立一个或多个 Child SA（用于实际的数据保护）。
    - 成功后，在双方的 SAD 中分别安装双向的 IPsec SA（通常为一对 SPI，分别用于两个方向）。
4. **对流量进行封装与加密（出站）**
    - 根据 SA 指定的模式和算法，把原始 IP 包封装。
        - 若**Tunnel 模式**：原始 IP 包被加密后作为 ESP 负载，再加上 ESP header/trailer，然后外面套上新的外层 IP 头（目的为对端网关的 IP）。
        - 若**Transport 模式**：保留原 IP 头，只加 ESP header/trailer（加密的是有效载荷部分）。
    - 如果使用完整性认证，会计算并附加 ICV（Integrity Check Value）。
    - 发送出网。
5. **接收端解包（入站）**
    - 接收端找到外层 IP header（若是隧道），根据 SPI 找到对应的 SA（在 SAD）。
    - 验证完整性（ICV），解密载荷，检查序号以防重放（anti-replay）。
    - 解出原始 IP 包并按通常路径交付到本地网络栈。
6. **重协商与重键（Rekey）**  
    SA 有生命周期（时间或流量限制），到期前双方用 IKE 进行重键以更新密钥，保证长期安全。