---
date: 2025-09-28T16:25:37
---

#算法/数学 #算法/回溯算法 
# 解数独

解数独和n皇后问题一样都用到了回溯思想。但解数独会更加复杂。

- 数独每次需要考虑三个状态，这个和n皇后一样，行，列，九宫格。
- 数独的三个状态没法像n皇后一样推导出下一层dfs时的状态，因此需要在回溯前就把每一行，列，九宫格的状态都记录下来。

```cpp
class Solution {
public:
    void solveSudoku(vector<vector<char>>& board) {
        int rows[9], cols[9], sqrs[3][3];
        for (int i = 0; i < 9; i++) {
            int s = 0;
            for (int j = 0; j < 9; j++) {
                if (board[i][j] != '.')
                    s |= (1 << board[i][j] - '0');
            }
            rows[i] = s;
        }

        for (int j = 0; j < 9; j++) {
            int s = 0;
            for (int i = 0; i < 9; i++) {
                if (board[i][j] != '.')
                    s |= (1 << board[i][j] - '0');
            }
            cols[j] = s;
        }

        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                int k = i * 3, l = j * 3;
                int s = 0;
                for (int m = k; m < k + 3; m++) {
                    for (int n = l; n < l + 3; n++) {
                        if (board[m][n] != '.')
                            s |= (1 << board[m][n] - '0');
                    }
                }
                sqrs[i][j] = s;
            }
        }

        dfs(board, rows, cols, sqrs, 0, 0);
    }

    bool dfs(vector<vector<char>>& board, int rows[9], int cols[9],
             int sqrs[3][3], int i, int j) {
        if (i == 9)
            return true;
        int ni = i, nj = j;
        if (j == 8) {
            nj = 0;
            ni++;
        } else {
            nj++;
        }

        if (board[i][j] == '.') {
            int s = rows[i] | cols[j] | sqrs[i / 3][j / 3];
            if (s == 1022)
                return false;
            for (int k = 1; k < 10; k++) {
                int bit = 1 << k;
                if (!(s & bit)) {
                    board[i][j] = '0' + k;
                    rows[i] |= bit;
                    cols[j] |= bit;
                    sqrs[i / 3][j / 3] |= bit;
                    if (dfs(board, rows, cols, sqrs, ni, nj)) {
                        return true;
                    }
                    board[i][j] = '.';
                    rows[i] ^= bit;
                    cols[j] ^= bit;
                    sqrs[i / 3][j / 3] ^= bit;
                }
            }
            return false;
        } else {
            return dfs(board, rows, cols, sqrs, ni, nj);
        }
    }
};
```

