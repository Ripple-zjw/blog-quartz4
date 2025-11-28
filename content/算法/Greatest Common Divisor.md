---
date: 2025-09-28T16:25:37
---

#算法/数学
# 最大公约数

使用欧几里得算法，这是目前最高效的算法

```cpp
#include <iostream>

using namespace std;

int gcd(int a, int b) {
    if (b == 0) return a;
    return gcd(b, a % b);
}

int main() {
    int n;
    scanf("%d", &n);
    
    for (int i = 0; i < n; i ++ ) {
        int a, b;
        scanf("%d%d", &a, &b);
        printf("%d\n", gcd(a, b));
    }
    
    return 0;
}
```