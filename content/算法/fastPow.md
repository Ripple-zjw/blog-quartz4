---
date: 2025-09-28T16:25:37
---

#算法/数学 
# 快速幂

快速幂（又叫二分幂或快速指数算法）的核心思想是：
把指数的二进制拆解，通过“平方”快速缩小计算规模，从而降低复杂度。

普通幂运算复杂度是$O(n)$, 快速幂可以做到$O(logn)$


```c
#include <stdio.h>

long long fast_pow(long long a, long long b, long long mod) {
    long long res = 1;
    
    while (b > 0) {
        if (b & 1) res = res * a % mod;
        a = a * a % mod;
        b >>= 1;
    }
    
    return res;
}

int main() {
    int n;
    scanf("%d", &n);
    
    for (int i = 0; i < n; i ++ ) {
        int a, b, p;
        scanf("%d%d%d", &a, &b, &p);
        printf("%d\n", fast_pow(a, b, p));
    }
    
    return 0;
}
```

### 思路总结

1. 指数按二进制分解：例如$13 = (1101)_2$,所以$a^{13} = a^8 * a^4 * a^1$
2. 每次平方更新底数，指数右移。
3. 遇到二进制位为 1 时，把结果乘上当前底数。
