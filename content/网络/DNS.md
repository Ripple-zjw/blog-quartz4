---
date: 2026-01-12
tags:
  - 网络
---

DNS（Domain Name System，域名系统）的作用很简单：**把人类容易记的域名，转换成计算机使用的 IP 地址**。

---
# DNS 是做什么的

可以把 DNS 理解成**互联网的电话簿**：
- 人：记域名（`google.com`）
- 计算机：用 IP（`142.250.72.14`）
- DNS：负责在两者之间做映射
没有 DNS，你每次上网都得记 IP。
---
# DNS域名规则

- 单个 label 最多63个字符
- 整个域名长度最多255个字符（这个长度包括报文中的长度字节和 `0x00`，所以实际没有这么长）
- 字符集限制
	- 原始 DNS：`a-z A-Z 0-9 -`
	- 非 ASCII 域名通过 **IDN / Punycode** 转换
		- **IDN（Internationalized Domain Name）**
		    - 概念 / 标准
		    - 规定：域名可以让人用 Unicode 输入
		- **Punycode**
		    - 具体算法
		    - 把 Unicode 转成 ASCII
---
# 一次 DNS 查询是怎么完成的（核心流程）
以访问 `www.example.com` 为例：
1. **浏览器缓存**
    - 浏览器先看看自己有没有解析过这个域名
2. **操作系统缓存**
    - 查系统 DNS 缓存（如 `hosts`、本地缓存）
3. **本地 DNS 服务器（递归解析器）**
    - 一般是路由器或运营商提供的 DNS
    - 用户只和它打交道
4. **根 DNS 服务器**
    - 告诉你：`.com` 的服务器在哪
5. **顶级域（TLD）服务器**
    - 告诉你：`example.com` 的权威服务器在哪
6. **权威 DNS 服务器**
    - 返回最终 IP 地址
7. **结果缓存**
    - 各级都会缓存一段时间，下次更快
一句话总结：  
**客户端只问一个 DNS，剩下的“跑腿”工作由递归 DNS 完成**

---
# DNS使用的传输层
- **默认使用 UDP 53 端口**
    - 快、开销小
- **以下情况用 TCP**
    - 响应超过 512 字节（老标准）
    - DNSSEC
    - 区域传送（AXFR）
现在很多实现会自动在 UDP / TCP 之间切换。
---
# 什么是递归解析器

递归解析器的定义只有一句话：
> **替客户端把 DNS 查到最终结果的那一方**

只要它：
- 接收客户端的 DNS 请求
- 自己去问根 / TLD / 权威 DNS
- 把最终答案返回给客户端
它就是递归解析器

---

# DNS报文解析

DNS 报文无论是 **查询** 还是 **响应**，结构是一样的：
```
+---------------------+
| Header              |
+---------------------+
| Question            |
+---------------------+
| Answer              |
+---------------------+
| Authority           |
+---------------------+
| Additional          |
+---------------------+
```

## Header（报文头，最关键）
Header 固定 **12 字节**，每个字段两个字节：
```
| ID      |
| Flags   |
| QDCOUNT |
| ANCOUNT |
| NSCOUNT |
| ARCOUNT |
```
### ID
- 客户端生成
- 用来匹配请求和响应
### Flags
16 位标志位，常见的有：

| 位      | 名称                      | 含义                                  |
| ------ | ----------------------- | ----------------------------------- |
| QR     | 查询 / 响应                 | 说明是在请求（0）还是响应（1）                    |
| OPCODE | 查询类型（几乎都是 0）            | 说明DNS在做什么操作，0标准DNS查询，1反向查询，2服务器状态查询 |
| AA     | 是否权威回答                  | 1表示这是权威服务器的回答，0不是权威服务器（缓存/转发）       |
| TC     | 是否被截断                   | 1表示被截断，0响应完整                        |
| RD     | 客户端要求递归                 | 1表示递归，0不递归                          |
| RA     | 服务器支持递归                 | 1支持递归，0不支持                          |
| RCODE  | 返回码（NOERROR / NXDOMAIN） | 查询结果[[DNS#^4b8df4\|RCODE常见值]]       |
RCODE常见值：

| 值   | 含义              |
| --- | --------------- |
| 0   | NOERROR（成功）     |
| 1   | FORMERR（报文格式错误） |
| 2   | SERVFAIL（服务器失败） |
| 3   | NXDOMAIN（域名不存在） |
| 4   | NOTIMP（不支持）     |
| 5   | REFUSED（拒绝）     |
### 剩余的所有COUNT
每个两字节，决定报文剩余数据的长度，每个部分含有多少条记录。比如一个question，返回了2个answer。在接下来的questions区就会有1个请求，answers区有两个记录。

> 几乎所有的DNS请求QDCOUNT都是1，协议允许大于1但基本没有人会这么做，大部分DNS服务器会忽略剩余Question或者返回失败。

## Questions/Queries区
每个Question包括：
```
QNAME | QTYPE | QCLASS
```
- QNAME： 要查询的域名
	- 在报文中这个域名是按照label存放的，即以 1 个长度字节开头`x`，接下来的`x`个字节是那个label的内容。
	- `x[长度]yyy[label]00[结束字符]`
	- 一个域名用`.`来划分多个label，最后用`00`字节表示结束。
	- 例如：`3www7example3com0`，每个字符在报文中占一字节。
	- 对于label中第一个长度字节，低6位表示长度，高2位表示类型。
		- 当类型为00时，说明这是一个普通label
		- 当类型为11时(`0xc0, 11000000 xxxxxxxx`)，说明不是一个 label，而是一个指针，指向报文中别的位置
		- **因此在DNS中，每个label的最大长度是63个，同时还要保证报文中整个QNAME的长度在255字节以内。**
- QTYPE：要查询的类型
	- A：IPv4 地址
	- AAAA：IPv6 地址
	- CNAME：别名指向另一个域名
	- MX：邮件服务器
	- NS：权威 DNS
	- TXT：文本
	- SRV：端口+主机
	- ANY：所有能给的（现在多被限制）
- QCLASS：属于哪一个网络
	- 最常见、几乎唯一见到的值：`IN`
	- IN=Internet

## Answers区

每个Answer存放的是对 Question 的“直接回答结果”。如果没有查到，Answers区就是空的。

Answer 区由 **0 条或多条资源记录（RR）** 组成。
每一条 RR 的格式是完全固定的：
```
NAME | TYPE | CLASS | TTL | RDLENGTH | RDATA
```

^0ed7f0

权威区、附加区的 RR **结构完全一样**。

- NAME：这条答案是给哪个域名的，使用label/指针结构，不定长
	- 通常 **不会真的把域名再写一遍**，几乎总是 **指针压缩（0xC0 xx）**
	- `0xc0 0c`表示“这个名字和报文里偏移 `0x0c` 的那个域名是同一个”
- TYPE：查询的类型的答案，和查询的QTYPE对应。2字节
	- 一个QTYPE可能会有多个TYPE作为回答，比如QTYPE查询`A`，ANSWER区可能会有两条这个Question的回答比如`cname`,`A`。
	- DNS设计成尽可能的给你所有的信息，防止你需要发多个请求。
- CLASS：几乎永远是 IN。2字节
- TTL：记录缓存时间，单位秒。4字节
- RDLENGTH：RDATA字段的长度。2字节
- RDATA：这条ANSWER的答案，比如：
	- TYPE：`A`，一个IPv4地址
	- TYPE：`AAAA`，一个IPv6地址
	- TYPE：`CNAME`，另一个域名，结构也是(label/指针结构)

## Authority区

Authority 区里放的仍然是 **资源记录（RR）**，结构和 Answer 一模一样：[[DNS#^0ed7f0|RR]]。但 **TYPE 非常有限**，常见的只有两类。

### NS 记录
这是 Authority 区最常见的内容。
- 递归解析过程中
- 当前服务器不是最终权威
- NS记录会指明权威服务器，递归解析器需要再向权威服务器查询

### SOA记录
表明我就是权威服务器，常出现在：
- NXDOMAIN，这个域名不存在。
- NODATA（NOERROR 但无 Answer）
- 权威 DNS 给出最终结论（有Answer也有SOA，不是一定会加SOA）

## Additional区

Additional 里放的同样也是[[DNS#^0ed7f0|RR]]，通常是Authority 或 Answer 中提到的名字的补充解析结果，它**不直接回答 Question**，但 **能减少你后续再查一次 DNS 的次数**。

### 常见记录类型

#### A/AAAA
给NS主机名配IP：
```
NAME: ns1.example.net
TYPE: A
RDATA: 192.0.2.1
```
比如Authority区告诉你权威服务器的域名
```
example.com NS ns1.example.net
example.com NS ns2.example.net
```
同时也会把这个域名的IP解析后放在Additional区里，这样你就可以少做一次dns请求。

#### OPT（EDNS0，非常重要）
```
Type: OPT (41)
```
这是 **EDNS 扩展**，它：
- 不是真正的 DNS 记录
- 不属于某个域名
- 专门用来 **扩展 DNS 能力**
比如：
- UDP 最大报文长度
- DNSSEC OK 位
- 扩展 flag
OPT记录只能出现在Additional区

#### DNSSEC相关
如果启用了 DNSSEC，Additional 里可能会有：
- RRSIG
- DNSKEY
用于 **校验 Answer 是否被篡改**

### Additional 区里的记录可靠吗？
重要点：
- **Additional 里的数据不是权威数据**
- 它只是“顺带提供”
- 客户端可以使用，也可以不使用
所以解析器通常会：
- 接受 A / AAAA 来提速
- 但 **不把它当最终权威**
