---
date: 2025-09-28T16:25:37
---

#算法/回溯算法
# 📌 问题描述
在 n×n 棋盘上放置 n 个皇后，要求任何两个皇后不能处于同一行、同一列或对角线上。输出所有可行的皇后位置方案。

## ⚙️ 算法核心思路

- 每一行只放一个皇后 ⇒ 用递归 DFS 遍历每一行
- 剪枝策略通过三位掩码实现（分别记录哪些列/对角线不能放）
- 使用 int 位运算代替布尔数组，加快判断和状态回溯效率

## 🧩 三个状态变量解释
```cpp
dfs(..., int ls, int ms, int rs, ...)
```
表示当前被占用的位置

| 掩码变量 | 含义                 | 说明                |
| ---- | ------------------ | ----------------- |
| `ms` | 列掩码（middle column） | 记录哪些列已经放置了皇后      |
| `ls` | 左对角线掩码             | 记录 `/` 方向对角线是否被占用 |
| `rs` | 右对角线掩码             | 记录 `\` 方向对角线是否被占用 |

- `/` 方向：每次递归需要左移 `ls << 1`
- `\` 方向：每次递归需要右移 `rs >> 1`
- 当前行的所有非法位置为：`status = ls | ms | rs`

## 🔄 DFS 主体逻辑
```cpp
int status = ls | rs | ms;
for (int col = 0; col < n; col++) {
    int bit = 1 << col;
    if (!(status & bit)) {
        queens[row] = col;
        dfs(queens, n, row + 1,
            (ls | bit) << 1,  // 左对角线左移
            ms | bit,         // 当前列标记
            (rs | bit) >> 1,  // 右对角线右移
            res);
        queens[row] = -1;     // 回溯
    }
}
```

### ✨ 整体流程：
- 遍历第 row 行的每一列，尝试是否能放皇后
- 判断是否被之前行的皇后攻击（通过 status & bit）
- 合法则设置 queens[row] = col，并递归进入下一行
- 递归完成后清空当前位置（回溯）

## 📃 函数说明

### `solveNQueens(int n)`
初始化 `queens` 数组表示第 i 行皇后放在哪一列

调用 `dfs(...)` 回溯所有方案

返回所有皇后位置组合

### `printNQueens(vector<int>& queens)`
将一组皇后解打印为棋盘形式，用 `Q` 和 `.` 表示

## ✍️ 示例代码

> 判题地址: https://www.acwing.com/problem/content/description/845/

```cpp
#include <iostream>
#include <vector>
#include <string>
#include <functional>

using namespace std;

class NQueensSolver {
public:
    static vector<vector<int>> solveNQueens(int n) {
        vector<vector<int>> res;
        vector<int> queens(n, -1);

        // 内部 dfs 函数
        function<void(int, int, int, int)> dfs = [&](int row, int ls, int ms, int rs) {
            if (row == n) {
                res.push_back(queens);
                return;
            }

            int status = ls | ms | rs;
            for (int col = 0; col < n; col++) {
                int bit = 1 << col;
                if (!(status & bit)) {
                    queens[row] = col;
                    dfs(row + 1, (ls | bit) << 1, ms | bit, (rs | bit) >> 1);
                    queens[row] = -1;
                }
            }
        };

        dfs(0, 0, 0, 0);
        return res;
    }

    static void printNQueens(const vector<int>& queens) {
        int n = queens.size();
        for (int i = 0; i < n; ++i) {
            string row(n, '.');
            row[queens[i]] = 'Q';
            cout << row << endl;
        }
        cout << endl;
    }
};


int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n;
    cin >> n;
    vector<vector<int>> ans = NQueensSolver::solveNQueens(n);
    for (const auto& queens : ans) {
        NQueensSolver::printNQueens(queens);
    }

    return 0;
}

```

```python
class NQueensSolver:
    @staticmethod
    def solve_n_queens(n):
        res = []
        queens = [-1] * n
        def dfs(row, ls, ms, rs):
            if row == n:
                res.append(queens[:])
                return
            status = ls | ms | rs
            for col in range(n):
                bit = 1 << col
                if not (status & bit):
                    queens[row] = col
                    dfs(row + 1, (ls | bit) << 1, ms | bit, (rs | bit) >> 1)
                    queens[row] = -1
        dfs(0, 0, 0, 0)
        return res

    @staticmethod
    def print_n_queens(queens):
        n = len(queens)
        for i in range(n):
            row = ['.'] * n
            row[queens[i]] = 'Q'
            print(''.join(row))
        print()

if __name__ == "__main__":
    n = int(input())
    solutions = NQueensSolver.solve_n_queens(n)
    for sol in solutions:
        NQueensSolver.print_n_queens(sol)

```

```go
package main

import (
    "bufio"
    "fmt"
    "os"
    "strconv"
)

type NQueensSolver struct{}

func solveNQueens(n int) [][]int {
    var res [][]int
    queens := make([]int, n)
    for i := range queens {
        queens[i] = -1
    }

    var dfs func(row, ls, ms, rs int)
    dfs = func(row, ls, ms, rs int) {
        if row == n {
            solution := make([]int, n)
            copy(solution, queens)
            res = append(res, solution)
            return
        }
        status := ls | ms | rs
        for col := 0; col < n; col++ {
            bit := 1 << col
            if status&bit == 0 {
                queens[row] = col
                dfs(row+1, (ls|bit)<<1, ms|bit, (rs|bit)>>1)
                queens[row] = -1
            }
        }
    }

    dfs(0, 0, 0, 0)
    return res
}

func printNQueens(queens []int) {
    n := len(queens)
    for i := 0; i < n; i++ {
        row := make([]byte, n)
        for j := range row {
            row[j] = '.'
        }
        row[queens[i]] = 'Q'
        fmt.Println(string(row))
    }
    fmt.Println()
}

func main() {
    scanner := bufio.NewScanner(os.Stdin)
    scanner.Scan()
    n, _ := strconv.Atoi(scanner.Text())
    solutions := solveNQueens(n)
    for _, sol := range solutions {
        printNQueens(sol)
    }
}

```

还有一种问题是只求有多少种方法但不需要列出来。
> 判题地址: https://leetcode.cn/problems/n-queens-ii/

```cpp
class Solution {
public:
    int totalNQueens(int n) {
        return dfs(n, 0, 0, 0, 0);
    }

    int dfs(int n, int row, int ls, int ms, int rs) {
        if (row == n) {
            return 1;
        }
        int status = ls | rs | ms;
        int res = 0;
        for (int col = 0; col < n; col ++ ) {
            int bit = 1 << col;
            if (!(status & bit)) {
                res += dfs(n, row + 1, (ls | bit) << 1, ms | bit, (rs | bit) >> 1);
            }
        }
        return res;
    }
};
```


## 📈 时间与空间复杂度
时间复杂度：`O(N!)`（最坏情况），但由于剪枝，实际远小于此

空间复杂度：`O(N)` 递归深度 + 解数组空间




