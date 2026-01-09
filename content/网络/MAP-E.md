---
date: 2025-12-12
tags:
  - 网络/4over6tun
---

# 一、MAP-E是什么

MAP-E 是一种 **IPv4 over IPv6** 的过渡技术，用来在 IPv4 地址紧缺的环境中，让运营商继续向用户提供 IPv4 访问能力，同时网络内部只跑 IPv6。

它的核心思想：
**把 IPv4 流量封装在 IPv6 里，同时使用 A+P（地址 + 端口）共享 IPv4 地址。**

也就是说：
- 运营商的网络完全是 IPv6-only；
- 用户侧和运营商侧之间用 IPv6 建“隧道”；
- 每个用户只分到 **部分端口范围**，而不是完整 IPv4 地址；
- 用端口切片方式把一个 IPv4 地址共享给许多用户。
整个MAP-E是无状态的，即br和ce不会维护任何v6和v4地址转换的状态表，全是靠map rule中的配置算出来的。

---
# 二、核心概念

## 1. PSID（Port Set Identifier）

用户不会拿到完整 IPv4，而是拿到：
- 1 个共享 IPv4 地址
- 再加上一个固定算法生成的端口区间（PSID）
由于CE拿到的IPv4地址是多个用户共享的，所以需要**IPv4+PSID**的方式识别某个CE。

## 2. PSID-BITS

PSID-BITS表示PSID占源端口的多少位。

因为PSID是源端口号的一部分，比如PSID-BITS为8，那么16位源端口号的高8位就是PSID。这也意味着如果PSID-BITS为8，那么客户端只能使用剩下的16-8位bits，即最低8位一共256个端口号。
$$
port-range = [PSID << 8, (PSID << 8) + 255]
$$
**PSID-BITS越大，同一个ipv4地址就能共享给更多的CE，但同时每个CE可使用的端口也就越少。**

|PSID-bits|含义|
|---|---|
|0|一个 IPv4 只给一个 CE（不共享）|
|4|一个 IPv4 给 16 个 CE|
|8|一个 IPv4 给 256 个 CE|
|12|一个 IPv4 给 4096 个 CE|

## 3. EA-bits

EA = **Embedded Address**  
意思是把你的 **IPv4 地址 + PSID 信息（端口片段）**，嵌入进你的 **IPv6 地址里的某一段 bits**。

**EA-bits = IPv6 地址的多少 bit 用来放 IPv4_A + PSID**

```
EA-bits = IPv4 suffix bits + PSID bits
```

其中
- IPv4 suffix bits就是一个地址（一般是从运营商获取的公网地址）的**主机段**，就是用32-子网掩码长度得到的后缀长度。
- PSID bits：你的端口组编号
## 4. Map rule

**MAP rule = 一组固定、双方一致的计算规则**，它回答 4 个问题：
1. **哪些 IPv4 地址属于 MAP-E？**
2. **IPv4 地址的哪几位会嵌入 IPv6？**
3. **端口是如何共享、如何切分的？**
4. **IPv6 地址里哪些 bit 承载这些信息？**

所以 MAP rule 不是一条路由、不是一条 ACL，而是**一份“映射说明书”**。
**只要 CE 和 BR 拿到同一份 MAP rule，  就可以完全无状态地互相算出对方的信息**。

map rule所包含的字段：

| 字段                     | 含义                        |
| ---------------------- | ------------------------- |
| **IPv4 prefix**        | MAP-E 使用的共享 IPv4 地址池      |
| **IPv4 prefix length** | 这个 IPv4 前缀的长度             |
| **IPv6 MAP prefix**    | 用于 CE 的 IPv6 域            |
| **IPv6 prefix length** | IPv6 域前缀长度                |
| **EA-bits length**     | IPv6 中用于嵌入信息的总 bit 数      |
| **PSID-bits**          | EA-bits 中有多少 bit 用来表示端口集合 |
| **PSID offset**        | 端口低位保留不用的 bit 数           |
| **BR IPv6 address**    | BR 的 IPv6 地址              |

---
# 三、如何算出IPv6地址

CE（用户侧设备）获得两个信息：
1. 你的 IPv6 前缀（例如 /56）
2. MAP Rule（里面写 EA-bits = 16、PSID-bits = X 等）

CE 根据这些规则：
- 从分配的 IPv6 前缀中抽出 56 bit
- 再在后面填入 EA-bits 那 16bit（包含 IPv4 suffix + PSID）
- 剩下的 bits 再随便补成一个合法地址

这样 CE 得到自己的 MAP IPv6 地址。
```
| IPv6 MAP 前缀 | EA-bits | IID 剩余位 |
```
IID 剩余位 可以随便填写任何值，也可以全0，它在整个MAP-E协议中完全没有任何关系，br只靠EA-bits就可以知道是哪个CE。

---

# 四、MAP-E报文处理流程

以下是一次 IPv4 流量的完整路径：
## 1）用户侧主机发一个 IPv4 报文

例如主机访问 8.8.8.8:80。
## 2）MAP-CE 做源端口检查

报文源端口是否在分配的 PSID 区间？
- 在 → 继续
- 不在 → 丢弃（因为不能使用未分配的端口）

### 3）CE 对 IPv4 报文做 **封装（Encapsulation）**

把整个 IPv4 报文封在一个 IPv6 外层头部中：
```
IPv6(src = CE IPv6)
IPv6(dst = BR IPv6)
[  Inner IPv4 packet  ]
```

## 4）IPv6-only 网络传输到 BR（隧道）
因为都是 IPv6，所以只需转发 IPv6。
## 5）BR 解封装
去掉 IPv6 头部，得到原始 IPv4 报文。
## 6）BR 发往 IPv4 互联网
## 7）返回流量一样走 IPv6 封装，然后到 CE，再交给用户主机。
br在收到v4的包后直接就可以根据map rule算出v6头部。

---
# 五、MAP-E的优点

|优点|说明|
|---|---|
|不需要 CGNAT|每个用户自己 NAT，BR 只做转发|
|可规模化|一个 IPv4 可以共享给 256、512 甚至更多用户|
|IPv6-only 核心网更简单|核心网全 IPv6，无需维护双栈|
|封装比 MAP-T 更简单|MAP-E 用封装模式，不做协议翻译|
## 和其他过渡技术的差异

|技术|原理|特点|
|---|---|---|
|**DS-Lite**|IPv4 封到 IPv6，然后在 CGNAT 做 NAT|会话容易被 CGNAT 限制|
|**MAP-E**|IPv4 封到 IPv6，**用户 NAT**|更去中心化，可扩展|
|**MAP-T**|IPv4 ↔ IPv6 转换，不是封装|不用增加头部，但更复杂|
|**464XLAT**|CLAT 翻译 IPv4→IPv6→IPv4|常见于移动网络（安卓）|

# 六、MAP-T协议

**MAP-T = 基于规则的 IPv4 ↔ IPv6 转换（Translation）**  
它通过**地址 + 端口映射规则**，把 IPv4 流量“翻译”为 IPv6 来传输。

> 从原理来讲，和MAP-E几乎一模一样。唯一的区别就是，**MAP-E是封装，即在v4头上加一层v6头，而MAP-T是翻译，即把v4的头去掉，加一个v6的头。**

|技术|做的事|
|---|---|
|**MAP-E**|**IPv4 报文不动，外面套一层 IPv6**|
|**MAP-T**|**IPv4 头消失，生成一个新的 IPv6 头**|

虽然看起来MAP-E和MAP-T基本没什么差别，但MAP-T在工程实现上要复杂的多。

|项目|MAP-E|MAP-T|
|---|---|---|
|IP 头|保留 IPv4|**换成 IPv6**|
|TTL / Hop Limit|IPv4 TTL|**IPv6 Hop Limit**|
|IP checksum|不变|**IPv4 没了**|
|TCP/UDP checksum|不变|**必须重算**|
|DF / 分片|IPv4 语义|**IPv6 语义**|
|ICMP|原样|**ICMP ↔ ICMPv6 翻译**|