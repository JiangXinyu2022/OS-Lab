#include <stdio.h>
#include <assert.h>
#include "buddy.c" // 引用前面提供的内存管理代码

int main() {
    // 初始化内存块
    memory[0].start = 0;
    memory[0].size = 512;
    memory[0].free = 1;

    // 分配内存
    int p0 = allocate(70);
    int p1 = allocate(35);
    int p2 = allocate(257);
    int p3 = allocate(63);

    // 验证分配
    assert(p0 != -1);
    assert(p1 != -1);
    assert(p2 != -1);
    assert(p3 != -1);

    // 释放内存
    deallocate(p1);
    deallocate(p3);

    // 验证释放
    assert(memory[1].free == 1); // 检查p1释放后内存块状态
    assert(memory[3].free == 1); // 检查p3释放后内存块状态

    // 合并空闲块
    deallocate(p0);

    // 验证合并
    assert(memory[0].free == 1); // 检查p0释放后内存块状态

    // 申请更多内存
    int p4 = allocate(255);
    int p5 = allocate(255);

    // 验证分配
    assert(p4 != -1);
    assert(p5 != -1);

    // 释放内存
    deallocate(p4);
    deallocate(p5);

    // 验证释放
    assert(memory[1].free == 1); // 检查p4释放后内存块状态
    assert(memory[3].free == 1); // 检查p5释放后内存块状态

    // 打印最终内存状态
    for (int i = 0; i < 512; i++) {
        printf("Block start: %d, Size: %d, Free: %d\n", memory[i].start, memory[i].size, memory[i].free);
    }

    printf("All tests passed!\n");

    return 0;
}
