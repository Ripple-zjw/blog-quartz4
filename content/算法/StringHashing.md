---
date: 2025-09-28T16:25:37
---

#算法/字符串 
# 字符串哈希

## 1. 什么是字符串哈希

字符串哈希（String Hashing）是一种将字符串映射为整数的技术，用来快速比较、查找子串等。
它的核心目标是：
- 快速比较：避免逐字符比对，通过一次对字符串的预处理`O(n)`，接下来对该字符串中任何子串的比较都可以做到`O(1)`
- 低冲突率：不同字符串尽量映射到不同整数。

## 2. 多项式哈希（Polynomial Rolling Hash）

最常用的哈希公式：
$$
H(s)=(s_0​ * p^0 + s_1​ * p^1 + s_2​ * p^2 + s_{n−1} ​* p^{n−1}) \bmod m
$$

- `si`: 第 `i` 个字符对应的数值(如 `'a'→1`，`'b'→2`)
- `p`：进制，一般取比字符集稍大的质数。
    - 常见：131、13331、137 等。
- `m`：模数，一般选大质数，或者直接利用 unsigned long long 自然溢出。

## 3. 前缀哈希（Prefix Hash）

为了快速求子串哈希，通常用前缀数组：

$$
H[i]=(H[i−1] * p + s_i​) \bmod m
$$

这样可以在 O(1) 内得到任意子串哈希：

$$
Hash(l,r)=(H[r]−H[l−1] * p^{r−l+1}) \bmod m
$$

#### 解析难点：为什么Hash(l, r)需要乘以$p^{r−l+1}$
我们用10进制来解释，虽然p一般都是质数。现在p = 10，假设现在`H[4] = 1234`, 那么`H[3] = 123`, `H[2] = 12`, `H[1] = 1`, `H[0] = 0`。

我现在要计算`hash(2, 4)`, 也就是`H[4] - H[1]`。如果直接减的话就是`1233`，这显然不是我们想要的值，我们其实希望的是`1234 - 1000`,因为这样就把H[4]中表示1的前缀字符串减去了，因此要将$1 * 10^3$。


## 4. 代码
题目地址：
> https://www.acwing.com/problem/content/description/843/

```cpp
#include <iostream>

using namespace std;
typedef unsigned long long ULL;

const ULL P = 131;
const int N = 1e5 + 10;

ULL h[N], p[N];

void init_hash(char* s, int size) {
    p[0] = 1;
    h[0] = 0;
    for (int i = 1; i <= size; i ++ ) p[i] = p[i - 1] * P;
    for (int i = 1; i <= size; i ++ ) h[i] = h[i - 1] * P + s[i - 1];
}

ULL get_hash(char* s, int l, int r) {
    return h[r] - h[l - 1] * p[r - l + 1];
}

int main() {
    int n, m;
    scanf("%d%d", &n, &m);
    char str[n];
    scanf("%s", &str);
    init_hash(str, n);
    for (int i = 0;  i < m; i ++ ) {
        int l1, r1, l2, r2;
        scanf("%d%d%d%d", &l1, &r1, &l2, &r2);
        puts(get_hash(str, l1, r1) == get_hash(str, l2, r2) ? "Yes" : "No");
        //printf("%s\n", get_hash(str, l1, r1) == get_hash(str, l2, r2) ? "Yes" : "No");
    }
    
    return 0;
}
```

