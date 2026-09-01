---
date: 2025-09-28T16:25:37
---

#算法/动态规划 
# 编辑距离

## 定义
编辑距离是将一个字符串变成另一个字符串所需的最少操作次数。允许的操作有：
- 插入一个字符
- 删除一个字符
- 替换一个字符

> 判题地址: https://www.acwing.com/problem/content/description/901/

## 基本思想（动态规划）
设字符串 A 长度为 n，字符串 B 长度为 m，定义：

> `dp[i][j]` 表示 A 的前 `i` 个字符 与 B 的前 `j` 个字符 的最小编辑距离

状态转移方程：
```
if A[i - 1] == B[j - 1]:
    dp[i][j] = dp[i - 1][j - 1]
else:
    dp[i][j] = min(
        dp[i - 1][j] + 1,     // 删除
        dp[i][j - 1] + 1,     // 插入
        dp[i - 1][j - 1] + 1  // 替换
    )

```

## 方法一：二维 DP

```cpp
#include <iostream>
#include <cstring>
#include <vector>


using namespace std;

int edit_distance(const string& s1, const string& s2) {
    int n = s1.size(), m = s2.size();
    
    int dp[n + 1][m + 1];
    
    for (int i = 0; i < n + 1; i ++ ) {
        dp[i][0] = i;
    }
    
    for (int j = 0; j < m + 1; j ++ ) {
        dp[0][j] = j;
    }
    
    for (int i = 1; i < n + 1; i ++ ) {
        for (int j = 1; j < m + 1; j ++ ) {
            if (s1[i - 1] == s2[j - 1]) {
                dp[i][j] = dp[i - 1][j - 1];
            } else {
                dp[i][j] = min(
                    dp[i - 1][j] + 1,
                    min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + 1)
                );
            }
        }
    }
    
    return dp[n][m];
}


int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    
    int n, m;
    cin >> n >> m;
    vector<string> vec(n);
    for (int i = 0; i < n; i ++ ) {
        cin >> vec[i];
    }
    
    for (int i = 0; i < m; i ++ ) {
        string str;
        int lim, tot = 0;
        cin >> str >> lim;
        for (int j = 0; j < n; j ++ ) {
            int cnt = edit_distance(str, vec[j]);
            tot += cnt <= lim;
        }
        cout << tot << endl;
    }
}
```
#### 优点：
简单易懂，结构直观

#### 缺点：
空间复杂度 `O(n * m)`，在重复计算或大量调用下开销大


## 优化代码

- 滚动数组：我们发现每次循环时dp数组的第一维只会用到前一位即`dp[i - 1]`，于是我们可以使用滚动数组降低dp数组的维度，即**用两个一维的数组来模拟dp数组的第一维**。
- 剪枝：在每次计算编辑距离时，不是每次都需要计算，如果两个字符串之间的长度差超过了`limit`就没有必要再计算编辑距离了。

```cpp
#include <iostream>
#include <cstring>
#include <vector>

using namespace std;

int edit_distance(const string& s1, const string& s2) {
    int n = s1.size(), m = s2.size();
    
    int dp[2][m + 1];
    
    
    for (int j = 0; j < m + 1; j ++ ) {
        dp[0][j] = j;
    }
    
    for (int i = 1; i < n + 1; i ++ ) {
        int curr = i & 1, prev = curr ^ 1;
        dp[curr][0] = i;
        for (int j = 1; j < m + 1; j ++ ) {
            if (s1[i - 1] == s2[j - 1]) {
                dp[curr][j] = dp[prev][j - 1];
            } else {
                dp[curr][j] = min(
                    dp[prev][j] + 1,
                    min(dp[curr][j - 1] + 1, dp[prev][j - 1] + 1)
                );
            }
        }
    }
    
    return dp[n & 1][m];
}


int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    
    int n, m;
    cin >> n >> m;
    vector<string> vec(n);
    for (int i = 0; i < n; i ++ ) {
        cin >> vec[i];
    }
    
    for (int i = 0; i < m; i ++ ) {
        string str;
        int lim, tot = 0;
        cin >> str >> lim;
        for (int j = 0; j < n; j ++ ) {
            if (abs((int)str.size() - (int)vec[j].size()) > lim) continue;
            int cnt = edit_distance(str, vec[j]);
            tot += cnt <= lim;
        }
        cout << tot << endl;
    }
}
```
```python
def edit_distance(s1: str, s2: str) -> int:
    n, m = len(s1), len(s2)
    dp = [[0] * (m + 1) for _ in range(2)]
    
    for j in range(m + 1):
        dp[0][j] = j

    for i in range(1, n + 1):
        curr, prev = i & 1, (i - 1) & 1
        dp[curr][0] = i
        for j in range(1, m + 1):
            if s1[i - 1] == s2[j - 1]:
                dp[curr][j] = dp[prev][j - 1]
            else:
                dp[curr][j] = min(
                    dp[prev][j] + 1,
                    dp[curr][j - 1] + 1,
                    dp[prev][j - 1] + 1
                )
    return dp[n & 1][m]

# 读取输入
n, m = map(int, input().split())
words = [input().strip() for _ in range(n)]

for _ in range(m):
    target, lim = input().split()
    lim = int(lim)
    count = 0
    for word in words:
        if abs(len(word) - len(target)) > lim:
            continue
        if edit_distance(target, word) <= lim:
            count += 1
    print(count)

```
```go
package main

import (
    "bufio"
    "fmt"
    "os"
    "strconv"
    "strings"
)

func editDistance(s1, s2 string) int {
    n, m := len(s1), len(s2)
    dp := [2][]int{}
    dp[0] = make([]int, m+1)
    dp[1] = make([]int, m+1)

    for j := 0; j <= m; j++ {
        dp[0][j] = j
    }

    for i := 1; i <= n; i++ {
        curr, prev := i%2, (i+1)%2
        dp[curr][0] = i
        for j := 1; j <= m; j++ {
            if s1[i-1] == s2[j-1] {
                dp[curr][j] = dp[prev][j-1]
            } else {
                dp[curr][j] = min(
                    dp[prev][j]+1,
                    dp[curr][j-1]+1, 
                    dp[prev][j-1]+1,
                )
            }
        }
    }
    return dp[n%2][m]
}

func min(a, b, c int) int {
    if a < b {
        if a < c {
            return a
        }
        return c
    } else {
        if b < c {
            return b
        }
        return c
    }
}


func abs(x int) int {
    if x < 0 {
        return -x
    }
    return x
}

func main() {
    scanner := bufio.NewScanner(os.Stdin)
    scanner.Scan()
    parts := strings.Fields(scanner.Text())
    n, _ := strconv.Atoi(parts[0])
    m, _ := strconv.Atoi(parts[1])

    words := make([]string, n)
    for i := 0; i < n; i++ {
        scanner.Scan()
        words[i] = scanner.Text()
    }

    for i := 0; i < m; i++ {
        scanner.Scan()
        parts := strings.Fields(scanner.Text())
        target := parts[0]
        lim, _ := strconv.Atoi(parts[1])
        count := 0
        for _, word := range words {
            if abs(len(word)-len(target)) > lim {
                continue
            }
            if editDistance(target, word) <= lim {
                count++
            }
        }
        fmt.Println(count)
    }
}

```

#### 优点：
空间从 `O(n * m)` 降到 `O(2 * m)`,更适合多次调用

| 方法        | 空间复杂度    | 时间复杂度    | 特点         |
| --------- | -------- | -------- | ---------- |
| 优化前（二维DP） | `O(n × m)` | `O(n × m)` | 简单直观       |
| 优化后（滚动DP） | `O(2 × m)` | `O(n × m)` | 内存占用更低，更高效 |



