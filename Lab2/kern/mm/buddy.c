#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 传入一个数，返回最接近该数的2的指数（包括该数为2的整数这种情况）
size_t getLessNearOfPower2(size_t x)
{
    size_t _i;
    for(_i = 0; _i < sizeof(size_t) * 8 - 1; _i++)
        if((1 << (_i+1)) > x)
            break;
    return (size_t)(1 << _i);
}


static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    // 设置当前页向后的curr_n个页
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // 设置总共的空闲内存页面
    nr_free += n;
    // 设置base指向尚未处理内存的end地址
    base += n;
    while(n != 0)
    {
        size_t curr_n = getLessNearOfPower2(n);
        // 向前挪一块
        base -= curr_n;
        // 设置free pages的数量
        base->property = curr_n;
        // 设置当前页为可用
        SetPageProperty(base);
        // 按照块的大小来插入空闲块，从小到大排序
        // @note 这里必须使用搜索的方式来插入块而不是直接list_add_after(&free_list)，因为存在大的内存块不相邻的情况
        list_entry_t* le;
        for(le = list_next(&free_list); le != &free_list; le = list_next(le))
        {
            struct Page *p = le2page(le, page_link);
            // 排序方式以内存块大小优先，地址其次。
            if((p->property > base->property) || (p->property ==  base->property && p > base))
                break;
        }
        list_add_before(le, &(base->page_link));
        n -= curr_n;
    }
}


static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    // 向上取2的幂次方，如果当前数为2的幂次方则不变
    size_t lessOfPower2 = getLessNearOfPower2(n);
    if (lessOfPower2 < n)
        n = 2 * lessOfPower2;
    // 如果待分配的空闲页面数量小于所需的内存数量
    if (n > nr_free) {
        return NULL;
    }
    // 查找符合要求的连续页
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    // 如果需要切割内存块时，一定分配切割后的前面那块
    if (page != NULL) {
        // 如果内存块过大，则持续切割内存
        while(page->property > n)
        {
            page->property /= 2;
            // 切割出的右边那一半内存块不用于内存分配
            struct Page *p = page + page->property;
            p->property = page->property;
            SetPageProperty(p);
            list_add_after(&(page->page_link), &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
        assert(page->property == n);
        list_del(&(page->page_link));
    }
    return page;
}


static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    // 向上取2的幂次方，如果当前数为2的幂次方则不变
    size_t lessOfPower2 = getLessNearOfPower2(n);
    if (lessOfPower2 < n)
        n = 2 * lessOfPower2;
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    list_entry_t *le;
    // 先插入至链表中
    for(le = list_next(&free_list); le != &free_list; le = list_next(le))
    {
        p = le2page(le, page_link);
        if ((base->property <= p->property)
                 || (p->property ==  base->property && p > base)) {
            break;
        }
    }
    list_add_before(le, &(base->page_link));
    // 先向左合并
    if(base->property == p->property && p + p->property == base) {
        p->property += base->property;
        ClearPageProperty(base);
        list_del(&(base->page_link));
        base = p;
        le = &(base->page_link);
    }

    // 之后循环向后合并
    // 此时的le指向插入块的下一个块
    while (le != &free_list) {
        p = le2page(le, page_link);
        // 如果可以合并(大小相等+地址相邻),则合并
        // 如果两个块的大小相同，则它们不一定内存相邻。
        // 也就是说，在一条链上，可能存在多个大小相等但却无法合并的块
        if (base->property == p->property && base + base->property == p)
        {
            // 向右合并
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
            le = &(base->page_link);
        }
        // 如果遍历到的内存块一定无法合并，则退出
        else if(base->property < p->property)
        {
            // 如果合并不了，则需要修改base在链表中的位置，使大小相同的聚在一起
            list_entry_t* targetLe = list_next(&base->page_link);
            p = le2page(targetLe, page_link);
            while((p->property < base->property)||(p->property ==  base->property && p > base))
                targetLe = list_next(targetLe);
            // 如果当前内存块的位置不正确，则重置位置
            if(targetLe != list_next(&base->page_link))
            {
                list_del(&(base->page_link));
                list_add_before(targetLe, &(base->page_link));
            }
            // 最后退出
            break;
        }
        le = list_next(le);
    }
}


static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager buddy_manager = {
    .name = "buddy_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

