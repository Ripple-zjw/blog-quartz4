#网络/IPv6/IPv6协议 #网络/IPv6/ICMPv6协议 #网络/IPv6/NDP协议 

# ipv6协议

## 🧩 一、核心协议层（IPv6 主体）

这些是 IPv6 协议栈的基础。

| 协议                                | 全称                                         | 作用                                         |
| --------------------------------- | ------------------------------------------ | ------------------------------------------ |
| **[IPv6](ipv6协议)（RFC 8200）**      | Internet Protocol version 6                | 定义 IPv6 的数据包结构、地址格式、分片、头部字段等。              |
| **[ICMPv6](ICMPv6协议)（RFC 4443）**  | Internet Control Message Protocol for IPv6 | IPv6 的控制消息协议（类似 IPv4 的 ICMP），用于错误报告、邻居发现等。 |
| **[NDP](NDP协议)（RFC 4861）**        | Neighbor Discovery Protocol                | 取代 ARP，用于地址解析、路由器发现、邻居可达性检测。               |
| **[MLD](MLD协议)（RFC 2710 / 3810）** | Multicast Listener Discovery               | 管理主机加入/离开 IPv6 多播组，类似 IPv4 的 IGMP。         |

---
## 🧭 二、地址分配与配置（自动化机制）

| 协议                                             | 全称                                           | 作用                            |
| ---------------------------------------------- | -------------------------------------------- | ----------------------------- |
| **[SLAAC](SLAAC协议.md)（RFC 4862）**              | Stateless Address Autoconfiguration          | 主机根据路由器广告（RA）自动生成地址（无状态）。     |
| **[DHCPv6](DHCPv6协议)（RFC 8415）**               | Dynamic Host Configuration Protocol for IPv6 | 服务器分配 IPv6 地址和其他配置（有状态）。      |
| **[DHCPv6-PD](DHCPv6-PD协议.md)（RFC 8415 §6.3）** | Prefix Delegation                            | 向下游路由器分配子网前缀（常用于家庭宽带和v6plus）。 |
| **RA（Router Advertisement）**                   | Router Advertisement Message                 | 路由器广播前缀信息、DNS信息等，供主机生成地址。     |
| **RS（Router Solicitation）**                    | Router Solicitation Message                  | 主机主动请求路由器发送 RA。               |

---
## 🔐 三、安全与认证协议

| 协议                   | 全称                         | 作用                      |
| -------------------- | -------------------------- | ----------------------- |
| **IPsec（RFC 4301+）** | Internet Protocol Security | IPv6 内建安全框架，支持加密与认证。    |
| **IKEv2（RFC 7296）**  | Internet Key Exchange v2   | 为 IPsec 建立安全会话。         |
| **SEND（RFC 3971）**   | Secure Neighbor Discovery  | 给 NDP 加上签名与认证，防止伪造邻居攻击。 |

---
## 🌍 四、DNS 相关扩展

|协议|全称|作用|
|---|---|---|
|**AAAA Record（RFC 3596）**|IPv6 Address Record|IPv6 对应的 DNS 记录类型。|
|**DNS64（RFC 6147）**|DNS IPv6/IPv4 互通|将 IPv4 地址合成为 IPv6 地址（配合 NAT64）。|
|**DNS over IPv6（RFC 3646）**|DNS over IPv6 transport|在 IPv6 网络中直接查询 DNS。|

---
## 🔀 五、过渡与兼容机制（IPv4 ↔ IPv6）

| 协议 / 技术                          | 作用                                     |
| -------------------------------- | -------------------------------------- |
| **Dual Stack**                   | 主机同时启用 IPv4 和 IPv6。                    |
| **6to4（RFC 3056）**               | IPv6 over IPv4 自动隧道（已淘汰）。              |
| **[6rd](6rd-tunnel) (RFC 5969)** | IPv6 over IPv4 IPv4 网络上快速部署 IPv6 的过渡机制 |
| **ISATAP（RFC 5214）**             | IPv6 over IPv4 内网自动隧道。                 |
| **Teredo（RFC 4380）**             | IPv6 over UDP over IPv4 穿透 NAT（已淘汰）。   |
| **DS-Lite（RFC 6333）**            | IPv6-only 网络访问 IPv4。                   |
| **NAT64/NAT46（RFC 6146）**        | IPv6/IPv4 地址转换。                        |
| **464XLAT（RFC 6877）**            | Android 移动网络常用的 NAT64/CLAT 模式。         |
| **MAP-E / MAP-T（RFC 7597/7599）** | IPv4 over IPv6 映射机制（ISP 常用）。           |
| **v6plus / OCN IPv6**            | 日本主流的 MAP-E 实现。                        |

---
## 📡 六、路由与传输层扩展

|协议|作用|
|---|---|
|**OSPFv3（RFC 5340）**|IPv6 的 OSPF 协议版本。|
|**RIPng（RFC 2080）**|IPv6 的 RIP 路由协议版本。|
|**BGP-4+（RFC 2545）**|支持 IPv6 的 BGP。|
|**EIGRP for IPv6（Cisco）**|Cisco 的私有 IPv6 路由协议版本。|
|**ICMPv6 Redirect / Router Renumbering（RFC 2894）**|动态更新路由前缀信息。|

---
## 📦 七、扩展头与功能增强

| 扩展头                             | 功能                           |
| ------------------------------- | ---------------------------- |
| **Hop-by-Hop Options Header**   | 每跳都要处理的选项（如 Jumbogram）。      |
| **Routing Header**              | 类似 IPv4 的源路由。                |
| **Fragment Header**             | 分片控制（仅源节点能分片）。               |
| **Destination Options Header**  | 目的节点的额外选项。                   |
| **Authentication / ESP Header** | IPsec 相关。                    |
| **Mobility Header（RFC 6275）**   | 移动 IPv6 的移动性支持（Mobile IPv6）。 |

---
## 🧠 八、特殊功能与改进型协议

| 协议 / 技术                             | 作用                          |
| ----------------------------------- | --------------------------- |
| **Mobile IPv6（RFC 6275）**           | 主机在移动网络间保持固定 IPv6 地址。       |
| **MIPv6 / PMIPv6 / NEMO**           | 各类移动性扩展。                    |
| **Segment Routing over IPv6（SRv6）** | 新一代基于 IPv6 的路由控制技术（SDN 常用）。 |
| **RDNSS / DNSSL（RFC 8106）**         | 通过 RA 下发 DNS 配置。            |
| **Flow Label（RFC 6437）**            | 流量识别标签，用于 QoS。              |
| **Jumbogram（RFC 2675）**             | 支持超过 65535 字节的 IPv6 大包。     |

---
## 📘 九、总结图（知识结构）

```
IPv6
├── 核心协议：IPv6, ICMPv6, NDP, MLD
├── 地址配置：SLAAC, DHCPv6, DHCPv6-PD, RA
├── 安全机制：IPsec, IKEv2, SEND
├── DNS扩展：AAAA, DNS64, RDNSS
├── 过渡技术：NAT64, 464XLAT, MAP-E, DS-Lite
├── 路由协议：OSPFv3, RIPng, BGP-4+
├── 扩展头部：Routing, Fragment, ESP, AH
├── 特殊功能：SRv6, MIPv6, Flow Label, Jumbogram
└── 应用层支持：DNS over IPv6, HTTP/3 over IPv6
```
---
# ipv6地址
#网络/IPv6  

![[ipv6地址分类]]


