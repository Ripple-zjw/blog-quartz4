---
date: 2025-09-28T16:25:37
tags:
  - 算法/排序
---
# 排序算法

## 快速排序

任意选择一个基准点`pivot`，每次将数组中小于基准点的数放在基准点左侧，大于的放在右侧。然后分别向基准点的左侧和右侧做递归。

```cpp
#include <iostream>
using namespace std;

const int N = 100010;

int q[N];
int n;

void quick_sort(int q[], int l, int r) {
    if (l >= r) return;
    int i = l - 1, j = r + 1, p = q[l + r >> 1];
    while (i < j) {
        do i ++ ; while (q[i] < p);
        do j -- ; while (q[j] > p);
        if (i < j) swap(q[i], q[j]);
    }
    
    quick_sort(q, l, j), quick_sort(q, j + 1, r);
}

int main() {
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &q[i]);
    quick_sort(q, 0, n - 1);
    for (int i = 0; i < n; i ++ ) printf("%d ", q[i]);
}
```

| 情况   | 时间复杂度      | 空间复杂度    | 稳定性   |
| ---- | ---------- | -------- | ----- |
| 最好情况 | O(n log n) | O(log n) | ❌ 不稳定 |
| 平均情况 | O(n log n) | O(log n) | ❌ 不稳定 |
| 最坏情况 | O(n²)      | O(n)     | ❌ 不稳定 |

### 三向切分快速排序

和快排的思路一样，不同点在于这次我们把一堆相同的数都作为基准点，这一段基准点放在中间。三分快排在排序相同元素很多的数组时速度非常快。

```cpp
#include <iostream>
using namespace std;

const int N = 100010;

int q[N];
int n;

void three_way_quick_sort(int q[], int l, int r) {
    if (l >= r) return;
    int lt = l, gt = r, i = l;
    int p = q[l + r >> 1];
    
    while (i <= gt) {
        if (q[i] < p) swap(q[i++], q[lt++]);
        else if (q[i] > p) swap(q[i], q[gt--]);
        else i++;
    }
    
    three_way_quick_sort(q, l, lt - 1), three_way_quick_sort(q, gt + 1, r);
}

int main() {
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &q[i]);
    three_way_quick_sort(q, 0, n - 1);
    for (int i = 0; i < n; i ++ ) printf("%d ", q[i]);
    
    return 0;
}
```

| 情况   | 时间复杂度       | 空间复杂度    | 稳定性   |
| ---- | ----------- | -------- | ----- |
| 最好情况 | O(n log n)  | O(log n) | ❌ 不稳定 |
| 平均情况 | O(n log n)  | O(log n) | ❌ 不稳定 |
| 最坏情况 | O(n²)（极端情况） | O(n)     | ❌ 不稳定 |


## 归并排序

先将数组按照二等分不停的切割，直到数组只有1个大小。然后开始再把它们组合起来，每次组合两个相邻的数组，这两个数组是有序的，组合的过程就是把这两个有序的小数组变成一个大数组。

```cpp
#include <cstdio>

using namespace std;

const int N = 1e5 + 10;
int a[N], t[N];

void merge_sort(int a[], int t[], int l, int r) {
    if (l >= r) return;
    int mid = l + r >> 1;
    merge_sort(a, t, l, mid), merge_sort(a, t, mid + 1, r);
    
    if (a[mid] <= a[mid + 1]) return;

    int i = l, j = mid + 1, k = l;
    while (i <= mid && j <= r) {
        if (a[i] < a[j]) t[k++] = a[i++];
        else t[k++] = a[j++];
    }
    while (i <= mid) t[k++] = a[i++];
    while (j <= r) t[k++] = a[j++];
    
    for (int i = l; i <= r; i ++ ) a[i] = t[i];
}

int main() {
    int n;
    scanf("%d", &n);
    
    for (int i = 0; i < n; i ++ ) {
        scanf("%d", &a[i]);
    }
    merge_sort(a, t, 0, n - 1);
    
    for (int i = 0; i < n; i ++ ) {
        printf("%d ", a[i]);
    }
    
    return 0;
}
```

| 情况   | 时间复杂度      | 空间复杂度 | 稳定性  |
| ---- | ---------- | ----- | ---- |
| 最好情况 | O(n log n) | O(n)  | ✅ 稳定 |
| 平均情况 | O(n log n) | O(n)  | ✅ 稳定 |
| 最坏情况 | O(n log n) | O(n)  | ✅ 稳定 |


## 堆排序

堆排序使用堆这个数据结构排序。先将整个数组建大顶堆，然后将堆顶元素和堆最后一个元素替换，此时堆长度-1，再用下沉操作维护堆。直到堆长度为0，整个数组排序完成。

```cpp
#include <iostream>
using namespace std;

const int N = 100010;

int a[N];
int n;

// heap start from index 0
void heapify(int a[], int n, int i) {
    int lar = i;
    int l = i * 2 + 1, r = i * 2 + 2;
    if (l < n && a[lar] < a[l]) lar = l;
    if (r < n && a[lar] < a[r]) lar = r;
    
    if (lar != i) {
        swap(a[lar], a[i]);
        heapify(a, n, lar);
    }
}

void heapSort(int a[], int n) {
    for (int i = n / 2 - 1; i >= 0; i -- ) heapify(a, n, i);

    for (int i = n - 1; i > 0; i -- ) {
        swap(a[0], a[i]);
        heapify(a, i, 0);
    }
}

int main() {
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    heapSort(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

| 操作   | 时间复杂度          |
| ---- | -------------- |
| 建堆   | O(n)           |
| 调整堆  | O(log n)       |
| 总体排序 | **O(n log n)** |


## 插入排序

1.  假设第一个元素已排好序
2.  从第二个元素开始，向前找插入位置
3.  将其插入已排序部分的合适位置
4.  重复直到所有元素都排好序

```cpp
#include <iostream>

using namespace std;

const int N = 1010;
int a[N];

void insertSort(int a[], int n) {
    for (int i = 1; i < n; i ++ ) {
        int t = a[i], j = i - 1;
        while (j >= 0 && a[j] > t) {
            a[j + 1] = a[j];
            j -- ;
        }
        a[j + 1] = t;
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    insertSort(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

| 情况     | 比较次数       | 移动次数       | 时间复杂度     |
| ------ | ---------- | ---------- | --------- |
| 最好（有序） | n - 1      | 0          | **O(n)**  |
| 最坏（逆序） | n(n - 1)/2 | n(n - 1)/2 | **O(n²)** |
| 平均     | n²/4       | n²/4       | **O(n²)** |
| 空间复杂度  | -          | -          | **O(1)**  |


## 冒泡排序

- 冒泡排序是一种简单的比较交换排序算法：
- 每次从头到尾两两比较相邻元素，把较大的“冒泡”移到后面；
- 重复进行 n-1 次，直到数组有序；
- 得名于“冒泡”的过程：大的元素像气泡一样逐渐上浮到数组末尾。

```cpp
#include <iostream>

using namespace std;

const int N = 1010;
int a[N];

void bubbleSort(int a[], int n) {
    for (int i = 0; i < n - 1; i ++ ) {
        bool f = true;
        for (int j = 0; j < n - i - 1; j ++ ) {
            if (a[j] > a[j + 1]) {
                swap(a[j + 1], a[j]);
                f = false;
            }
        }
        if (f) return;
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    bubbleSort(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

| 情况   | 时间复杂度 | 空间复杂度 | 稳定性  |
| ---- | ----- | ----- | ---- |
| 最好情况 | O(n)  | O(1)  | ✅ 稳定 |
| 平均情况 | O(n²) | O(1)  | ✅ 稳定 |
| 最坏情况 | O(n²) | O(1)  | ✅ 稳定 |



## 选择排序

- 从未排序区间中找出最小值的下标 `minIndex`
- 将其与当前位置 `i` 交换
- 执行 `n−1` 轮后数组有序

```cpp
#include <iostream>

using namespace std;

const int N = 1010;
int a[N];

void selectionSort(int a[], int n) {
    for (int i = 0; i < n - 1; i ++ ) {
        int mi = i;
        for (int j = i + 1; j < n; j ++ ) {
            if (a[mi] > a[j]) mi = j;
        }
        if (mi != i) swap(a[mi], a[i]);
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    selectionSort(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

| 情况   | 时间复杂度 | 空间复杂度 | 稳定性   |
| ---- | ----- | ----- | ----- |
| 最好情况 | O(n²) | O(1)  | ❌ 不稳定 |
| 平均情况 | O(n²) | O(1)  | ❌ 不稳定 |
| 最坏情况 | O(n²) | O(1)  | ❌ 不稳定 |


## 希尔排序

1. 选定初始步长 `gap`，一般为 `n/2`，逐轮缩小至 `1`
1. 将数组分成若干组，对每组使用插入排序
1. 每轮 `gap` 缩小一半，直至 `gap = 1`，完成排序

> 希尔排序就是插入排序的变体，用于解决插入排序的缺点。**插入排序在插入靠后的较小数时需要移动大量的数。**希尔排序会优先把这些小数插到前面，最后`gap=1`时做一次完整的插入排序，此时速度会快很多。

```cpp
#include <iostream>

using namespace std;

const int N = 100010;
int a[N];

void shellSort(int a[], int n) {
    for (int gap = n / 2; gap > 0; gap /= 2) {
        for (int i = gap; i < n; i ++ ) {
            int t = a[i];
            int j = i;
            while (j >= gap && a[j - gap] > t) {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = t;
        }
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    shellSort(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

| 情况   | 时间复杂度（经典增量序列）                        | 空间复杂度 | 稳定性   |
| ---- | ------------------------------------ | ----- | ----- |
| 最好情况 | $O(n log n)$                         | O(1)  | ❌ 不稳定 |
| 平均情况 | $O(n^{1.3} \textasciitilde n^{1.5})$ | O(1)  | ❌ 不稳定 |
| 最坏情况 | $O(n^2)$                             | O(1)  | ❌ 不稳定 |

### Hibbard 序列（$2^k - 1$）

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

const int N = 100010;
int a[N];

vector<int> generateHibbardGaps(int n) {
    vector<int> gaps;
    for (int k = 1; (1 << k) - 1 < n; k++)
        gaps.push_back((1 << k) - 1);
    reverse(gaps.begin(), gaps.end());
    return gaps;
}

void shellSort_hibbard(int a[], int n) {
    vector<int> gaps = generateHibbardGaps(n);
    
    for (int gap : gaps) {
        for (int i = gap; i < n; i ++ ) {
            int t = a[i];
            int j = i;
            while (j >= gap && a[j - gap] > t) {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = t;
        }
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    shellSort_hibbard(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```

### Knuth 序列（$(3^k - 1)/2$）

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

const int N = 100010;
int a[N];

vector<int> generateKnuthGaps(int n) {
    vector<int> gaps;
    for (int gap = 1; gap < n; gap = gap * 3 + 1)
        gaps.push_back(gap);
    reverse(gaps.begin(), gaps.end());
    return gaps;
}

void shellSort_knuth(int a[], int n) {
    vector<int> gaps = generateKnuthGaps(n);
    
    for (int gap : gaps) {
        for (int i = gap; i < n; i ++ ) {
            int t = a[i];
            int j = i;
            while (j >= gap && a[j - gap] > t) {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = t;
        }
    }
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ ) scanf("%d", &a[i]);
    shellSort_knuth(a, n);
    for (int i = 0; i < n; i ++ ) printf("%d ", a[i]);
    
    return 0;
}
```









