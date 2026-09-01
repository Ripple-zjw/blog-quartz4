---
date: 2025-10-16T16:25:43
tags:
  - 网络/4over6tun
---

# 一、基本概念

**DS-Lite（Dual-Stack Lite）** 是一种过渡技术，用于在 IPv6-only 的 ISP 网络中，为用户提供 IPv4 互联网访问能力。  
它通过 **IPv4 over IPv6 隧道（Softwire）** 和 **集中 NAT（CGN/AFTR）** 来实现。

> 目的：让运营商的核心网络只运行 IPv6，而用户仍能访问 IPv4 网站。

DS-Lite 架构由两个关键组件组成：

| 组件       | 全称                               | 功能                                     |
| -------- | -------------------------------- | -------------------------------------- |
| **B4**   | Basic Bridging BroadBand element | 位于用户网关（CPE）内，负责将 IPv4 流量封装到 IPv6 隧道中   |
| **AFTR** | Address Family Transition Router | 位于运营商侧，负责解封 IPv6 隧道并进行 IPv4 NAT（CGNAT） |

## 工作原理
 
 IPv4 over IPv6 封装
- 用户主机只知道 IPv4 网络（例如 192.168.1.x）。
- CPE（B4）拿到 ISP 分配的 **IPv6 地址**。
- 当用户访问 IPv4 网站时：
    1. 数据包从主机发到 B4（CPE）。
    2. B4 把 IPv4 数据包封装到 IPv6 报文中。
    3. IPv6 报文通过 ISP 的 IPv6-only 网络传输到 AFTR。
    4. AFTR 解封装得到 IPv4 数据包，执行 NAT44（转换为公网 IPv4 地址）。
    5. 发往互联网的 IPv4 网站。
    6. 回包相反路径返回。

## 原理图
```
IPv4 Host → B4 (CPE) → [IPv6-only ISP] → AFTR → IPv4 Internet
        |           |                 |
     私网IPv4     IPv6隧道封装        公网IPv4
```

## 协议封装
```
Outer IPv6 Header
┌────────────────────────────┐
│ IPv6 Source = B4 IPv6 Addr │
│ IPv6 Dest   = AFTR IPv6    │
│ Next Header = 4 (IPv4)     │
└────────────────────────────┘
Inner IPv4 Packet
┌────────────────────────────┐
│ Source = Private IPv4 Addr │
│ Dest   = Public IPv4 Addr  │
└────────────────────────────┘
```
### B4 地址与 AFTR 地址

- B4：位于用户端，通常自动配置。
- AFTR：可通过 DHCPv6 option 或手动指定获得。

**DHCPv6 选项号：64 (AFTR-Name Option)**
- B4 可以从 DHCPv6 服务器获取 AFTR 的域名。
- 然后通过 DNS AAAA 记录解析为 IPv6 地址。

### NAT 与端口共享机制

AFTR 端执行 **NAT44（CGNAT）**：  
多个用户共享同一个公网 IPv4 地址，每个用户分配一部分端口范围（Port-Set）。

| 项目      | 描述                              |
| ------- | ------------------------------- |
| IPv4 地址 | AFTR 对外公网地址                     |
| 端口范围    | 每个 DS-Lite 用户分配的子集（例如 1000 个端口） |
| 映射方式    | AFTR 建立会话表，记录 IPv6 来源地址对应的端口块   |

> 💡 AFTR 会维护「IPv6 源地址 + 端口块」的映射关系。


# 二、配置方法

## B4(Client)
```
# IPv6 地址为 ISP 分配
# AFTR 地址为 DHCPv6 获取
ip tunnel add ds-lite mode ipip6 remote <AFTR_IPv6> local <B4_IPv6>
ip link set ds-lite up
ip addr add 192.0.0.2/32 dev ds-lite
ip route add default via 192.0.0.1 dev ds-lite
```

## AFTR(ISP)
```
ip tunnel add ds-lite mode ipip6 local <AFTR_IPv6>
ip link set ds-lite up
ip addr add 192.0.0.1/32 dev ds-lite

# 开启NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

## ds-lite 保留ipv4地址段

### 地址来源

IANA 在 [RFC 6333](https://datatracker.ietf.org/doc/html/rfc6333) 和 [RFC 6334](https://datatracker.ietf.org/doc/html/rfc6334) 中规定了：

> 为 DS-Lite 内部 IPv4 通道端点（B4 与 AFTR）保留了一个特殊地址块：  
> **192.0.0.0/29**

也就是说，`192.0.0.0 ~ 192.0.0.7` 都是专门给 DS-Lite 用的，不能在公网或私网中出现。

| 地址                | 角色         | 说明                         |
| ----------------- | ---------- | -------------------------- |
| **192.0.0.1/32**  | AFTR（集中网关） | 通常用作 DS-Lite 隧道的远端 IPv4 地址 |
| **192.0.0.2/32**  | B4（用户侧）    | 通常用作 DS-Lite 隧道的本地 IPv4 地址 |
| 192.0.0.0/29 其余地址 | 保留         | 不应在普通网络中使用                 |
> 这两个地址通常不会在任何 ARP、路由表或 DNS 中出现，仅在隧道内部使用。

当主机发出 IPv4 流量（例如访问 `8.8.8.8`）时：
```
Inner IPv4 packet:
  Src = 192.168.1.10
  Dst = 8.8.8.8
Encapsulated in tunnel:
  Outer IPv6 Src = <B4 IPv6 address>
  Outer IPv6 Dst = <AFTR IPv6 address>
Tunnel Interface:
  Local IPv4 = 192.0.0.2/32
  Remote IPv4 = 192.0.0.1/32
```
B4 用 `192.0.0.2` 当作本地虚拟 IPv4，  
AFTR 用 `192.0.0.1` 当作远端虚拟 IPv4。

这对地址只在隧道接口上存在，不参与任何公网通信。
### 为什么需要“虚拟 IPv4 地址”（192.0.0.1 / 192.0.0.2）

在 Linux 里建立一个 **tunnel interface**（比如 DS-Lite 的 IPv4-over-IPv6 tunnel）：
- **隧道接口**本质上是一个逻辑设备（virtual interface）。
- 它本身不“懂”你要封装什么协议，内核路由决定哪些流量经过它。
- **路由匹配是基于地址族的**：
    - IPv4 流量会走 **IPv4 路由表**（`ip route show`）
    - IPv6 流量会走 **IPv6 路由表**（`ip -6 route show`）

如果没有 `192.0.0.2/32`：
- 内核看到发往 `8.8.8.8` 的 IPv4 包，
- 不知道要通过哪个接口转发（因为 tunnel 没有 IPv4 地址，也无法匹配路由表）。
有了 `192.0.0.2 → 192.0.0.1` 的逻辑接口：
- 内核可以建立路由：`default via 192.0.0.1 dev ds-lite`
- 所有 IPv4 流量自然通过这个隧道封装。
还有一个原因是dslite-tunnel并没有一个v4地址（比如公网地址），因此我们要在tunnel的两端设置一个v4地址，以此来通信。

> ==简单总结：只有给 tunnel 配 IPv4 地址，内核才会把 IPv4 流量交给它。==

# 三、优缺点总结

## **优点**
- ISP 核心网络无需维护 IPv4。
- 用户设备无需公网 IPv4。
- 平滑过渡到 IPv6-only 网络。
## **缺点**
- NAT44 仍是瓶颈，端口共享。
- 应用兼容性问题（例如 P2P、游戏）。
- AFTR 性能要求高。