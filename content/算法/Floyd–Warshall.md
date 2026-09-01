---
date: 2025-09-28T16:25:37
tags:
  - 算法/图论
  - 算法/最短路
---
Floyd 算法（又叫 **Floyd–Warshall 算法**）是一种经典的 **多源最短路径算法**，用于计算 **任意两点间的最短距离**。

## 算法原理简述

假设图有 `n` 个节点，用邻接矩阵 `dist[i][j]` 表示从节点 `i` 到节点 `j` 的边权。

核心思想：

> 逐步引入中间点 `k`，尝试用它来“优化”路径。 
>  若 `dist[i][j] > dist[i][k] + dist[k][j]`，则更新。

公式如下：
$$dist[i][j] = \min(dist[i][j], dist[i][k] + dist[k][j])$$
时间复杂度为 $O(n^3)$。

### 题目
```
给定一个 n 个点 m 条边的有向图，图中可能存在重边和自环，边权可能为负数。

再给定 k 个询问，每个询问包含两个整数 x 和 y，表示查询从点 x 到点 y 的最短距离，如果路径不存在，则输出 `impossible`。

数据保证图中不存在负权回路。

#### 输入格式

第一行包含三个整数 n,m,k。

接下来 m 行，每行包含三个整数 x,y,z，表示存在一条从点 x 到点 y 的有向边，边长为 z。

接下来 k 行，每行包含两个整数 x,y，表示询问点 x 到点 y 的最短距离。

#### 输出格式

共 k 行，每行输出一个整数，表示询问的结果，若询问两点间不存在路径，则输出 `impossible`。

#### 数据范围

1≤n≤200,  
1≤k≤n2  
1≤m≤20000,  
图中涉及边长绝对值均不超过 10000。

#### 输入样例：


3 3 2
1 2 1
2 3 2
1 3 1
2 1
1 3


#### 输出样例：

impossible
1
```

### 代码
```cpp
#include <iostream>
#include <vector>

using namespace std;

const int INF = 0x3f3f3f3f;

void floyd(int st, int en, vector<vector<int>>& dp) {
    for (int mid = st; mid <= en; mid ++ ) {
        for (int i = st; i <= en; i ++ ) {
            for (int j = st; j <= en; j ++ ) {
                if (dp[i][mid] < INF && dp[mid][j] < INF)
                    dp[i][j] = min(dp[i][j], dp[i][mid] + dp[mid][j]);
            }
        }
    }
}

int main() {
    int n, m, k;
    scanf("%d%d%d", &n, &m, &k);
    vector<vector<int>> adjm(n + 1, vector<int>(n + 1, INF));
    for (int i = 1; i <= n; i ++ ) adjm[i][i] = 0;
    
    for (int i = 0; i < m; i ++ ) {
        int x, y, z;
        scanf("%d%d%d", &x, &y, &z);
        adjm[x][y] = min(adjm[x][y], z);
    }
    
    floyd(1, n, adjm);
    
    for (int i = 0; i < k; i ++ ) {
        int x, y;
        scanf("%d%d", &x, &y);
        if (adjm[x][y] >= INF) printf("impossible\n");
        else printf("%d\n", adjm[x][y]);
    }
    
    return 0;
}
```


## 路径还原

###  思路原理

除了 `dist[i][j]`（最短距离），再维护一个数组：

`vector<vector<int>> nxt(n + 1, vector<int>(n + 1, -1));`

它表示：

> `nxt[i][j]` 是在从 i → j 的最短路径上，i 的**下一个节点**。

### 初始化：

当有一条边 i → j 时：

`nxt[i][j] = j;`

### 更新规则：

当 Floyd 发现一个更短路径：

```cpp
if (dp[i][mid] < INF && dp[mid][j] < INF && dp[i][mid] + dp[mid][j] < dp[i][j]) {
	dp[i][j] = dp[i][mid] + dp[mid][j];
	nxt[i][j] = nxt[i][mid];
}
```

意思是：

> 从 i 走到 j 的第一步，现在应该先走到 i→k 的第一步。

```cpp
#include <iostream>
#include <vector>

using namespace std;

const int INF = 0x3f3f3f3f;

void floyd(int st, int en, vector<vector<int>>& dp, vector<vector<int>>& nxt) {
    for (int mid = st; mid <= en; mid ++ ) {
        for (int i = st; i <= en; i ++ ) {
            for (int j = st; j <= en; j ++ ) {
                if (dp[i][mid] < INF && dp[mid][j] < INF && dp[i][mid] + dp[mid][j] < dp[i][j]) {
                    dp[i][j] = dp[i][mid] + dp[mid][j];
                    nxt[i][j] = nxt[i][mid];
                }
            }
        }
    }
}

vector<int> get_path(int u, int v, const vector<vector<int>>& nxt) {
    if (nxt[u][v] == -1) return {};
    vector<int> path = {u};
    while (u != v) {
        u = nxt[u][v];
        path.push_back(u);
    }
    return path;
}

int main() {
    int n, m, k;
    scanf("%d%d%d", &n, &m, &k);
    vector<vector<int>> adjm(n + 1, vector<int>(n + 1, INF));
    vector<vector<int>> nxt(n + 1, vector<int>(n + 1, -1)); // 路径还原
    for (int i = 1; i <= n; i ++ ) {
        adjm[i][i] = 0;
        nxt[i][i] = i;
    }
    
    for (int i = 0; i < m; i ++ ) {
        int x, y, z;
        scanf("%d%d%d", &x, &y, &z);
        if (z < adjm[x][y]) {
            adjm[x][y] = z;
            nxt[x][y] = y;
        }
    }
    
    floyd(1, n, adjm, nxt);
    
    for (int i = 0; i < k; i ++ ) {
        int x, y;
        scanf("%d%d", &x, &y);
        if (adjm[x][y] >= INF) printf("impossible\n");
        else printf("%d\n", adjm[x][y]);
        
        vector<int> path = get_path(x, y, nxt);
        printf("路径: ");
        for (int p = 0; p < path.size(); p++) {
            printf("%d", path[p]);
            if (p + 1 < path.size()) printf(" -> ");
        }
        printf("\n");
    }
    
    return 0;
}
```