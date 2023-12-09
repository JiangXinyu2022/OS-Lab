
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000a1517          	auipc	a0,0xa1
ffffffffc020003a:	02250513          	addi	a0,a0,34 # ffffffffc02a1058 <edata>
ffffffffc020003e:	000ac617          	auipc	a2,0xac
ffffffffc0200042:	5a260613          	addi	a2,a2,1442 # ffffffffc02ac5e0 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	5ae060ef          	jal	ra,ffffffffc02065fc <memset>
    cons_init();                // init the console
ffffffffc0200052:	536000ef          	jal	ra,ffffffffc0200588 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	5d258593          	addi	a1,a1,1490 # ffffffffc0206628 <etext+0x2>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206648 <etext+0x22>
ffffffffc0200066:	128000ef          	jal	ra,ffffffffc020018e <cprintf>

    print_kerninfo();
ffffffffc020006a:	1ac000ef          	jal	ra,ffffffffc0200216 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	5c6020ef          	jal	ra,ffffffffc0202634 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5ee000ef          	jal	ra,ffffffffc0200660 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	3e8040ef          	jal	ra,ffffffffc0204462 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	50f050ef          	jal	ra,ffffffffc0205d8c <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	57a000ef          	jal	ra,ffffffffc02005fc <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	306030ef          	jal	ra,ffffffffc020338c <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	4a8000ef          	jal	ra,ffffffffc0200532 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c6000ef          	jal	ra,ffffffffc0200654 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	647050ef          	jal	ra,ffffffffc0205ed8 <cpu_idle>

ffffffffc0200096 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200096:	715d                	addi	sp,sp,-80
ffffffffc0200098:	e486                	sd	ra,72(sp)
ffffffffc020009a:	e0a2                	sd	s0,64(sp)
ffffffffc020009c:	fc26                	sd	s1,56(sp)
ffffffffc020009e:	f84a                	sd	s2,48(sp)
ffffffffc02000a0:	f44e                	sd	s3,40(sp)
ffffffffc02000a2:	f052                	sd	s4,32(sp)
ffffffffc02000a4:	ec56                	sd	s5,24(sp)
ffffffffc02000a6:	e85a                	sd	s6,16(sp)
ffffffffc02000a8:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02000aa:	c901                	beqz	a0,ffffffffc02000ba <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02000ac:	85aa                	mv	a1,a0
ffffffffc02000ae:	00006517          	auipc	a0,0x6
ffffffffc02000b2:	5a250513          	addi	a0,a0,1442 # ffffffffc0206650 <etext+0x2a>
ffffffffc02000b6:	0d8000ef          	jal	ra,ffffffffc020018e <cprintf>
readline(const char *prompt) {
ffffffffc02000ba:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000bc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000be:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000c0:	4aa9                	li	s5,10
ffffffffc02000c2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000c4:	000a1b97          	auipc	s7,0xa1
ffffffffc02000c8:	f94b8b93          	addi	s7,s7,-108 # ffffffffc02a1058 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000cc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000d0:	136000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000d4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000d6:	00054b63          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	00a95b63          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc02000de:	029a5463          	ble	s1,s4,ffffffffc0200106 <readline+0x70>
        c = getchar();
ffffffffc02000e2:	124000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000e6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000e8:	fe0559e3          	bgez	a0,ffffffffc02000da <readline+0x44>
            return NULL;
ffffffffc02000ec:	4501                	li	a0,0
ffffffffc02000ee:	a099                	j	ffffffffc0200134 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02000f0:	03341463          	bne	s0,s3,ffffffffc0200118 <readline+0x82>
ffffffffc02000f4:	e8b9                	bnez	s1,ffffffffc020014a <readline+0xb4>
        c = getchar();
ffffffffc02000f6:	110000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000fa:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000fc:	fe0548e3          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200100:	fea958e3          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc0200104:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200106:	8522                	mv	a0,s0
ffffffffc0200108:	0ba000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i ++] = c;
ffffffffc020010c:	009b87b3          	add	a5,s7,s1
ffffffffc0200110:	00878023          	sb	s0,0(a5)
ffffffffc0200114:	2485                	addiw	s1,s1,1
ffffffffc0200116:	bf6d                	j	ffffffffc02000d0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200118:	01540463          	beq	s0,s5,ffffffffc0200120 <readline+0x8a>
ffffffffc020011c:	fb641ae3          	bne	s0,s6,ffffffffc02000d0 <readline+0x3a>
            cputchar(c);
ffffffffc0200120:	8522                	mv	a0,s0
ffffffffc0200122:	0a0000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i] = '\0';
ffffffffc0200126:	000a1517          	auipc	a0,0xa1
ffffffffc020012a:	f3250513          	addi	a0,a0,-206 # ffffffffc02a1058 <edata>
ffffffffc020012e:	94aa                	add	s1,s1,a0
ffffffffc0200130:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200134:	60a6                	ld	ra,72(sp)
ffffffffc0200136:	6406                	ld	s0,64(sp)
ffffffffc0200138:	74e2                	ld	s1,56(sp)
ffffffffc020013a:	7942                	ld	s2,48(sp)
ffffffffc020013c:	79a2                	ld	s3,40(sp)
ffffffffc020013e:	7a02                	ld	s4,32(sp)
ffffffffc0200140:	6ae2                	ld	s5,24(sp)
ffffffffc0200142:	6b42                	ld	s6,16(sp)
ffffffffc0200144:	6ba2                	ld	s7,8(sp)
ffffffffc0200146:	6161                	addi	sp,sp,80
ffffffffc0200148:	8082                	ret
            cputchar(c);
ffffffffc020014a:	4521                	li	a0,8
ffffffffc020014c:	076000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            i --;
ffffffffc0200150:	34fd                	addiw	s1,s1,-1
ffffffffc0200152:	bfbd                	j	ffffffffc02000d0 <readline+0x3a>

ffffffffc0200154 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200154:	1141                	addi	sp,sp,-16
ffffffffc0200156:	e022                	sd	s0,0(sp)
ffffffffc0200158:	e406                	sd	ra,8(sp)
ffffffffc020015a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020015c:	42e000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc0200160:	401c                	lw	a5,0(s0)
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200164:	2785                	addiw	a5,a5,1
ffffffffc0200166:	c01c                	sw	a5,0(s0)
}
ffffffffc0200168:	6402                	ld	s0,0(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020016e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	86ae                	mv	a3,a1
ffffffffc0200172:	862a                	mv	a2,a0
ffffffffc0200174:	006c                	addi	a1,sp,12
ffffffffc0200176:	00000517          	auipc	a0,0x0
ffffffffc020017a:	fde50513          	addi	a0,a0,-34 # ffffffffc0200154 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc020017e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200180:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200182:	050060ef          	jal	ra,ffffffffc02061d2 <vprintfmt>
    return cnt;
}
ffffffffc0200186:	60e2                	ld	ra,24(sp)
ffffffffc0200188:	4532                	lw	a0,12(sp)
ffffffffc020018a:	6105                	addi	sp,sp,32
ffffffffc020018c:	8082                	ret

ffffffffc020018e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020018e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200190:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200194:	f42e                	sd	a1,40(sp)
ffffffffc0200196:	f832                	sd	a2,48(sp)
ffffffffc0200198:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020019a:	862a                	mv	a2,a0
ffffffffc020019c:	004c                	addi	a1,sp,4
ffffffffc020019e:	00000517          	auipc	a0,0x0
ffffffffc02001a2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200154 <cputch>
ffffffffc02001a6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02001a8:	ec06                	sd	ra,24(sp)
ffffffffc02001aa:	e0ba                	sd	a4,64(sp)
ffffffffc02001ac:	e4be                	sd	a5,72(sp)
ffffffffc02001ae:	e8c2                	sd	a6,80(sp)
ffffffffc02001b0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001b4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001b6:	01c060ef          	jal	ra,ffffffffc02061d2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	4512                	lw	a0,4(sp)
ffffffffc02001be:	6125                	addi	sp,sp,96
ffffffffc02001c0:	8082                	ret

ffffffffc02001c2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001c2:	3c80006f          	j	ffffffffc020058a <cons_putc>

ffffffffc02001c6 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001c6:	1101                	addi	sp,sp,-32
ffffffffc02001c8:	e822                	sd	s0,16(sp)
ffffffffc02001ca:	ec06                	sd	ra,24(sp)
ffffffffc02001cc:	e426                	sd	s1,8(sp)
ffffffffc02001ce:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001d0:	00054503          	lbu	a0,0(a0)
ffffffffc02001d4:	c51d                	beqz	a0,ffffffffc0200202 <cputs+0x3c>
ffffffffc02001d6:	0405                	addi	s0,s0,1
ffffffffc02001d8:	4485                	li	s1,1
ffffffffc02001da:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001dc:	3ae000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc02001e0:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc02001e4:	0405                	addi	s0,s0,1
ffffffffc02001e6:	fff44503          	lbu	a0,-1(s0)
ffffffffc02001ea:	f96d                	bnez	a0,ffffffffc02001dc <cputs+0x16>
ffffffffc02001ec:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f0:	4529                	li	a0,10
ffffffffc02001f2:	398000ef          	jal	ra,ffffffffc020058a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001f6:	8522                	mv	a0,s0
ffffffffc02001f8:	60e2                	ld	ra,24(sp)
ffffffffc02001fa:	6442                	ld	s0,16(sp)
ffffffffc02001fc:	64a2                	ld	s1,8(sp)
ffffffffc02001fe:	6105                	addi	sp,sp,32
ffffffffc0200200:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200202:	4405                	li	s0,1
ffffffffc0200204:	b7f5                	j	ffffffffc02001f0 <cputs+0x2a>

ffffffffc0200206 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200206:	1141                	addi	sp,sp,-16
ffffffffc0200208:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020020a:	3b6000ef          	jal	ra,ffffffffc02005c0 <cons_getc>
ffffffffc020020e:	dd75                	beqz	a0,ffffffffc020020a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	0141                	addi	sp,sp,16
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200216:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200218:	00006517          	auipc	a0,0x6
ffffffffc020021c:	47050513          	addi	a0,a0,1136 # ffffffffc0206688 <etext+0x62>
void print_kerninfo(void) {
ffffffffc0200220:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	f6dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200226:	00000597          	auipc	a1,0x0
ffffffffc020022a:	e1058593          	addi	a1,a1,-496 # ffffffffc0200036 <kern_init>
ffffffffc020022e:	00006517          	auipc	a0,0x6
ffffffffc0200232:	47a50513          	addi	a0,a0,1146 # ffffffffc02066a8 <etext+0x82>
ffffffffc0200236:	f59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	3ec58593          	addi	a1,a1,1004 # ffffffffc0206626 <etext>
ffffffffc0200242:	00006517          	auipc	a0,0x6
ffffffffc0200246:	48650513          	addi	a0,a0,1158 # ffffffffc02066c8 <etext+0xa2>
ffffffffc020024a:	f45ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020024e:	000a1597          	auipc	a1,0xa1
ffffffffc0200252:	e0a58593          	addi	a1,a1,-502 # ffffffffc02a1058 <edata>
ffffffffc0200256:	00006517          	auipc	a0,0x6
ffffffffc020025a:	49250513          	addi	a0,a0,1170 # ffffffffc02066e8 <etext+0xc2>
ffffffffc020025e:	f31ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200262:	000ac597          	auipc	a1,0xac
ffffffffc0200266:	37e58593          	addi	a1,a1,894 # ffffffffc02ac5e0 <end>
ffffffffc020026a:	00006517          	auipc	a0,0x6
ffffffffc020026e:	49e50513          	addi	a0,a0,1182 # ffffffffc0206708 <etext+0xe2>
ffffffffc0200272:	f1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200276:	000ac597          	auipc	a1,0xac
ffffffffc020027a:	76958593          	addi	a1,a1,1897 # ffffffffc02ac9df <end+0x3ff>
ffffffffc020027e:	00000797          	auipc	a5,0x0
ffffffffc0200282:	db878793          	addi	a5,a5,-584 # ffffffffc0200036 <kern_init>
ffffffffc0200286:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020028a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020028e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200294:	95be                	add	a1,a1,a5
ffffffffc0200296:	85a9                	srai	a1,a1,0xa
ffffffffc0200298:	00006517          	auipc	a0,0x6
ffffffffc020029c:	49050513          	addi	a0,a0,1168 # ffffffffc0206728 <etext+0x102>
}
ffffffffc02002a0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	eedff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02002a6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002a6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002a8:	00006617          	auipc	a2,0x6
ffffffffc02002ac:	3b060613          	addi	a2,a2,944 # ffffffffc0206658 <etext+0x32>
ffffffffc02002b0:	04d00593          	li	a1,77
ffffffffc02002b4:	00006517          	auipc	a0,0x6
ffffffffc02002b8:	3bc50513          	addi	a0,a0,956 # ffffffffc0206670 <etext+0x4a>
void print_stackframe(void) {
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002be:	1c6000ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02002c2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c4:	00006617          	auipc	a2,0x6
ffffffffc02002c8:	57460613          	addi	a2,a2,1396 # ffffffffc0206838 <commands+0xe0>
ffffffffc02002cc:	00006597          	auipc	a1,0x6
ffffffffc02002d0:	58c58593          	addi	a1,a1,1420 # ffffffffc0206858 <commands+0x100>
ffffffffc02002d4:	00006517          	auipc	a0,0x6
ffffffffc02002d8:	58c50513          	addi	a0,a0,1420 # ffffffffc0206860 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002dc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002de:	eb1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002e2:	00006617          	auipc	a2,0x6
ffffffffc02002e6:	58e60613          	addi	a2,a2,1422 # ffffffffc0206870 <commands+0x118>
ffffffffc02002ea:	00006597          	auipc	a1,0x6
ffffffffc02002ee:	5ae58593          	addi	a1,a1,1454 # ffffffffc0206898 <commands+0x140>
ffffffffc02002f2:	00006517          	auipc	a0,0x6
ffffffffc02002f6:	56e50513          	addi	a0,a0,1390 # ffffffffc0206860 <commands+0x108>
ffffffffc02002fa:	e95ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002fe:	00006617          	auipc	a2,0x6
ffffffffc0200302:	5aa60613          	addi	a2,a2,1450 # ffffffffc02068a8 <commands+0x150>
ffffffffc0200306:	00006597          	auipc	a1,0x6
ffffffffc020030a:	5c258593          	addi	a1,a1,1474 # ffffffffc02068c8 <commands+0x170>
ffffffffc020030e:	00006517          	auipc	a0,0x6
ffffffffc0200312:	55250513          	addi	a0,a0,1362 # ffffffffc0206860 <commands+0x108>
ffffffffc0200316:	e79ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    }
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200326:	ef1ff0ef          	jal	ra,ffffffffc0200216 <print_kerninfo>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200332:	1141                	addi	sp,sp,-16
ffffffffc0200334:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200336:	f71ff0ef          	jal	ra,ffffffffc02002a6 <print_stackframe>
    return 0;
}
ffffffffc020033a:	60a2                	ld	ra,8(sp)
ffffffffc020033c:	4501                	li	a0,0
ffffffffc020033e:	0141                	addi	sp,sp,16
ffffffffc0200340:	8082                	ret

ffffffffc0200342 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200342:	7115                	addi	sp,sp,-224
ffffffffc0200344:	e962                	sd	s8,144(sp)
ffffffffc0200346:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200348:	00006517          	auipc	a0,0x6
ffffffffc020034c:	45850513          	addi	a0,a0,1112 # ffffffffc02067a0 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200350:	ed86                	sd	ra,216(sp)
ffffffffc0200352:	e9a2                	sd	s0,208(sp)
ffffffffc0200354:	e5a6                	sd	s1,200(sp)
ffffffffc0200356:	e1ca                	sd	s2,192(sp)
ffffffffc0200358:	fd4e                	sd	s3,184(sp)
ffffffffc020035a:	f952                	sd	s4,176(sp)
ffffffffc020035c:	f556                	sd	s5,168(sp)
ffffffffc020035e:	f15a                	sd	s6,160(sp)
ffffffffc0200360:	ed5e                	sd	s7,152(sp)
ffffffffc0200362:	e566                	sd	s9,136(sp)
ffffffffc0200364:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200366:	e29ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036a:	00006517          	auipc	a0,0x6
ffffffffc020036e:	45e50513          	addi	a0,a0,1118 # ffffffffc02067c8 <commands+0x70>
ffffffffc0200372:	e1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    if (tf != NULL) {
ffffffffc0200376:	000c0563          	beqz	s8,ffffffffc0200380 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037a:	8562                	mv	a0,s8
ffffffffc020037c:	4ce000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc0200380:	00006c97          	auipc	s9,0x6
ffffffffc0200384:	3d8c8c93          	addi	s9,s9,984 # ffffffffc0206758 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200388:	00006997          	auipc	s3,0x6
ffffffffc020038c:	46898993          	addi	s3,s3,1128 # ffffffffc02067f0 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	46890913          	addi	s2,s2,1128 # ffffffffc02067f8 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200398:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	00006b17          	auipc	s6,0x6
ffffffffc020039e:	466b0b13          	addi	s6,s6,1126 # ffffffffc0206800 <commands+0xa8>
    if (argc == 0) {
ffffffffc02003a2:	00006a97          	auipc	s5,0x6
ffffffffc02003a6:	4b6a8a93          	addi	s5,s5,1206 # ffffffffc0206858 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003aa:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003ac:	854e                	mv	a0,s3
ffffffffc02003ae:	ce9ff0ef          	jal	ra,ffffffffc0200096 <readline>
ffffffffc02003b2:	842a                	mv	s0,a0
ffffffffc02003b4:	dd65                	beqz	a0,ffffffffc02003ac <kmonitor+0x6a>
ffffffffc02003b6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003ba:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	c999                	beqz	a1,ffffffffc02003d2 <kmonitor+0x90>
ffffffffc02003be:	854a                	mv	a0,s2
ffffffffc02003c0:	21e060ef          	jal	ra,ffffffffc02065de <strchr>
ffffffffc02003c4:	c925                	beqz	a0,ffffffffc0200434 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02003c6:	00144583          	lbu	a1,1(s0)
ffffffffc02003ca:	00040023          	sb	zero,0(s0)
ffffffffc02003ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d0:	f5fd                	bnez	a1,ffffffffc02003be <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02003d2:	dce9                	beqz	s1,ffffffffc02003ac <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d4:	6582                	ld	a1,0(sp)
ffffffffc02003d6:	00006d17          	auipc	s10,0x6
ffffffffc02003da:	382d0d13          	addi	s10,s10,898 # ffffffffc0206758 <commands>
    if (argc == 0) {
ffffffffc02003de:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e2:	0d61                	addi	s10,s10,24
ffffffffc02003e4:	1d0060ef          	jal	ra,ffffffffc02065b4 <strcmp>
ffffffffc02003e8:	c919                	beqz	a0,ffffffffc02003fe <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ea:	2405                	addiw	s0,s0,1
ffffffffc02003ec:	09740463          	beq	s0,s7,ffffffffc0200474 <kmonitor+0x132>
ffffffffc02003f0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f4:	6582                	ld	a1,0(sp)
ffffffffc02003f6:	0d61                	addi	s10,s10,24
ffffffffc02003f8:	1bc060ef          	jal	ra,ffffffffc02065b4 <strcmp>
ffffffffc02003fc:	f57d                	bnez	a0,ffffffffc02003ea <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003fe:	00141793          	slli	a5,s0,0x1
ffffffffc0200402:	97a2                	add	a5,a5,s0
ffffffffc0200404:	078e                	slli	a5,a5,0x3
ffffffffc0200406:	97e6                	add	a5,a5,s9
ffffffffc0200408:	6b9c                	ld	a5,16(a5)
ffffffffc020040a:	8662                	mv	a2,s8
ffffffffc020040c:	002c                	addi	a1,sp,8
ffffffffc020040e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200412:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200414:	f8055ce3          	bgez	a0,ffffffffc02003ac <kmonitor+0x6a>
}
ffffffffc0200418:	60ee                	ld	ra,216(sp)
ffffffffc020041a:	644e                	ld	s0,208(sp)
ffffffffc020041c:	64ae                	ld	s1,200(sp)
ffffffffc020041e:	690e                	ld	s2,192(sp)
ffffffffc0200420:	79ea                	ld	s3,184(sp)
ffffffffc0200422:	7a4a                	ld	s4,176(sp)
ffffffffc0200424:	7aaa                	ld	s5,168(sp)
ffffffffc0200426:	7b0a                	ld	s6,160(sp)
ffffffffc0200428:	6bea                	ld	s7,152(sp)
ffffffffc020042a:	6c4a                	ld	s8,144(sp)
ffffffffc020042c:	6caa                	ld	s9,136(sp)
ffffffffc020042e:	6d0a                	ld	s10,128(sp)
ffffffffc0200430:	612d                	addi	sp,sp,224
ffffffffc0200432:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200434:	00044783          	lbu	a5,0(s0)
ffffffffc0200438:	dfc9                	beqz	a5,ffffffffc02003d2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020043a:	03448863          	beq	s1,s4,ffffffffc020046a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020043e:	00349793          	slli	a5,s1,0x3
ffffffffc0200442:	0118                	addi	a4,sp,128
ffffffffc0200444:	97ba                	add	a5,a5,a4
ffffffffc0200446:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020044e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200450:	e591                	bnez	a1,ffffffffc020045c <kmonitor+0x11a>
ffffffffc0200452:	b749                	j	ffffffffc02003d4 <kmonitor+0x92>
            buf ++;
ffffffffc0200454:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
ffffffffc020045a:	ddad                	beqz	a1,ffffffffc02003d4 <kmonitor+0x92>
ffffffffc020045c:	854a                	mv	a0,s2
ffffffffc020045e:	180060ef          	jal	ra,ffffffffc02065de <strchr>
ffffffffc0200462:	d96d                	beqz	a0,ffffffffc0200454 <kmonitor+0x112>
ffffffffc0200464:	00044583          	lbu	a1,0(s0)
ffffffffc0200468:	bf91                	j	ffffffffc02003bc <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020046a:	45c1                	li	a1,16
ffffffffc020046c:	855a                	mv	a0,s6
ffffffffc020046e:	d21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0200472:	b7f1                	j	ffffffffc020043e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200474:	6582                	ld	a1,0(sp)
ffffffffc0200476:	00006517          	auipc	a0,0x6
ffffffffc020047a:	3aa50513          	addi	a0,a0,938 # ffffffffc0206820 <commands+0xc8>
ffffffffc020047e:	d11ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
ffffffffc0200482:	b72d                	j	ffffffffc02003ac <kmonitor+0x6a>

ffffffffc0200484 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200484:	000ac317          	auipc	t1,0xac
ffffffffc0200488:	fd430313          	addi	t1,t1,-44 # ffffffffc02ac458 <is_panic>
ffffffffc020048c:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200490:	715d                	addi	sp,sp,-80
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e822                	sd	s0,16(sp)
ffffffffc0200496:	f436                	sd	a3,40(sp)
ffffffffc0200498:	f83a                	sd	a4,48(sp)
ffffffffc020049a:	fc3e                	sd	a5,56(sp)
ffffffffc020049c:	e0c2                	sd	a6,64(sp)
ffffffffc020049e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004a0:	02031c63          	bnez	t1,ffffffffc02004d8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004a4:	4785                	li	a5,1
ffffffffc02004a6:	8432                	mv	s0,a2
ffffffffc02004a8:	000ac717          	auipc	a4,0xac
ffffffffc02004ac:	faf73823          	sd	a5,-80(a4) # ffffffffc02ac458 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02004b2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b4:	85aa                	mv	a1,a0
ffffffffc02004b6:	00006517          	auipc	a0,0x6
ffffffffc02004ba:	42250513          	addi	a0,a0,1058 # ffffffffc02068d8 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02004be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c0:	ccfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004c4:	65a2                	ld	a1,8(sp)
ffffffffc02004c6:	8522                	mv	a0,s0
ffffffffc02004c8:	ca7ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc02004cc:	00007517          	auipc	a0,0x7
ffffffffc02004d0:	3c450513          	addi	a0,a0,964 # ffffffffc0207890 <default_pmm_manager+0x530>
ffffffffc02004d4:	cbbff0ef          	jal	ra,ffffffffc020018e <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	4581                	li	a1,0
ffffffffc02004dc:	4601                	li	a2,0
ffffffffc02004de:	48a1                	li	a7,8
ffffffffc02004e0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004e4:	176000ef          	jal	ra,ffffffffc020065a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004e8:	4501                	li	a0,0
ffffffffc02004ea:	e59ff0ef          	jal	ra,ffffffffc0200342 <kmonitor>
ffffffffc02004ee:	bfed                	j	ffffffffc02004e8 <__panic+0x64>

ffffffffc02004f0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f0:	715d                	addi	sp,sp,-80
ffffffffc02004f2:	e822                	sd	s0,16(sp)
ffffffffc02004f4:	fc3e                	sd	a5,56(sp)
ffffffffc02004f6:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004f8:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fa:	862e                	mv	a2,a1
ffffffffc02004fc:	85aa                	mv	a1,a0
ffffffffc02004fe:	00006517          	auipc	a0,0x6
ffffffffc0200502:	3fa50513          	addi	a0,a0,1018 # ffffffffc02068f8 <commands+0x1a0>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200506:	ec06                	sd	ra,24(sp)
ffffffffc0200508:	f436                	sd	a3,40(sp)
ffffffffc020050a:	f83a                	sd	a4,48(sp)
ffffffffc020050c:	e0c2                	sd	a6,64(sp)
ffffffffc020050e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200510:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200512:	c7dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200516:	65a2                	ld	a1,8(sp)
ffffffffc0200518:	8522                	mv	a0,s0
ffffffffc020051a:	c55ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc020051e:	00007517          	auipc	a0,0x7
ffffffffc0200522:	37250513          	addi	a0,a0,882 # ffffffffc0207890 <default_pmm_manager+0x530>
ffffffffc0200526:	c69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    va_end(ap);
}
ffffffffc020052a:	60e2                	ld	ra,24(sp)
ffffffffc020052c:	6442                	ld	s0,16(sp)
ffffffffc020052e:	6161                	addi	sp,sp,80
ffffffffc0200530:	8082                	ret

ffffffffc0200532 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200532:	67e1                	lui	a5,0x18
ffffffffc0200534:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc20>
ffffffffc0200538:	000ac717          	auipc	a4,0xac
ffffffffc020053c:	f2f73423          	sd	a5,-216(a4) # ffffffffc02ac460 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200540:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200544:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200546:	953e                	add	a0,a0,a5
ffffffffc0200548:	4601                	li	a2,0
ffffffffc020054a:	4881                	li	a7,0
ffffffffc020054c:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200550:	02000793          	li	a5,32
ffffffffc0200554:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200558:	00006517          	auipc	a0,0x6
ffffffffc020055c:	3c050513          	addi	a0,a0,960 # ffffffffc0206918 <commands+0x1c0>
    ticks = 0;
ffffffffc0200560:	000ac797          	auipc	a5,0xac
ffffffffc0200564:	f407b823          	sd	zero,-176(a5) # ffffffffc02ac4b0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200568:	c27ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020056c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200570:	000ac797          	auipc	a5,0xac
ffffffffc0200574:	ef078793          	addi	a5,a5,-272 # ffffffffc02ac460 <timebase>
ffffffffc0200578:	639c                	ld	a5,0(a5)
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4881                	li	a7,0
ffffffffc0200582:	00000073          	ecall
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200588:	8082                	ret

ffffffffc020058a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020058a:	100027f3          	csrr	a5,sstatus
ffffffffc020058e:	8b89                	andi	a5,a5,2
ffffffffc0200590:	0ff57513          	andi	a0,a0,255
ffffffffc0200594:	e799                	bnez	a5,ffffffffc02005a2 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200596:	4581                	li	a1,0
ffffffffc0200598:	4601                	li	a2,0
ffffffffc020059a:	4885                	li	a7,1
ffffffffc020059c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005a0:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a2:	1101                	addi	sp,sp,-32
ffffffffc02005a4:	ec06                	sd	ra,24(sp)
ffffffffc02005a6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a8:	0b2000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	4581                	li	a1,0
ffffffffc02005b0:	4601                	li	a2,0
ffffffffc02005b2:	4885                	li	a7,1
ffffffffc02005b4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b8:	60e2                	ld	ra,24(sp)
ffffffffc02005ba:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005bc:	0980006f          	j	ffffffffc0200654 <intr_enable>

ffffffffc02005c0 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005c0:	100027f3          	csrr	a5,sstatus
ffffffffc02005c4:	8b89                	andi	a5,a5,2
ffffffffc02005c6:	eb89                	bnez	a5,ffffffffc02005d8 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c8:	4501                	li	a0,0
ffffffffc02005ca:	4581                	li	a1,0
ffffffffc02005cc:	4601                	li	a2,0
ffffffffc02005ce:	4889                	li	a7,2
ffffffffc02005d0:	00000073          	ecall
ffffffffc02005d4:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d6:	8082                	ret
int cons_getc(void) {
ffffffffc02005d8:	1101                	addi	sp,sp,-32
ffffffffc02005da:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005dc:	07e000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005e0:	4501                	li	a0,0
ffffffffc02005e2:	4581                	li	a1,0
ffffffffc02005e4:	4601                	li	a2,0
ffffffffc02005e6:	4889                	li	a7,2
ffffffffc02005e8:	00000073          	ecall
ffffffffc02005ec:	2501                	sext.w	a0,a0
ffffffffc02005ee:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f0:	064000ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc02005f4:	60e2                	ld	ra,24(sp)
ffffffffc02005f6:	6522                	ld	a0,8(sp)
ffffffffc02005f8:	6105                	addi	sp,sp,32
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005fe:	00253513          	sltiu	a0,a0,2
ffffffffc0200602:	8082                	ret

ffffffffc0200604 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200604:	03800513          	li	a0,56
ffffffffc0200608:	8082                	ret

ffffffffc020060a <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020060a:	000a1797          	auipc	a5,0xa1
ffffffffc020060e:	e4e78793          	addi	a5,a5,-434 # ffffffffc02a1458 <ide>
ffffffffc0200612:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200616:	1141                	addi	sp,sp,-16
ffffffffc0200618:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020061a:	95be                	add	a1,a1,a5
ffffffffc020061c:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200620:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200622:	7ed050ef          	jal	ra,ffffffffc020660e <memcpy>
    return 0;
}
ffffffffc0200626:	60a2                	ld	ra,8(sp)
ffffffffc0200628:	4501                	li	a0,0
ffffffffc020062a:	0141                	addi	sp,sp,16
ffffffffc020062c:	8082                	ret

ffffffffc020062e <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc020062e:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200630:	0095979b          	slliw	a5,a1,0x9
ffffffffc0200634:	000a1517          	auipc	a0,0xa1
ffffffffc0200638:	e2450513          	addi	a0,a0,-476 # ffffffffc02a1458 <ide>
                   size_t nsecs) {
ffffffffc020063c:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020063e:	00969613          	slli	a2,a3,0x9
ffffffffc0200642:	85ba                	mv	a1,a4
ffffffffc0200644:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc0200646:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200648:	7c7050ef          	jal	ra,ffffffffc020660e <memcpy>
    return 0;
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	4501                	li	a0,0
ffffffffc0200650:	0141                	addi	sp,sp,16
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200654:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200658:	8082                	ret

ffffffffc020065a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020065e:	8082                	ret

ffffffffc0200660 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	67a78793          	addi	a5,a5,1658 # ffffffffc0200ce0 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	5dc50513          	addi	a0,a0,1500 # ffffffffc0206c60 <commands+0x508>
void print_regs(struct pushregs* gpr) {
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	b01ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	5e450513          	addi	a0,a0,1508 # ffffffffc0206c78 <commands+0x520>
ffffffffc020069c:	af3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206c90 <commands+0x538>
ffffffffc02006aa:	ae5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	5f850513          	addi	a0,a0,1528 # ffffffffc0206ca8 <commands+0x550>
ffffffffc02006b8:	ad7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	60250513          	addi	a0,a0,1538 # ffffffffc0206cc0 <commands+0x568>
ffffffffc02006c6:	ac9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	60c50513          	addi	a0,a0,1548 # ffffffffc0206cd8 <commands+0x580>
ffffffffc02006d4:	abbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	61650513          	addi	a0,a0,1558 # ffffffffc0206cf0 <commands+0x598>
ffffffffc02006e2:	aadff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	62050513          	addi	a0,a0,1568 # ffffffffc0206d08 <commands+0x5b0>
ffffffffc02006f0:	a9fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	62a50513          	addi	a0,a0,1578 # ffffffffc0206d20 <commands+0x5c8>
ffffffffc02006fe:	a91ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	63450513          	addi	a0,a0,1588 # ffffffffc0206d38 <commands+0x5e0>
ffffffffc020070c:	a83ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	63e50513          	addi	a0,a0,1598 # ffffffffc0206d50 <commands+0x5f8>
ffffffffc020071a:	a75ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	64850513          	addi	a0,a0,1608 # ffffffffc0206d68 <commands+0x610>
ffffffffc0200728:	a67ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	65250513          	addi	a0,a0,1618 # ffffffffc0206d80 <commands+0x628>
ffffffffc0200736:	a59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	65c50513          	addi	a0,a0,1628 # ffffffffc0206d98 <commands+0x640>
ffffffffc0200744:	a4bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	66650513          	addi	a0,a0,1638 # ffffffffc0206db0 <commands+0x658>
ffffffffc0200752:	a3dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	67050513          	addi	a0,a0,1648 # ffffffffc0206dc8 <commands+0x670>
ffffffffc0200760:	a2fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	67a50513          	addi	a0,a0,1658 # ffffffffc0206de0 <commands+0x688>
ffffffffc020076e:	a21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	68450513          	addi	a0,a0,1668 # ffffffffc0206df8 <commands+0x6a0>
ffffffffc020077c:	a13ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	68e50513          	addi	a0,a0,1678 # ffffffffc0206e10 <commands+0x6b8>
ffffffffc020078a:	a05ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	69850513          	addi	a0,a0,1688 # ffffffffc0206e28 <commands+0x6d0>
ffffffffc0200798:	9f7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	6a250513          	addi	a0,a0,1698 # ffffffffc0206e40 <commands+0x6e8>
ffffffffc02007a6:	9e9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0206e58 <commands+0x700>
ffffffffc02007b4:	9dbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	6b650513          	addi	a0,a0,1718 # ffffffffc0206e70 <commands+0x718>
ffffffffc02007c2:	9cdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	6c050513          	addi	a0,a0,1728 # ffffffffc0206e88 <commands+0x730>
ffffffffc02007d0:	9bfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00006517          	auipc	a0,0x6
ffffffffc02007da:	6ca50513          	addi	a0,a0,1738 # ffffffffc0206ea0 <commands+0x748>
ffffffffc02007de:	9b1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00006517          	auipc	a0,0x6
ffffffffc02007e8:	6d450513          	addi	a0,a0,1748 # ffffffffc0206eb8 <commands+0x760>
ffffffffc02007ec:	9a3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00006517          	auipc	a0,0x6
ffffffffc02007f6:	6de50513          	addi	a0,a0,1758 # ffffffffc0206ed0 <commands+0x778>
ffffffffc02007fa:	995ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00006517          	auipc	a0,0x6
ffffffffc0200804:	6e850513          	addi	a0,a0,1768 # ffffffffc0206ee8 <commands+0x790>
ffffffffc0200808:	987ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00006517          	auipc	a0,0x6
ffffffffc0200812:	6f250513          	addi	a0,a0,1778 # ffffffffc0206f00 <commands+0x7a8>
ffffffffc0200816:	979ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	6fc50513          	addi	a0,a0,1788 # ffffffffc0206f18 <commands+0x7c0>
ffffffffc0200824:	96bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00006517          	auipc	a0,0x6
ffffffffc020082e:	70650513          	addi	a0,a0,1798 # ffffffffc0206f30 <commands+0x7d8>
ffffffffc0200832:	95dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	70c50513          	addi	a0,a0,1804 # ffffffffc0206f48 <commands+0x7f0>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	949ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020084a <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00006517          	auipc	a0,0x6
ffffffffc0200856:	70e50513          	addi	a0,a0,1806 # ffffffffc0206f60 <commands+0x808>
print_trapframe(struct trapframe *tf) {
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	933ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00006517          	auipc	a0,0x6
ffffffffc020086e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206f78 <commands+0x820>
ffffffffc0200872:	91dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00006517          	auipc	a0,0x6
ffffffffc020087e:	71650513          	addi	a0,a0,1814 # ffffffffc0206f90 <commands+0x838>
ffffffffc0200882:	90dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	71e50513          	addi	a0,a0,1822 # ffffffffc0206fa8 <commands+0x850>
ffffffffc0200892:	8fdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00006517          	auipc	a0,0x6
ffffffffc02008a2:	71a50513          	addi	a0,a0,1818 # ffffffffc0206fb8 <commands+0x860>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	8e7ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02008ac <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008b0:	000ac497          	auipc	s1,0xac
ffffffffc02008b4:	d1848493          	addi	s1,s1,-744 # ffffffffc02ac5c8 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	2fa50513          	addi	a0,a0,762 # ffffffffc0206be0 <commands+0x488>
ffffffffc02008ee:	8a1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
        assert(current == idleproc);
ffffffffc02008f6:	000ac797          	auipc	a5,0xac
ffffffffc02008fa:	b9a78793          	addi	a5,a5,-1126 # ffffffffc02ac490 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000ac797          	auipc	a5,0xac
ffffffffc0200904:	b9878793          	addi	a5,a5,-1128 # ffffffffc02ac498 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	08a0406f          	j	ffffffffc02049a8 <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc0200936:	000ac797          	auipc	a5,0xac
ffffffffc020093a:	b5a78793          	addi	a5,a5,-1190 # ffffffffc02ac490 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	0540406f          	j	ffffffffc02049a8 <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	2a868693          	addi	a3,a3,680 # ffffffffc0206c00 <commands+0x4a8>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	2b860613          	addi	a2,a2,696 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0200968:	06b00593          	li	a1,107
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	2c450513          	addi	a0,a0,708 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200974:	b11ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	23e50513          	addi	a0,a0,574 # ffffffffc0206be0 <commands+0x488>
ffffffffc02009aa:	fe4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	29a60613          	addi	a2,a2,666 # ffffffffc0206c48 <commands+0x4f0>
ffffffffc02009b6:	07200593          	li	a1,114
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	27650513          	addi	a0,a0,630 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc02009c2:	ac3ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	f5870713          	addi	a4,a4,-168 # ffffffffc0206934 <commands+0x1dc>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	1b250513          	addi	a0,a0,434 # ffffffffc0206ba0 <commands+0x448>
ffffffffc02009f6:	f98ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	18650513          	addi	a0,a0,390 # ffffffffc0206b80 <commands+0x428>
ffffffffc0200a02:	f8cff06f          	j	ffffffffc020018e <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	13a50513          	addi	a0,a0,314 # ffffffffc0206b40 <commands+0x3e8>
ffffffffc0200a0e:	f80ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	14e50513          	addi	a0,a0,334 # ffffffffc0206b60 <commands+0x408>
ffffffffc0200a1a:	f74ff06f          	j	ffffffffc020018e <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	1a250513          	addi	a0,a0,418 # ffffffffc0206bc0 <commands+0x468>
ffffffffc0200a26:	f68ff06f          	j	ffffffffc020018e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200a2e:	b3fff0ef          	jal	ra,ffffffffc020056c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a32:	000ac797          	auipc	a5,0xac
ffffffffc0200a36:	a7e78793          	addi	a5,a5,-1410 # ffffffffc02ac4b0 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000ac697          	auipc	a3,0xac
ffffffffc0200a4a:	a6f6b523          	sd	a5,-1430(a3) # ffffffffc02ac4b0 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000ac797          	auipc	a5,0xac
ffffffffc0200a54:	a4078793          	addi	a5,a5,-1472 # ffffffffc02ac490 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1af76e63          	bltu	a4,a5,ffffffffc0200c2c <exception_handler+0x1c2>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	ef070713          	addi	a4,a4,-272 # ffffffffc0206964 <commands+0x20c>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	00850513          	addi	a0,a0,8 # ffffffffc0206a98 <commands+0x340>
ffffffffc0200a98:	ef6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            tf->epc += 4;
ffffffffc0200a9c:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa0:	60e2                	ld	ra,24(sp)
ffffffffc0200aa2:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200aa4:	0791                	addi	a5,a5,4
ffffffffc0200aa6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200aae:	6200506f          	j	ffffffffc02060ce <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	00650513          	addi	a0,a0,6 # ffffffffc0206ab8 <commands+0x360>
}
ffffffffc0200aba:	6442                	ld	s0,16(sp)
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	64a2                	ld	s1,8(sp)
ffffffffc0200ac0:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200ac2:	eccff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200ac6:	00006517          	auipc	a0,0x6
ffffffffc0200aca:	01250513          	addi	a0,a0,18 # ffffffffc0206ad8 <commands+0x380>
ffffffffc0200ace:	b7f5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200ad0:	00006517          	auipc	a0,0x6
ffffffffc0200ad4:	02850513          	addi	a0,a0,40 # ffffffffc0206af8 <commands+0x3a0>
ffffffffc0200ad8:	b7cd                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ada:	00006517          	auipc	a0,0x6
ffffffffc0200ade:	03650513          	addi	a0,a0,54 # ffffffffc0206b10 <commands+0x3b8>
ffffffffc0200ae2:	eacff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae6:	8522                	mv	a0,s0
ffffffffc0200ae8:	dc5ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200aec:	84aa                	mv	s1,a0
ffffffffc0200aee:	14051163          	bnez	a0,ffffffffc0200c30 <exception_handler+0x1c6>
}
ffffffffc0200af2:	60e2                	ld	ra,24(sp)
ffffffffc0200af4:	6442                	ld	s0,16(sp)
ffffffffc0200af6:	64a2                	ld	s1,8(sp)
ffffffffc0200af8:	6105                	addi	sp,sp,32
ffffffffc0200afa:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200afc:	00006517          	auipc	a0,0x6
ffffffffc0200b00:	02c50513          	addi	a0,a0,44 # ffffffffc0206b28 <commands+0x3d0>
ffffffffc0200b04:	e8aff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	da3ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b0e:	84aa                	mv	s1,a0
ffffffffc0200b10:	d16d                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b12:	8522                	mv	a0,s0
ffffffffc0200b14:	d37ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b18:	86a6                	mv	a3,s1
ffffffffc0200b1a:	00006617          	auipc	a2,0x6
ffffffffc0200b1e:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206a48 <commands+0x2f0>
ffffffffc0200b22:	0f800593          	li	a1,248
ffffffffc0200b26:	00006517          	auipc	a0,0x6
ffffffffc0200b2a:	10a50513          	addi	a0,a0,266 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200b2e:	957ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b32:	00006517          	auipc	a0,0x6
ffffffffc0200b36:	e7650513          	addi	a0,a0,-394 # ffffffffc02069a8 <commands+0x250>
ffffffffc0200b3a:	b741                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b3c:	00006517          	auipc	a0,0x6
ffffffffc0200b40:	e8c50513          	addi	a0,a0,-372 # ffffffffc02069c8 <commands+0x270>
ffffffffc0200b44:	bf9d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	ea250513          	addi	a0,a0,-350 # ffffffffc02069e8 <commands+0x290>
ffffffffc0200b4e:	b7b5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b50:	00006517          	auipc	a0,0x6
ffffffffc0200b54:	eb050513          	addi	a0,a0,-336 # ffffffffc0206a00 <commands+0x2a8>
ffffffffc0200b58:	e36ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b5c:	6458                	ld	a4,136(s0)
ffffffffc0200b5e:	47a9                	li	a5,10
ffffffffc0200b60:	f8f719e3          	bne	a4,a5,ffffffffc0200af2 <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b64:	10843783          	ld	a5,264(s0)
ffffffffc0200b68:	0791                	addi	a5,a5,4
ffffffffc0200b6a:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b6e:	560050ef          	jal	ra,ffffffffc02060ce <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b72:	000ac797          	auipc	a5,0xac
ffffffffc0200b76:	91e78793          	addi	a5,a5,-1762 # ffffffffc02ac490 <current>
ffffffffc0200b7a:	639c                	ld	a5,0(a5)
ffffffffc0200b7c:	8522                	mv	a0,s0
}
ffffffffc0200b7e:	6442                	ld	s0,16(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b80:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200b82:	60e2                	ld	ra,24(sp)
ffffffffc0200b84:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b86:	6589                	lui	a1,0x2
ffffffffc0200b88:	95be                	add	a1,a1,a5
}
ffffffffc0200b8a:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b8c:	2220006f          	j	ffffffffc0200dae <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	e8050513          	addi	a0,a0,-384 # ffffffffc0206a10 <commands+0x2b8>
ffffffffc0200b98:	b70d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	e9650513          	addi	a0,a0,-362 # ffffffffc0206a30 <commands+0x2d8>
ffffffffc0200ba2:	decff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	d05ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200bac:	84aa                	mv	s1,a0
ffffffffc0200bae:	d131                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bb0:	8522                	mv	a0,s0
ffffffffc0200bb2:	c99ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bb6:	86a6                	mv	a3,s1
ffffffffc0200bb8:	00006617          	auipc	a2,0x6
ffffffffc0200bbc:	e9060613          	addi	a2,a2,-368 # ffffffffc0206a48 <commands+0x2f0>
ffffffffc0200bc0:	0cd00593          	li	a1,205
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	06c50513          	addi	a0,a0,108 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200bcc:	8b9ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	eb050513          	addi	a0,a0,-336 # ffffffffc0206a80 <commands+0x328>
ffffffffc0200bd8:	db6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	ccfff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200be2:	84aa                	mv	s1,a0
ffffffffc0200be4:	f00507e3          	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200be8:	8522                	mv	a0,s0
ffffffffc0200bea:	c61ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bee:	86a6                	mv	a3,s1
ffffffffc0200bf0:	00006617          	auipc	a2,0x6
ffffffffc0200bf4:	e5860613          	addi	a2,a2,-424 # ffffffffc0206a48 <commands+0x2f0>
ffffffffc0200bf8:	0d700593          	li	a1,215
ffffffffc0200bfc:	00006517          	auipc	a0,0x6
ffffffffc0200c00:	03450513          	addi	a0,a0,52 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200c04:	881ff0ef          	jal	ra,ffffffffc0200484 <__panic>
}
ffffffffc0200c08:	6442                	ld	s0,16(sp)
ffffffffc0200c0a:	60e2                	ld	ra,24(sp)
ffffffffc0200c0c:	64a2                	ld	s1,8(sp)
ffffffffc0200c0e:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c10:	c3bff06f          	j	ffffffffc020084a <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200c14:	00006617          	auipc	a2,0x6
ffffffffc0200c18:	e5460613          	addi	a2,a2,-428 # ffffffffc0206a68 <commands+0x310>
ffffffffc0200c1c:	0d100593          	li	a1,209
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	01050513          	addi	a0,a0,16 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200c28:	85dff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200c2c:	c1fff06f          	j	ffffffffc020084a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200c30:	8522                	mv	a0,s0
ffffffffc0200c32:	c19ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c36:	86a6                	mv	a3,s1
ffffffffc0200c38:	00006617          	auipc	a2,0x6
ffffffffc0200c3c:	e1060613          	addi	a2,a2,-496 # ffffffffc0206a48 <commands+0x2f0>
ffffffffc0200c40:	0f100593          	li	a1,241
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	fec50513          	addi	a0,a0,-20 # ffffffffc0206c30 <commands+0x4d8>
ffffffffc0200c4c:	839ff0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0200c50 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c50:	1101                	addi	sp,sp,-32
ffffffffc0200c52:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c54:	000ac417          	auipc	s0,0xac
ffffffffc0200c58:	83c40413          	addi	s0,s0,-1988 # ffffffffc02ac490 <current>
ffffffffc0200c5c:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c5e:	ec06                	sd	ra,24(sp)
ffffffffc0200c60:	e426                	sd	s1,8(sp)
ffffffffc0200c62:	e04a                	sd	s2,0(sp)
ffffffffc0200c64:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c68:	cf1d                	beqz	a4,ffffffffc0200ca6 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c6a:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c6e:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c72:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c74:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0206c463          	bltz	a3,ffffffffc0200ca0 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c7c:	defff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c80:	601c                	ld	a5,0(s0)
ffffffffc0200c82:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c86:	e499                	bnez	s1,ffffffffc0200c94 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c88:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c8c:	8b05                	andi	a4,a4,1
ffffffffc0200c8e:	e339                	bnez	a4,ffffffffc0200cd4 <trap+0x84>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c90:	6f9c                	ld	a5,24(a5)
ffffffffc0200c92:	eb95                	bnez	a5,ffffffffc0200cc6 <trap+0x76>
                schedule();
            }
        }
    }
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
ffffffffc0200c96:	6442                	ld	s0,16(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
ffffffffc0200c9e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ca0:	d2dff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200ca4:	bff1                	j	ffffffffc0200c80 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ca6:	0006c963          	bltz	a3,ffffffffc0200cb8 <trap+0x68>
}
ffffffffc0200caa:	6442                	ld	s0,16(sp)
ffffffffc0200cac:	60e2                	ld	ra,24(sp)
ffffffffc0200cae:	64a2                	ld	s1,8(sp)
ffffffffc0200cb0:	6902                	ld	s2,0(sp)
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cb4:	db7ff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cb8:	6442                	ld	s0,16(sp)
ffffffffc0200cba:	60e2                	ld	ra,24(sp)
ffffffffc0200cbc:	64a2                	ld	s1,8(sp)
ffffffffc0200cbe:	6902                	ld	s2,0(sp)
ffffffffc0200cc0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cc2:	d0bff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200cc6:	6442                	ld	s0,16(sp)
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
ffffffffc0200cca:	64a2                	ld	s1,8(sp)
ffffffffc0200ccc:	6902                	ld	s2,0(sp)
ffffffffc0200cce:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cd0:	3080506f          	j	ffffffffc0205fd8 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200cd4:	555d                	li	a0,-9
ffffffffc0200cd6:	700040ef          	jal	ra,ffffffffc02053d6 <do_exit>
ffffffffc0200cda:	601c                	ld	a5,0(s0)
ffffffffc0200cdc:	bf55                	j	ffffffffc0200c90 <trap+0x40>
	...

ffffffffc0200ce0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ce0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ce4:	00011463          	bnez	sp,ffffffffc0200cec <__alltraps+0xc>
ffffffffc0200ce8:	14002173          	csrr	sp,sscratch
ffffffffc0200cec:	712d                	addi	sp,sp,-288
ffffffffc0200cee:	e002                	sd	zero,0(sp)
ffffffffc0200cf0:	e406                	sd	ra,8(sp)
ffffffffc0200cf2:	ec0e                	sd	gp,24(sp)
ffffffffc0200cf4:	f012                	sd	tp,32(sp)
ffffffffc0200cf6:	f416                	sd	t0,40(sp)
ffffffffc0200cf8:	f81a                	sd	t1,48(sp)
ffffffffc0200cfa:	fc1e                	sd	t2,56(sp)
ffffffffc0200cfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200cfe:	e4a6                	sd	s1,72(sp)
ffffffffc0200d00:	e8aa                	sd	a0,80(sp)
ffffffffc0200d02:	ecae                	sd	a1,88(sp)
ffffffffc0200d04:	f0b2                	sd	a2,96(sp)
ffffffffc0200d06:	f4b6                	sd	a3,104(sp)
ffffffffc0200d08:	f8ba                	sd	a4,112(sp)
ffffffffc0200d0a:	fcbe                	sd	a5,120(sp)
ffffffffc0200d0c:	e142                	sd	a6,128(sp)
ffffffffc0200d0e:	e546                	sd	a7,136(sp)
ffffffffc0200d10:	e94a                	sd	s2,144(sp)
ffffffffc0200d12:	ed4e                	sd	s3,152(sp)
ffffffffc0200d14:	f152                	sd	s4,160(sp)
ffffffffc0200d16:	f556                	sd	s5,168(sp)
ffffffffc0200d18:	f95a                	sd	s6,176(sp)
ffffffffc0200d1a:	fd5e                	sd	s7,184(sp)
ffffffffc0200d1c:	e1e2                	sd	s8,192(sp)
ffffffffc0200d1e:	e5e6                	sd	s9,200(sp)
ffffffffc0200d20:	e9ea                	sd	s10,208(sp)
ffffffffc0200d22:	edee                	sd	s11,216(sp)
ffffffffc0200d24:	f1f2                	sd	t3,224(sp)
ffffffffc0200d26:	f5f6                	sd	t4,232(sp)
ffffffffc0200d28:	f9fa                	sd	t5,240(sp)
ffffffffc0200d2a:	fdfe                	sd	t6,248(sp)
ffffffffc0200d2c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d30:	100024f3          	csrr	s1,sstatus
ffffffffc0200d34:	14102973          	csrr	s2,sepc
ffffffffc0200d38:	143029f3          	csrr	s3,stval
ffffffffc0200d3c:	14202a73          	csrr	s4,scause
ffffffffc0200d40:	e822                	sd	s0,16(sp)
ffffffffc0200d42:	e226                	sd	s1,256(sp)
ffffffffc0200d44:	e64a                	sd	s2,264(sp)
ffffffffc0200d46:	ea4e                	sd	s3,272(sp)
ffffffffc0200d48:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d4a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d4c:	f05ff0ef          	jal	ra,ffffffffc0200c50 <trap>

ffffffffc0200d50 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d50:	6492                	ld	s1,256(sp)
ffffffffc0200d52:	6932                	ld	s2,264(sp)
ffffffffc0200d54:	1004f413          	andi	s0,s1,256
ffffffffc0200d58:	e401                	bnez	s0,ffffffffc0200d60 <__trapret+0x10>
ffffffffc0200d5a:	1200                	addi	s0,sp,288
ffffffffc0200d5c:	14041073          	csrw	sscratch,s0
ffffffffc0200d60:	10049073          	csrw	sstatus,s1
ffffffffc0200d64:	14191073          	csrw	sepc,s2
ffffffffc0200d68:	60a2                	ld	ra,8(sp)
ffffffffc0200d6a:	61e2                	ld	gp,24(sp)
ffffffffc0200d6c:	7202                	ld	tp,32(sp)
ffffffffc0200d6e:	72a2                	ld	t0,40(sp)
ffffffffc0200d70:	7342                	ld	t1,48(sp)
ffffffffc0200d72:	73e2                	ld	t2,56(sp)
ffffffffc0200d74:	6406                	ld	s0,64(sp)
ffffffffc0200d76:	64a6                	ld	s1,72(sp)
ffffffffc0200d78:	6546                	ld	a0,80(sp)
ffffffffc0200d7a:	65e6                	ld	a1,88(sp)
ffffffffc0200d7c:	7606                	ld	a2,96(sp)
ffffffffc0200d7e:	76a6                	ld	a3,104(sp)
ffffffffc0200d80:	7746                	ld	a4,112(sp)
ffffffffc0200d82:	77e6                	ld	a5,120(sp)
ffffffffc0200d84:	680a                	ld	a6,128(sp)
ffffffffc0200d86:	68aa                	ld	a7,136(sp)
ffffffffc0200d88:	694a                	ld	s2,144(sp)
ffffffffc0200d8a:	69ea                	ld	s3,152(sp)
ffffffffc0200d8c:	7a0a                	ld	s4,160(sp)
ffffffffc0200d8e:	7aaa                	ld	s5,168(sp)
ffffffffc0200d90:	7b4a                	ld	s6,176(sp)
ffffffffc0200d92:	7bea                	ld	s7,184(sp)
ffffffffc0200d94:	6c0e                	ld	s8,192(sp)
ffffffffc0200d96:	6cae                	ld	s9,200(sp)
ffffffffc0200d98:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9a:	6dee                	ld	s11,216(sp)
ffffffffc0200d9c:	7e0e                	ld	t3,224(sp)
ffffffffc0200d9e:	7eae                	ld	t4,232(sp)
ffffffffc0200da0:	7f4e                	ld	t5,240(sp)
ffffffffc0200da2:	7fee                	ld	t6,248(sp)
ffffffffc0200da4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200da6:	10200073          	sret

ffffffffc0200daa <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200daa:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dac:	b755                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200dae <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200dae:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200db2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200db6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200dba:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200dbe:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dc2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dc6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dca:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dce:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dd2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dd4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dd6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200dd8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dda:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ddc:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200dde:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200de0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200de2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200de4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200de6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200de8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200dea:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200dec:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dee:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200df0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200df2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200df4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200df6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200df8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dfa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dfc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dfe:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e00:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e02:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e04:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e06:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e08:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e0a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e0c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e0e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e10:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e12:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e14:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e16:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e18:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e1a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e1c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e1e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e20:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e22:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e24:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e26:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e28:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e2a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e2c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e2e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e30:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e32:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e34:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e36:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e38:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e3a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e3c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e3e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e40:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e42:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e44:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e46:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e48:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e4a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e4c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e4e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e50:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e52:	812e                	mv	sp,a1
ffffffffc0200e54:	bdf5                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200e56 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e56:	000ab797          	auipc	a5,0xab
ffffffffc0200e5a:	66278793          	addi	a5,a5,1634 # ffffffffc02ac4b8 <free_area>
ffffffffc0200e5e:	e79c                	sd	a5,8(a5)
ffffffffc0200e60:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e62:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e66:	8082                	ret

ffffffffc0200e68 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e68:	000ab517          	auipc	a0,0xab
ffffffffc0200e6c:	66056503          	lwu	a0,1632(a0) # ffffffffc02ac4c8 <free_area+0x10>
ffffffffc0200e70:	8082                	ret

ffffffffc0200e72 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e72:	715d                	addi	sp,sp,-80
ffffffffc0200e74:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e76:	000ab917          	auipc	s2,0xab
ffffffffc0200e7a:	64290913          	addi	s2,s2,1602 # ffffffffc02ac4b8 <free_area>
ffffffffc0200e7e:	00893783          	ld	a5,8(s2)
ffffffffc0200e82:	e486                	sd	ra,72(sp)
ffffffffc0200e84:	e0a2                	sd	s0,64(sp)
ffffffffc0200e86:	fc26                	sd	s1,56(sp)
ffffffffc0200e88:	f44e                	sd	s3,40(sp)
ffffffffc0200e8a:	f052                	sd	s4,32(sp)
ffffffffc0200e8c:	ec56                	sd	s5,24(sp)
ffffffffc0200e8e:	e85a                	sd	s6,16(sp)
ffffffffc0200e90:	e45e                	sd	s7,8(sp)
ffffffffc0200e92:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e94:	31278463          	beq	a5,s2,ffffffffc020119c <default_check+0x32a>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e98:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e9c:	8305                	srli	a4,a4,0x1
ffffffffc0200e9e:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ea0:	30070263          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0200ea4:	4401                	li	s0,0
ffffffffc0200ea6:	4481                	li	s1,0
ffffffffc0200ea8:	a031                	j	ffffffffc0200eb4 <default_check+0x42>
ffffffffc0200eaa:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200eae:	8b09                	andi	a4,a4,2
ffffffffc0200eb0:	2e070a63          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
        count ++, total += p->property;
ffffffffc0200eb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb8:	679c                	ld	a5,8(a5)
ffffffffc0200eba:	2485                	addiw	s1,s1,1
ffffffffc0200ebc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ebe:	ff2796e3          	bne	a5,s2,ffffffffc0200eaa <default_check+0x38>
ffffffffc0200ec2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200ec4:	05c010ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0200ec8:	73351e63          	bne	a0,s3,ffffffffc0201604 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ecc:	4505                	li	a0,1
ffffffffc0200ece:	785000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ed2:	8a2a                	mv	s4,a0
ffffffffc0200ed4:	46050863          	beqz	a0,ffffffffc0201344 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ed8:	4505                	li	a0,1
ffffffffc0200eda:	779000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ede:	89aa                	mv	s3,a0
ffffffffc0200ee0:	74050263          	beqz	a0,ffffffffc0201624 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ee4:	4505                	li	a0,1
ffffffffc0200ee6:	76d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200eea:	8aaa                	mv	s5,a0
ffffffffc0200eec:	4c050c63          	beqz	a0,ffffffffc02013c4 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ef0:	2d3a0a63          	beq	s4,s3,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef4:	2caa0863          	beq	s4,a0,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef8:	2ca98663          	beq	s3,a0,ffffffffc02011c4 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200efc:	000a2783          	lw	a5,0(s4)
ffffffffc0200f00:	2e079263          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f04:	0009a783          	lw	a5,0(s3)
ffffffffc0200f08:	2c079e63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f0c:	411c                	lw	a5,0(a0)
ffffffffc0200f0e:	2c079b63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200f12:	000ab797          	auipc	a5,0xab
ffffffffc0200f16:	5d678793          	addi	a5,a5,1494 # ffffffffc02ac4e8 <pages>
ffffffffc0200f1a:	639c                	ld	a5,0(a5)
ffffffffc0200f1c:	00008717          	auipc	a4,0x8
ffffffffc0200f20:	e0470713          	addi	a4,a4,-508 # ffffffffc0208d20 <nbase>
ffffffffc0200f24:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f26:	000ab717          	auipc	a4,0xab
ffffffffc0200f2a:	55270713          	addi	a4,a4,1362 # ffffffffc02ac478 <npage>
ffffffffc0200f2e:	6314                	ld	a3,0(a4)
ffffffffc0200f30:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f34:	8719                	srai	a4,a4,0x6
ffffffffc0200f36:	9732                	add	a4,a4,a2
ffffffffc0200f38:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f3a:	0732                	slli	a4,a4,0xc
ffffffffc0200f3c:	2cd77463          	bleu	a3,a4,ffffffffc0201204 <default_check+0x392>
    return page - pages + nbase;
ffffffffc0200f40:	40f98733          	sub	a4,s3,a5
ffffffffc0200f44:	8719                	srai	a4,a4,0x6
ffffffffc0200f46:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f48:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f4a:	4ed77d63          	bleu	a3,a4,ffffffffc0201444 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc0200f4e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f52:	8799                	srai	a5,a5,0x6
ffffffffc0200f54:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f56:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f58:	34d7f663          	bleu	a3,a5,ffffffffc02012a4 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc0200f5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f5e:	00093c03          	ld	s8,0(s2)
ffffffffc0200f62:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f66:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200f6a:	000ab797          	auipc	a5,0xab
ffffffffc0200f6e:	5527bb23          	sd	s2,1366(a5) # ffffffffc02ac4c0 <free_area+0x8>
ffffffffc0200f72:	000ab797          	auipc	a5,0xab
ffffffffc0200f76:	5527b323          	sd	s2,1350(a5) # ffffffffc02ac4b8 <free_area>
    nr_free = 0;
ffffffffc0200f7a:	000ab797          	auipc	a5,0xab
ffffffffc0200f7e:	5407a723          	sw	zero,1358(a5) # ffffffffc02ac4c8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f82:	6d1000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200f86:	2e051f63          	bnez	a0,ffffffffc0201284 <default_check+0x412>
    free_page(p0);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	8552                	mv	a0,s4
ffffffffc0200f8e:	74d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0200f92:	4585                	li	a1,1
ffffffffc0200f94:	854e                	mv	a0,s3
ffffffffc0200f96:	745000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0200f9a:	4585                	li	a1,1
ffffffffc0200f9c:	8556                	mv	a0,s5
ffffffffc0200f9e:	73d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(nr_free == 3);
ffffffffc0200fa2:	01092703          	lw	a4,16(s2)
ffffffffc0200fa6:	478d                	li	a5,3
ffffffffc0200fa8:	2af71e63          	bne	a4,a5,ffffffffc0201264 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fac:	4505                	li	a0,1
ffffffffc0200fae:	6a5000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fb2:	89aa                	mv	s3,a0
ffffffffc0200fb4:	28050863          	beqz	a0,ffffffffc0201244 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	699000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fbe:	8aaa                	mv	s5,a0
ffffffffc0200fc0:	3e050263          	beqz	a0,ffffffffc02013a4 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	68d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fca:	8a2a                	mv	s4,a0
ffffffffc0200fcc:	3a050c63          	beqz	a0,ffffffffc0201384 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	681000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fd6:	38051763          	bnez	a0,ffffffffc0201364 <default_check+0x4f2>
    free_page(p0);
ffffffffc0200fda:	4585                	li	a1,1
ffffffffc0200fdc:	854e                	mv	a0,s3
ffffffffc0200fde:	6fd000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fe2:	00893783          	ld	a5,8(s2)
ffffffffc0200fe6:	23278f63          	beq	a5,s2,ffffffffc0201224 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc0200fea:	4505                	li	a0,1
ffffffffc0200fec:	667000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ff0:	32a99a63          	bne	s3,a0,ffffffffc0201324 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	65d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ffa:	30051563          	bnez	a0,ffffffffc0201304 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0200ffe:	01092783          	lw	a5,16(s2)
ffffffffc0201002:	2e079163          	bnez	a5,ffffffffc02012e4 <default_check+0x472>
    free_page(p);
ffffffffc0201006:	854e                	mv	a0,s3
ffffffffc0201008:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020100a:	000ab797          	auipc	a5,0xab
ffffffffc020100e:	4b87b723          	sd	s8,1198(a5) # ffffffffc02ac4b8 <free_area>
ffffffffc0201012:	000ab797          	auipc	a5,0xab
ffffffffc0201016:	4b77b723          	sd	s7,1198(a5) # ffffffffc02ac4c0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020101a:	000ab797          	auipc	a5,0xab
ffffffffc020101e:	4b67a723          	sw	s6,1198(a5) # ffffffffc02ac4c8 <free_area+0x10>
    free_page(p);
ffffffffc0201022:	6b9000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0201026:	4585                	li	a1,1
ffffffffc0201028:	8556                	mv	a0,s5
ffffffffc020102a:	6b1000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	8552                	mv	a0,s4
ffffffffc0201032:	6a9000ef          	jal	ra,ffffffffc0201eda <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201036:	4515                	li	a0,5
ffffffffc0201038:	61b000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020103c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103e:	28050363          	beqz	a0,ffffffffc02012c4 <default_check+0x452>
ffffffffc0201042:	651c                	ld	a5,8(a0)
ffffffffc0201044:	8385                	srli	a5,a5,0x1
ffffffffc0201046:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201048:	54079e63          	bnez	a5,ffffffffc02015a4 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020104c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104e:	00093b03          	ld	s6,0(s2)
ffffffffc0201052:	00893a83          	ld	s5,8(s2)
ffffffffc0201056:	000ab797          	auipc	a5,0xab
ffffffffc020105a:	4727b123          	sd	s2,1122(a5) # ffffffffc02ac4b8 <free_area>
ffffffffc020105e:	000ab797          	auipc	a5,0xab
ffffffffc0201062:	4727b123          	sd	s2,1122(a5) # ffffffffc02ac4c0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0201066:	5ed000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020106a:	50051d63          	bnez	a0,ffffffffc0201584 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020106e:	08098a13          	addi	s4,s3,128
ffffffffc0201072:	8552                	mv	a0,s4
ffffffffc0201074:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201076:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc020107a:	000ab797          	auipc	a5,0xab
ffffffffc020107e:	4407a723          	sw	zero,1102(a5) # ffffffffc02ac4c8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201082:	659000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201086:	4511                	li	a0,4
ffffffffc0201088:	5cb000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020108c:	4c051c63          	bnez	a0,ffffffffc0201564 <default_check+0x6f2>
ffffffffc0201090:	0889b783          	ld	a5,136(s3)
ffffffffc0201094:	8385                	srli	a5,a5,0x1
ffffffffc0201096:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201098:	4a078663          	beqz	a5,ffffffffc0201544 <default_check+0x6d2>
ffffffffc020109c:	0909a703          	lw	a4,144(s3)
ffffffffc02010a0:	478d                	li	a5,3
ffffffffc02010a2:	4af71163          	bne	a4,a5,ffffffffc0201544 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010a6:	450d                	li	a0,3
ffffffffc02010a8:	5ab000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010ac:	8c2a                	mv	s8,a0
ffffffffc02010ae:	46050b63          	beqz	a0,ffffffffc0201524 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc02010b2:	4505                	li	a0,1
ffffffffc02010b4:	59f000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010b8:	44051663          	bnez	a0,ffffffffc0201504 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc02010bc:	438a1463          	bne	s4,s8,ffffffffc02014e4 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010c0:	4585                	li	a1,1
ffffffffc02010c2:	854e                	mv	a0,s3
ffffffffc02010c4:	617000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_pages(p1, 3);
ffffffffc02010c8:	458d                	li	a1,3
ffffffffc02010ca:	8552                	mv	a0,s4
ffffffffc02010cc:	60f000ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc02010d0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010d4:	04098c13          	addi	s8,s3,64
ffffffffc02010d8:	8385                	srli	a5,a5,0x1
ffffffffc02010da:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010dc:	3e078463          	beqz	a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010e0:	0109a703          	lw	a4,16(s3)
ffffffffc02010e4:	4785                	li	a5,1
ffffffffc02010e6:	3cf71f63          	bne	a4,a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010ea:	008a3783          	ld	a5,8(s4)
ffffffffc02010ee:	8385                	srli	a5,a5,0x1
ffffffffc02010f0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010f2:	3a078963          	beqz	a5,ffffffffc02014a4 <default_check+0x632>
ffffffffc02010f6:	010a2703          	lw	a4,16(s4)
ffffffffc02010fa:	478d                	li	a5,3
ffffffffc02010fc:	3af71463          	bne	a4,a5,ffffffffc02014a4 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201100:	4505                	li	a0,1
ffffffffc0201102:	551000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201106:	36a99f63          	bne	s3,a0,ffffffffc0201484 <default_check+0x612>
    free_page(p0);
ffffffffc020110a:	4585                	li	a1,1
ffffffffc020110c:	5cf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201110:	4509                	li	a0,2
ffffffffc0201112:	541000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201116:	34aa1763          	bne	s4,a0,ffffffffc0201464 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc020111a:	4589                	li	a1,2
ffffffffc020111c:	5bf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	8562                	mv	a0,s8
ffffffffc0201124:	5b7000ef          	jal	ra,ffffffffc0201eda <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201128:	4515                	li	a0,5
ffffffffc020112a:	529000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020112e:	89aa                	mv	s3,a0
ffffffffc0201130:	48050a63          	beqz	a0,ffffffffc02015c4 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	51d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020113a:	2e051563          	bnez	a0,ffffffffc0201424 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc020113e:	01092783          	lw	a5,16(s2)
ffffffffc0201142:	2c079163          	bnez	a5,ffffffffc0201404 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201146:	4595                	li	a1,5
ffffffffc0201148:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020114a:	000ab797          	auipc	a5,0xab
ffffffffc020114e:	3777af23          	sw	s7,894(a5) # ffffffffc02ac4c8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0201152:	000ab797          	auipc	a5,0xab
ffffffffc0201156:	3767b323          	sd	s6,870(a5) # ffffffffc02ac4b8 <free_area>
ffffffffc020115a:	000ab797          	auipc	a5,0xab
ffffffffc020115e:	3757b323          	sd	s5,870(a5) # ffffffffc02ac4c0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0201162:	579000ef          	jal	ra,ffffffffc0201eda <free_pages>
    return listelm->next;
ffffffffc0201166:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020116a:	01278963          	beq	a5,s2,ffffffffc020117c <default_check+0x30a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020116e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201172:	679c                	ld	a5,8(a5)
ffffffffc0201174:	34fd                	addiw	s1,s1,-1
ffffffffc0201176:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201178:	ff279be3          	bne	a5,s2,ffffffffc020116e <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc020117c:	26049463          	bnez	s1,ffffffffc02013e4 <default_check+0x572>
    assert(total == 0);
ffffffffc0201180:	46041263          	bnez	s0,ffffffffc02015e4 <default_check+0x772>
}
ffffffffc0201184:	60a6                	ld	ra,72(sp)
ffffffffc0201186:	6406                	ld	s0,64(sp)
ffffffffc0201188:	74e2                	ld	s1,56(sp)
ffffffffc020118a:	7942                	ld	s2,48(sp)
ffffffffc020118c:	79a2                	ld	s3,40(sp)
ffffffffc020118e:	7a02                	ld	s4,32(sp)
ffffffffc0201190:	6ae2                	ld	s5,24(sp)
ffffffffc0201192:	6b42                	ld	s6,16(sp)
ffffffffc0201194:	6ba2                	ld	s7,8(sp)
ffffffffc0201196:	6c02                	ld	s8,0(sp)
ffffffffc0201198:	6161                	addi	sp,sp,80
ffffffffc020119a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020119c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020119e:	4401                	li	s0,0
ffffffffc02011a0:	4481                	li	s1,0
ffffffffc02011a2:	b30d                	j	ffffffffc0200ec4 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc02011a4:	00006697          	auipc	a3,0x6
ffffffffc02011a8:	e2c68693          	addi	a3,a3,-468 # ffffffffc0206fd0 <commands+0x878>
ffffffffc02011ac:	00006617          	auipc	a2,0x6
ffffffffc02011b0:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02011b4:	0f000593          	li	a1,240
ffffffffc02011b8:	00006517          	auipc	a0,0x6
ffffffffc02011bc:	e2850513          	addi	a0,a0,-472 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02011c0:	ac4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011c4:	00006697          	auipc	a3,0x6
ffffffffc02011c8:	eb468693          	addi	a3,a3,-332 # ffffffffc0207078 <commands+0x920>
ffffffffc02011cc:	00006617          	auipc	a2,0x6
ffffffffc02011d0:	a4c60613          	addi	a2,a2,-1460 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02011d4:	0bd00593          	li	a1,189
ffffffffc02011d8:	00006517          	auipc	a0,0x6
ffffffffc02011dc:	e0850513          	addi	a0,a0,-504 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02011e0:	aa4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011e4:	00006697          	auipc	a3,0x6
ffffffffc02011e8:	ebc68693          	addi	a3,a3,-324 # ffffffffc02070a0 <commands+0x948>
ffffffffc02011ec:	00006617          	auipc	a2,0x6
ffffffffc02011f0:	a2c60613          	addi	a2,a2,-1492 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02011f4:	0be00593          	li	a1,190
ffffffffc02011f8:	00006517          	auipc	a0,0x6
ffffffffc02011fc:	de850513          	addi	a0,a0,-536 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201200:	a84ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201204:	00006697          	auipc	a3,0x6
ffffffffc0201208:	edc68693          	addi	a3,a3,-292 # ffffffffc02070e0 <commands+0x988>
ffffffffc020120c:	00006617          	auipc	a2,0x6
ffffffffc0201210:	a0c60613          	addi	a2,a2,-1524 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201214:	0c000593          	li	a1,192
ffffffffc0201218:	00006517          	auipc	a0,0x6
ffffffffc020121c:	dc850513          	addi	a0,a0,-568 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201220:	a64ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201224:	00006697          	auipc	a3,0x6
ffffffffc0201228:	f4468693          	addi	a3,a3,-188 # ffffffffc0207168 <commands+0xa10>
ffffffffc020122c:	00006617          	auipc	a2,0x6
ffffffffc0201230:	9ec60613          	addi	a2,a2,-1556 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201234:	0d900593          	li	a1,217
ffffffffc0201238:	00006517          	auipc	a0,0x6
ffffffffc020123c:	da850513          	addi	a0,a0,-600 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201240:	a44ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201244:	00006697          	auipc	a3,0x6
ffffffffc0201248:	dd468693          	addi	a3,a3,-556 # ffffffffc0207018 <commands+0x8c0>
ffffffffc020124c:	00006617          	auipc	a2,0x6
ffffffffc0201250:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201254:	0d200593          	li	a1,210
ffffffffc0201258:	00006517          	auipc	a0,0x6
ffffffffc020125c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201260:	a24ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 3);
ffffffffc0201264:	00006697          	auipc	a3,0x6
ffffffffc0201268:	ef468693          	addi	a3,a3,-268 # ffffffffc0207158 <commands+0xa00>
ffffffffc020126c:	00006617          	auipc	a2,0x6
ffffffffc0201270:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201274:	0d000593          	li	a1,208
ffffffffc0201278:	00006517          	auipc	a0,0x6
ffffffffc020127c:	d6850513          	addi	a0,a0,-664 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201280:	a04ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201284:	00006697          	auipc	a3,0x6
ffffffffc0201288:	ebc68693          	addi	a3,a3,-324 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020128c:	00006617          	auipc	a2,0x6
ffffffffc0201290:	98c60613          	addi	a2,a2,-1652 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201294:	0cb00593          	li	a1,203
ffffffffc0201298:	00006517          	auipc	a0,0x6
ffffffffc020129c:	d4850513          	addi	a0,a0,-696 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02012a0:	9e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012a4:	00006697          	auipc	a3,0x6
ffffffffc02012a8:	e7c68693          	addi	a3,a3,-388 # ffffffffc0207120 <commands+0x9c8>
ffffffffc02012ac:	00006617          	auipc	a2,0x6
ffffffffc02012b0:	96c60613          	addi	a2,a2,-1684 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02012b4:	0c200593          	li	a1,194
ffffffffc02012b8:	00006517          	auipc	a0,0x6
ffffffffc02012bc:	d2850513          	addi	a0,a0,-728 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02012c0:	9c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != NULL);
ffffffffc02012c4:	00006697          	auipc	a3,0x6
ffffffffc02012c8:	eec68693          	addi	a3,a3,-276 # ffffffffc02071b0 <commands+0xa58>
ffffffffc02012cc:	00006617          	auipc	a2,0x6
ffffffffc02012d0:	94c60613          	addi	a2,a2,-1716 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02012d4:	0f800593          	li	a1,248
ffffffffc02012d8:	00006517          	auipc	a0,0x6
ffffffffc02012dc:	d0850513          	addi	a0,a0,-760 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02012e0:	9a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc02012e4:	00006697          	auipc	a3,0x6
ffffffffc02012e8:	ebc68693          	addi	a3,a3,-324 # ffffffffc02071a0 <commands+0xa48>
ffffffffc02012ec:	00006617          	auipc	a2,0x6
ffffffffc02012f0:	92c60613          	addi	a2,a2,-1748 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02012f4:	0df00593          	li	a1,223
ffffffffc02012f8:	00006517          	auipc	a0,0x6
ffffffffc02012fc:	ce850513          	addi	a0,a0,-792 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201300:	984ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201304:	00006697          	auipc	a3,0x6
ffffffffc0201308:	e3c68693          	addi	a3,a3,-452 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020130c:	00006617          	auipc	a2,0x6
ffffffffc0201310:	90c60613          	addi	a2,a2,-1780 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201314:	0dd00593          	li	a1,221
ffffffffc0201318:	00006517          	auipc	a0,0x6
ffffffffc020131c:	cc850513          	addi	a0,a0,-824 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201320:	964ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201324:	00006697          	auipc	a3,0x6
ffffffffc0201328:	e5c68693          	addi	a3,a3,-420 # ffffffffc0207180 <commands+0xa28>
ffffffffc020132c:	00006617          	auipc	a2,0x6
ffffffffc0201330:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201334:	0dc00593          	li	a1,220
ffffffffc0201338:	00006517          	auipc	a0,0x6
ffffffffc020133c:	ca850513          	addi	a0,a0,-856 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201340:	944ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201344:	00006697          	auipc	a3,0x6
ffffffffc0201348:	cd468693          	addi	a3,a3,-812 # ffffffffc0207018 <commands+0x8c0>
ffffffffc020134c:	00006617          	auipc	a2,0x6
ffffffffc0201350:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201354:	0b900593          	li	a1,185
ffffffffc0201358:	00006517          	auipc	a0,0x6
ffffffffc020135c:	c8850513          	addi	a0,a0,-888 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201360:	924ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201364:	00006697          	auipc	a3,0x6
ffffffffc0201368:	ddc68693          	addi	a3,a3,-548 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020136c:	00006617          	auipc	a2,0x6
ffffffffc0201370:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201374:	0d600593          	li	a1,214
ffffffffc0201378:	00006517          	auipc	a0,0x6
ffffffffc020137c:	c6850513          	addi	a0,a0,-920 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201380:	904ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201384:	00006697          	auipc	a3,0x6
ffffffffc0201388:	cd468693          	addi	a3,a3,-812 # ffffffffc0207058 <commands+0x900>
ffffffffc020138c:	00006617          	auipc	a2,0x6
ffffffffc0201390:	88c60613          	addi	a2,a2,-1908 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201394:	0d400593          	li	a1,212
ffffffffc0201398:	00006517          	auipc	a0,0x6
ffffffffc020139c:	c4850513          	addi	a0,a0,-952 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02013a0:	8e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a4:	00006697          	auipc	a3,0x6
ffffffffc02013a8:	c9468693          	addi	a3,a3,-876 # ffffffffc0207038 <commands+0x8e0>
ffffffffc02013ac:	00006617          	auipc	a2,0x6
ffffffffc02013b0:	86c60613          	addi	a2,a2,-1940 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02013b4:	0d300593          	li	a1,211
ffffffffc02013b8:	00006517          	auipc	a0,0x6
ffffffffc02013bc:	c2850513          	addi	a0,a0,-984 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02013c0:	8c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013c4:	00006697          	auipc	a3,0x6
ffffffffc02013c8:	c9468693          	addi	a3,a3,-876 # ffffffffc0207058 <commands+0x900>
ffffffffc02013cc:	00006617          	auipc	a2,0x6
ffffffffc02013d0:	84c60613          	addi	a2,a2,-1972 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02013d4:	0bb00593          	li	a1,187
ffffffffc02013d8:	00006517          	auipc	a0,0x6
ffffffffc02013dc:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02013e0:	8a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(count == 0);
ffffffffc02013e4:	00006697          	auipc	a3,0x6
ffffffffc02013e8:	f1c68693          	addi	a3,a3,-228 # ffffffffc0207300 <commands+0xba8>
ffffffffc02013ec:	00006617          	auipc	a2,0x6
ffffffffc02013f0:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02013f4:	12500593          	li	a1,293
ffffffffc02013f8:	00006517          	auipc	a0,0x6
ffffffffc02013fc:	be850513          	addi	a0,a0,-1048 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201400:	884ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc0201404:	00006697          	auipc	a3,0x6
ffffffffc0201408:	d9c68693          	addi	a3,a3,-612 # ffffffffc02071a0 <commands+0xa48>
ffffffffc020140c:	00006617          	auipc	a2,0x6
ffffffffc0201410:	80c60613          	addi	a2,a2,-2036 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201414:	11a00593          	li	a1,282
ffffffffc0201418:	00006517          	auipc	a0,0x6
ffffffffc020141c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201420:	864ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201424:	00006697          	auipc	a3,0x6
ffffffffc0201428:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	7ec60613          	addi	a2,a2,2028 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201434:	11800593          	li	a1,280
ffffffffc0201438:	00006517          	auipc	a0,0x6
ffffffffc020143c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201440:	844ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201444:	00006697          	auipc	a3,0x6
ffffffffc0201448:	cbc68693          	addi	a3,a3,-836 # ffffffffc0207100 <commands+0x9a8>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	7cc60613          	addi	a2,a2,1996 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201454:	0c100593          	li	a1,193
ffffffffc0201458:	00006517          	auipc	a0,0x6
ffffffffc020145c:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201460:	824ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201464:	00006697          	auipc	a3,0x6
ffffffffc0201468:	e5c68693          	addi	a3,a3,-420 # ffffffffc02072c0 <commands+0xb68>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201474:	11200593          	li	a1,274
ffffffffc0201478:	00006517          	auipc	a0,0x6
ffffffffc020147c:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201480:	804ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201484:	00006697          	auipc	a3,0x6
ffffffffc0201488:	e1c68693          	addi	a3,a3,-484 # ffffffffc02072a0 <commands+0xb48>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	78c60613          	addi	a2,a2,1932 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201494:	11000593          	li	a1,272
ffffffffc0201498:	00006517          	auipc	a0,0x6
ffffffffc020149c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02014a0:	fe5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014a4:	00006697          	auipc	a3,0x6
ffffffffc02014a8:	dd468693          	addi	a3,a3,-556 # ffffffffc0207278 <commands+0xb20>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	76c60613          	addi	a2,a2,1900 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02014b4:	10e00593          	li	a1,270
ffffffffc02014b8:	00006517          	auipc	a0,0x6
ffffffffc02014bc:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02014c0:	fc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014c4:	00006697          	auipc	a3,0x6
ffffffffc02014c8:	d8c68693          	addi	a3,a3,-628 # ffffffffc0207250 <commands+0xaf8>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	74c60613          	addi	a2,a2,1868 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02014d4:	10d00593          	li	a1,269
ffffffffc02014d8:	00006517          	auipc	a0,0x6
ffffffffc02014dc:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02014e0:	fa5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014e4:	00006697          	auipc	a3,0x6
ffffffffc02014e8:	d5c68693          	addi	a3,a3,-676 # ffffffffc0207240 <commands+0xae8>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	72c60613          	addi	a2,a2,1836 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02014f4:	10800593          	li	a1,264
ffffffffc02014f8:	00006517          	auipc	a0,0x6
ffffffffc02014fc:	ae850513          	addi	a0,a0,-1304 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201500:	f85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201504:	00006697          	auipc	a3,0x6
ffffffffc0201508:	c3c68693          	addi	a3,a3,-964 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	70c60613          	addi	a2,a2,1804 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201514:	10700593          	li	a1,263
ffffffffc0201518:	00006517          	auipc	a0,0x6
ffffffffc020151c:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201520:	f65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201524:	00006697          	auipc	a3,0x6
ffffffffc0201528:	cfc68693          	addi	a3,a3,-772 # ffffffffc0207220 <commands+0xac8>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201534:	10600593          	li	a1,262
ffffffffc0201538:	00006517          	auipc	a0,0x6
ffffffffc020153c:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201540:	f45fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201544:	00006697          	auipc	a3,0x6
ffffffffc0201548:	cac68693          	addi	a3,a3,-852 # ffffffffc02071f0 <commands+0xa98>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	6cc60613          	addi	a2,a2,1740 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201554:	10500593          	li	a1,261
ffffffffc0201558:	00006517          	auipc	a0,0x6
ffffffffc020155c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201560:	f25fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201564:	00006697          	auipc	a3,0x6
ffffffffc0201568:	c7468693          	addi	a3,a3,-908 # ffffffffc02071d8 <commands+0xa80>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201574:	10400593          	li	a1,260
ffffffffc0201578:	00006517          	auipc	a0,0x6
ffffffffc020157c:	a6850513          	addi	a0,a0,-1432 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201580:	f05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201584:	00006697          	auipc	a3,0x6
ffffffffc0201588:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0207140 <commands+0x9e8>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	68c60613          	addi	a2,a2,1676 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201594:	0fe00593          	li	a1,254
ffffffffc0201598:	00006517          	auipc	a0,0x6
ffffffffc020159c:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02015a0:	ee5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015a4:	00006697          	auipc	a3,0x6
ffffffffc02015a8:	c1c68693          	addi	a3,a3,-996 # ffffffffc02071c0 <commands+0xa68>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	66c60613          	addi	a2,a2,1644 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02015b4:	0f900593          	li	a1,249
ffffffffc02015b8:	00006517          	auipc	a0,0x6
ffffffffc02015bc:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02015c0:	ec5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015c4:	00006697          	auipc	a3,0x6
ffffffffc02015c8:	d1c68693          	addi	a3,a3,-740 # ffffffffc02072e0 <commands+0xb88>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	64c60613          	addi	a2,a2,1612 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02015d4:	11700593          	li	a1,279
ffffffffc02015d8:	00006517          	auipc	a0,0x6
ffffffffc02015dc:	a0850513          	addi	a0,a0,-1528 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02015e0:	ea5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == 0);
ffffffffc02015e4:	00006697          	auipc	a3,0x6
ffffffffc02015e8:	d2c68693          	addi	a3,a3,-724 # ffffffffc0207310 <commands+0xbb8>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	62c60613          	addi	a2,a2,1580 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02015f4:	12600593          	li	a1,294
ffffffffc02015f8:	00006517          	auipc	a0,0x6
ffffffffc02015fc:	9e850513          	addi	a0,a0,-1560 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201600:	e85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201604:	00006697          	auipc	a3,0x6
ffffffffc0201608:	9f468693          	addi	a3,a3,-1548 # ffffffffc0206ff8 <commands+0x8a0>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	60c60613          	addi	a2,a2,1548 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201614:	0f300593          	li	a1,243
ffffffffc0201618:	00006517          	auipc	a0,0x6
ffffffffc020161c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201620:	e65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201624:	00006697          	auipc	a3,0x6
ffffffffc0201628:	a1468693          	addi	a3,a3,-1516 # ffffffffc0207038 <commands+0x8e0>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	5ec60613          	addi	a2,a2,1516 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201634:	0ba00593          	li	a1,186
ffffffffc0201638:	00006517          	auipc	a0,0x6
ffffffffc020163c:	9a850513          	addi	a0,a0,-1624 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201640:	e45fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201644 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201644:	1141                	addi	sp,sp,-16
ffffffffc0201646:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201648:	16058e63          	beqz	a1,ffffffffc02017c4 <default_free_pages+0x180>
    for (; p != base + n; p ++) {
ffffffffc020164c:	00659693          	slli	a3,a1,0x6
ffffffffc0201650:	96aa                	add	a3,a3,a0
ffffffffc0201652:	02d50d63          	beq	a0,a3,ffffffffc020168c <default_free_pages+0x48>
ffffffffc0201656:	651c                	ld	a5,8(a0)
ffffffffc0201658:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020165a:	14079563          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc020165e:	651c                	ld	a5,8(a0)
ffffffffc0201660:	8385                	srli	a5,a5,0x1
ffffffffc0201662:	8b85                	andi	a5,a5,1
ffffffffc0201664:	14079063          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201668:	87aa                	mv	a5,a0
ffffffffc020166a:	a809                	j	ffffffffc020167c <default_free_pages+0x38>
ffffffffc020166c:	6798                	ld	a4,8(a5)
ffffffffc020166e:	8b05                	andi	a4,a4,1
ffffffffc0201670:	12071a63          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b09                	andi	a4,a4,2
ffffffffc0201678:	12071663          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc020167c:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201680:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201684:	04078793          	addi	a5,a5,64
ffffffffc0201688:	fed792e3          	bne	a5,a3,ffffffffc020166c <default_free_pages+0x28>
    base->property = n;
ffffffffc020168c:	2581                	sext.w	a1,a1
ffffffffc020168e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201690:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201694:	4789                	li	a5,2
ffffffffc0201696:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020169a:	000ab697          	auipc	a3,0xab
ffffffffc020169e:	e1e68693          	addi	a3,a3,-482 # ffffffffc02ac4b8 <free_area>
ffffffffc02016a2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016a4:	669c                	ld	a5,8(a3)
ffffffffc02016a6:	9db9                	addw	a1,a1,a4
ffffffffc02016a8:	000ab717          	auipc	a4,0xab
ffffffffc02016ac:	e2b72023          	sw	a1,-480(a4) # ffffffffc02ac4c8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02016b0:	0cd78163          	beq	a5,a3,ffffffffc0201772 <default_free_pages+0x12e>
            struct Page* page = le2page(le, page_link);
ffffffffc02016b4:	fe878713          	addi	a4,a5,-24
ffffffffc02016b8:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ba:	4801                	li	a6,0
ffffffffc02016bc:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016c0:	00e56a63          	bltu	a0,a4,ffffffffc02016d4 <default_free_pages+0x90>
    return listelm->next;
ffffffffc02016c4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016c6:	04d70f63          	beq	a4,a3,ffffffffc0201724 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016ca:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016cc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016d0:	fee57ae3          	bleu	a4,a0,ffffffffc02016c4 <default_free_pages+0x80>
ffffffffc02016d4:	00080663          	beqz	a6,ffffffffc02016e0 <default_free_pages+0x9c>
ffffffffc02016d8:	000ab817          	auipc	a6,0xab
ffffffffc02016dc:	deb83023          	sd	a1,-544(a6) # ffffffffc02ac4b8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016e0:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016e2:	e390                	sd	a2,0(a5)
ffffffffc02016e4:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02016e6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e8:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc02016ea:	06d58a63          	beq	a1,a3,ffffffffc020175e <default_free_pages+0x11a>
        if (p + p->property == base) {
ffffffffc02016ee:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc02016f2:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc02016f6:	02061793          	slli	a5,a2,0x20
ffffffffc02016fa:	83e9                	srli	a5,a5,0x1a
ffffffffc02016fc:	97ba                	add	a5,a5,a4
ffffffffc02016fe:	04f51b63          	bne	a0,a5,ffffffffc0201754 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0201702:	491c                	lw	a5,16(a0)
ffffffffc0201704:	9e3d                	addw	a2,a2,a5
ffffffffc0201706:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020170a:	57f5                	li	a5,-3
ffffffffc020170c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201710:	01853803          	ld	a6,24(a0)
ffffffffc0201714:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0201716:	853a                	mv	a0,a4
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201718:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020171c:	659c                	ld	a5,8(a1)
ffffffffc020171e:	01063023          	sd	a6,0(a2)
ffffffffc0201722:	a815                	j	ffffffffc0201756 <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc0201724:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201726:	f114                	sd	a3,32(a0)
ffffffffc0201728:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020172a:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020172c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172e:	00d70563          	beq	a4,a3,ffffffffc0201738 <default_free_pages+0xf4>
ffffffffc0201732:	4805                	li	a6,1
ffffffffc0201734:	87ba                	mv	a5,a4
ffffffffc0201736:	bf59                	j	ffffffffc02016cc <default_free_pages+0x88>
ffffffffc0201738:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020173a:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020173c:	00d78d63          	beq	a5,a3,ffffffffc0201756 <default_free_pages+0x112>
        if (p + p->property == base) {
ffffffffc0201740:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201744:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0201748:	02061793          	slli	a5,a2,0x20
ffffffffc020174c:	83e9                	srli	a5,a5,0x1a
ffffffffc020174e:	97ba                	add	a5,a5,a4
ffffffffc0201750:	faf509e3          	beq	a0,a5,ffffffffc0201702 <default_free_pages+0xbe>
ffffffffc0201754:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201756:	fe878713          	addi	a4,a5,-24
ffffffffc020175a:	00d78963          	beq	a5,a3,ffffffffc020176c <default_free_pages+0x128>
        if (base + base->property == p) {
ffffffffc020175e:	4910                	lw	a2,16(a0)
ffffffffc0201760:	02061693          	slli	a3,a2,0x20
ffffffffc0201764:	82e9                	srli	a3,a3,0x1a
ffffffffc0201766:	96aa                	add	a3,a3,a0
ffffffffc0201768:	00d70e63          	beq	a4,a3,ffffffffc0201784 <default_free_pages+0x140>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	0141                	addi	sp,sp,16
ffffffffc0201770:	8082                	ret
ffffffffc0201772:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201774:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201778:	e398                	sd	a4,0(a5)
ffffffffc020177a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020177c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020177e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201780:	0141                	addi	sp,sp,16
ffffffffc0201782:	8082                	ret
            base->property += p->property;
ffffffffc0201784:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201788:	ff078693          	addi	a3,a5,-16
ffffffffc020178c:	9e39                	addw	a2,a2,a4
ffffffffc020178e:	c910                	sw	a2,16(a0)
ffffffffc0201790:	5775                	li	a4,-3
ffffffffc0201792:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201796:	6398                	ld	a4,0(a5)
ffffffffc0201798:	679c                	ld	a5,8(a5)
}
ffffffffc020179a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020179c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020179e:	e398                	sd	a4,0(a5)
ffffffffc02017a0:	0141                	addi	sp,sp,16
ffffffffc02017a2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017a4:	00006697          	auipc	a3,0x6
ffffffffc02017a8:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0207320 <commands+0xbc8>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	46c60613          	addi	a2,a2,1132 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02017b4:	08300593          	li	a1,131
ffffffffc02017b8:	00006517          	auipc	a0,0x6
ffffffffc02017bc:	82850513          	addi	a0,a0,-2008 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02017c0:	cc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc02017c4:	00006697          	auipc	a3,0x6
ffffffffc02017c8:	b8468693          	addi	a3,a3,-1148 # ffffffffc0207348 <commands+0xbf0>
ffffffffc02017cc:	00005617          	auipc	a2,0x5
ffffffffc02017d0:	44c60613          	addi	a2,a2,1100 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02017d4:	08000593          	li	a1,128
ffffffffc02017d8:	00006517          	auipc	a0,0x6
ffffffffc02017dc:	80850513          	addi	a0,a0,-2040 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02017e0:	ca5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02017e4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017e4:	c959                	beqz	a0,ffffffffc020187a <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02017e6:	000ab597          	auipc	a1,0xab
ffffffffc02017ea:	cd258593          	addi	a1,a1,-814 # ffffffffc02ac4b8 <free_area>
ffffffffc02017ee:	0105a803          	lw	a6,16(a1)
ffffffffc02017f2:	862a                	mv	a2,a0
ffffffffc02017f4:	02081793          	slli	a5,a6,0x20
ffffffffc02017f8:	9381                	srli	a5,a5,0x20
ffffffffc02017fa:	00a7ee63          	bltu	a5,a0,ffffffffc0201816 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017fe:	87ae                	mv	a5,a1
ffffffffc0201800:	a801                	j	ffffffffc0201810 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201802:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201806:	02071693          	slli	a3,a4,0x20
ffffffffc020180a:	9281                	srli	a3,a3,0x20
ffffffffc020180c:	00c6f763          	bleu	a2,a3,ffffffffc020181a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201810:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201812:	feb798e3          	bne	a5,a1,ffffffffc0201802 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201816:	4501                	li	a0,0
}
ffffffffc0201818:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc020181a:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc020181e:	dd6d                	beqz	a0,ffffffffc0201818 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201820:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201824:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0201828:	00060e1b          	sext.w	t3,a2
ffffffffc020182c:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201830:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201834:	02d67863          	bleu	a3,a2,ffffffffc0201864 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0201838:	061a                	slli	a2,a2,0x6
ffffffffc020183a:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc020183c:	41c7073b          	subw	a4,a4,t3
ffffffffc0201840:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201842:	00860693          	addi	a3,a2,8
ffffffffc0201846:	4709                	li	a4,2
ffffffffc0201848:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc020184c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201850:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0201854:	0105a803          	lw	a6,16(a1)
ffffffffc0201858:	e314                	sd	a3,0(a4)
ffffffffc020185a:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc020185e:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0201860:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc0201864:	41c8083b          	subw	a6,a6,t3
ffffffffc0201868:	000ab717          	auipc	a4,0xab
ffffffffc020186c:	c7072023          	sw	a6,-928(a4) # ffffffffc02ac4c8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201870:	5775                	li	a4,-3
ffffffffc0201872:	17c1                	addi	a5,a5,-16
ffffffffc0201874:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201878:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020187a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020187c:	00006697          	auipc	a3,0x6
ffffffffc0201880:	acc68693          	addi	a3,a3,-1332 # ffffffffc0207348 <commands+0xbf0>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	39460613          	addi	a2,a2,916 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020188c:	06200593          	li	a1,98
ffffffffc0201890:	00005517          	auipc	a0,0x5
ffffffffc0201894:	75050513          	addi	a0,a0,1872 # ffffffffc0206fe0 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201898:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020189a:	bebfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020189e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020189e:	1141                	addi	sp,sp,-16
ffffffffc02018a0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018a2:	c1ed                	beqz	a1,ffffffffc0201984 <default_init_memmap+0xe6>
    for (; p != base + n; p ++) {
ffffffffc02018a4:	00659693          	slli	a3,a1,0x6
ffffffffc02018a8:	96aa                	add	a3,a3,a0
ffffffffc02018aa:	02d50463          	beq	a0,a3,ffffffffc02018d2 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ae:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02018b0:	87aa                	mv	a5,a0
ffffffffc02018b2:	8b05                	andi	a4,a4,1
ffffffffc02018b4:	e709                	bnez	a4,ffffffffc02018be <default_init_memmap+0x20>
ffffffffc02018b6:	a07d                	j	ffffffffc0201964 <default_init_memmap+0xc6>
ffffffffc02018b8:	6798                	ld	a4,8(a5)
ffffffffc02018ba:	8b05                	andi	a4,a4,1
ffffffffc02018bc:	c745                	beqz	a4,ffffffffc0201964 <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc02018be:	0007a823          	sw	zero,16(a5)
ffffffffc02018c2:	0007b423          	sd	zero,8(a5)
ffffffffc02018c6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02018ca:	04078793          	addi	a5,a5,64
ffffffffc02018ce:	fed795e3          	bne	a5,a3,ffffffffc02018b8 <default_init_memmap+0x1a>
    base->property = n;
ffffffffc02018d2:	2581                	sext.w	a1,a1
ffffffffc02018d4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018d6:	4789                	li	a5,2
ffffffffc02018d8:	00850713          	addi	a4,a0,8
ffffffffc02018dc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018e0:	000ab697          	auipc	a3,0xab
ffffffffc02018e4:	bd868693          	addi	a3,a3,-1064 # ffffffffc02ac4b8 <free_area>
ffffffffc02018e8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018ea:	669c                	ld	a5,8(a3)
ffffffffc02018ec:	9db9                	addw	a1,a1,a4
ffffffffc02018ee:	000ab717          	auipc	a4,0xab
ffffffffc02018f2:	bcb72d23          	sw	a1,-1062(a4) # ffffffffc02ac4c8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02018f6:	04d78a63          	beq	a5,a3,ffffffffc020194a <default_init_memmap+0xac>
            struct Page* page = le2page(le, page_link);
ffffffffc02018fa:	fe878713          	addi	a4,a5,-24
ffffffffc02018fe:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201900:	4801                	li	a6,0
ffffffffc0201902:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201906:	00e56a63          	bltu	a0,a4,ffffffffc020191a <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc020190a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020190c:	02d70563          	beq	a4,a3,ffffffffc0201936 <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201910:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201912:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201916:	fee57ae3          	bleu	a4,a0,ffffffffc020190a <default_init_memmap+0x6c>
ffffffffc020191a:	00080663          	beqz	a6,ffffffffc0201926 <default_init_memmap+0x88>
ffffffffc020191e:	000ab717          	auipc	a4,0xab
ffffffffc0201922:	b8b73d23          	sd	a1,-1126(a4) # ffffffffc02ac4b8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201926:	6398                	ld	a4,0(a5)
}
ffffffffc0201928:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020192a:	e390                	sd	a2,0(a5)
ffffffffc020192c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020192e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201930:	ed18                	sd	a4,24(a0)
ffffffffc0201932:	0141                	addi	sp,sp,16
ffffffffc0201934:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201936:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201938:	f114                	sd	a3,32(a0)
ffffffffc020193a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020193c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020193e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201940:	00d70e63          	beq	a4,a3,ffffffffc020195c <default_init_memmap+0xbe>
ffffffffc0201944:	4805                	li	a6,1
ffffffffc0201946:	87ba                	mv	a5,a4
ffffffffc0201948:	b7e9                	j	ffffffffc0201912 <default_init_memmap+0x74>
}
ffffffffc020194a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020194c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201950:	e398                	sd	a4,0(a5)
ffffffffc0201952:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201954:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201956:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201958:	0141                	addi	sp,sp,16
ffffffffc020195a:	8082                	ret
ffffffffc020195c:	60a2                	ld	ra,8(sp)
ffffffffc020195e:	e290                	sd	a2,0(a3)
ffffffffc0201960:	0141                	addi	sp,sp,16
ffffffffc0201962:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201964:	00006697          	auipc	a3,0x6
ffffffffc0201968:	9ec68693          	addi	a3,a3,-1556 # ffffffffc0207350 <commands+0xbf8>
ffffffffc020196c:	00005617          	auipc	a2,0x5
ffffffffc0201970:	2ac60613          	addi	a2,a2,684 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201974:	04900593          	li	a1,73
ffffffffc0201978:	00005517          	auipc	a0,0x5
ffffffffc020197c:	66850513          	addi	a0,a0,1640 # ffffffffc0206fe0 <commands+0x888>
ffffffffc0201980:	b05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc0201984:	00006697          	auipc	a3,0x6
ffffffffc0201988:	9c468693          	addi	a3,a3,-1596 # ffffffffc0207348 <commands+0xbf0>
ffffffffc020198c:	00005617          	auipc	a2,0x5
ffffffffc0201990:	28c60613          	addi	a2,a2,652 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201994:	04600593          	li	a1,70
ffffffffc0201998:	00005517          	auipc	a0,0x5
ffffffffc020199c:	64850513          	addi	a0,a0,1608 # ffffffffc0206fe0 <commands+0x888>
ffffffffc02019a0:	ae5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02019a4 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02019a4:	c125                	beqz	a0,ffffffffc0201a04 <slob_free+0x60>
		return;

	if (size)
ffffffffc02019a6:	e1a5                	bnez	a1,ffffffffc0201a06 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	100027f3          	csrr	a5,sstatus
ffffffffc02019ac:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019ae:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b0:	e3bd                	bnez	a5,ffffffffc0201a16 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019b2:	0009f797          	auipc	a5,0x9f
ffffffffc02019b6:	69678793          	addi	a5,a5,1686 # ffffffffc02a1048 <slobfree>
ffffffffc02019ba:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019bc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019be:	00a7fa63          	bleu	a0,a5,ffffffffc02019d2 <slob_free+0x2e>
ffffffffc02019c2:	00e56c63          	bltu	a0,a4,ffffffffc02019da <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c6:	00e7fa63          	bleu	a4,a5,ffffffffc02019da <slob_free+0x36>
    return 0;
ffffffffc02019ca:	87ba                	mv	a5,a4
ffffffffc02019cc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ce:	fea7eae3          	bltu	a5,a0,ffffffffc02019c2 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019d2:	fee7ece3          	bltu	a5,a4,ffffffffc02019ca <slob_free+0x26>
ffffffffc02019d6:	fee57ae3          	bleu	a4,a0,ffffffffc02019ca <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc02019da:	4110                	lw	a2,0(a0)
ffffffffc02019dc:	00461693          	slli	a3,a2,0x4
ffffffffc02019e0:	96aa                	add	a3,a3,a0
ffffffffc02019e2:	08d70b63          	beq	a4,a3,ffffffffc0201a78 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02019e6:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc02019e8:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02019ea:	00469713          	slli	a4,a3,0x4
ffffffffc02019ee:	973e                	add	a4,a4,a5
ffffffffc02019f0:	08e50f63          	beq	a0,a4,ffffffffc0201a8e <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc02019f4:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc02019f6:	0009f717          	auipc	a4,0x9f
ffffffffc02019fa:	64f73923          	sd	a5,1618(a4) # ffffffffc02a1048 <slobfree>
    if (flag) {
ffffffffc02019fe:	c199                	beqz	a1,ffffffffc0201a04 <slob_free+0x60>
        intr_enable();
ffffffffc0201a00:	c55fe06f          	j	ffffffffc0200654 <intr_enable>
ffffffffc0201a04:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc0201a06:	05bd                	addi	a1,a1,15
ffffffffc0201a08:	8191                	srli	a1,a1,0x4
ffffffffc0201a0a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a10:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a12:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a14:	dfd9                	beqz	a5,ffffffffc02019b2 <slob_free+0xe>
{
ffffffffc0201a16:	1101                	addi	sp,sp,-32
ffffffffc0201a18:	e42a                	sd	a0,8(sp)
ffffffffc0201a1a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201a1c:	c3ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a20:	0009f797          	auipc	a5,0x9f
ffffffffc0201a24:	62878793          	addi	a5,a5,1576 # ffffffffc02a1048 <slobfree>
ffffffffc0201a28:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0201a2a:	6522                	ld	a0,8(sp)
ffffffffc0201a2c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a2e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a30:	00a7fa63          	bleu	a0,a5,ffffffffc0201a44 <slob_free+0xa0>
ffffffffc0201a34:	00e56c63          	bltu	a0,a4,ffffffffc0201a4c <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a38:	00e7fa63          	bleu	a4,a5,ffffffffc0201a4c <slob_free+0xa8>
    return 0;
ffffffffc0201a3c:	87ba                	mv	a5,a4
ffffffffc0201a3e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a40:	fea7eae3          	bltu	a5,a0,ffffffffc0201a34 <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a44:	fee7ece3          	bltu	a5,a4,ffffffffc0201a3c <slob_free+0x98>
ffffffffc0201a48:	fee57ae3          	bleu	a4,a0,ffffffffc0201a3c <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc0201a4c:	4110                	lw	a2,0(a0)
ffffffffc0201a4e:	00461693          	slli	a3,a2,0x4
ffffffffc0201a52:	96aa                	add	a3,a3,a0
ffffffffc0201a54:	04d70763          	beq	a4,a3,ffffffffc0201aa2 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc0201a58:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a5a:	4394                	lw	a3,0(a5)
ffffffffc0201a5c:	00469713          	slli	a4,a3,0x4
ffffffffc0201a60:	973e                	add	a4,a4,a5
ffffffffc0201a62:	04e50663          	beq	a0,a4,ffffffffc0201aae <slob_free+0x10a>
		cur->next = b;
ffffffffc0201a66:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc0201a68:	0009f717          	auipc	a4,0x9f
ffffffffc0201a6c:	5ef73023          	sd	a5,1504(a4) # ffffffffc02a1048 <slobfree>
    if (flag) {
ffffffffc0201a70:	e58d                	bnez	a1,ffffffffc0201a9a <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a72:	60e2                	ld	ra,24(sp)
ffffffffc0201a74:	6105                	addi	sp,sp,32
ffffffffc0201a76:	8082                	ret
		b->units += cur->next->units;
ffffffffc0201a78:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a7a:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201a7c:	9e35                	addw	a2,a2,a3
ffffffffc0201a7e:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc0201a80:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a82:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a84:	00469713          	slli	a4,a3,0x4
ffffffffc0201a88:	973e                	add	a4,a4,a5
ffffffffc0201a8a:	f6e515e3          	bne	a0,a4,ffffffffc02019f4 <slob_free+0x50>
		cur->units += b->units;
ffffffffc0201a8e:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201a90:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201a92:	9eb9                	addw	a3,a3,a4
ffffffffc0201a94:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201a96:	e790                	sd	a2,8(a5)
ffffffffc0201a98:	bfb9                	j	ffffffffc02019f6 <slob_free+0x52>
}
ffffffffc0201a9a:	60e2                	ld	ra,24(sp)
ffffffffc0201a9c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a9e:	bb7fe06f          	j	ffffffffc0200654 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201aa2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201aa4:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201aa6:	9e35                	addw	a2,a2,a3
ffffffffc0201aa8:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0201aaa:	e518                	sd	a4,8(a0)
ffffffffc0201aac:	b77d                	j	ffffffffc0201a5a <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0201aae:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201ab0:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201ab2:	9eb9                	addw	a3,a3,a4
ffffffffc0201ab4:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201ab6:	e790                	sd	a2,8(a5)
ffffffffc0201ab8:	bf45                	j	ffffffffc0201a68 <slob_free+0xc4>

ffffffffc0201aba <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201aba:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201abc:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201abe:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ac2:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201ac4:	38e000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
  if(!page)
ffffffffc0201ac8:	c139                	beqz	a0,ffffffffc0201b0e <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc0201aca:	000ab797          	auipc	a5,0xab
ffffffffc0201ace:	a1e78793          	addi	a5,a5,-1506 # ffffffffc02ac4e8 <pages>
ffffffffc0201ad2:	6394                	ld	a3,0(a5)
ffffffffc0201ad4:	00007797          	auipc	a5,0x7
ffffffffc0201ad8:	24c78793          	addi	a5,a5,588 # ffffffffc0208d20 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201adc:	000ab717          	auipc	a4,0xab
ffffffffc0201ae0:	99c70713          	addi	a4,a4,-1636 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc0201ae4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ae8:	6388                	ld	a0,0(a5)
ffffffffc0201aea:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201aec:	57fd                	li	a5,-1
ffffffffc0201aee:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0201af0:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0201af2:	83b1                	srli	a5,a5,0xc
ffffffffc0201af4:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201af6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201af8:	00e7ff63          	bleu	a4,a5,ffffffffc0201b16 <__slob_get_free_pages.isra.0+0x5c>
ffffffffc0201afc:	000ab797          	auipc	a5,0xab
ffffffffc0201b00:	9dc78793          	addi	a5,a5,-1572 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0201b04:	6388                	ld	a0,0(a5)
}
ffffffffc0201b06:	60a2                	ld	ra,8(sp)
ffffffffc0201b08:	9536                	add	a0,a0,a3
ffffffffc0201b0a:	0141                	addi	sp,sp,16
ffffffffc0201b0c:	8082                	ret
ffffffffc0201b0e:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0201b10:	4501                	li	a0,0
}
ffffffffc0201b12:	0141                	addi	sp,sp,16
ffffffffc0201b14:	8082                	ret
ffffffffc0201b16:	00006617          	auipc	a2,0x6
ffffffffc0201b1a:	89a60613          	addi	a2,a2,-1894 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0201b1e:	06900593          	li	a1,105
ffffffffc0201b22:	00006517          	auipc	a0,0x6
ffffffffc0201b26:	8b650513          	addi	a0,a0,-1866 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0201b2a:	95bfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b2e:	7179                	addi	sp,sp,-48
ffffffffc0201b30:	f406                	sd	ra,40(sp)
ffffffffc0201b32:	f022                	sd	s0,32(sp)
ffffffffc0201b34:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201b36:	01050713          	addi	a4,a0,16
ffffffffc0201b3a:	6785                	lui	a5,0x1
ffffffffc0201b3c:	0cf77b63          	bleu	a5,a4,ffffffffc0201c12 <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b40:	00f50413          	addi	s0,a0,15
ffffffffc0201b44:	8011                	srli	s0,s0,0x4
ffffffffc0201b46:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b48:	10002673          	csrr	a2,sstatus
ffffffffc0201b4c:	8a09                	andi	a2,a2,2
ffffffffc0201b4e:	ea5d                	bnez	a2,ffffffffc0201c04 <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc0201b50:	0009f497          	auipc	s1,0x9f
ffffffffc0201b54:	4f848493          	addi	s1,s1,1272 # ffffffffc02a1048 <slobfree>
ffffffffc0201b58:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b5a:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b5c:	4398                	lw	a4,0(a5)
ffffffffc0201b5e:	0a875763          	ble	s0,a4,ffffffffc0201c0c <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc0201b62:	00f68a63          	beq	a3,a5,ffffffffc0201b76 <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b66:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b68:	4118                	lw	a4,0(a0)
ffffffffc0201b6a:	02875763          	ble	s0,a4,ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc0201b6e:	6094                	ld	a3,0(s1)
ffffffffc0201b70:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc0201b72:	fef69ae3          	bne	a3,a5,ffffffffc0201b66 <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc0201b76:	ea39                	bnez	a2,ffffffffc0201bcc <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b78:	4501                	li	a0,0
ffffffffc0201b7a:	f41ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201b7e:	cd29                	beqz	a0,ffffffffc0201bd8 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b80:	6585                	lui	a1,0x1
ffffffffc0201b82:	e23ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b86:	10002673          	csrr	a2,sstatus
ffffffffc0201b8a:	8a09                	andi	a2,a2,2
ffffffffc0201b8c:	ea1d                	bnez	a2,ffffffffc0201bc2 <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc0201b8e:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b90:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b92:	4118                	lw	a4,0(a0)
ffffffffc0201b94:	fc874de3          	blt	a4,s0,ffffffffc0201b6e <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0201b98:	04e40663          	beq	s0,a4,ffffffffc0201be4 <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc0201b9c:	00441693          	slli	a3,s0,0x4
ffffffffc0201ba0:	96aa                	add	a3,a3,a0
ffffffffc0201ba2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201ba4:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0201ba6:	9f01                	subw	a4,a4,s0
ffffffffc0201ba8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201baa:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201bac:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0201bae:	0009f717          	auipc	a4,0x9f
ffffffffc0201bb2:	48f73d23          	sd	a5,1178(a4) # ffffffffc02a1048 <slobfree>
    if (flag) {
ffffffffc0201bb6:	ee15                	bnez	a2,ffffffffc0201bf2 <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0201bb8:	70a2                	ld	ra,40(sp)
ffffffffc0201bba:	7402                	ld	s0,32(sp)
ffffffffc0201bbc:	64e2                	ld	s1,24(sp)
ffffffffc0201bbe:	6145                	addi	sp,sp,48
ffffffffc0201bc0:	8082                	ret
        intr_disable();
ffffffffc0201bc2:	a99fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201bc6:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0201bc8:	609c                	ld	a5,0(s1)
ffffffffc0201bca:	b7d9                	j	ffffffffc0201b90 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0201bcc:	a89fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bd0:	4501                	li	a0,0
ffffffffc0201bd2:	ee9ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201bd6:	f54d                	bnez	a0,ffffffffc0201b80 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0201bd8:	70a2                	ld	ra,40(sp)
ffffffffc0201bda:	7402                	ld	s0,32(sp)
ffffffffc0201bdc:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0201bde:	4501                	li	a0,0
}
ffffffffc0201be0:	6145                	addi	sp,sp,48
ffffffffc0201be2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201be4:	6518                	ld	a4,8(a0)
ffffffffc0201be6:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0201be8:	0009f717          	auipc	a4,0x9f
ffffffffc0201bec:	46f73023          	sd	a5,1120(a4) # ffffffffc02a1048 <slobfree>
    if (flag) {
ffffffffc0201bf0:	d661                	beqz	a2,ffffffffc0201bb8 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0201bf2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201bf4:	a61fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc0201bf8:	70a2                	ld	ra,40(sp)
ffffffffc0201bfa:	7402                	ld	s0,32(sp)
ffffffffc0201bfc:	6522                	ld	a0,8(sp)
ffffffffc0201bfe:	64e2                	ld	s1,24(sp)
ffffffffc0201c00:	6145                	addi	sp,sp,48
ffffffffc0201c02:	8082                	ret
        intr_disable();
ffffffffc0201c04:	a57fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201c08:	4605                	li	a2,1
ffffffffc0201c0a:	b799                	j	ffffffffc0201b50 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201c0c:	853e                	mv	a0,a5
ffffffffc0201c0e:	87b6                	mv	a5,a3
ffffffffc0201c10:	b761                	j	ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201c12:	00006697          	auipc	a3,0x6
ffffffffc0201c16:	83e68693          	addi	a3,a3,-1986 # ffffffffc0207450 <default_pmm_manager+0xf0>
ffffffffc0201c1a:	00005617          	auipc	a2,0x5
ffffffffc0201c1e:	ffe60613          	addi	a2,a2,-2 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0201c22:	06400593          	li	a1,100
ffffffffc0201c26:	00006517          	auipc	a0,0x6
ffffffffc0201c2a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0207470 <default_pmm_manager+0x110>
ffffffffc0201c2e:	857fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201c32 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201c32:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201c34:	00006517          	auipc	a0,0x6
ffffffffc0201c38:	85450513          	addi	a0,a0,-1964 # ffffffffc0207488 <default_pmm_manager+0x128>
kmalloc_init(void) {
ffffffffc0201c3c:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201c3e:	d50fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c42:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c44:	00005517          	auipc	a0,0x5
ffffffffc0201c48:	7ec50513          	addi	a0,a0,2028 # ffffffffc0207430 <default_pmm_manager+0xd0>
}
ffffffffc0201c4c:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c4e:	d40fe06f          	j	ffffffffc020018e <cprintf>

ffffffffc0201c52 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201c52:	4501                	li	a0,0
ffffffffc0201c54:	8082                	ret

ffffffffc0201c56 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c56:	1101                	addi	sp,sp,-32
ffffffffc0201c58:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c5a:	6905                	lui	s2,0x1
{
ffffffffc0201c5c:	e822                	sd	s0,16(sp)
ffffffffc0201c5e:	ec06                	sd	ra,24(sp)
ffffffffc0201c60:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c62:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8581>
{
ffffffffc0201c66:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c68:	04a7fc63          	bleu	a0,a5,ffffffffc0201cc0 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c6c:	4561                	li	a0,24
ffffffffc0201c6e:	ec1ff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
ffffffffc0201c72:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c74:	cd21                	beqz	a0,ffffffffc0201ccc <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc0201c76:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c7a:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c7c:	00f95763          	ble	a5,s2,ffffffffc0201c8a <kmalloc+0x34>
ffffffffc0201c80:	6705                	lui	a4,0x1
ffffffffc0201c82:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c84:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c86:	fef74ee3          	blt	a4,a5,ffffffffc0201c82 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c8a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c8c:	e2fff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
ffffffffc0201c90:	e488                	sd	a0,8(s1)
ffffffffc0201c92:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201c94:	c935                	beqz	a0,ffffffffc0201d08 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c96:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9a:	8b89                	andi	a5,a5,2
ffffffffc0201c9c:	e3a1                	bnez	a5,ffffffffc0201cdc <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0201c9e:	000aa797          	auipc	a5,0xaa
ffffffffc0201ca2:	7ca78793          	addi	a5,a5,1994 # ffffffffc02ac468 <bigblocks>
ffffffffc0201ca6:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201ca8:	000aa717          	auipc	a4,0xaa
ffffffffc0201cac:	7c973023          	sd	s1,1984(a4) # ffffffffc02ac468 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cb0:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201cb2:	8522                	mv	a0,s0
ffffffffc0201cb4:	60e2                	ld	ra,24(sp)
ffffffffc0201cb6:	6442                	ld	s0,16(sp)
ffffffffc0201cb8:	64a2                	ld	s1,8(sp)
ffffffffc0201cba:	6902                	ld	s2,0(sp)
ffffffffc0201cbc:	6105                	addi	sp,sp,32
ffffffffc0201cbe:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201cc0:	0541                	addi	a0,a0,16
ffffffffc0201cc2:	e6dff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201cc6:	01050413          	addi	s0,a0,16
ffffffffc0201cca:	f565                	bnez	a0,ffffffffc0201cb2 <kmalloc+0x5c>
ffffffffc0201ccc:	4401                	li	s0,0
}
ffffffffc0201cce:	8522                	mv	a0,s0
ffffffffc0201cd0:	60e2                	ld	ra,24(sp)
ffffffffc0201cd2:	6442                	ld	s0,16(sp)
ffffffffc0201cd4:	64a2                	ld	s1,8(sp)
ffffffffc0201cd6:	6902                	ld	s2,0(sp)
ffffffffc0201cd8:	6105                	addi	sp,sp,32
ffffffffc0201cda:	8082                	ret
        intr_disable();
ffffffffc0201cdc:	97ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ce0:	000aa797          	auipc	a5,0xaa
ffffffffc0201ce4:	78878793          	addi	a5,a5,1928 # ffffffffc02ac468 <bigblocks>
ffffffffc0201ce8:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201cea:	000aa717          	auipc	a4,0xaa
ffffffffc0201cee:	76973f23          	sd	s1,1918(a4) # ffffffffc02ac468 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cf2:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0201cf4:	961fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201cf8:	6480                	ld	s0,8(s1)
}
ffffffffc0201cfa:	60e2                	ld	ra,24(sp)
ffffffffc0201cfc:	64a2                	ld	s1,8(sp)
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	6902                	ld	s2,0(sp)
ffffffffc0201d04:	6105                	addi	sp,sp,32
ffffffffc0201d06:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d08:	45e1                	li	a1,24
ffffffffc0201d0a:	8526                	mv	a0,s1
ffffffffc0201d0c:	c99ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201d10:	b74d                	j	ffffffffc0201cb2 <kmalloc+0x5c>

ffffffffc0201d12 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d12:	c175                	beqz	a0,ffffffffc0201df6 <kfree+0xe4>
{
ffffffffc0201d14:	1101                	addi	sp,sp,-32
ffffffffc0201d16:	e426                	sd	s1,8(sp)
ffffffffc0201d18:	ec06                	sd	ra,24(sp)
ffffffffc0201d1a:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201d1c:	03451793          	slli	a5,a0,0x34
ffffffffc0201d20:	84aa                	mv	s1,a0
ffffffffc0201d22:	eb8d                	bnez	a5,ffffffffc0201d54 <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d24:	100027f3          	csrr	a5,sstatus
ffffffffc0201d28:	8b89                	andi	a5,a5,2
ffffffffc0201d2a:	efc9                	bnez	a5,ffffffffc0201dc4 <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d2c:	000aa797          	auipc	a5,0xaa
ffffffffc0201d30:	73c78793          	addi	a5,a5,1852 # ffffffffc02ac468 <bigblocks>
ffffffffc0201d34:	6394                	ld	a3,0(a5)
ffffffffc0201d36:	ce99                	beqz	a3,ffffffffc0201d54 <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0201d38:	669c                	ld	a5,8(a3)
ffffffffc0201d3a:	6a80                	ld	s0,16(a3)
ffffffffc0201d3c:	0af50e63          	beq	a0,a5,ffffffffc0201df8 <kfree+0xe6>
    return 0;
ffffffffc0201d40:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d42:	c801                	beqz	s0,ffffffffc0201d52 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc0201d44:	6418                	ld	a4,8(s0)
ffffffffc0201d46:	681c                	ld	a5,16(s0)
ffffffffc0201d48:	00970f63          	beq	a4,s1,ffffffffc0201d66 <kfree+0x54>
ffffffffc0201d4c:	86a2                	mv	a3,s0
ffffffffc0201d4e:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d50:	f875                	bnez	s0,ffffffffc0201d44 <kfree+0x32>
    if (flag) {
ffffffffc0201d52:	e659                	bnez	a2,ffffffffc0201de0 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d54:	6442                	ld	s0,16(sp)
ffffffffc0201d56:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d58:	ff048513          	addi	a0,s1,-16
}
ffffffffc0201d5c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d5e:	4581                	li	a1,0
}
ffffffffc0201d60:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d62:	c43ff06f          	j	ffffffffc02019a4 <slob_free>
				*last = bb->next;
ffffffffc0201d66:	ea9c                	sd	a5,16(a3)
ffffffffc0201d68:	e641                	bnez	a2,ffffffffc0201df0 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc0201d6a:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d6e:	4018                	lw	a4,0(s0)
ffffffffc0201d70:	08f4ea63          	bltu	s1,a5,ffffffffc0201e04 <kfree+0xf2>
ffffffffc0201d74:	000aa797          	auipc	a5,0xaa
ffffffffc0201d78:	76478793          	addi	a5,a5,1892 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0201d7c:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201d7e:	000aa797          	auipc	a5,0xaa
ffffffffc0201d82:	6fa78793          	addi	a5,a5,1786 # ffffffffc02ac478 <npage>
ffffffffc0201d86:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0201d88:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0201d8a:	80b1                	srli	s1,s1,0xc
ffffffffc0201d8c:	08f4f963          	bleu	a5,s1,ffffffffc0201e1e <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d90:	00007797          	auipc	a5,0x7
ffffffffc0201d94:	f9078793          	addi	a5,a5,-112 # ffffffffc0208d20 <nbase>
ffffffffc0201d98:	639c                	ld	a5,0(a5)
ffffffffc0201d9a:	000aa697          	auipc	a3,0xaa
ffffffffc0201d9e:	74e68693          	addi	a3,a3,1870 # ffffffffc02ac4e8 <pages>
ffffffffc0201da2:	6288                	ld	a0,0(a3)
ffffffffc0201da4:	8c9d                	sub	s1,s1,a5
ffffffffc0201da6:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201da8:	4585                	li	a1,1
ffffffffc0201daa:	9526                	add	a0,a0,s1
ffffffffc0201dac:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201db0:	12a000ef          	jal	ra,ffffffffc0201eda <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db4:	8522                	mv	a0,s0
}
ffffffffc0201db6:	6442                	ld	s0,16(sp)
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbc:	45e1                	li	a1,24
}
ffffffffc0201dbe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dc0:	be5ff06f          	j	ffffffffc02019a4 <slob_free>
        intr_disable();
ffffffffc0201dc4:	897fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201dc8:	000aa797          	auipc	a5,0xaa
ffffffffc0201dcc:	6a078793          	addi	a5,a5,1696 # ffffffffc02ac468 <bigblocks>
ffffffffc0201dd0:	6394                	ld	a3,0(a5)
ffffffffc0201dd2:	c699                	beqz	a3,ffffffffc0201de0 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0201dd4:	669c                	ld	a5,8(a3)
ffffffffc0201dd6:	6a80                	ld	s0,16(a3)
ffffffffc0201dd8:	00f48763          	beq	s1,a5,ffffffffc0201de6 <kfree+0xd4>
        return 1;
ffffffffc0201ddc:	4605                	li	a2,1
ffffffffc0201dde:	b795                	j	ffffffffc0201d42 <kfree+0x30>
        intr_enable();
ffffffffc0201de0:	875fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201de4:	bf85                	j	ffffffffc0201d54 <kfree+0x42>
				*last = bb->next;
ffffffffc0201de6:	000aa797          	auipc	a5,0xaa
ffffffffc0201dea:	6887b123          	sd	s0,1666(a5) # ffffffffc02ac468 <bigblocks>
ffffffffc0201dee:	8436                	mv	s0,a3
ffffffffc0201df0:	865fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201df4:	bf9d                	j	ffffffffc0201d6a <kfree+0x58>
ffffffffc0201df6:	8082                	ret
ffffffffc0201df8:	000aa797          	auipc	a5,0xaa
ffffffffc0201dfc:	6687b823          	sd	s0,1648(a5) # ffffffffc02ac468 <bigblocks>
ffffffffc0201e00:	8436                	mv	s0,a3
ffffffffc0201e02:	b7a5                	j	ffffffffc0201d6a <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0201e04:	86a6                	mv	a3,s1
ffffffffc0201e06:	00005617          	auipc	a2,0x5
ffffffffc0201e0a:	5e260613          	addi	a2,a2,1506 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc0201e0e:	06e00593          	li	a1,110
ffffffffc0201e12:	00005517          	auipc	a0,0x5
ffffffffc0201e16:	5c650513          	addi	a0,a0,1478 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0201e1a:	e6afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201e1e:	00005617          	auipc	a2,0x5
ffffffffc0201e22:	5f260613          	addi	a2,a2,1522 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc0201e26:	06200593          	li	a1,98
ffffffffc0201e2a:	00005517          	auipc	a0,0x5
ffffffffc0201e2e:	5ae50513          	addi	a0,a0,1454 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0201e32:	e52fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e36 <pa2page.part.4>:
pa2page(uintptr_t pa) {
ffffffffc0201e36:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e38:	00005617          	auipc	a2,0x5
ffffffffc0201e3c:	5d860613          	addi	a2,a2,1496 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc0201e40:	06200593          	li	a1,98
ffffffffc0201e44:	00005517          	auipc	a0,0x5
ffffffffc0201e48:	59450513          	addi	a0,a0,1428 # ffffffffc02073d8 <default_pmm_manager+0x78>
pa2page(uintptr_t pa) {
ffffffffc0201e4c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e4e:	e36fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e52 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201e52:	715d                	addi	sp,sp,-80
ffffffffc0201e54:	e0a2                	sd	s0,64(sp)
ffffffffc0201e56:	fc26                	sd	s1,56(sp)
ffffffffc0201e58:	f84a                	sd	s2,48(sp)
ffffffffc0201e5a:	f44e                	sd	s3,40(sp)
ffffffffc0201e5c:	f052                	sd	s4,32(sp)
ffffffffc0201e5e:	ec56                	sd	s5,24(sp)
ffffffffc0201e60:	e486                	sd	ra,72(sp)
ffffffffc0201e62:	842a                	mv	s0,a0
ffffffffc0201e64:	000aa497          	auipc	s1,0xaa
ffffffffc0201e68:	66c48493          	addi	s1,s1,1644 # ffffffffc02ac4d0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e6c:	4985                	li	s3,1
ffffffffc0201e6e:	000aaa17          	auipc	s4,0xaa
ffffffffc0201e72:	61aa0a13          	addi	s4,s4,1562 # ffffffffc02ac488 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e76:	0005091b          	sext.w	s2,a0
ffffffffc0201e7a:	000aaa97          	auipc	s5,0xaa
ffffffffc0201e7e:	74ea8a93          	addi	s5,s5,1870 # ffffffffc02ac5c8 <check_mm_struct>
ffffffffc0201e82:	a00d                	j	ffffffffc0201ea4 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201e84:	609c                	ld	a5,0(s1)
ffffffffc0201e86:	6f9c                	ld	a5,24(a5)
ffffffffc0201e88:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e8a:	4601                	li	a2,0
ffffffffc0201e8c:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e8e:	ed0d                	bnez	a0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e90:	0289ec63          	bltu	s3,s0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e94:	000a2783          	lw	a5,0(s4)
ffffffffc0201e98:	2781                	sext.w	a5,a5
ffffffffc0201e9a:	c79d                	beqz	a5,ffffffffc0201ec8 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e9c:	000ab503          	ld	a0,0(s5)
ffffffffc0201ea0:	48d010ef          	jal	ra,ffffffffc0203b2c <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ea4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ea8:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201eaa:	8522                	mv	a0,s0
ffffffffc0201eac:	dfe1                	beqz	a5,ffffffffc0201e84 <alloc_pages+0x32>
        intr_disable();
ffffffffc0201eae:	facfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201eb2:	609c                	ld	a5,0(s1)
ffffffffc0201eb4:	8522                	mv	a0,s0
ffffffffc0201eb6:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb8:	9782                	jalr	a5
ffffffffc0201eba:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ebc:	f98fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201ec0:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0201ec2:	4601                	li	a2,0
ffffffffc0201ec4:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201ec6:	d569                	beqz	a0,ffffffffc0201e90 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201ec8:	60a6                	ld	ra,72(sp)
ffffffffc0201eca:	6406                	ld	s0,64(sp)
ffffffffc0201ecc:	74e2                	ld	s1,56(sp)
ffffffffc0201ece:	7942                	ld	s2,48(sp)
ffffffffc0201ed0:	79a2                	ld	s3,40(sp)
ffffffffc0201ed2:	7a02                	ld	s4,32(sp)
ffffffffc0201ed4:	6ae2                	ld	s5,24(sp)
ffffffffc0201ed6:	6161                	addi	sp,sp,80
ffffffffc0201ed8:	8082                	ret

ffffffffc0201eda <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201eda:	100027f3          	csrr	a5,sstatus
ffffffffc0201ede:	8b89                	andi	a5,a5,2
ffffffffc0201ee0:	eb89                	bnez	a5,ffffffffc0201ef2 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ee2:	000aa797          	auipc	a5,0xaa
ffffffffc0201ee6:	5ee78793          	addi	a5,a5,1518 # ffffffffc02ac4d0 <pmm_manager>
ffffffffc0201eea:	639c                	ld	a5,0(a5)
ffffffffc0201eec:	0207b303          	ld	t1,32(a5)
ffffffffc0201ef0:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201ef2:	1101                	addi	sp,sp,-32
ffffffffc0201ef4:	ec06                	sd	ra,24(sp)
ffffffffc0201ef6:	e822                	sd	s0,16(sp)
ffffffffc0201ef8:	e426                	sd	s1,8(sp)
ffffffffc0201efa:	842a                	mv	s0,a0
ffffffffc0201efc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201efe:	f5cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f02:	000aa797          	auipc	a5,0xaa
ffffffffc0201f06:	5ce78793          	addi	a5,a5,1486 # ffffffffc02ac4d0 <pmm_manager>
ffffffffc0201f0a:	639c                	ld	a5,0(a5)
ffffffffc0201f0c:	85a6                	mv	a1,s1
ffffffffc0201f0e:	8522                	mv	a0,s0
ffffffffc0201f10:	739c                	ld	a5,32(a5)
ffffffffc0201f12:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f14:	6442                	ld	s0,16(sp)
ffffffffc0201f16:	60e2                	ld	ra,24(sp)
ffffffffc0201f18:	64a2                	ld	s1,8(sp)
ffffffffc0201f1a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f1c:	f38fe06f          	j	ffffffffc0200654 <intr_enable>

ffffffffc0201f20 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f20:	100027f3          	csrr	a5,sstatus
ffffffffc0201f24:	8b89                	andi	a5,a5,2
ffffffffc0201f26:	eb89                	bnez	a5,ffffffffc0201f38 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	000aa797          	auipc	a5,0xaa
ffffffffc0201f2c:	5a878793          	addi	a5,a5,1448 # ffffffffc02ac4d0 <pmm_manager>
ffffffffc0201f30:	639c                	ld	a5,0(a5)
ffffffffc0201f32:	0287b303          	ld	t1,40(a5)
ffffffffc0201f36:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201f38:	1141                	addi	sp,sp,-16
ffffffffc0201f3a:	e406                	sd	ra,8(sp)
ffffffffc0201f3c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f3e:	f1cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f42:	000aa797          	auipc	a5,0xaa
ffffffffc0201f46:	58e78793          	addi	a5,a5,1422 # ffffffffc02ac4d0 <pmm_manager>
ffffffffc0201f4a:	639c                	ld	a5,0(a5)
ffffffffc0201f4c:	779c                	ld	a5,40(a5)
ffffffffc0201f4e:	9782                	jalr	a5
ffffffffc0201f50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f52:	f02fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f56:	8522                	mv	a0,s0
ffffffffc0201f58:	60a2                	ld	ra,8(sp)
ffffffffc0201f5a:	6402                	ld	s0,0(sp)
ffffffffc0201f5c:	0141                	addi	sp,sp,16
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f60:	7139                	addi	sp,sp,-64
ffffffffc0201f62:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f64:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201f68:	1ff4f493          	andi	s1,s1,511
ffffffffc0201f6c:	048e                	slli	s1,s1,0x3
ffffffffc0201f6e:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f70:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f72:	f04a                	sd	s2,32(sp)
ffffffffc0201f74:	ec4e                	sd	s3,24(sp)
ffffffffc0201f76:	e852                	sd	s4,16(sp)
ffffffffc0201f78:	fc06                	sd	ra,56(sp)
ffffffffc0201f7a:	f822                	sd	s0,48(sp)
ffffffffc0201f7c:	e456                	sd	s5,8(sp)
ffffffffc0201f7e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f80:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f84:	892e                	mv	s2,a1
ffffffffc0201f86:	8a32                	mv	s4,a2
ffffffffc0201f88:	000aa997          	auipc	s3,0xaa
ffffffffc0201f8c:	4f098993          	addi	s3,s3,1264 # ffffffffc02ac478 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f90:	e7bd                	bnez	a5,ffffffffc0201ffe <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201f92:	12060c63          	beqz	a2,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0201f96:	4505                	li	a0,1
ffffffffc0201f98:	ebbff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201f9c:	842a                	mv	s0,a0
ffffffffc0201f9e:	12050663          	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201fa2:	000aab17          	auipc	s6,0xaa
ffffffffc0201fa6:	546b0b13          	addi	s6,s6,1350 # ffffffffc02ac4e8 <pages>
ffffffffc0201faa:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc0201fae:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb0:	000aa997          	auipc	s3,0xaa
ffffffffc0201fb4:	4c898993          	addi	s3,s3,1224 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc0201fb8:	40a40533          	sub	a0,s0,a0
ffffffffc0201fbc:	00080ab7          	lui	s5,0x80
ffffffffc0201fc0:	8519                	srai	a0,a0,0x6
ffffffffc0201fc2:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201fc6:	c01c                	sw	a5,0(s0)
ffffffffc0201fc8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201fca:	9556                	add	a0,a0,s5
ffffffffc0201fcc:	83b1                	srli	a5,a5,0xc
ffffffffc0201fce:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd0:	0532                	slli	a0,a0,0xc
ffffffffc0201fd2:	14e7f363          	bleu	a4,a5,ffffffffc0202118 <get_pte+0x1b8>
ffffffffc0201fd6:	000aa797          	auipc	a5,0xaa
ffffffffc0201fda:	50278793          	addi	a5,a5,1282 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0201fde:	639c                	ld	a5,0(a5)
ffffffffc0201fe0:	6605                	lui	a2,0x1
ffffffffc0201fe2:	4581                	li	a1,0
ffffffffc0201fe4:	953e                	add	a0,a0,a5
ffffffffc0201fe6:	616040ef          	jal	ra,ffffffffc02065fc <memset>
    return page - pages + nbase;
ffffffffc0201fea:	000b3683          	ld	a3,0(s6)
ffffffffc0201fee:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ff2:	8699                	srai	a3,a3,0x6
ffffffffc0201ff4:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff6:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ffc:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ffe:	77fd                	lui	a5,0xfffff
ffffffffc0202000:	068a                	slli	a3,a3,0x2
ffffffffc0202002:	0009b703          	ld	a4,0(s3)
ffffffffc0202006:	8efd                	and	a3,a3,a5
ffffffffc0202008:	00c6d793          	srli	a5,a3,0xc
ffffffffc020200c:	0ce7f163          	bleu	a4,a5,ffffffffc02020ce <get_pte+0x16e>
ffffffffc0202010:	000aaa97          	auipc	s5,0xaa
ffffffffc0202014:	4c8a8a93          	addi	s5,s5,1224 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0202018:	000ab403          	ld	s0,0(s5)
ffffffffc020201c:	01595793          	srli	a5,s2,0x15
ffffffffc0202020:	1ff7f793          	andi	a5,a5,511
ffffffffc0202024:	96a2                	add	a3,a3,s0
ffffffffc0202026:	00379413          	slli	s0,a5,0x3
ffffffffc020202a:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc020202c:	6014                	ld	a3,0(s0)
ffffffffc020202e:	0016f793          	andi	a5,a3,1
ffffffffc0202032:	e3ad                	bnez	a5,ffffffffc0202094 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0202034:	080a0b63          	beqz	s4,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0202038:	4505                	li	a0,1
ffffffffc020203a:	e19ff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020203e:	84aa                	mv	s1,a0
ffffffffc0202040:	c549                	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0202042:	000aab17          	auipc	s6,0xaa
ffffffffc0202046:	4a6b0b13          	addi	s6,s6,1190 # ffffffffc02ac4e8 <pages>
ffffffffc020204a:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc020204e:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0202050:	00080a37          	lui	s4,0x80
ffffffffc0202054:	40a48533          	sub	a0,s1,a0
ffffffffc0202058:	8519                	srai	a0,a0,0x6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205a:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc020205e:	c09c                	sw	a5,0(s1)
ffffffffc0202060:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202062:	9552                	add	a0,a0,s4
ffffffffc0202064:	83b1                	srli	a5,a5,0xc
ffffffffc0202066:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202068:	0532                	slli	a0,a0,0xc
ffffffffc020206a:	08e7fa63          	bleu	a4,a5,ffffffffc02020fe <get_pte+0x19e>
ffffffffc020206e:	000ab783          	ld	a5,0(s5)
ffffffffc0202072:	6605                	lui	a2,0x1
ffffffffc0202074:	4581                	li	a1,0
ffffffffc0202076:	953e                	add	a0,a0,a5
ffffffffc0202078:	584040ef          	jal	ra,ffffffffc02065fc <memset>
    return page - pages + nbase;
ffffffffc020207c:	000b3683          	ld	a3,0(s6)
ffffffffc0202080:	40d486b3          	sub	a3,s1,a3
ffffffffc0202084:	8699                	srai	a3,a3,0x6
ffffffffc0202086:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202088:	06aa                	slli	a3,a3,0xa
ffffffffc020208a:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020208e:	e014                	sd	a3,0(s0)
ffffffffc0202090:	0009b703          	ld	a4,0(s3)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202094:	068a                	slli	a3,a3,0x2
ffffffffc0202096:	757d                	lui	a0,0xfffff
ffffffffc0202098:	8ee9                	and	a3,a3,a0
ffffffffc020209a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020209e:	04e7f463          	bleu	a4,a5,ffffffffc02020e6 <get_pte+0x186>
ffffffffc02020a2:	000ab503          	ld	a0,0(s5)
ffffffffc02020a6:	00c95793          	srli	a5,s2,0xc
ffffffffc02020aa:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ae:	96aa                	add	a3,a3,a0
ffffffffc02020b0:	00379513          	slli	a0,a5,0x3
ffffffffc02020b4:	9536                	add	a0,a0,a3
}
ffffffffc02020b6:	70e2                	ld	ra,56(sp)
ffffffffc02020b8:	7442                	ld	s0,48(sp)
ffffffffc02020ba:	74a2                	ld	s1,40(sp)
ffffffffc02020bc:	7902                	ld	s2,32(sp)
ffffffffc02020be:	69e2                	ld	s3,24(sp)
ffffffffc02020c0:	6a42                	ld	s4,16(sp)
ffffffffc02020c2:	6aa2                	ld	s5,8(sp)
ffffffffc02020c4:	6b02                	ld	s6,0(sp)
ffffffffc02020c6:	6121                	addi	sp,sp,64
ffffffffc02020c8:	8082                	ret
            return NULL;
ffffffffc02020ca:	4501                	li	a0,0
ffffffffc02020cc:	b7ed                	j	ffffffffc02020b6 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020ce:	00005617          	auipc	a2,0x5
ffffffffc02020d2:	2e260613          	addi	a2,a2,738 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc02020d6:	0e300593          	li	a1,227
ffffffffc02020da:	00005517          	auipc	a0,0x5
ffffffffc02020de:	3f650513          	addi	a0,a0,1014 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02020e2:	ba2fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020e6:	00005617          	auipc	a2,0x5
ffffffffc02020ea:	2ca60613          	addi	a2,a2,714 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc02020ee:	0ee00593          	li	a1,238
ffffffffc02020f2:	00005517          	auipc	a0,0x5
ffffffffc02020f6:	3de50513          	addi	a0,a0,990 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02020fa:	b8afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020fe:	86aa                	mv	a3,a0
ffffffffc0202100:	00005617          	auipc	a2,0x5
ffffffffc0202104:	2b060613          	addi	a2,a2,688 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202108:	0eb00593          	li	a1,235
ffffffffc020210c:	00005517          	auipc	a0,0x5
ffffffffc0202110:	3c450513          	addi	a0,a0,964 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202114:	b70fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202118:	86aa                	mv	a3,a0
ffffffffc020211a:	00005617          	auipc	a2,0x5
ffffffffc020211e:	29660613          	addi	a2,a2,662 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202122:	0df00593          	li	a1,223
ffffffffc0202126:	00005517          	auipc	a0,0x5
ffffffffc020212a:	3aa50513          	addi	a0,a0,938 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc020212e:	b56fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202132 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202132:	1141                	addi	sp,sp,-16
ffffffffc0202134:	e022                	sd	s0,0(sp)
ffffffffc0202136:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202138:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020213a:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020213c:	e25ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202140:	c011                	beqz	s0,ffffffffc0202144 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0202142:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202144:	c129                	beqz	a0,ffffffffc0202186 <get_page+0x54>
ffffffffc0202146:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202148:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020214a:	0017f713          	andi	a4,a5,1
ffffffffc020214e:	e709                	bnez	a4,ffffffffc0202158 <get_page+0x26>
}
ffffffffc0202150:	60a2                	ld	ra,8(sp)
ffffffffc0202152:	6402                	ld	s0,0(sp)
ffffffffc0202154:	0141                	addi	sp,sp,16
ffffffffc0202156:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202158:	000aa717          	auipc	a4,0xaa
ffffffffc020215c:	32070713          	addi	a4,a4,800 # ffffffffc02ac478 <npage>
ffffffffc0202160:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202162:	078a                	slli	a5,a5,0x2
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202166:	02e7f563          	bleu	a4,a5,ffffffffc0202190 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020216a:	000aa717          	auipc	a4,0xaa
ffffffffc020216e:	37e70713          	addi	a4,a4,894 # ffffffffc02ac4e8 <pages>
ffffffffc0202172:	6308                	ld	a0,0(a4)
ffffffffc0202174:	60a2                	ld	ra,8(sp)
ffffffffc0202176:	6402                	ld	s0,0(sp)
ffffffffc0202178:	fff80737          	lui	a4,0xfff80
ffffffffc020217c:	97ba                	add	a5,a5,a4
ffffffffc020217e:	079a                	slli	a5,a5,0x6
ffffffffc0202180:	953e                	add	a0,a0,a5
ffffffffc0202182:	0141                	addi	sp,sp,16
ffffffffc0202184:	8082                	ret
ffffffffc0202186:	60a2                	ld	ra,8(sp)
ffffffffc0202188:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc020218a:	4501                	li	a0,0
}
ffffffffc020218c:	0141                	addi	sp,sp,16
ffffffffc020218e:	8082                	ret
ffffffffc0202190:	ca7ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202194 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202194:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202196:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020219a:	ec86                	sd	ra,88(sp)
ffffffffc020219c:	e8a2                	sd	s0,80(sp)
ffffffffc020219e:	e4a6                	sd	s1,72(sp)
ffffffffc02021a0:	e0ca                	sd	s2,64(sp)
ffffffffc02021a2:	fc4e                	sd	s3,56(sp)
ffffffffc02021a4:	f852                	sd	s4,48(sp)
ffffffffc02021a6:	f456                	sd	s5,40(sp)
ffffffffc02021a8:	f05a                	sd	s6,32(sp)
ffffffffc02021aa:	ec5e                	sd	s7,24(sp)
ffffffffc02021ac:	e862                	sd	s8,16(sp)
ffffffffc02021ae:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021b0:	03479713          	slli	a4,a5,0x34
ffffffffc02021b4:	eb71                	bnez	a4,ffffffffc0202288 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc02021b6:	002007b7          	lui	a5,0x200
ffffffffc02021ba:	842e                	mv	s0,a1
ffffffffc02021bc:	0af5e663          	bltu	a1,a5,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c0:	8932                	mv	s2,a2
ffffffffc02021c2:	0ac5f363          	bleu	a2,a1,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c6:	4785                	li	a5,1
ffffffffc02021c8:	07fe                	slli	a5,a5,0x1f
ffffffffc02021ca:	08c7ef63          	bltu	a5,a2,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021ce:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021d0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02021d2:	000aac97          	auipc	s9,0xaa
ffffffffc02021d6:	2a6c8c93          	addi	s9,s9,678 # ffffffffc02ac478 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021da:	000aac17          	auipc	s8,0xaa
ffffffffc02021de:	30ec0c13          	addi	s8,s8,782 # ffffffffc02ac4e8 <pages>
ffffffffc02021e2:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021e6:	00200b37          	lui	s6,0x200
ffffffffc02021ea:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021ee:	4601                	li	a2,0
ffffffffc02021f0:	85a2                	mv	a1,s0
ffffffffc02021f2:	854e                	mv	a0,s3
ffffffffc02021f4:	d6dff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02021f8:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02021fa:	cd21                	beqz	a0,ffffffffc0202252 <unmap_range+0xbe>
        if (*ptep != 0) {
ffffffffc02021fc:	611c                	ld	a5,0(a0)
ffffffffc02021fe:	e38d                	bnez	a5,ffffffffc0202220 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc0202200:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202202:	ff2466e3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
}
ffffffffc0202206:	60e6                	ld	ra,88(sp)
ffffffffc0202208:	6446                	ld	s0,80(sp)
ffffffffc020220a:	64a6                	ld	s1,72(sp)
ffffffffc020220c:	6906                	ld	s2,64(sp)
ffffffffc020220e:	79e2                	ld	s3,56(sp)
ffffffffc0202210:	7a42                	ld	s4,48(sp)
ffffffffc0202212:	7aa2                	ld	s5,40(sp)
ffffffffc0202214:	7b02                	ld	s6,32(sp)
ffffffffc0202216:	6be2                	ld	s7,24(sp)
ffffffffc0202218:	6c42                	ld	s8,16(sp)
ffffffffc020221a:	6ca2                	ld	s9,8(sp)
ffffffffc020221c:	6125                	addi	sp,sp,96
ffffffffc020221e:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202220:	0017f713          	andi	a4,a5,1
ffffffffc0202224:	df71                	beqz	a4,ffffffffc0202200 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc0202226:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020222a:	078a                	slli	a5,a5,0x2
ffffffffc020222c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020222e:	06e7fd63          	bleu	a4,a5,ffffffffc02022a8 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc0202232:	000c3503          	ld	a0,0(s8)
ffffffffc0202236:	97de                	add	a5,a5,s7
ffffffffc0202238:	079a                	slli	a5,a5,0x6
ffffffffc020223a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020223c:	411c                	lw	a5,0(a0)
ffffffffc020223e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202242:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202244:	cf11                	beqz	a4,ffffffffc0202260 <unmap_range+0xcc>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202246:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020224a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020224e:	9452                	add	s0,s0,s4
ffffffffc0202250:	bf4d                	j	ffffffffc0202202 <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202252:	945a                	add	s0,s0,s6
ffffffffc0202254:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202258:	d45d                	beqz	s0,ffffffffc0202206 <unmap_range+0x72>
ffffffffc020225a:	f9246ae3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
ffffffffc020225e:	b765                	j	ffffffffc0202206 <unmap_range+0x72>
            free_page(page);
ffffffffc0202260:	4585                	li	a1,1
ffffffffc0202262:	c79ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202266:	b7c5                	j	ffffffffc0202246 <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc0202268:	00006697          	auipc	a3,0x6
ffffffffc020226c:	81068693          	addi	a3,a3,-2032 # ffffffffc0207a78 <default_pmm_manager+0x718>
ffffffffc0202270:	00005617          	auipc	a2,0x5
ffffffffc0202274:	9a860613          	addi	a2,a2,-1624 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202278:	11000593          	li	a1,272
ffffffffc020227c:	00005517          	auipc	a0,0x5
ffffffffc0202280:	25450513          	addi	a0,a0,596 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202284:	a00fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202288:	00005697          	auipc	a3,0x5
ffffffffc020228c:	7c068693          	addi	a3,a3,1984 # ffffffffc0207a48 <default_pmm_manager+0x6e8>
ffffffffc0202290:	00005617          	auipc	a2,0x5
ffffffffc0202294:	98860613          	addi	a2,a2,-1656 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202298:	10f00593          	li	a1,271
ffffffffc020229c:	00005517          	auipc	a0,0x5
ffffffffc02022a0:	23450513          	addi	a0,a0,564 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02022a4:	9e0fe0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02022a8:	b8fff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc02022ac <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022ac:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ae:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022b2:	fc86                	sd	ra,120(sp)
ffffffffc02022b4:	f8a2                	sd	s0,112(sp)
ffffffffc02022b6:	f4a6                	sd	s1,104(sp)
ffffffffc02022b8:	f0ca                	sd	s2,96(sp)
ffffffffc02022ba:	ecce                	sd	s3,88(sp)
ffffffffc02022bc:	e8d2                	sd	s4,80(sp)
ffffffffc02022be:	e4d6                	sd	s5,72(sp)
ffffffffc02022c0:	e0da                	sd	s6,64(sp)
ffffffffc02022c2:	fc5e                	sd	s7,56(sp)
ffffffffc02022c4:	f862                	sd	s8,48(sp)
ffffffffc02022c6:	f466                	sd	s9,40(sp)
ffffffffc02022c8:	f06a                	sd	s10,32(sp)
ffffffffc02022ca:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022cc:	03479713          	slli	a4,a5,0x34
ffffffffc02022d0:	1c071163          	bnez	a4,ffffffffc0202492 <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc02022d4:	002007b7          	lui	a5,0x200
ffffffffc02022d8:	20f5e563          	bltu	a1,a5,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022dc:	8b32                	mv	s6,a2
ffffffffc02022de:	20c5f263          	bleu	a2,a1,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022e2:	4785                	li	a5,1
ffffffffc02022e4:	07fe                	slli	a5,a5,0x1f
ffffffffc02022e6:	1ec7ee63          	bltu	a5,a2,ffffffffc02024e2 <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022ea:	c00009b7          	lui	s3,0xc0000
ffffffffc02022ee:	400007b7          	lui	a5,0x40000
ffffffffc02022f2:	0135f9b3          	and	s3,a1,s3
ffffffffc02022f6:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022f8:	c0000337          	lui	t1,0xc0000
ffffffffc02022fc:	00698933          	add	s2,s3,t1
ffffffffc0202300:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202304:	1ff97913          	andi	s2,s2,511
ffffffffc0202308:	8e2a                	mv	t3,a0
ffffffffc020230a:	090e                	slli	s2,s2,0x3
ffffffffc020230c:	9972                	add	s2,s2,t3
ffffffffc020230e:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202312:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc0202316:	5dfd                	li	s11,-1
        if (pde1&PTE_V){
ffffffffc0202318:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020231c:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc020231e:	000aad17          	auipc	s10,0xaa
ffffffffc0202322:	15ad0d13          	addi	s10,s10,346 # ffffffffc02ac478 <npage>
    return KADDR(page2pa(page));
ffffffffc0202326:	00cddd93          	srli	s11,s11,0xc
ffffffffc020232a:	000aa717          	auipc	a4,0xaa
ffffffffc020232e:	1ae70713          	addi	a4,a4,430 # ffffffffc02ac4d8 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc0202332:	000aae97          	auipc	t4,0xaa
ffffffffc0202336:	1b6e8e93          	addi	t4,t4,438 # ffffffffc02ac4e8 <pages>
        if (pde1&PTE_V){
ffffffffc020233a:	e79d                	bnez	a5,ffffffffc0202368 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc020233c:	12098963          	beqz	s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc0202340:	400007b7          	lui	a5,0x40000
ffffffffc0202344:	84ce                	mv	s1,s3
ffffffffc0202346:	97ce                	add	a5,a5,s3
ffffffffc0202348:	1369f363          	bleu	s6,s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc020234c:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020234e:	00698933          	add	s2,s3,t1
ffffffffc0202352:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202356:	1ff97913          	andi	s2,s2,511
ffffffffc020235a:	090e                	slli	s2,s2,0x3
ffffffffc020235c:	9972                	add	s2,s2,t3
ffffffffc020235e:	00093b83          	ld	s7,0(s2)
        if (pde1&PTE_V){
ffffffffc0202362:	001bf793          	andi	a5,s7,1
ffffffffc0202366:	dbf9                	beqz	a5,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202368:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020236c:	0b8a                	slli	s7,s7,0x2
ffffffffc020236e:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202372:	14fbfc63          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202376:	fff80ab7          	lui	s5,0xfff80
ffffffffc020237a:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc020237c:	000806b7          	lui	a3,0x80
ffffffffc0202380:	96d6                	add	a3,a3,s5
ffffffffc0202382:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc0202386:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc020238a:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020238c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020238e:	12f67263          	bleu	a5,a2,ffffffffc02024b2 <exit_range+0x206>
ffffffffc0202392:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc0202396:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202398:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc020239c:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc020239e:	00080837          	lui	a6,0x80
ffffffffc02023a2:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc02023a4:	00200c37          	lui	s8,0x200
ffffffffc02023a8:	a801                	j	ffffffffc02023b8 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc02023aa:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02023ac:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02023ae:	c0d9                	beqz	s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b0:	0934f263          	bleu	s3,s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b4:	0d64fc63          	bleu	s6,s1,ffffffffc020248c <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023b8:	0154d413          	srli	s0,s1,0x15
ffffffffc02023bc:	1ff47413          	andi	s0,s0,511
ffffffffc02023c0:	040e                	slli	s0,s0,0x3
ffffffffc02023c2:	9452                	add	s0,s0,s4
ffffffffc02023c4:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc02023c6:	0017f693          	andi	a3,a5,1
ffffffffc02023ca:	d2e5                	beqz	a3,ffffffffc02023aa <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc02023cc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023d0:	00279513          	slli	a0,a5,0x2
ffffffffc02023d4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023d6:	0eb57a63          	bleu	a1,a0,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023da:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc02023dc:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc02023e0:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc02023e4:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023e8:	0cb7f563          	bleu	a1,a5,ffffffffc02024b2 <exit_range+0x206>
ffffffffc02023ec:	631c                	ld	a5,0(a4)
ffffffffc02023ee:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023f0:	015685b3          	add	a1,a3,s5
                        if (pt[i]&PTE_V){
ffffffffc02023f4:	629c                	ld	a5,0(a3)
ffffffffc02023f6:	8b85                	andi	a5,a5,1
ffffffffc02023f8:	fbd5                	bnez	a5,ffffffffc02023ac <exit_range+0x100>
ffffffffc02023fa:	06a1                	addi	a3,a3,8
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023fc:	fed59ce3          	bne	a1,a3,ffffffffc02023f4 <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0202400:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc0202404:	4585                	li	a1,1
ffffffffc0202406:	e072                	sd	t3,0(sp)
ffffffffc0202408:	953e                	add	a0,a0,a5
ffffffffc020240a:	ad1ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                d0start += PTSIZE;
ffffffffc020240e:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202410:	00043023          	sd	zero,0(s0)
ffffffffc0202414:	000aae97          	auipc	t4,0xaa
ffffffffc0202418:	0d4e8e93          	addi	t4,t4,212 # ffffffffc02ac4e8 <pages>
ffffffffc020241c:	6e02                	ld	t3,0(sp)
ffffffffc020241e:	c0000337          	lui	t1,0xc0000
ffffffffc0202422:	fff808b7          	lui	a7,0xfff80
ffffffffc0202426:	00080837          	lui	a6,0x80
ffffffffc020242a:	000aa717          	auipc	a4,0xaa
ffffffffc020242e:	0ae70713          	addi	a4,a4,174 # ffffffffc02ac4d8 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202432:	fcbd                	bnez	s1,ffffffffc02023b0 <exit_range+0x104>
            if (free_pd0) {
ffffffffc0202434:	f00c84e3          	beqz	s9,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202438:	000d3783          	ld	a5,0(s10)
ffffffffc020243c:	e072                	sd	t3,0(sp)
ffffffffc020243e:	08fbf663          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202442:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc0202446:	67a2                	ld	a5,8(sp)
ffffffffc0202448:	4585                	li	a1,1
ffffffffc020244a:	953e                	add	a0,a0,a5
ffffffffc020244c:	a8fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202450:	00093023          	sd	zero,0(s2)
ffffffffc0202454:	000aa717          	auipc	a4,0xaa
ffffffffc0202458:	08470713          	addi	a4,a4,132 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc020245c:	c0000337          	lui	t1,0xc0000
ffffffffc0202460:	6e02                	ld	t3,0(sp)
ffffffffc0202462:	000aae97          	auipc	t4,0xaa
ffffffffc0202466:	086e8e93          	addi	t4,t4,134 # ffffffffc02ac4e8 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc020246a:	ec099be3          	bnez	s3,ffffffffc0202340 <exit_range+0x94>
}
ffffffffc020246e:	70e6                	ld	ra,120(sp)
ffffffffc0202470:	7446                	ld	s0,112(sp)
ffffffffc0202472:	74a6                	ld	s1,104(sp)
ffffffffc0202474:	7906                	ld	s2,96(sp)
ffffffffc0202476:	69e6                	ld	s3,88(sp)
ffffffffc0202478:	6a46                	ld	s4,80(sp)
ffffffffc020247a:	6aa6                	ld	s5,72(sp)
ffffffffc020247c:	6b06                	ld	s6,64(sp)
ffffffffc020247e:	7be2                	ld	s7,56(sp)
ffffffffc0202480:	7c42                	ld	s8,48(sp)
ffffffffc0202482:	7ca2                	ld	s9,40(sp)
ffffffffc0202484:	7d02                	ld	s10,32(sp)
ffffffffc0202486:	6de2                	ld	s11,24(sp)
ffffffffc0202488:	6109                	addi	sp,sp,128
ffffffffc020248a:	8082                	ret
            if (free_pd0) {
ffffffffc020248c:	ea0c8ae3          	beqz	s9,ffffffffc0202340 <exit_range+0x94>
ffffffffc0202490:	b765                	j	ffffffffc0202438 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202492:	00005697          	auipc	a3,0x5
ffffffffc0202496:	5b668693          	addi	a3,a3,1462 # ffffffffc0207a48 <default_pmm_manager+0x6e8>
ffffffffc020249a:	00004617          	auipc	a2,0x4
ffffffffc020249e:	77e60613          	addi	a2,a2,1918 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02024a2:	12000593          	li	a1,288
ffffffffc02024a6:	00005517          	auipc	a0,0x5
ffffffffc02024aa:	02a50513          	addi	a0,a0,42 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02024ae:	fd7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02024b2:	00005617          	auipc	a2,0x5
ffffffffc02024b6:	efe60613          	addi	a2,a2,-258 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc02024ba:	06900593          	li	a1,105
ffffffffc02024be:	00005517          	auipc	a0,0x5
ffffffffc02024c2:	f1a50513          	addi	a0,a0,-230 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02024c6:	fbffd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02024ca:	00005617          	auipc	a2,0x5
ffffffffc02024ce:	f4660613          	addi	a2,a2,-186 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc02024d2:	06200593          	li	a1,98
ffffffffc02024d6:	00005517          	auipc	a0,0x5
ffffffffc02024da:	f0250513          	addi	a0,a0,-254 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02024de:	fa7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024e2:	00005697          	auipc	a3,0x5
ffffffffc02024e6:	59668693          	addi	a3,a3,1430 # ffffffffc0207a78 <default_pmm_manager+0x718>
ffffffffc02024ea:	00004617          	auipc	a2,0x4
ffffffffc02024ee:	72e60613          	addi	a2,a2,1838 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02024f2:	12100593          	li	a1,289
ffffffffc02024f6:	00005517          	auipc	a0,0x5
ffffffffc02024fa:	fda50513          	addi	a0,a0,-38 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02024fe:	f87fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202502 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202502:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202504:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202506:	e426                	sd	s1,8(sp)
ffffffffc0202508:	ec06                	sd	ra,24(sp)
ffffffffc020250a:	e822                	sd	s0,16(sp)
ffffffffc020250c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020250e:	a53ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep != NULL) {
ffffffffc0202512:	c511                	beqz	a0,ffffffffc020251e <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202514:	611c                	ld	a5,0(a0)
ffffffffc0202516:	842a                	mv	s0,a0
ffffffffc0202518:	0017f713          	andi	a4,a5,1
ffffffffc020251c:	e711                	bnez	a4,ffffffffc0202528 <page_remove+0x26>
}
ffffffffc020251e:	60e2                	ld	ra,24(sp)
ffffffffc0202520:	6442                	ld	s0,16(sp)
ffffffffc0202522:	64a2                	ld	s1,8(sp)
ffffffffc0202524:	6105                	addi	sp,sp,32
ffffffffc0202526:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202528:	000aa717          	auipc	a4,0xaa
ffffffffc020252c:	f5070713          	addi	a4,a4,-176 # ffffffffc02ac478 <npage>
ffffffffc0202530:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202532:	078a                	slli	a5,a5,0x2
ffffffffc0202534:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202536:	02e7fe63          	bleu	a4,a5,ffffffffc0202572 <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc020253a:	000aa717          	auipc	a4,0xaa
ffffffffc020253e:	fae70713          	addi	a4,a4,-82 # ffffffffc02ac4e8 <pages>
ffffffffc0202542:	6308                	ld	a0,0(a4)
ffffffffc0202544:	fff80737          	lui	a4,0xfff80
ffffffffc0202548:	97ba                	add	a5,a5,a4
ffffffffc020254a:	079a                	slli	a5,a5,0x6
ffffffffc020254c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020254e:	411c                	lw	a5,0(a0)
ffffffffc0202550:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202554:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202556:	cb11                	beqz	a4,ffffffffc020256a <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202558:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020255c:	12048073          	sfence.vma	s1
}
ffffffffc0202560:	60e2                	ld	ra,24(sp)
ffffffffc0202562:	6442                	ld	s0,16(sp)
ffffffffc0202564:	64a2                	ld	s1,8(sp)
ffffffffc0202566:	6105                	addi	sp,sp,32
ffffffffc0202568:	8082                	ret
            free_page(page);
ffffffffc020256a:	4585                	li	a1,1
ffffffffc020256c:	96fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202570:	b7e5                	j	ffffffffc0202558 <page_remove+0x56>
ffffffffc0202572:	8c5ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202576 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202576:	7179                	addi	sp,sp,-48
ffffffffc0202578:	e44e                	sd	s3,8(sp)
ffffffffc020257a:	89b2                	mv	s3,a2
ffffffffc020257c:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020257e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202580:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202582:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202584:	ec26                	sd	s1,24(sp)
ffffffffc0202586:	f406                	sd	ra,40(sp)
ffffffffc0202588:	e84a                	sd	s2,16(sp)
ffffffffc020258a:	e052                	sd	s4,0(sp)
ffffffffc020258c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020258e:	9d3ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep == NULL) {
ffffffffc0202592:	cd49                	beqz	a0,ffffffffc020262c <page_insert+0xb6>
    page->ref += 1;
ffffffffc0202594:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0202596:	611c                	ld	a5,0(a0)
ffffffffc0202598:	892a                	mv	s2,a0
ffffffffc020259a:	0016871b          	addiw	a4,a3,1
ffffffffc020259e:	c018                	sw	a4,0(s0)
ffffffffc02025a0:	0017f713          	andi	a4,a5,1
ffffffffc02025a4:	ef05                	bnez	a4,ffffffffc02025dc <page_insert+0x66>
ffffffffc02025a6:	000aa797          	auipc	a5,0xaa
ffffffffc02025aa:	f4278793          	addi	a5,a5,-190 # ffffffffc02ac4e8 <pages>
ffffffffc02025ae:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc02025b0:	8c19                	sub	s0,s0,a4
ffffffffc02025b2:	000806b7          	lui	a3,0x80
ffffffffc02025b6:	8419                	srai	s0,s0,0x6
ffffffffc02025b8:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025ba:	042a                	slli	s0,s0,0xa
ffffffffc02025bc:	8c45                	or	s0,s0,s1
ffffffffc02025be:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02025c2:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c6:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02025ca:	4501                	li	a0,0
}
ffffffffc02025cc:	70a2                	ld	ra,40(sp)
ffffffffc02025ce:	7402                	ld	s0,32(sp)
ffffffffc02025d0:	64e2                	ld	s1,24(sp)
ffffffffc02025d2:	6942                	ld	s2,16(sp)
ffffffffc02025d4:	69a2                	ld	s3,8(sp)
ffffffffc02025d6:	6a02                	ld	s4,0(sp)
ffffffffc02025d8:	6145                	addi	sp,sp,48
ffffffffc02025da:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02025dc:	000aa717          	auipc	a4,0xaa
ffffffffc02025e0:	e9c70713          	addi	a4,a4,-356 # ffffffffc02ac478 <npage>
ffffffffc02025e4:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025e6:	078a                	slli	a5,a5,0x2
ffffffffc02025e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025ea:	04e7f363          	bleu	a4,a5,ffffffffc0202630 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ee:	000aaa17          	auipc	s4,0xaa
ffffffffc02025f2:	efaa0a13          	addi	s4,s4,-262 # ffffffffc02ac4e8 <pages>
ffffffffc02025f6:	000a3703          	ld	a4,0(s4)
ffffffffc02025fa:	fff80537          	lui	a0,0xfff80
ffffffffc02025fe:	953e                	add	a0,a0,a5
ffffffffc0202600:	051a                	slli	a0,a0,0x6
ffffffffc0202602:	953a                	add	a0,a0,a4
        if (p == page) {
ffffffffc0202604:	00a40a63          	beq	s0,a0,ffffffffc0202618 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0202608:	411c                	lw	a5,0(a0)
ffffffffc020260a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020260e:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0202610:	c691                	beqz	a3,ffffffffc020261c <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202612:	12098073          	sfence.vma	s3
ffffffffc0202616:	bf69                	j	ffffffffc02025b0 <page_insert+0x3a>
ffffffffc0202618:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020261a:	bf59                	j	ffffffffc02025b0 <page_insert+0x3a>
            free_page(page);
ffffffffc020261c:	4585                	li	a1,1
ffffffffc020261e:	8bdff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202622:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202626:	12098073          	sfence.vma	s3
ffffffffc020262a:	b759                	j	ffffffffc02025b0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020262c:	5571                	li	a0,-4
ffffffffc020262e:	bf79                	j	ffffffffc02025cc <page_insert+0x56>
ffffffffc0202630:	807ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202634 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202634:	00005797          	auipc	a5,0x5
ffffffffc0202638:	d2c78793          	addi	a5,a5,-724 # ffffffffc0207360 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020263c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020263e:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202640:	00005517          	auipc	a0,0x5
ffffffffc0202644:	eb850513          	addi	a0,a0,-328 # ffffffffc02074f8 <default_pmm_manager+0x198>
void pmm_init(void) {
ffffffffc0202648:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020264a:	000aa717          	auipc	a4,0xaa
ffffffffc020264e:	e8f73323          	sd	a5,-378(a4) # ffffffffc02ac4d0 <pmm_manager>
void pmm_init(void) {
ffffffffc0202652:	e0a2                	sd	s0,64(sp)
ffffffffc0202654:	fc26                	sd	s1,56(sp)
ffffffffc0202656:	f84a                	sd	s2,48(sp)
ffffffffc0202658:	f44e                	sd	s3,40(sp)
ffffffffc020265a:	f052                	sd	s4,32(sp)
ffffffffc020265c:	ec56                	sd	s5,24(sp)
ffffffffc020265e:	e85a                	sd	s6,16(sp)
ffffffffc0202660:	e45e                	sd	s7,8(sp)
ffffffffc0202662:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202664:	000aa417          	auipc	s0,0xaa
ffffffffc0202668:	e6c40413          	addi	s0,s0,-404 # ffffffffc02ac4d0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020266c:	b23fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pmm_manager->init();
ffffffffc0202670:	601c                	ld	a5,0(s0)
ffffffffc0202672:	000aa497          	auipc	s1,0xaa
ffffffffc0202676:	e0648493          	addi	s1,s1,-506 # ffffffffc02ac478 <npage>
ffffffffc020267a:	000aa917          	auipc	s2,0xaa
ffffffffc020267e:	e6e90913          	addi	s2,s2,-402 # ffffffffc02ac4e8 <pages>
ffffffffc0202682:	679c                	ld	a5,8(a5)
ffffffffc0202684:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202686:	57f5                	li	a5,-3
ffffffffc0202688:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020268a:	00005517          	auipc	a0,0x5
ffffffffc020268e:	e8650513          	addi	a0,a0,-378 # ffffffffc0207510 <default_pmm_manager+0x1b0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202692:	000aa717          	auipc	a4,0xaa
ffffffffc0202696:	e4f73323          	sd	a5,-442(a4) # ffffffffc02ac4d8 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020269a:	af5fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020269e:	46c5                	li	a3,17
ffffffffc02026a0:	06ee                	slli	a3,a3,0x1b
ffffffffc02026a2:	40100613          	li	a2,1025
ffffffffc02026a6:	16fd                	addi	a3,a3,-1
ffffffffc02026a8:	0656                	slli	a2,a2,0x15
ffffffffc02026aa:	07e005b7          	lui	a1,0x7e00
ffffffffc02026ae:	00005517          	auipc	a0,0x5
ffffffffc02026b2:	e7a50513          	addi	a0,a0,-390 # ffffffffc0207528 <default_pmm_manager+0x1c8>
ffffffffc02026b6:	ad9fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026ba:	777d                	lui	a4,0xfffff
ffffffffc02026bc:	000ab797          	auipc	a5,0xab
ffffffffc02026c0:	f2378793          	addi	a5,a5,-221 # ffffffffc02ad5df <end+0xfff>
ffffffffc02026c4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02026c6:	00088737          	lui	a4,0x88
ffffffffc02026ca:	000aa697          	auipc	a3,0xaa
ffffffffc02026ce:	dae6b723          	sd	a4,-594(a3) # ffffffffc02ac478 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d2:	000aa717          	auipc	a4,0xaa
ffffffffc02026d6:	e0f73b23          	sd	a5,-490(a4) # ffffffffc02ac4e8 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026da:	4701                	li	a4,0
ffffffffc02026dc:	4685                	li	a3,1
ffffffffc02026de:	fff80837          	lui	a6,0xfff80
ffffffffc02026e2:	a019                	j	ffffffffc02026e8 <pmm_init+0xb4>
ffffffffc02026e4:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc02026e8:	00671613          	slli	a2,a4,0x6
ffffffffc02026ec:	97b2                	add	a5,a5,a2
ffffffffc02026ee:	07a1                	addi	a5,a5,8
ffffffffc02026f0:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026f4:	6090                	ld	a2,0(s1)
ffffffffc02026f6:	0705                	addi	a4,a4,1
ffffffffc02026f8:	010607b3          	add	a5,a2,a6
ffffffffc02026fc:	fef764e3          	bltu	a4,a5,ffffffffc02026e4 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202700:	00093503          	ld	a0,0(s2)
ffffffffc0202704:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202708:	00661693          	slli	a3,a2,0x6
ffffffffc020270c:	97aa                	add	a5,a5,a0
ffffffffc020270e:	96be                	add	a3,a3,a5
ffffffffc0202710:	c02007b7          	lui	a5,0xc0200
ffffffffc0202714:	7af6ed63          	bltu	a3,a5,ffffffffc0202ece <pmm_init+0x89a>
ffffffffc0202718:	000aa997          	auipc	s3,0xaa
ffffffffc020271c:	dc098993          	addi	s3,s3,-576 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0202720:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202724:	47c5                	li	a5,17
ffffffffc0202726:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202728:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020272a:	02f6f763          	bleu	a5,a3,ffffffffc0202758 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020272e:	6585                	lui	a1,0x1
ffffffffc0202730:	15fd                	addi	a1,a1,-1
ffffffffc0202732:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc0202734:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202738:	48c77a63          	bleu	a2,a4,ffffffffc0202bcc <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc020273c:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273e:	75fd                	lui	a1,0xfffff
ffffffffc0202740:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc0202742:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc0202744:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202746:	40d786b3          	sub	a3,a5,a3
ffffffffc020274a:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020274c:	00c6d593          	srli	a1,a3,0xc
ffffffffc0202750:	953a                	add	a0,a0,a4
ffffffffc0202752:	9602                	jalr	a2
ffffffffc0202754:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202758:	00005517          	auipc	a0,0x5
ffffffffc020275c:	df850513          	addi	a0,a0,-520 # ffffffffc0207550 <default_pmm_manager+0x1f0>
ffffffffc0202760:	a2ffd0ef          	jal	ra,ffffffffc020018e <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202764:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202766:	000aa417          	auipc	s0,0xaa
ffffffffc020276a:	d0a40413          	addi	s0,s0,-758 # ffffffffc02ac470 <boot_pgdir>
    pmm_manager->check();
ffffffffc020276e:	7b9c                	ld	a5,48(a5)
ffffffffc0202770:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202772:	00005517          	auipc	a0,0x5
ffffffffc0202776:	df650513          	addi	a0,a0,-522 # ffffffffc0207568 <default_pmm_manager+0x208>
ffffffffc020277a:	a15fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020277e:	00009697          	auipc	a3,0x9
ffffffffc0202782:	88268693          	addi	a3,a3,-1918 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202786:	000aa797          	auipc	a5,0xaa
ffffffffc020278a:	ced7b523          	sd	a3,-790(a5) # ffffffffc02ac470 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020278e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202792:	10f6eae3          	bltu	a3,a5,ffffffffc02030a6 <pmm_init+0xa72>
ffffffffc0202796:	0009b783          	ld	a5,0(s3)
ffffffffc020279a:	8e9d                	sub	a3,a3,a5
ffffffffc020279c:	000aa797          	auipc	a5,0xaa
ffffffffc02027a0:	d4d7b223          	sd	a3,-700(a5) # ffffffffc02ac4e0 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc02027a4:	f7cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027a8:	6098                	ld	a4,0(s1)
ffffffffc02027aa:	c80007b7          	lui	a5,0xc8000
ffffffffc02027ae:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc02027b0:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027b2:	0ce7eae3          	bltu	a5,a4,ffffffffc0203086 <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02027b6:	6008                	ld	a0,0(s0)
ffffffffc02027b8:	44050463          	beqz	a0,ffffffffc0202c00 <pmm_init+0x5cc>
ffffffffc02027bc:	6785                	lui	a5,0x1
ffffffffc02027be:	17fd                	addi	a5,a5,-1
ffffffffc02027c0:	8fe9                	and	a5,a5,a0
ffffffffc02027c2:	2781                	sext.w	a5,a5
ffffffffc02027c4:	42079e63          	bnez	a5,ffffffffc0202c00 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02027c8:	4601                	li	a2,0
ffffffffc02027ca:	4581                	li	a1,0
ffffffffc02027cc:	967ff0ef          	jal	ra,ffffffffc0202132 <get_page>
ffffffffc02027d0:	78051b63          	bnez	a0,ffffffffc0202f66 <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02027d4:	4505                	li	a0,1
ffffffffc02027d6:	e7cff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02027da:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02027dc:	6008                	ld	a0,0(s0)
ffffffffc02027de:	4681                	li	a3,0
ffffffffc02027e0:	4601                	li	a2,0
ffffffffc02027e2:	85d6                	mv	a1,s5
ffffffffc02027e4:	d93ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02027e8:	7a051f63          	bnez	a0,ffffffffc0202fa6 <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02027ec:	6008                	ld	a0,0(s0)
ffffffffc02027ee:	4601                	li	a2,0
ffffffffc02027f0:	4581                	li	a1,0
ffffffffc02027f2:	f6eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02027f6:	78050863          	beqz	a0,ffffffffc0202f86 <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc02027fa:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027fc:	0017f713          	andi	a4,a5,1
ffffffffc0202800:	3e070463          	beqz	a4,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc0202804:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202806:	078a                	slli	a5,a5,0x2
ffffffffc0202808:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020280a:	3ce7f163          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020280e:	00093683          	ld	a3,0(s2)
ffffffffc0202812:	fff80637          	lui	a2,0xfff80
ffffffffc0202816:	97b2                	add	a5,a5,a2
ffffffffc0202818:	079a                	slli	a5,a5,0x6
ffffffffc020281a:	97b6                	add	a5,a5,a3
ffffffffc020281c:	72fa9563          	bne	s5,a5,ffffffffc0202f46 <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0202820:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc0202824:	4785                	li	a5,1
ffffffffc0202826:	70fb9063          	bne	s7,a5,ffffffffc0202f26 <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020282a:	6008                	ld	a0,0(s0)
ffffffffc020282c:	76fd                	lui	a3,0xfffff
ffffffffc020282e:	611c                	ld	a5,0(a0)
ffffffffc0202830:	078a                	slli	a5,a5,0x2
ffffffffc0202832:	8ff5                	and	a5,a5,a3
ffffffffc0202834:	00c7d613          	srli	a2,a5,0xc
ffffffffc0202838:	66e67e63          	bleu	a4,a2,ffffffffc0202eb4 <pmm_init+0x880>
ffffffffc020283c:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202840:	97e2                	add	a5,a5,s8
ffffffffc0202842:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc0202846:	0b0a                	slli	s6,s6,0x2
ffffffffc0202848:	00db7b33          	and	s6,s6,a3
ffffffffc020284c:	00cb5793          	srli	a5,s6,0xc
ffffffffc0202850:	56e7f863          	bleu	a4,a5,ffffffffc0202dc0 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202854:	4601                	li	a2,0
ffffffffc0202856:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202858:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020285a:	f06ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020285e:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202860:	55651063          	bne	a0,s6,ffffffffc0202da0 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc0202864:	4505                	li	a0,1
ffffffffc0202866:	decff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020286a:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020286c:	6008                	ld	a0,0(s0)
ffffffffc020286e:	46d1                	li	a3,20
ffffffffc0202870:	6605                	lui	a2,0x1
ffffffffc0202872:	85da                	mv	a1,s6
ffffffffc0202874:	d03ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202878:	50051463          	bnez	a0,ffffffffc0202d80 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020287c:	6008                	ld	a0,0(s0)
ffffffffc020287e:	4601                	li	a2,0
ffffffffc0202880:	6585                	lui	a1,0x1
ffffffffc0202882:	edeff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202886:	4c050d63          	beqz	a0,ffffffffc0202d60 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc020288a:	611c                	ld	a5,0(a0)
ffffffffc020288c:	0107f713          	andi	a4,a5,16
ffffffffc0202890:	4a070863          	beqz	a4,ffffffffc0202d40 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc0202894:	8b91                	andi	a5,a5,4
ffffffffc0202896:	48078563          	beqz	a5,ffffffffc0202d20 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020289a:	6008                	ld	a0,0(s0)
ffffffffc020289c:	611c                	ld	a5,0(a0)
ffffffffc020289e:	8bc1                	andi	a5,a5,16
ffffffffc02028a0:	46078063          	beqz	a5,ffffffffc0202d00 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc02028a4:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
ffffffffc02028a8:	43779c63          	bne	a5,s7,ffffffffc0202ce0 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02028ac:	4681                	li	a3,0
ffffffffc02028ae:	6605                	lui	a2,0x1
ffffffffc02028b0:	85d6                	mv	a1,s5
ffffffffc02028b2:	cc5ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02028b6:	40051563          	bnez	a0,ffffffffc0202cc0 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc02028ba:	000aa703          	lw	a4,0(s5)
ffffffffc02028be:	4789                	li	a5,2
ffffffffc02028c0:	3ef71063          	bne	a4,a5,ffffffffc0202ca0 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc02028c4:	000b2783          	lw	a5,0(s6)
ffffffffc02028c8:	3a079c63          	bnez	a5,ffffffffc0202c80 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02028cc:	6008                	ld	a0,0(s0)
ffffffffc02028ce:	4601                	li	a2,0
ffffffffc02028d0:	6585                	lui	a1,0x1
ffffffffc02028d2:	e8eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02028d6:	38050563          	beqz	a0,ffffffffc0202c60 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc02028da:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02028dc:	00177793          	andi	a5,a4,1
ffffffffc02028e0:	30078463          	beqz	a5,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc02028e4:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e6:	00271793          	slli	a5,a4,0x2
ffffffffc02028ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028ec:	2ed7f063          	bleu	a3,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02028f0:	00093683          	ld	a3,0(s2)
ffffffffc02028f4:	fff80637          	lui	a2,0xfff80
ffffffffc02028f8:	97b2                	add	a5,a5,a2
ffffffffc02028fa:	079a                	slli	a5,a5,0x6
ffffffffc02028fc:	97b6                	add	a5,a5,a3
ffffffffc02028fe:	32fa9163          	bne	s5,a5,ffffffffc0202c20 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202902:	8b41                	andi	a4,a4,16
ffffffffc0202904:	70071163          	bnez	a4,ffffffffc0203006 <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202908:	6008                	ld	a0,0(s0)
ffffffffc020290a:	4581                	li	a1,0
ffffffffc020290c:	bf7ff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202910:	000aa703          	lw	a4,0(s5)
ffffffffc0202914:	4785                	li	a5,1
ffffffffc0202916:	6cf71863          	bne	a4,a5,ffffffffc0202fe6 <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc020291a:	000b2783          	lw	a5,0(s6)
ffffffffc020291e:	6a079463          	bnez	a5,ffffffffc0202fc6 <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202922:	6008                	ld	a0,0(s0)
ffffffffc0202924:	6585                	lui	a1,0x1
ffffffffc0202926:	bddff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020292a:	000aa783          	lw	a5,0(s5)
ffffffffc020292e:	50079363          	bnez	a5,ffffffffc0202e34 <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc0202932:	000b2783          	lw	a5,0(s6)
ffffffffc0202936:	4c079f63          	bnez	a5,ffffffffc0202e14 <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020293a:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020293e:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202940:	000ab783          	ld	a5,0(s5)
ffffffffc0202944:	078a                	slli	a5,a5,0x2
ffffffffc0202946:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202948:	28c7f263          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020294c:	fff80737          	lui	a4,0xfff80
ffffffffc0202950:	00093503          	ld	a0,0(s2)
ffffffffc0202954:	97ba                	add	a5,a5,a4
ffffffffc0202956:	079a                	slli	a5,a5,0x6
ffffffffc0202958:	00f50733          	add	a4,a0,a5
ffffffffc020295c:	4314                	lw	a3,0(a4)
ffffffffc020295e:	4705                	li	a4,1
ffffffffc0202960:	48e69a63          	bne	a3,a4,ffffffffc0202df4 <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc0202964:	8799                	srai	a5,a5,0x6
ffffffffc0202966:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020296a:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc020296c:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020296e:	8331                	srli	a4,a4,0xc
ffffffffc0202970:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202972:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202974:	46c77363          	bleu	a2,a4,ffffffffc0202dda <pmm_init+0x7a6>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202978:	0009b683          	ld	a3,0(s3)
ffffffffc020297c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc020297e:	639c                	ld	a5,0(a5)
ffffffffc0202980:	078a                	slli	a5,a5,0x2
ffffffffc0202982:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202984:	24c7f463          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202988:	416787b3          	sub	a5,a5,s6
ffffffffc020298c:	079a                	slli	a5,a5,0x6
ffffffffc020298e:	953e                	add	a0,a0,a5
ffffffffc0202990:	4585                	li	a1,1
ffffffffc0202992:	d48ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202996:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020299a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020299c:	078a                	slli	a5,a5,0x2
ffffffffc020299e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02029a0:	22e7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	416787b3          	sub	a5,a5,s6
ffffffffc02029ac:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02029ae:	953e                	add	a0,a0,a5
ffffffffc02029b0:	4585                	li	a1,1
ffffffffc02029b2:	d28ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02029b6:	601c                	ld	a5,0(s0)
ffffffffc02029b8:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02029bc:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02029c0:	d60ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc02029c4:	68aa1163          	bne	s4,a0,ffffffffc0203046 <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029c8:	00005517          	auipc	a0,0x5
ffffffffc02029cc:	eb050513          	addi	a0,a0,-336 # ffffffffc0207878 <default_pmm_manager+0x518>
ffffffffc02029d0:	fbefd0ef          	jal	ra,ffffffffc020018e <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc02029d4:	d4cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029d8:	6098                	ld	a4,0(s1)
ffffffffc02029da:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc02029de:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029e0:	00c71693          	slli	a3,a4,0xc
ffffffffc02029e4:	18d7f563          	bleu	a3,a5,ffffffffc0202b6e <pmm_init+0x53a>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029e8:	83b1                	srli	a5,a5,0xc
ffffffffc02029ea:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029ec:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029f0:	1ae7f163          	bleu	a4,a5,ffffffffc0202b92 <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02029f4:	7bfd                	lui	s7,0xfffff
ffffffffc02029f6:	6b05                	lui	s6,0x1
ffffffffc02029f8:	a029                	j	ffffffffc0202a02 <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029fa:	00cad713          	srli	a4,s5,0xc
ffffffffc02029fe:	18f77a63          	bleu	a5,a4,ffffffffc0202b92 <pmm_init+0x55e>
ffffffffc0202a02:	0009b583          	ld	a1,0(s3)
ffffffffc0202a06:	4601                	li	a2,0
ffffffffc0202a08:	95d6                	add	a1,a1,s5
ffffffffc0202a0a:	d56ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202a0e:	16050263          	beqz	a0,ffffffffc0202b72 <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a12:	611c                	ld	a5,0(a0)
ffffffffc0202a14:	078a                	slli	a5,a5,0x2
ffffffffc0202a16:	0177f7b3          	and	a5,a5,s7
ffffffffc0202a1a:	19579963          	bne	a5,s5,ffffffffc0202bac <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202a1e:	609c                	ld	a5,0(s1)
ffffffffc0202a20:	9ada                	add	s5,s5,s6
ffffffffc0202a22:	6008                	ld	a0,0(s0)
ffffffffc0202a24:	00c79713          	slli	a4,a5,0xc
ffffffffc0202a28:	fceae9e3          	bltu	s5,a4,ffffffffc02029fa <pmm_init+0x3c6>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0202a2c:	611c                	ld	a5,0(a0)
ffffffffc0202a2e:	62079c63          	bnez	a5,ffffffffc0203066 <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0202a32:	4505                	li	a0,1
ffffffffc0202a34:	c1eff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0202a38:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a3a:	6008                	ld	a0,0(s0)
ffffffffc0202a3c:	4699                	li	a3,6
ffffffffc0202a3e:	10000613          	li	a2,256
ffffffffc0202a42:	85d6                	mv	a1,s5
ffffffffc0202a44:	b33ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a48:	1e051c63          	bnez	a0,ffffffffc0202c40 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0202a4c:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0202a50:	4785                	li	a5,1
ffffffffc0202a52:	44f71163          	bne	a4,a5,ffffffffc0202e94 <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a56:	6008                	ld	a0,0(s0)
ffffffffc0202a58:	6b05                	lui	s6,0x1
ffffffffc0202a5a:	4699                	li	a3,6
ffffffffc0202a5c:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8470>
ffffffffc0202a60:	85d6                	mv	a1,s5
ffffffffc0202a62:	b15ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a66:	40051763          	bnez	a0,ffffffffc0202e74 <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0202a6a:	000aa703          	lw	a4,0(s5)
ffffffffc0202a6e:	4789                	li	a5,2
ffffffffc0202a70:	3ef71263          	bne	a4,a5,ffffffffc0202e54 <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202a74:	00005597          	auipc	a1,0x5
ffffffffc0202a78:	f3c58593          	addi	a1,a1,-196 # ffffffffc02079b0 <default_pmm_manager+0x650>
ffffffffc0202a7c:	10000513          	li	a0,256
ffffffffc0202a80:	323030ef          	jal	ra,ffffffffc02065a2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a84:	100b0593          	addi	a1,s6,256
ffffffffc0202a88:	10000513          	li	a0,256
ffffffffc0202a8c:	329030ef          	jal	ra,ffffffffc02065b4 <strcmp>
ffffffffc0202a90:	44051b63          	bnez	a0,ffffffffc0202ee6 <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0202a94:	00093683          	ld	a3,0(s2)
ffffffffc0202a98:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202a9c:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0202a9e:	40da86b3          	sub	a3,s5,a3
ffffffffc0202aa2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202aa4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202aa6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202aa8:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0202aac:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ab0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab2:	10f77f63          	bleu	a5,a4,ffffffffc0202bd0 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ab6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202aba:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202abe:	96be                	add	a3,a3,a5
ffffffffc0202ac0:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd52b20>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ac4:	29b030ef          	jal	ra,ffffffffc020655e <strlen>
ffffffffc0202ac8:	54051f63          	bnez	a0,ffffffffc0203026 <pmm_init+0x9f2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202acc:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202ad0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ad2:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd52a20>
ffffffffc0202ad6:	068a                	slli	a3,a3,0x2
ffffffffc0202ad8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ada:	0ef6f963          	bleu	a5,a3,ffffffffc0202bcc <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0202ade:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ae2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ae4:	0efb7663          	bleu	a5,s6,ffffffffc0202bd0 <pmm_init+0x59c>
ffffffffc0202ae8:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202aec:	4585                	li	a1,1
ffffffffc0202aee:	8556                	mv	a0,s5
ffffffffc0202af0:	99b6                	add	s3,s3,a3
ffffffffc0202af2:	be8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202af6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202afa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afc:	078a                	slli	a5,a5,0x2
ffffffffc0202afe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b00:	0ce7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b04:	00093503          	ld	a0,0(s2)
ffffffffc0202b08:	fff809b7          	lui	s3,0xfff80
ffffffffc0202b0c:	97ce                	add	a5,a5,s3
ffffffffc0202b0e:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202b10:	953e                	add	a0,a0,a5
ffffffffc0202b12:	4585                	li	a1,1
ffffffffc0202b14:	bc6ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b18:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0202b1c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	078a                	slli	a5,a5,0x2
ffffffffc0202b20:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b22:	0ae7f563          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b26:	00093503          	ld	a0,0(s2)
ffffffffc0202b2a:	97ce                	add	a5,a5,s3
ffffffffc0202b2c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202b2e:	953e                	add	a0,a0,a5
ffffffffc0202b30:	4585                	li	a1,1
ffffffffc0202b32:	ba8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0202b36:	601c                	ld	a5,0(s0)
ffffffffc0202b38:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0202b3c:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202b40:	be0ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0202b44:	3caa1163          	bne	s4,a0,ffffffffc0202f06 <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202b48:	00005517          	auipc	a0,0x5
ffffffffc0202b4c:	ee050513          	addi	a0,a0,-288 # ffffffffc0207a28 <default_pmm_manager+0x6c8>
ffffffffc0202b50:	e3efd0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0202b54:	6406                	ld	s0,64(sp)
ffffffffc0202b56:	60a6                	ld	ra,72(sp)
ffffffffc0202b58:	74e2                	ld	s1,56(sp)
ffffffffc0202b5a:	7942                	ld	s2,48(sp)
ffffffffc0202b5c:	79a2                	ld	s3,40(sp)
ffffffffc0202b5e:	7a02                	ld	s4,32(sp)
ffffffffc0202b60:	6ae2                	ld	s5,24(sp)
ffffffffc0202b62:	6b42                	ld	s6,16(sp)
ffffffffc0202b64:	6ba2                	ld	s7,8(sp)
ffffffffc0202b66:	6c02                	ld	s8,0(sp)
ffffffffc0202b68:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0202b6a:	8c8ff06f          	j	ffffffffc0201c32 <kmalloc_init>
ffffffffc0202b6e:	6008                	ld	a0,0(s0)
ffffffffc0202b70:	bd75                	j	ffffffffc0202a2c <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b72:	00005697          	auipc	a3,0x5
ffffffffc0202b76:	d2668693          	addi	a3,a3,-730 # ffffffffc0207898 <default_pmm_manager+0x538>
ffffffffc0202b7a:	00004617          	auipc	a2,0x4
ffffffffc0202b7e:	09e60613          	addi	a2,a2,158 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202b82:	22700593          	li	a1,551
ffffffffc0202b86:	00005517          	auipc	a0,0x5
ffffffffc0202b8a:	94a50513          	addi	a0,a0,-1718 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202b8e:	8f7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202b92:	86d6                	mv	a3,s5
ffffffffc0202b94:	00005617          	auipc	a2,0x5
ffffffffc0202b98:	81c60613          	addi	a2,a2,-2020 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202b9c:	22700593          	li	a1,551
ffffffffc0202ba0:	00005517          	auipc	a0,0x5
ffffffffc0202ba4:	93050513          	addi	a0,a0,-1744 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202ba8:	8ddfd0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bac:	00005697          	auipc	a3,0x5
ffffffffc0202bb0:	d2c68693          	addi	a3,a3,-724 # ffffffffc02078d8 <default_pmm_manager+0x578>
ffffffffc0202bb4:	00004617          	auipc	a2,0x4
ffffffffc0202bb8:	06460613          	addi	a2,a2,100 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202bbc:	22800593          	li	a1,552
ffffffffc0202bc0:	00005517          	auipc	a0,0x5
ffffffffc0202bc4:	91050513          	addi	a0,a0,-1776 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202bc8:	8bdfd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202bcc:	a6aff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0202bd0:	00004617          	auipc	a2,0x4
ffffffffc0202bd4:	7e060613          	addi	a2,a2,2016 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202bd8:	06900593          	li	a1,105
ffffffffc0202bdc:	00004517          	auipc	a0,0x4
ffffffffc0202be0:	7fc50513          	addi	a0,a0,2044 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0202be4:	8a1fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202be8:	00005617          	auipc	a2,0x5
ffffffffc0202bec:	a8060613          	addi	a2,a2,-1408 # ffffffffc0207668 <default_pmm_manager+0x308>
ffffffffc0202bf0:	07400593          	li	a1,116
ffffffffc0202bf4:	00004517          	auipc	a0,0x4
ffffffffc0202bf8:	7e450513          	addi	a0,a0,2020 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0202bfc:	889fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c00:	00005697          	auipc	a3,0x5
ffffffffc0202c04:	9a868693          	addi	a3,a3,-1624 # ffffffffc02075a8 <default_pmm_manager+0x248>
ffffffffc0202c08:	00004617          	auipc	a2,0x4
ffffffffc0202c0c:	01060613          	addi	a2,a2,16 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202c10:	1eb00593          	li	a1,491
ffffffffc0202c14:	00005517          	auipc	a0,0x5
ffffffffc0202c18:	8bc50513          	addi	a0,a0,-1860 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202c1c:	869fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c20:	00005697          	auipc	a3,0x5
ffffffffc0202c24:	a7068693          	addi	a3,a3,-1424 # ffffffffc0207690 <default_pmm_manager+0x330>
ffffffffc0202c28:	00004617          	auipc	a2,0x4
ffffffffc0202c2c:	ff060613          	addi	a2,a2,-16 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202c30:	20700593          	li	a1,519
ffffffffc0202c34:	00005517          	auipc	a0,0x5
ffffffffc0202c38:	89c50513          	addi	a0,a0,-1892 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202c3c:	849fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c40:	00005697          	auipc	a3,0x5
ffffffffc0202c44:	cc868693          	addi	a3,a3,-824 # ffffffffc0207908 <default_pmm_manager+0x5a8>
ffffffffc0202c48:	00004617          	auipc	a2,0x4
ffffffffc0202c4c:	fd060613          	addi	a2,a2,-48 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202c50:	23000593          	li	a1,560
ffffffffc0202c54:	00005517          	auipc	a0,0x5
ffffffffc0202c58:	87c50513          	addi	a0,a0,-1924 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202c5c:	829fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202c60:	00005697          	auipc	a3,0x5
ffffffffc0202c64:	ac068693          	addi	a3,a3,-1344 # ffffffffc0207720 <default_pmm_manager+0x3c0>
ffffffffc0202c68:	00004617          	auipc	a2,0x4
ffffffffc0202c6c:	fb060613          	addi	a2,a2,-80 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202c70:	20600593          	li	a1,518
ffffffffc0202c74:	00005517          	auipc	a0,0x5
ffffffffc0202c78:	85c50513          	addi	a0,a0,-1956 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202c7c:	809fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202c80:	00005697          	auipc	a3,0x5
ffffffffc0202c84:	b6868693          	addi	a3,a3,-1176 # ffffffffc02077e8 <default_pmm_manager+0x488>
ffffffffc0202c88:	00004617          	auipc	a2,0x4
ffffffffc0202c8c:	f9060613          	addi	a2,a2,-112 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202c90:	20500593          	li	a1,517
ffffffffc0202c94:	00005517          	auipc	a0,0x5
ffffffffc0202c98:	83c50513          	addi	a0,a0,-1988 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202c9c:	fe8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202ca0:	00005697          	auipc	a3,0x5
ffffffffc0202ca4:	b3068693          	addi	a3,a3,-1232 # ffffffffc02077d0 <default_pmm_manager+0x470>
ffffffffc0202ca8:	00004617          	auipc	a2,0x4
ffffffffc0202cac:	f7060613          	addi	a2,a2,-144 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202cb0:	20400593          	li	a1,516
ffffffffc0202cb4:	00005517          	auipc	a0,0x5
ffffffffc0202cb8:	81c50513          	addi	a0,a0,-2020 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202cbc:	fc8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202cc0:	00005697          	auipc	a3,0x5
ffffffffc0202cc4:	ae068693          	addi	a3,a3,-1312 # ffffffffc02077a0 <default_pmm_manager+0x440>
ffffffffc0202cc8:	00004617          	auipc	a2,0x4
ffffffffc0202ccc:	f5060613          	addi	a2,a2,-176 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202cd0:	20300593          	li	a1,515
ffffffffc0202cd4:	00004517          	auipc	a0,0x4
ffffffffc0202cd8:	7fc50513          	addi	a0,a0,2044 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202cdc:	fa8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202ce0:	00005697          	auipc	a3,0x5
ffffffffc0202ce4:	aa868693          	addi	a3,a3,-1368 # ffffffffc0207788 <default_pmm_manager+0x428>
ffffffffc0202ce8:	00004617          	auipc	a2,0x4
ffffffffc0202cec:	f3060613          	addi	a2,a2,-208 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202cf0:	20100593          	li	a1,513
ffffffffc0202cf4:	00004517          	auipc	a0,0x4
ffffffffc0202cf8:	7dc50513          	addi	a0,a0,2012 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202cfc:	f88fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202d00:	00005697          	auipc	a3,0x5
ffffffffc0202d04:	a7068693          	addi	a3,a3,-1424 # ffffffffc0207770 <default_pmm_manager+0x410>
ffffffffc0202d08:	00004617          	auipc	a2,0x4
ffffffffc0202d0c:	f1060613          	addi	a2,a2,-240 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202d10:	20000593          	li	a1,512
ffffffffc0202d14:	00004517          	auipc	a0,0x4
ffffffffc0202d18:	7bc50513          	addi	a0,a0,1980 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202d1c:	f68fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202d20:	00005697          	auipc	a3,0x5
ffffffffc0202d24:	a4068693          	addi	a3,a3,-1472 # ffffffffc0207760 <default_pmm_manager+0x400>
ffffffffc0202d28:	00004617          	auipc	a2,0x4
ffffffffc0202d2c:	ef060613          	addi	a2,a2,-272 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202d30:	1ff00593          	li	a1,511
ffffffffc0202d34:	00004517          	auipc	a0,0x4
ffffffffc0202d38:	79c50513          	addi	a0,a0,1948 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202d3c:	f48fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202d40:	00005697          	auipc	a3,0x5
ffffffffc0202d44:	a1068693          	addi	a3,a3,-1520 # ffffffffc0207750 <default_pmm_manager+0x3f0>
ffffffffc0202d48:	00004617          	auipc	a2,0x4
ffffffffc0202d4c:	ed060613          	addi	a2,a2,-304 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202d50:	1fe00593          	li	a1,510
ffffffffc0202d54:	00004517          	auipc	a0,0x4
ffffffffc0202d58:	77c50513          	addi	a0,a0,1916 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202d5c:	f28fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d60:	00005697          	auipc	a3,0x5
ffffffffc0202d64:	9c068693          	addi	a3,a3,-1600 # ffffffffc0207720 <default_pmm_manager+0x3c0>
ffffffffc0202d68:	00004617          	auipc	a2,0x4
ffffffffc0202d6c:	eb060613          	addi	a2,a2,-336 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202d70:	1fd00593          	li	a1,509
ffffffffc0202d74:	00004517          	auipc	a0,0x4
ffffffffc0202d78:	75c50513          	addi	a0,a0,1884 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202d7c:	f08fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d80:	00005697          	auipc	a3,0x5
ffffffffc0202d84:	96868693          	addi	a3,a3,-1688 # ffffffffc02076e8 <default_pmm_manager+0x388>
ffffffffc0202d88:	00004617          	auipc	a2,0x4
ffffffffc0202d8c:	e9060613          	addi	a2,a2,-368 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202d90:	1fc00593          	li	a1,508
ffffffffc0202d94:	00004517          	auipc	a0,0x4
ffffffffc0202d98:	73c50513          	addi	a0,a0,1852 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202d9c:	ee8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202da0:	00005697          	auipc	a3,0x5
ffffffffc0202da4:	92068693          	addi	a3,a3,-1760 # ffffffffc02076c0 <default_pmm_manager+0x360>
ffffffffc0202da8:	00004617          	auipc	a2,0x4
ffffffffc0202dac:	e7060613          	addi	a2,a2,-400 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202db0:	1f900593          	li	a1,505
ffffffffc0202db4:	00004517          	auipc	a0,0x4
ffffffffc0202db8:	71c50513          	addi	a0,a0,1820 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202dbc:	ec8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202dc0:	86da                	mv	a3,s6
ffffffffc0202dc2:	00004617          	auipc	a2,0x4
ffffffffc0202dc6:	5ee60613          	addi	a2,a2,1518 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202dca:	1f800593          	li	a1,504
ffffffffc0202dce:	00004517          	auipc	a0,0x4
ffffffffc0202dd2:	70250513          	addi	a0,a0,1794 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202dd6:	eaefd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202dda:	86be                	mv	a3,a5
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	5d460613          	addi	a2,a2,1492 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202de4:	06900593          	li	a1,105
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	5f050513          	addi	a0,a0,1520 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0202df0:	e94fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202df4:	00005697          	auipc	a3,0x5
ffffffffc0202df8:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0207830 <default_pmm_manager+0x4d0>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202e04:	21200593          	li	a1,530
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	6c850513          	addi	a0,a0,1736 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202e10:	e74fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e14:	00005697          	auipc	a3,0x5
ffffffffc0202e18:	9d468693          	addi	a3,a3,-1580 # ffffffffc02077e8 <default_pmm_manager+0x488>
ffffffffc0202e1c:	00004617          	auipc	a2,0x4
ffffffffc0202e20:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202e24:	21000593          	li	a1,528
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	6a850513          	addi	a0,a0,1704 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202e30:	e54fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e34:	00005697          	auipc	a3,0x5
ffffffffc0202e38:	9e468693          	addi	a3,a3,-1564 # ffffffffc0207818 <default_pmm_manager+0x4b8>
ffffffffc0202e3c:	00004617          	auipc	a2,0x4
ffffffffc0202e40:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202e44:	20f00593          	li	a1,527
ffffffffc0202e48:	00004517          	auipc	a0,0x4
ffffffffc0202e4c:	68850513          	addi	a0,a0,1672 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202e50:	e34fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202e54:	00005697          	auipc	a3,0x5
ffffffffc0202e58:	b4468693          	addi	a3,a3,-1212 # ffffffffc0207998 <default_pmm_manager+0x638>
ffffffffc0202e5c:	00004617          	auipc	a2,0x4
ffffffffc0202e60:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202e64:	23300593          	li	a1,563
ffffffffc0202e68:	00004517          	auipc	a0,0x4
ffffffffc0202e6c:	66850513          	addi	a0,a0,1640 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202e70:	e14fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e74:	00005697          	auipc	a3,0x5
ffffffffc0202e78:	ae468693          	addi	a3,a3,-1308 # ffffffffc0207958 <default_pmm_manager+0x5f8>
ffffffffc0202e7c:	00004617          	auipc	a2,0x4
ffffffffc0202e80:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202e84:	23200593          	li	a1,562
ffffffffc0202e88:	00004517          	auipc	a0,0x4
ffffffffc0202e8c:	64850513          	addi	a0,a0,1608 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202e90:	df4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202e94:	00005697          	auipc	a3,0x5
ffffffffc0202e98:	aac68693          	addi	a3,a3,-1364 # ffffffffc0207940 <default_pmm_manager+0x5e0>
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202ea4:	23100593          	li	a1,561
ffffffffc0202ea8:	00004517          	auipc	a0,0x4
ffffffffc0202eac:	62850513          	addi	a0,a0,1576 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202eb0:	dd4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202eb4:	86be                	mv	a3,a5
ffffffffc0202eb6:	00004617          	auipc	a2,0x4
ffffffffc0202eba:	4fa60613          	addi	a2,a2,1274 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0202ebe:	1f700593          	li	a1,503
ffffffffc0202ec2:	00004517          	auipc	a0,0x4
ffffffffc0202ec6:	60e50513          	addi	a0,a0,1550 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202eca:	dbafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	51a60613          	addi	a2,a2,1306 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc0202ed6:	07f00593          	li	a1,127
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	5f650513          	addi	a0,a0,1526 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202ee2:	da2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ee6:	00005697          	auipc	a3,0x5
ffffffffc0202eea:	ae268693          	addi	a3,a3,-1310 # ffffffffc02079c8 <default_pmm_manager+0x668>
ffffffffc0202eee:	00004617          	auipc	a2,0x4
ffffffffc0202ef2:	d2a60613          	addi	a2,a2,-726 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202ef6:	23700593          	li	a1,567
ffffffffc0202efa:	00004517          	auipc	a0,0x4
ffffffffc0202efe:	5d650513          	addi	a0,a0,1494 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202f02:	d82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202f06:	00005697          	auipc	a3,0x5
ffffffffc0202f0a:	95268693          	addi	a3,a3,-1710 # ffffffffc0207858 <default_pmm_manager+0x4f8>
ffffffffc0202f0e:	00004617          	auipc	a2,0x4
ffffffffc0202f12:	d0a60613          	addi	a2,a2,-758 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202f16:	24300593          	li	a1,579
ffffffffc0202f1a:	00004517          	auipc	a0,0x4
ffffffffc0202f1e:	5b650513          	addi	a0,a0,1462 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202f22:	d62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f26:	00004697          	auipc	a3,0x4
ffffffffc0202f2a:	78268693          	addi	a3,a3,1922 # ffffffffc02076a8 <default_pmm_manager+0x348>
ffffffffc0202f2e:	00004617          	auipc	a2,0x4
ffffffffc0202f32:	cea60613          	addi	a2,a2,-790 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202f36:	1f500593          	li	a1,501
ffffffffc0202f3a:	00004517          	auipc	a0,0x4
ffffffffc0202f3e:	59650513          	addi	a0,a0,1430 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202f42:	d42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f46:	00004697          	auipc	a3,0x4
ffffffffc0202f4a:	74a68693          	addi	a3,a3,1866 # ffffffffc0207690 <default_pmm_manager+0x330>
ffffffffc0202f4e:	00004617          	auipc	a2,0x4
ffffffffc0202f52:	cca60613          	addi	a2,a2,-822 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202f56:	1f400593          	li	a1,500
ffffffffc0202f5a:	00004517          	auipc	a0,0x4
ffffffffc0202f5e:	57650513          	addi	a0,a0,1398 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202f62:	d22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202f66:	00004697          	auipc	a3,0x4
ffffffffc0202f6a:	67a68693          	addi	a3,a3,1658 # ffffffffc02075e0 <default_pmm_manager+0x280>
ffffffffc0202f6e:	00004617          	auipc	a2,0x4
ffffffffc0202f72:	caa60613          	addi	a2,a2,-854 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202f76:	1ec00593          	li	a1,492
ffffffffc0202f7a:	00004517          	auipc	a0,0x4
ffffffffc0202f7e:	55650513          	addi	a0,a0,1366 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202f82:	d02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202f86:	00004697          	auipc	a3,0x4
ffffffffc0202f8a:	6b268693          	addi	a3,a3,1714 # ffffffffc0207638 <default_pmm_manager+0x2d8>
ffffffffc0202f8e:	00004617          	auipc	a2,0x4
ffffffffc0202f92:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202f96:	1f300593          	li	a1,499
ffffffffc0202f9a:	00004517          	auipc	a0,0x4
ffffffffc0202f9e:	53650513          	addi	a0,a0,1334 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202fa2:	ce2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202fa6:	00004697          	auipc	a3,0x4
ffffffffc0202faa:	66268693          	addi	a3,a3,1634 # ffffffffc0207608 <default_pmm_manager+0x2a8>
ffffffffc0202fae:	00004617          	auipc	a2,0x4
ffffffffc0202fb2:	c6a60613          	addi	a2,a2,-918 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202fb6:	1f000593          	li	a1,496
ffffffffc0202fba:	00004517          	auipc	a0,0x4
ffffffffc0202fbe:	51650513          	addi	a0,a0,1302 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202fc2:	cc2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fc6:	00005697          	auipc	a3,0x5
ffffffffc0202fca:	82268693          	addi	a3,a3,-2014 # ffffffffc02077e8 <default_pmm_manager+0x488>
ffffffffc0202fce:	00004617          	auipc	a2,0x4
ffffffffc0202fd2:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202fd6:	20c00593          	li	a1,524
ffffffffc0202fda:	00004517          	auipc	a0,0x4
ffffffffc0202fde:	4f650513          	addi	a0,a0,1270 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0202fe2:	ca2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fe6:	00004697          	auipc	a3,0x4
ffffffffc0202fea:	6c268693          	addi	a3,a3,1730 # ffffffffc02076a8 <default_pmm_manager+0x348>
ffffffffc0202fee:	00004617          	auipc	a2,0x4
ffffffffc0202ff2:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0202ff6:	20b00593          	li	a1,523
ffffffffc0202ffa:	00004517          	auipc	a0,0x4
ffffffffc0202ffe:	4d650513          	addi	a0,a0,1238 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203002:	c82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203006:	00004697          	auipc	a3,0x4
ffffffffc020300a:	7fa68693          	addi	a3,a3,2042 # ffffffffc0207800 <default_pmm_manager+0x4a0>
ffffffffc020300e:	00004617          	auipc	a2,0x4
ffffffffc0203012:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203016:	20800593          	li	a1,520
ffffffffc020301a:	00004517          	auipc	a0,0x4
ffffffffc020301e:	4b650513          	addi	a0,a0,1206 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203022:	c62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203026:	00005697          	auipc	a3,0x5
ffffffffc020302a:	9da68693          	addi	a3,a3,-1574 # ffffffffc0207a00 <default_pmm_manager+0x6a0>
ffffffffc020302e:	00004617          	auipc	a2,0x4
ffffffffc0203032:	bea60613          	addi	a2,a2,-1046 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203036:	23a00593          	li	a1,570
ffffffffc020303a:	00004517          	auipc	a0,0x4
ffffffffc020303e:	49650513          	addi	a0,a0,1174 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203042:	c42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203046:	00005697          	auipc	a3,0x5
ffffffffc020304a:	81268693          	addi	a3,a3,-2030 # ffffffffc0207858 <default_pmm_manager+0x4f8>
ffffffffc020304e:	00004617          	auipc	a2,0x4
ffffffffc0203052:	bca60613          	addi	a2,a2,-1078 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203056:	21a00593          	li	a1,538
ffffffffc020305a:	00004517          	auipc	a0,0x4
ffffffffc020305e:	47650513          	addi	a0,a0,1142 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203062:	c22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203066:	00005697          	auipc	a3,0x5
ffffffffc020306a:	88a68693          	addi	a3,a3,-1910 # ffffffffc02078f0 <default_pmm_manager+0x590>
ffffffffc020306e:	00004617          	auipc	a2,0x4
ffffffffc0203072:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203076:	22c00593          	li	a1,556
ffffffffc020307a:	00004517          	auipc	a0,0x4
ffffffffc020307e:	45650513          	addi	a0,a0,1110 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203082:	c02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203086:	00004697          	auipc	a3,0x4
ffffffffc020308a:	50268693          	addi	a3,a3,1282 # ffffffffc0207588 <default_pmm_manager+0x228>
ffffffffc020308e:	00004617          	auipc	a2,0x4
ffffffffc0203092:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203096:	1ea00593          	li	a1,490
ffffffffc020309a:	00004517          	auipc	a0,0x4
ffffffffc020309e:	43650513          	addi	a0,a0,1078 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02030a2:	be2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02030a6:	00004617          	auipc	a2,0x4
ffffffffc02030aa:	34260613          	addi	a2,a2,834 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc02030ae:	0c100593          	li	a1,193
ffffffffc02030b2:	00004517          	auipc	a0,0x4
ffffffffc02030b6:	41e50513          	addi	a0,a0,1054 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02030ba:	bcafd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02030be <copy_range>:
               bool share) {
ffffffffc02030be:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030c0:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc02030c4:	f486                	sd	ra,104(sp)
ffffffffc02030c6:	f0a2                	sd	s0,96(sp)
ffffffffc02030c8:	eca6                	sd	s1,88(sp)
ffffffffc02030ca:	e8ca                	sd	s2,80(sp)
ffffffffc02030cc:	e4ce                	sd	s3,72(sp)
ffffffffc02030ce:	e0d2                	sd	s4,64(sp)
ffffffffc02030d0:	fc56                	sd	s5,56(sp)
ffffffffc02030d2:	f85a                	sd	s6,48(sp)
ffffffffc02030d4:	f45e                	sd	s7,40(sp)
ffffffffc02030d6:	f062                	sd	s8,32(sp)
ffffffffc02030d8:	ec66                	sd	s9,24(sp)
ffffffffc02030da:	e86a                	sd	s10,16(sp)
ffffffffc02030dc:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030de:	03479713          	slli	a4,a5,0x34
ffffffffc02030e2:	1e071863          	bnez	a4,ffffffffc02032d2 <copy_range+0x214>
    assert(USER_ACCESS(start, end));
ffffffffc02030e6:	002007b7          	lui	a5,0x200
ffffffffc02030ea:	8432                	mv	s0,a2
ffffffffc02030ec:	16f66b63          	bltu	a2,a5,ffffffffc0203262 <copy_range+0x1a4>
ffffffffc02030f0:	84b6                	mv	s1,a3
ffffffffc02030f2:	16d67863          	bleu	a3,a2,ffffffffc0203262 <copy_range+0x1a4>
ffffffffc02030f6:	4785                	li	a5,1
ffffffffc02030f8:	07fe                	slli	a5,a5,0x1f
ffffffffc02030fa:	16d7e463          	bltu	a5,a3,ffffffffc0203262 <copy_range+0x1a4>
ffffffffc02030fe:	5a7d                	li	s4,-1
ffffffffc0203100:	8aaa                	mv	s5,a0
ffffffffc0203102:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc0203104:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203106:	000a9c17          	auipc	s8,0xa9
ffffffffc020310a:	372c0c13          	addi	s8,s8,882 # ffffffffc02ac478 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020310e:	000a9b97          	auipc	s7,0xa9
ffffffffc0203112:	3dab8b93          	addi	s7,s7,986 # ffffffffc02ac4e8 <pages>
    return page - pages + nbase;
ffffffffc0203116:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020311a:	00ca5a13          	srli	s4,s4,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020311e:	4601                	li	a2,0
ffffffffc0203120:	85a2                	mv	a1,s0
ffffffffc0203122:	854a                	mv	a0,s2
ffffffffc0203124:	e3dfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203128:	8caa                	mv	s9,a0
        if (ptep == NULL) {
ffffffffc020312a:	c17d                	beqz	a0,ffffffffc0203210 <copy_range+0x152>
        if (*ptep & PTE_V) {
ffffffffc020312c:	611c                	ld	a5,0(a0)
ffffffffc020312e:	8b85                	andi	a5,a5,1
ffffffffc0203130:	e785                	bnez	a5,ffffffffc0203158 <copy_range+0x9a>
        start += PGSIZE;
ffffffffc0203132:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0203134:	fe9465e3          	bltu	s0,s1,ffffffffc020311e <copy_range+0x60>
    return 0;
ffffffffc0203138:	4501                	li	a0,0
}
ffffffffc020313a:	70a6                	ld	ra,104(sp)
ffffffffc020313c:	7406                	ld	s0,96(sp)
ffffffffc020313e:	64e6                	ld	s1,88(sp)
ffffffffc0203140:	6946                	ld	s2,80(sp)
ffffffffc0203142:	69a6                	ld	s3,72(sp)
ffffffffc0203144:	6a06                	ld	s4,64(sp)
ffffffffc0203146:	7ae2                	ld	s5,56(sp)
ffffffffc0203148:	7b42                	ld	s6,48(sp)
ffffffffc020314a:	7ba2                	ld	s7,40(sp)
ffffffffc020314c:	7c02                	ld	s8,32(sp)
ffffffffc020314e:	6ce2                	ld	s9,24(sp)
ffffffffc0203150:	6d42                	ld	s10,16(sp)
ffffffffc0203152:	6da2                	ld	s11,8(sp)
ffffffffc0203154:	6165                	addi	sp,sp,112
ffffffffc0203156:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc0203158:	4605                	li	a2,1
ffffffffc020315a:	85a2                	mv	a1,s0
ffffffffc020315c:	8556                	mv	a0,s5
ffffffffc020315e:	e03fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203162:	c169                	beqz	a0,ffffffffc0203224 <copy_range+0x166>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203164:	000cb783          	ld	a5,0(s9)
    if (!(pte & PTE_V)) {
ffffffffc0203168:	0017f713          	andi	a4,a5,1
ffffffffc020316c:	01f7fc93          	andi	s9,a5,31
ffffffffc0203170:	14070563          	beqz	a4,ffffffffc02032ba <copy_range+0x1fc>
    if (PPN(pa) >= npage) {
ffffffffc0203174:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203178:	078a                	slli	a5,a5,0x2
ffffffffc020317a:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020317e:	12d77263          	bleu	a3,a4,ffffffffc02032a2 <copy_range+0x1e4>
    return &pages[PPN(pa) - nbase];
ffffffffc0203182:	000bb783          	ld	a5,0(s7)
ffffffffc0203186:	fff806b7          	lui	a3,0xfff80
ffffffffc020318a:	9736                	add	a4,a4,a3
ffffffffc020318c:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc020318e:	4505                	li	a0,1
ffffffffc0203190:	00e78db3          	add	s11,a5,a4
ffffffffc0203194:	cbffe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203198:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc020319a:	0a0d8463          	beqz	s11,ffffffffc0203242 <copy_range+0x184>
            assert(npage != NULL);
ffffffffc020319e:	c175                	beqz	a0,ffffffffc0203282 <copy_range+0x1c4>
    return page - pages + nbase;
ffffffffc02031a0:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc02031a4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02031a8:	40ed86b3          	sub	a3,s11,a4
ffffffffc02031ac:	8699                	srai	a3,a3,0x6
ffffffffc02031ae:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc02031b0:	0146f7b3          	and	a5,a3,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc02031b4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02031b6:	06c7fa63          	bleu	a2,a5,ffffffffc020322a <copy_range+0x16c>
    return page - pages + nbase;
ffffffffc02031ba:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc02031be:	000a9717          	auipc	a4,0xa9
ffffffffc02031c2:	31a70713          	addi	a4,a4,794 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc02031c6:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02031c8:	8799                	srai	a5,a5,0x6
ffffffffc02031ca:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc02031cc:	0147f733          	and	a4,a5,s4
ffffffffc02031d0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02031d4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02031d6:	04c77963          	bleu	a2,a4,ffffffffc0203228 <copy_range+0x16a>
 	        memcpy(kva_dst, kva_src, PGSIZE);			//复制父进程到子进程  
ffffffffc02031da:	6605                	lui	a2,0x1
ffffffffc02031dc:	953e                	add	a0,a0,a5
ffffffffc02031de:	430030ef          	jal	ra,ffffffffc020660e <memcpy>
	        ret = page_insert(to, npage, start, perm);	//建立子进程页地址起始位置与物理地址的映射关系(prem是权限) 
ffffffffc02031e2:	86e6                	mv	a3,s9
ffffffffc02031e4:	8622                	mv	a2,s0
ffffffffc02031e6:	85ea                	mv	a1,s10
ffffffffc02031e8:	8556                	mv	a0,s5
ffffffffc02031ea:	b8cff0ef          	jal	ra,ffffffffc0202576 <page_insert>
            assert(ret == 0);
ffffffffc02031ee:	d131                	beqz	a0,ffffffffc0203132 <copy_range+0x74>
ffffffffc02031f0:	00004697          	auipc	a3,0x4
ffffffffc02031f4:	2d068693          	addi	a3,a3,720 # ffffffffc02074c0 <default_pmm_manager+0x160>
ffffffffc02031f8:	00004617          	auipc	a2,0x4
ffffffffc02031fc:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203200:	18c00593          	li	a1,396
ffffffffc0203204:	00004517          	auipc	a0,0x4
ffffffffc0203208:	2cc50513          	addi	a0,a0,716 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc020320c:	a78fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203210:	002007b7          	lui	a5,0x200
ffffffffc0203214:	943e                	add	s0,s0,a5
ffffffffc0203216:	ffe007b7          	lui	a5,0xffe00
ffffffffc020321a:	8c7d                	and	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc020321c:	dc11                	beqz	s0,ffffffffc0203138 <copy_range+0x7a>
ffffffffc020321e:	f09460e3          	bltu	s0,s1,ffffffffc020311e <copy_range+0x60>
ffffffffc0203222:	bf19                	j	ffffffffc0203138 <copy_range+0x7a>
                return -E_NO_MEM;
ffffffffc0203224:	5571                	li	a0,-4
ffffffffc0203226:	bf11                	j	ffffffffc020313a <copy_range+0x7c>
ffffffffc0203228:	86be                	mv	a3,a5
ffffffffc020322a:	00004617          	auipc	a2,0x4
ffffffffc020322e:	18660613          	addi	a2,a2,390 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0203232:	06900593          	li	a1,105
ffffffffc0203236:	00004517          	auipc	a0,0x4
ffffffffc020323a:	1a250513          	addi	a0,a0,418 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc020323e:	a46fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(page != NULL);
ffffffffc0203242:	00004697          	auipc	a3,0x4
ffffffffc0203246:	25e68693          	addi	a3,a3,606 # ffffffffc02074a0 <default_pmm_manager+0x140>
ffffffffc020324a:	00004617          	auipc	a2,0x4
ffffffffc020324e:	9ce60613          	addi	a2,a2,-1586 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203252:	17200593          	li	a1,370
ffffffffc0203256:	00004517          	auipc	a0,0x4
ffffffffc020325a:	27a50513          	addi	a0,a0,634 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc020325e:	a26fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203262:	00005697          	auipc	a3,0x5
ffffffffc0203266:	81668693          	addi	a3,a3,-2026 # ffffffffc0207a78 <default_pmm_manager+0x718>
ffffffffc020326a:	00004617          	auipc	a2,0x4
ffffffffc020326e:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203272:	15e00593          	li	a1,350
ffffffffc0203276:	00004517          	auipc	a0,0x4
ffffffffc020327a:	25a50513          	addi	a0,a0,602 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc020327e:	a06fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(npage != NULL);
ffffffffc0203282:	00004697          	auipc	a3,0x4
ffffffffc0203286:	22e68693          	addi	a3,a3,558 # ffffffffc02074b0 <default_pmm_manager+0x150>
ffffffffc020328a:	00004617          	auipc	a2,0x4
ffffffffc020328e:	98e60613          	addi	a2,a2,-1650 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203292:	17300593          	li	a1,371
ffffffffc0203296:	00004517          	auipc	a0,0x4
ffffffffc020329a:	23a50513          	addi	a0,a0,570 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc020329e:	9e6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02032a2:	00004617          	auipc	a2,0x4
ffffffffc02032a6:	16e60613          	addi	a2,a2,366 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc02032aa:	06200593          	li	a1,98
ffffffffc02032ae:	00004517          	auipc	a0,0x4
ffffffffc02032b2:	12a50513          	addi	a0,a0,298 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02032b6:	9cefd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02032ba:	00004617          	auipc	a2,0x4
ffffffffc02032be:	3ae60613          	addi	a2,a2,942 # ffffffffc0207668 <default_pmm_manager+0x308>
ffffffffc02032c2:	07400593          	li	a1,116
ffffffffc02032c6:	00004517          	auipc	a0,0x4
ffffffffc02032ca:	11250513          	addi	a0,a0,274 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02032ce:	9b6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032d2:	00004697          	auipc	a3,0x4
ffffffffc02032d6:	77668693          	addi	a3,a3,1910 # ffffffffc0207a48 <default_pmm_manager+0x6e8>
ffffffffc02032da:	00004617          	auipc	a2,0x4
ffffffffc02032de:	93e60613          	addi	a2,a2,-1730 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02032e2:	15d00593          	li	a1,349
ffffffffc02032e6:	00004517          	auipc	a0,0x4
ffffffffc02032ea:	1ea50513          	addi	a0,a0,490 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc02032ee:	996fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02032f2 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02032f2:	12058073          	sfence.vma	a1
}
ffffffffc02032f6:	8082                	ret

ffffffffc02032f8 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02032f8:	7179                	addi	sp,sp,-48
ffffffffc02032fa:	e84a                	sd	s2,16(sp)
ffffffffc02032fc:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02032fe:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203300:	f022                	sd	s0,32(sp)
ffffffffc0203302:	ec26                	sd	s1,24(sp)
ffffffffc0203304:	e44e                	sd	s3,8(sp)
ffffffffc0203306:	f406                	sd	ra,40(sp)
ffffffffc0203308:	84ae                	mv	s1,a1
ffffffffc020330a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020330c:	b47fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203310:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203312:	cd1d                	beqz	a0,ffffffffc0203350 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203314:	85aa                	mv	a1,a0
ffffffffc0203316:	86ce                	mv	a3,s3
ffffffffc0203318:	8626                	mv	a2,s1
ffffffffc020331a:	854a                	mv	a0,s2
ffffffffc020331c:	a5aff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0203320:	e121                	bnez	a0,ffffffffc0203360 <pgdir_alloc_page+0x68>
        if (swap_init_ok) {
ffffffffc0203322:	000a9797          	auipc	a5,0xa9
ffffffffc0203326:	16678793          	addi	a5,a5,358 # ffffffffc02ac488 <swap_init_ok>
ffffffffc020332a:	439c                	lw	a5,0(a5)
ffffffffc020332c:	2781                	sext.w	a5,a5
ffffffffc020332e:	c38d                	beqz	a5,ffffffffc0203350 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL) {
ffffffffc0203330:	000a9797          	auipc	a5,0xa9
ffffffffc0203334:	29878793          	addi	a5,a5,664 # ffffffffc02ac5c8 <check_mm_struct>
ffffffffc0203338:	6388                	ld	a0,0(a5)
ffffffffc020333a:	c919                	beqz	a0,ffffffffc0203350 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc020333c:	4681                	li	a3,0
ffffffffc020333e:	8622                	mv	a2,s0
ffffffffc0203340:	85a6                	mv	a1,s1
ffffffffc0203342:	7da000ef          	jal	ra,ffffffffc0203b1c <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0203346:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0203348:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc020334a:	4785                	li	a5,1
ffffffffc020334c:	02f71063          	bne	a4,a5,ffffffffc020336c <pgdir_alloc_page+0x74>
}
ffffffffc0203350:	8522                	mv	a0,s0
ffffffffc0203352:	70a2                	ld	ra,40(sp)
ffffffffc0203354:	7402                	ld	s0,32(sp)
ffffffffc0203356:	64e2                	ld	s1,24(sp)
ffffffffc0203358:	6942                	ld	s2,16(sp)
ffffffffc020335a:	69a2                	ld	s3,8(sp)
ffffffffc020335c:	6145                	addi	sp,sp,48
ffffffffc020335e:	8082                	ret
            free_page(page);
ffffffffc0203360:	8522                	mv	a0,s0
ffffffffc0203362:	4585                	li	a1,1
ffffffffc0203364:	b77fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
            return NULL;
ffffffffc0203368:	4401                	li	s0,0
ffffffffc020336a:	b7dd                	j	ffffffffc0203350 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc020336c:	00004697          	auipc	a3,0x4
ffffffffc0203370:	17468693          	addi	a3,a3,372 # ffffffffc02074e0 <default_pmm_manager+0x180>
ffffffffc0203374:	00004617          	auipc	a2,0x4
ffffffffc0203378:	8a460613          	addi	a2,a2,-1884 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020337c:	1cb00593          	li	a1,459
ffffffffc0203380:	00004517          	auipc	a0,0x4
ffffffffc0203384:	15050513          	addi	a0,a0,336 # ffffffffc02074d0 <default_pmm_manager+0x170>
ffffffffc0203388:	8fcfd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020338c <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020338c:	7135                	addi	sp,sp,-160
ffffffffc020338e:	ed06                	sd	ra,152(sp)
ffffffffc0203390:	e922                	sd	s0,144(sp)
ffffffffc0203392:	e526                	sd	s1,136(sp)
ffffffffc0203394:	e14a                	sd	s2,128(sp)
ffffffffc0203396:	fcce                	sd	s3,120(sp)
ffffffffc0203398:	f8d2                	sd	s4,112(sp)
ffffffffc020339a:	f4d6                	sd	s5,104(sp)
ffffffffc020339c:	f0da                	sd	s6,96(sp)
ffffffffc020339e:	ecde                	sd	s7,88(sp)
ffffffffc02033a0:	e8e2                	sd	s8,80(sp)
ffffffffc02033a2:	e4e6                	sd	s9,72(sp)
ffffffffc02033a4:	e0ea                	sd	s10,64(sp)
ffffffffc02033a6:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02033a8:	790010ef          	jal	ra,ffffffffc0204b38 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02033ac:	000a9797          	auipc	a5,0xa9
ffffffffc02033b0:	1cc78793          	addi	a5,a5,460 # ffffffffc02ac578 <max_swap_offset>
ffffffffc02033b4:	6394                	ld	a3,0(a5)
ffffffffc02033b6:	010007b7          	lui	a5,0x1000
ffffffffc02033ba:	17e1                	addi	a5,a5,-8
ffffffffc02033bc:	ff968713          	addi	a4,a3,-7
ffffffffc02033c0:	4ae7ee63          	bltu	a5,a4,ffffffffc020387c <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02033c4:	0009e797          	auipc	a5,0x9e
ffffffffc02033c8:	c4478793          	addi	a5,a5,-956 # ffffffffc02a1008 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02033cc:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02033ce:	000a9697          	auipc	a3,0xa9
ffffffffc02033d2:	0af6b923          	sd	a5,178(a3) # ffffffffc02ac480 <sm>
     int r = sm->init();
ffffffffc02033d6:	9702                	jalr	a4
ffffffffc02033d8:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc02033da:	c10d                	beqz	a0,ffffffffc02033fc <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02033dc:	60ea                	ld	ra,152(sp)
ffffffffc02033de:	644a                	ld	s0,144(sp)
ffffffffc02033e0:	8556                	mv	a0,s5
ffffffffc02033e2:	64aa                	ld	s1,136(sp)
ffffffffc02033e4:	690a                	ld	s2,128(sp)
ffffffffc02033e6:	79e6                	ld	s3,120(sp)
ffffffffc02033e8:	7a46                	ld	s4,112(sp)
ffffffffc02033ea:	7aa6                	ld	s5,104(sp)
ffffffffc02033ec:	7b06                	ld	s6,96(sp)
ffffffffc02033ee:	6be6                	ld	s7,88(sp)
ffffffffc02033f0:	6c46                	ld	s8,80(sp)
ffffffffc02033f2:	6ca6                	ld	s9,72(sp)
ffffffffc02033f4:	6d06                	ld	s10,64(sp)
ffffffffc02033f6:	7de2                	ld	s11,56(sp)
ffffffffc02033f8:	610d                	addi	sp,sp,160
ffffffffc02033fa:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02033fc:	000a9797          	auipc	a5,0xa9
ffffffffc0203400:	08478793          	addi	a5,a5,132 # ffffffffc02ac480 <sm>
ffffffffc0203404:	639c                	ld	a5,0(a5)
ffffffffc0203406:	00004517          	auipc	a0,0x4
ffffffffc020340a:	70a50513          	addi	a0,a0,1802 # ffffffffc0207b10 <default_pmm_manager+0x7b0>
    return listelm->next;
ffffffffc020340e:	000a9417          	auipc	s0,0xa9
ffffffffc0203412:	0aa40413          	addi	s0,s0,170 # ffffffffc02ac4b8 <free_area>
ffffffffc0203416:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203418:	4785                	li	a5,1
ffffffffc020341a:	000a9717          	auipc	a4,0xa9
ffffffffc020341e:	06f72723          	sw	a5,110(a4) # ffffffffc02ac488 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203422:	d6dfc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0203426:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203428:	36878e63          	beq	a5,s0,ffffffffc02037a4 <swap_init+0x418>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020342c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203430:	8305                	srli	a4,a4,0x1
ffffffffc0203432:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203434:	36070c63          	beqz	a4,ffffffffc02037ac <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc0203438:	4481                	li	s1,0
ffffffffc020343a:	4901                	li	s2,0
ffffffffc020343c:	a031                	j	ffffffffc0203448 <swap_init+0xbc>
ffffffffc020343e:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0203442:	8b09                	andi	a4,a4,2
ffffffffc0203444:	36070463          	beqz	a4,ffffffffc02037ac <swap_init+0x420>
        count ++, total += p->property;
ffffffffc0203448:	ff87a703          	lw	a4,-8(a5)
ffffffffc020344c:	679c                	ld	a5,8(a5)
ffffffffc020344e:	2905                	addiw	s2,s2,1
ffffffffc0203450:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203452:	fe8796e3          	bne	a5,s0,ffffffffc020343e <swap_init+0xb2>
ffffffffc0203456:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0203458:	ac9fe0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc020345c:	69351863          	bne	a0,s3,ffffffffc0203aec <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203460:	8626                	mv	a2,s1
ffffffffc0203462:	85ca                	mv	a1,s2
ffffffffc0203464:	00004517          	auipc	a0,0x4
ffffffffc0203468:	6c450513          	addi	a0,a0,1732 # ffffffffc0207b28 <default_pmm_manager+0x7c8>
ffffffffc020346c:	d23fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0203470:	457000ef          	jal	ra,ffffffffc02040c6 <mm_create>
ffffffffc0203474:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0203476:	60050b63          	beqz	a0,ffffffffc0203a8c <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020347a:	000a9797          	auipc	a5,0xa9
ffffffffc020347e:	14e78793          	addi	a5,a5,334 # ffffffffc02ac5c8 <check_mm_struct>
ffffffffc0203482:	639c                	ld	a5,0(a5)
ffffffffc0203484:	62079463          	bnez	a5,ffffffffc0203aac <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203488:	000a9797          	auipc	a5,0xa9
ffffffffc020348c:	fe878793          	addi	a5,a5,-24 # ffffffffc02ac470 <boot_pgdir>
ffffffffc0203490:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc0203494:	000a9797          	auipc	a5,0xa9
ffffffffc0203498:	12a7ba23          	sd	a0,308(a5) # ffffffffc02ac5c8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020349c:	000b3783          	ld	a5,0(s6) # 80000 <_binary_obj___user_exit_out_size+0x75580>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034a0:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02034a4:	4e079863          	bnez	a5,ffffffffc0203994 <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02034a8:	6599                	lui	a1,0x6
ffffffffc02034aa:	460d                	li	a2,3
ffffffffc02034ac:	6505                	lui	a0,0x1
ffffffffc02034ae:	465000ef          	jal	ra,ffffffffc0204112 <vma_create>
ffffffffc02034b2:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02034b4:	50050063          	beqz	a0,ffffffffc02039b4 <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc02034b8:	855e                	mv	a0,s7
ffffffffc02034ba:	4c5000ef          	jal	ra,ffffffffc020417e <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02034be:	00004517          	auipc	a0,0x4
ffffffffc02034c2:	6da50513          	addi	a0,a0,1754 # ffffffffc0207b98 <default_pmm_manager+0x838>
ffffffffc02034c6:	cc9fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02034ca:	018bb503          	ld	a0,24(s7)
ffffffffc02034ce:	4605                	li	a2,1
ffffffffc02034d0:	6585                	lui	a1,0x1
ffffffffc02034d2:	a8ffe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02034d6:	4e050f63          	beqz	a0,ffffffffc02039d4 <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034da:	00004517          	auipc	a0,0x4
ffffffffc02034de:	70e50513          	addi	a0,a0,1806 # ffffffffc0207be8 <default_pmm_manager+0x888>
ffffffffc02034e2:	000a9997          	auipc	s3,0xa9
ffffffffc02034e6:	00e98993          	addi	s3,s3,14 # ffffffffc02ac4f0 <check_rp>
ffffffffc02034ea:	ca5fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02034ee:	000a9a17          	auipc	s4,0xa9
ffffffffc02034f2:	022a0a13          	addi	s4,s4,34 # ffffffffc02ac510 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034f6:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc02034f8:	4505                	li	a0,1
ffffffffc02034fa:	959fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02034fe:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0203502:	32050d63          	beqz	a0,ffffffffc020383c <swap_init+0x4b0>
ffffffffc0203506:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203508:	8b89                	andi	a5,a5,2
ffffffffc020350a:	30079963          	bnez	a5,ffffffffc020381c <swap_init+0x490>
ffffffffc020350e:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203510:	ff4c14e3          	bne	s8,s4,ffffffffc02034f8 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203514:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203516:	000a9c17          	auipc	s8,0xa9
ffffffffc020351a:	fdac0c13          	addi	s8,s8,-38 # ffffffffc02ac4f0 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc020351e:	ec3e                	sd	a5,24(sp)
ffffffffc0203520:	641c                	ld	a5,8(s0)
ffffffffc0203522:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203524:	481c                	lw	a5,16(s0)
ffffffffc0203526:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0203528:	000a9797          	auipc	a5,0xa9
ffffffffc020352c:	f887bc23          	sd	s0,-104(a5) # ffffffffc02ac4c0 <free_area+0x8>
ffffffffc0203530:	000a9797          	auipc	a5,0xa9
ffffffffc0203534:	f887b423          	sd	s0,-120(a5) # ffffffffc02ac4b8 <free_area>
     nr_free = 0;
ffffffffc0203538:	000a9797          	auipc	a5,0xa9
ffffffffc020353c:	f807a823          	sw	zero,-112(a5) # ffffffffc02ac4c8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203540:	000c3503          	ld	a0,0(s8)
ffffffffc0203544:	4585                	li	a1,1
ffffffffc0203546:	0c21                	addi	s8,s8,8
ffffffffc0203548:	993fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020354c:	ff4c1ae3          	bne	s8,s4,ffffffffc0203540 <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203550:	01042c03          	lw	s8,16(s0)
ffffffffc0203554:	4791                	li	a5,4
ffffffffc0203556:	50fc1b63          	bne	s8,a5,ffffffffc0203a6c <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020355a:	00004517          	auipc	a0,0x4
ffffffffc020355e:	71650513          	addi	a0,a0,1814 # ffffffffc0207c70 <default_pmm_manager+0x910>
ffffffffc0203562:	c2dfc0ef          	jal	ra,ffffffffc020018e <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203566:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0203568:	000a9797          	auipc	a5,0xa9
ffffffffc020356c:	f207a223          	sw	zero,-220(a5) # ffffffffc02ac48c <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203570:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0203572:	000a9797          	auipc	a5,0xa9
ffffffffc0203576:	f1a78793          	addi	a5,a5,-230 # ffffffffc02ac48c <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020357a:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
     assert(pgfault_num==1);
ffffffffc020357e:	4398                	lw	a4,0(a5)
ffffffffc0203580:	4585                	li	a1,1
ffffffffc0203582:	2701                	sext.w	a4,a4
ffffffffc0203584:	38b71863          	bne	a4,a1,ffffffffc0203914 <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0203588:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc020358c:	4394                	lw	a3,0(a5)
ffffffffc020358e:	2681                	sext.w	a3,a3
ffffffffc0203590:	3ae69263          	bne	a3,a4,ffffffffc0203934 <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203594:	6689                	lui	a3,0x2
ffffffffc0203596:	462d                	li	a2,11
ffffffffc0203598:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
     assert(pgfault_num==2);
ffffffffc020359c:	4398                	lw	a4,0(a5)
ffffffffc020359e:	4589                	li	a1,2
ffffffffc02035a0:	2701                	sext.w	a4,a4
ffffffffc02035a2:	2eb71963          	bne	a4,a1,ffffffffc0203894 <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02035a6:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02035aa:	4394                	lw	a3,0(a5)
ffffffffc02035ac:	2681                	sext.w	a3,a3
ffffffffc02035ae:	30e69363          	bne	a3,a4,ffffffffc02038b4 <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02035b2:	668d                	lui	a3,0x3
ffffffffc02035b4:	4631                	li	a2,12
ffffffffc02035b6:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
     assert(pgfault_num==3);
ffffffffc02035ba:	4398                	lw	a4,0(a5)
ffffffffc02035bc:	458d                	li	a1,3
ffffffffc02035be:	2701                	sext.w	a4,a4
ffffffffc02035c0:	30b71a63          	bne	a4,a1,ffffffffc02038d4 <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02035c4:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02035c8:	4394                	lw	a3,0(a5)
ffffffffc02035ca:	2681                	sext.w	a3,a3
ffffffffc02035cc:	32e69463          	bne	a3,a4,ffffffffc02038f4 <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02035d0:	6691                	lui	a3,0x4
ffffffffc02035d2:	4635                	li	a2,13
ffffffffc02035d4:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
     assert(pgfault_num==4);
ffffffffc02035d8:	4398                	lw	a4,0(a5)
ffffffffc02035da:	2701                	sext.w	a4,a4
ffffffffc02035dc:	37871c63          	bne	a4,s8,ffffffffc0203954 <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02035e0:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02035e4:	439c                	lw	a5,0(a5)
ffffffffc02035e6:	2781                	sext.w	a5,a5
ffffffffc02035e8:	38e79663          	bne	a5,a4,ffffffffc0203974 <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc02035ec:	481c                	lw	a5,16(s0)
ffffffffc02035ee:	40079363          	bnez	a5,ffffffffc02039f4 <swap_init+0x668>
ffffffffc02035f2:	000a9797          	auipc	a5,0xa9
ffffffffc02035f6:	f1e78793          	addi	a5,a5,-226 # ffffffffc02ac510 <swap_in_seq_no>
ffffffffc02035fa:	000a9717          	auipc	a4,0xa9
ffffffffc02035fe:	f3e70713          	addi	a4,a4,-194 # ffffffffc02ac538 <swap_out_seq_no>
ffffffffc0203602:	000a9617          	auipc	a2,0xa9
ffffffffc0203606:	f3660613          	addi	a2,a2,-202 # ffffffffc02ac538 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc020360a:	56fd                	li	a3,-1
ffffffffc020360c:	c394                	sw	a3,0(a5)
ffffffffc020360e:	c314                	sw	a3,0(a4)
ffffffffc0203610:	0791                	addi	a5,a5,4
ffffffffc0203612:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203614:	fef61ce3          	bne	a2,a5,ffffffffc020360c <swap_init+0x280>
ffffffffc0203618:	000a9697          	auipc	a3,0xa9
ffffffffc020361c:	f8068693          	addi	a3,a3,-128 # ffffffffc02ac598 <check_ptep>
ffffffffc0203620:	000a9817          	auipc	a6,0xa9
ffffffffc0203624:	ed080813          	addi	a6,a6,-304 # ffffffffc02ac4f0 <check_rp>
ffffffffc0203628:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc020362a:	000a9c97          	auipc	s9,0xa9
ffffffffc020362e:	e4ec8c93          	addi	s9,s9,-434 # ffffffffc02ac478 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203632:	00005d97          	auipc	s11,0x5
ffffffffc0203636:	6eed8d93          	addi	s11,s11,1774 # ffffffffc0208d20 <nbase>
ffffffffc020363a:	000a9c17          	auipc	s8,0xa9
ffffffffc020363e:	eaec0c13          	addi	s8,s8,-338 # ffffffffc02ac4e8 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203642:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203646:	4601                	li	a2,0
ffffffffc0203648:	85ea                	mv	a1,s10
ffffffffc020364a:	855a                	mv	a0,s6
ffffffffc020364c:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc020364e:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203650:	911fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203654:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0203656:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203658:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc020365a:	20050163          	beqz	a0,ffffffffc020385c <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020365e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203660:	0017f613          	andi	a2,a5,1
ffffffffc0203664:	1a060063          	beqz	a2,ffffffffc0203804 <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc0203668:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020366c:	078a                	slli	a5,a5,0x2
ffffffffc020366e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203670:	14c7fe63          	bleu	a2,a5,ffffffffc02037cc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203674:	000db703          	ld	a4,0(s11)
ffffffffc0203678:	000c3603          	ld	a2,0(s8)
ffffffffc020367c:	00083583          	ld	a1,0(a6)
ffffffffc0203680:	8f99                	sub	a5,a5,a4
ffffffffc0203682:	079a                	slli	a5,a5,0x6
ffffffffc0203684:	e43a                	sd	a4,8(sp)
ffffffffc0203686:	97b2                	add	a5,a5,a2
ffffffffc0203688:	14f59e63          	bne	a1,a5,ffffffffc02037e4 <swap_init+0x458>
ffffffffc020368c:	6785                	lui	a5,0x1
ffffffffc020368e:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203690:	6795                	lui	a5,0x5
ffffffffc0203692:	06a1                	addi	a3,a3,8
ffffffffc0203694:	0821                	addi	a6,a6,8
ffffffffc0203696:	fafd16e3          	bne	s10,a5,ffffffffc0203642 <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc020369a:	00004517          	auipc	a0,0x4
ffffffffc020369e:	67e50513          	addi	a0,a0,1662 # ffffffffc0207d18 <default_pmm_manager+0x9b8>
ffffffffc02036a2:	aedfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = sm->check_swap();
ffffffffc02036a6:	000a9797          	auipc	a5,0xa9
ffffffffc02036aa:	dda78793          	addi	a5,a5,-550 # ffffffffc02ac480 <sm>
ffffffffc02036ae:	639c                	ld	a5,0(a5)
ffffffffc02036b0:	7f9c                	ld	a5,56(a5)
ffffffffc02036b2:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02036b4:	40051c63          	bnez	a0,ffffffffc0203acc <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc02036b8:	77a2                	ld	a5,40(sp)
ffffffffc02036ba:	000a9717          	auipc	a4,0xa9
ffffffffc02036be:	e0f72723          	sw	a5,-498(a4) # ffffffffc02ac4c8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02036c2:	67e2                	ld	a5,24(sp)
ffffffffc02036c4:	000a9717          	auipc	a4,0xa9
ffffffffc02036c8:	def73a23          	sd	a5,-524(a4) # ffffffffc02ac4b8 <free_area>
ffffffffc02036cc:	7782                	ld	a5,32(sp)
ffffffffc02036ce:	000a9717          	auipc	a4,0xa9
ffffffffc02036d2:	def73923          	sd	a5,-526(a4) # ffffffffc02ac4c0 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02036d6:	0009b503          	ld	a0,0(s3)
ffffffffc02036da:	4585                	li	a1,1
ffffffffc02036dc:	09a1                	addi	s3,s3,8
ffffffffc02036de:	ffcfe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036e2:	ff499ae3          	bne	s3,s4,ffffffffc02036d6 <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc02036e6:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc02036ea:	855e                	mv	a0,s7
ffffffffc02036ec:	361000ef          	jal	ra,ffffffffc020424c <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02036f0:	000a9797          	auipc	a5,0xa9
ffffffffc02036f4:	d8078793          	addi	a5,a5,-640 # ffffffffc02ac470 <boot_pgdir>
ffffffffc02036f8:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc02036fa:	000a9697          	auipc	a3,0xa9
ffffffffc02036fe:	ec06b723          	sd	zero,-306(a3) # ffffffffc02ac5c8 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc0203702:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203706:	6394                	ld	a3,0(a5)
ffffffffc0203708:	068a                	slli	a3,a3,0x2
ffffffffc020370a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020370c:	0ce6f063          	bleu	a4,a3,ffffffffc02037cc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203710:	67a2                	ld	a5,8(sp)
ffffffffc0203712:	000c3503          	ld	a0,0(s8)
ffffffffc0203716:	8e9d                	sub	a3,a3,a5
ffffffffc0203718:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc020371a:	8699                	srai	a3,a3,0x6
ffffffffc020371c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020371e:	57fd                	li	a5,-1
ffffffffc0203720:	83b1                	srli	a5,a5,0xc
ffffffffc0203722:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203724:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203726:	2ee7f763          	bleu	a4,a5,ffffffffc0203a14 <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc020372a:	000a9797          	auipc	a5,0xa9
ffffffffc020372e:	dae78793          	addi	a5,a5,-594 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0203732:	639c                	ld	a5,0(a5)
ffffffffc0203734:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203736:	629c                	ld	a5,0(a3)
ffffffffc0203738:	078a                	slli	a5,a5,0x2
ffffffffc020373a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020373c:	08e7f863          	bleu	a4,a5,ffffffffc02037cc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203740:	69a2                	ld	s3,8(sp)
ffffffffc0203742:	4585                	li	a1,1
ffffffffc0203744:	413787b3          	sub	a5,a5,s3
ffffffffc0203748:	079a                	slli	a5,a5,0x6
ffffffffc020374a:	953e                	add	a0,a0,a5
ffffffffc020374c:	f8efe0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203750:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203754:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203758:	078a                	slli	a5,a5,0x2
ffffffffc020375a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020375c:	06e7f863          	bleu	a4,a5,ffffffffc02037cc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203760:	000c3503          	ld	a0,0(s8)
ffffffffc0203764:	413787b3          	sub	a5,a5,s3
ffffffffc0203768:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc020376a:	4585                	li	a1,1
ffffffffc020376c:	953e                	add	a0,a0,a5
ffffffffc020376e:	f6cfe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     pgdir[0] = 0;
ffffffffc0203772:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0203776:	12000073          	sfence.vma
    return listelm->next;
ffffffffc020377a:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020377c:	00878963          	beq	a5,s0,ffffffffc020378e <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203780:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203784:	679c                	ld	a5,8(a5)
ffffffffc0203786:	397d                	addiw	s2,s2,-1
ffffffffc0203788:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020378a:	fe879be3          	bne	a5,s0,ffffffffc0203780 <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc020378e:	28091f63          	bnez	s2,ffffffffc0203a2c <swap_init+0x6a0>
     assert(total==0);
ffffffffc0203792:	2a049d63          	bnez	s1,ffffffffc0203a4c <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203796:	00004517          	auipc	a0,0x4
ffffffffc020379a:	5d250513          	addi	a0,a0,1490 # ffffffffc0207d68 <default_pmm_manager+0xa08>
ffffffffc020379e:	9f1fc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02037a2:	b92d                	j	ffffffffc02033dc <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc02037a4:	4481                	li	s1,0
ffffffffc02037a6:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037a8:	4981                	li	s3,0
ffffffffc02037aa:	b17d                	j	ffffffffc0203458 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc02037ac:	00004697          	auipc	a3,0x4
ffffffffc02037b0:	82468693          	addi	a3,a3,-2012 # ffffffffc0206fd0 <commands+0x878>
ffffffffc02037b4:	00003617          	auipc	a2,0x3
ffffffffc02037b8:	46460613          	addi	a2,a2,1124 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02037bc:	0bc00593          	li	a1,188
ffffffffc02037c0:	00004517          	auipc	a0,0x4
ffffffffc02037c4:	34050513          	addi	a0,a0,832 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02037c8:	cbdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02037cc:	00004617          	auipc	a2,0x4
ffffffffc02037d0:	c4460613          	addi	a2,a2,-956 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc02037d4:	06200593          	li	a1,98
ffffffffc02037d8:	00004517          	auipc	a0,0x4
ffffffffc02037dc:	c0050513          	addi	a0,a0,-1024 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02037e0:	ca5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02037e4:	00004697          	auipc	a3,0x4
ffffffffc02037e8:	50c68693          	addi	a3,a3,1292 # ffffffffc0207cf0 <default_pmm_manager+0x990>
ffffffffc02037ec:	00003617          	auipc	a2,0x3
ffffffffc02037f0:	42c60613          	addi	a2,a2,1068 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02037f4:	0fc00593          	li	a1,252
ffffffffc02037f8:	00004517          	auipc	a0,0x4
ffffffffc02037fc:	30850513          	addi	a0,a0,776 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203800:	c85fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203804:	00004617          	auipc	a2,0x4
ffffffffc0203808:	e6460613          	addi	a2,a2,-412 # ffffffffc0207668 <default_pmm_manager+0x308>
ffffffffc020380c:	07400593          	li	a1,116
ffffffffc0203810:	00004517          	auipc	a0,0x4
ffffffffc0203814:	bc850513          	addi	a0,a0,-1080 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0203818:	c6dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc020381c:	00004697          	auipc	a3,0x4
ffffffffc0203820:	40c68693          	addi	a3,a3,1036 # ffffffffc0207c28 <default_pmm_manager+0x8c8>
ffffffffc0203824:	00003617          	auipc	a2,0x3
ffffffffc0203828:	3f460613          	addi	a2,a2,1012 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020382c:	0dd00593          	li	a1,221
ffffffffc0203830:	00004517          	auipc	a0,0x4
ffffffffc0203834:	2d050513          	addi	a0,a0,720 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203838:	c4dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc020383c:	00004697          	auipc	a3,0x4
ffffffffc0203840:	3d468693          	addi	a3,a3,980 # ffffffffc0207c10 <default_pmm_manager+0x8b0>
ffffffffc0203844:	00003617          	auipc	a2,0x3
ffffffffc0203848:	3d460613          	addi	a2,a2,980 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020384c:	0dc00593          	li	a1,220
ffffffffc0203850:	00004517          	auipc	a0,0x4
ffffffffc0203854:	2b050513          	addi	a0,a0,688 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203858:	c2dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc020385c:	00004697          	auipc	a3,0x4
ffffffffc0203860:	47c68693          	addi	a3,a3,1148 # ffffffffc0207cd8 <default_pmm_manager+0x978>
ffffffffc0203864:	00003617          	auipc	a2,0x3
ffffffffc0203868:	3b460613          	addi	a2,a2,948 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020386c:	0fb00593          	li	a1,251
ffffffffc0203870:	00004517          	auipc	a0,0x4
ffffffffc0203874:	29050513          	addi	a0,a0,656 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203878:	c0dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc020387c:	00004617          	auipc	a2,0x4
ffffffffc0203880:	26460613          	addi	a2,a2,612 # ffffffffc0207ae0 <default_pmm_manager+0x780>
ffffffffc0203884:	02800593          	li	a1,40
ffffffffc0203888:	00004517          	auipc	a0,0x4
ffffffffc020388c:	27850513          	addi	a0,a0,632 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203890:	bf5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc0203894:	00004697          	auipc	a3,0x4
ffffffffc0203898:	41468693          	addi	a3,a3,1044 # ffffffffc0207ca8 <default_pmm_manager+0x948>
ffffffffc020389c:	00003617          	auipc	a2,0x3
ffffffffc02038a0:	37c60613          	addi	a2,a2,892 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02038a4:	09700593          	li	a1,151
ffffffffc02038a8:	00004517          	auipc	a0,0x4
ffffffffc02038ac:	25850513          	addi	a0,a0,600 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02038b0:	bd5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc02038b4:	00004697          	auipc	a3,0x4
ffffffffc02038b8:	3f468693          	addi	a3,a3,1012 # ffffffffc0207ca8 <default_pmm_manager+0x948>
ffffffffc02038bc:	00003617          	auipc	a2,0x3
ffffffffc02038c0:	35c60613          	addi	a2,a2,860 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02038c4:	09900593          	li	a1,153
ffffffffc02038c8:	00004517          	auipc	a0,0x4
ffffffffc02038cc:	23850513          	addi	a0,a0,568 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02038d0:	bb5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038d4:	00004697          	auipc	a3,0x4
ffffffffc02038d8:	3e468693          	addi	a3,a3,996 # ffffffffc0207cb8 <default_pmm_manager+0x958>
ffffffffc02038dc:	00003617          	auipc	a2,0x3
ffffffffc02038e0:	33c60613          	addi	a2,a2,828 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02038e4:	09b00593          	li	a1,155
ffffffffc02038e8:	00004517          	auipc	a0,0x4
ffffffffc02038ec:	21850513          	addi	a0,a0,536 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02038f0:	b95fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038f4:	00004697          	auipc	a3,0x4
ffffffffc02038f8:	3c468693          	addi	a3,a3,964 # ffffffffc0207cb8 <default_pmm_manager+0x958>
ffffffffc02038fc:	00003617          	auipc	a2,0x3
ffffffffc0203900:	31c60613          	addi	a2,a2,796 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203904:	09d00593          	li	a1,157
ffffffffc0203908:	00004517          	auipc	a0,0x4
ffffffffc020390c:	1f850513          	addi	a0,a0,504 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203910:	b75fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203914:	00004697          	auipc	a3,0x4
ffffffffc0203918:	38468693          	addi	a3,a3,900 # ffffffffc0207c98 <default_pmm_manager+0x938>
ffffffffc020391c:	00003617          	auipc	a2,0x3
ffffffffc0203920:	2fc60613          	addi	a2,a2,764 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203924:	09300593          	li	a1,147
ffffffffc0203928:	00004517          	auipc	a0,0x4
ffffffffc020392c:	1d850513          	addi	a0,a0,472 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203930:	b55fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203934:	00004697          	auipc	a3,0x4
ffffffffc0203938:	36468693          	addi	a3,a3,868 # ffffffffc0207c98 <default_pmm_manager+0x938>
ffffffffc020393c:	00003617          	auipc	a2,0x3
ffffffffc0203940:	2dc60613          	addi	a2,a2,732 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203944:	09500593          	li	a1,149
ffffffffc0203948:	00004517          	auipc	a0,0x4
ffffffffc020394c:	1b850513          	addi	a0,a0,440 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203950:	b35fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc0203954:	00004697          	auipc	a3,0x4
ffffffffc0203958:	37468693          	addi	a3,a3,884 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc020395c:	00003617          	auipc	a2,0x3
ffffffffc0203960:	2bc60613          	addi	a2,a2,700 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203964:	09f00593          	li	a1,159
ffffffffc0203968:	00004517          	auipc	a0,0x4
ffffffffc020396c:	19850513          	addi	a0,a0,408 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203970:	b15fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc0203974:	00004697          	auipc	a3,0x4
ffffffffc0203978:	35468693          	addi	a3,a3,852 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc020397c:	00003617          	auipc	a2,0x3
ffffffffc0203980:	29c60613          	addi	a2,a2,668 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203984:	0a100593          	li	a1,161
ffffffffc0203988:	00004517          	auipc	a0,0x4
ffffffffc020398c:	17850513          	addi	a0,a0,376 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203990:	af5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203994:	00004697          	auipc	a3,0x4
ffffffffc0203998:	1e468693          	addi	a3,a3,484 # ffffffffc0207b78 <default_pmm_manager+0x818>
ffffffffc020399c:	00003617          	auipc	a2,0x3
ffffffffc02039a0:	27c60613          	addi	a2,a2,636 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02039a4:	0cc00593          	li	a1,204
ffffffffc02039a8:	00004517          	auipc	a0,0x4
ffffffffc02039ac:	15850513          	addi	a0,a0,344 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02039b0:	ad5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(vma != NULL);
ffffffffc02039b4:	00004697          	auipc	a3,0x4
ffffffffc02039b8:	1d468693          	addi	a3,a3,468 # ffffffffc0207b88 <default_pmm_manager+0x828>
ffffffffc02039bc:	00003617          	auipc	a2,0x3
ffffffffc02039c0:	25c60613          	addi	a2,a2,604 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02039c4:	0cf00593          	li	a1,207
ffffffffc02039c8:	00004517          	auipc	a0,0x4
ffffffffc02039cc:	13850513          	addi	a0,a0,312 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02039d0:	ab5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02039d4:	00004697          	auipc	a3,0x4
ffffffffc02039d8:	1fc68693          	addi	a3,a3,508 # ffffffffc0207bd0 <default_pmm_manager+0x870>
ffffffffc02039dc:	00003617          	auipc	a2,0x3
ffffffffc02039e0:	23c60613          	addi	a2,a2,572 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02039e4:	0d700593          	li	a1,215
ffffffffc02039e8:	00004517          	auipc	a0,0x4
ffffffffc02039ec:	11850513          	addi	a0,a0,280 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc02039f0:	a95fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert( nr_free == 0);         
ffffffffc02039f4:	00003697          	auipc	a3,0x3
ffffffffc02039f8:	7ac68693          	addi	a3,a3,1964 # ffffffffc02071a0 <commands+0xa48>
ffffffffc02039fc:	00003617          	auipc	a2,0x3
ffffffffc0203a00:	21c60613          	addi	a2,a2,540 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203a04:	0f300593          	li	a1,243
ffffffffc0203a08:	00004517          	auipc	a0,0x4
ffffffffc0203a0c:	0f850513          	addi	a0,a0,248 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203a10:	a75fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203a14:	00004617          	auipc	a2,0x4
ffffffffc0203a18:	99c60613          	addi	a2,a2,-1636 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0203a1c:	06900593          	li	a1,105
ffffffffc0203a20:	00004517          	auipc	a0,0x4
ffffffffc0203a24:	9b850513          	addi	a0,a0,-1608 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0203a28:	a5dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(count==0);
ffffffffc0203a2c:	00004697          	auipc	a3,0x4
ffffffffc0203a30:	31c68693          	addi	a3,a3,796 # ffffffffc0207d48 <default_pmm_manager+0x9e8>
ffffffffc0203a34:	00003617          	auipc	a2,0x3
ffffffffc0203a38:	1e460613          	addi	a2,a2,484 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203a3c:	11d00593          	li	a1,285
ffffffffc0203a40:	00004517          	auipc	a0,0x4
ffffffffc0203a44:	0c050513          	addi	a0,a0,192 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203a48:	a3dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total==0);
ffffffffc0203a4c:	00004697          	auipc	a3,0x4
ffffffffc0203a50:	30c68693          	addi	a3,a3,780 # ffffffffc0207d58 <default_pmm_manager+0x9f8>
ffffffffc0203a54:	00003617          	auipc	a2,0x3
ffffffffc0203a58:	1c460613          	addi	a2,a2,452 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203a5c:	11e00593          	li	a1,286
ffffffffc0203a60:	00004517          	auipc	a0,0x4
ffffffffc0203a64:	0a050513          	addi	a0,a0,160 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203a68:	a1dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a6c:	00004697          	auipc	a3,0x4
ffffffffc0203a70:	1dc68693          	addi	a3,a3,476 # ffffffffc0207c48 <default_pmm_manager+0x8e8>
ffffffffc0203a74:	00003617          	auipc	a2,0x3
ffffffffc0203a78:	1a460613          	addi	a2,a2,420 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203a7c:	0ea00593          	li	a1,234
ffffffffc0203a80:	00004517          	auipc	a0,0x4
ffffffffc0203a84:	08050513          	addi	a0,a0,128 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203a88:	9fdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(mm != NULL);
ffffffffc0203a8c:	00004697          	auipc	a3,0x4
ffffffffc0203a90:	0c468693          	addi	a3,a3,196 # ffffffffc0207b50 <default_pmm_manager+0x7f0>
ffffffffc0203a94:	00003617          	auipc	a2,0x3
ffffffffc0203a98:	18460613          	addi	a2,a2,388 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203a9c:	0c400593          	li	a1,196
ffffffffc0203aa0:	00004517          	auipc	a0,0x4
ffffffffc0203aa4:	06050513          	addi	a0,a0,96 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203aa8:	9ddfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203aac:	00004697          	auipc	a3,0x4
ffffffffc0203ab0:	0b468693          	addi	a3,a3,180 # ffffffffc0207b60 <default_pmm_manager+0x800>
ffffffffc0203ab4:	00003617          	auipc	a2,0x3
ffffffffc0203ab8:	16460613          	addi	a2,a2,356 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203abc:	0c700593          	li	a1,199
ffffffffc0203ac0:	00004517          	auipc	a0,0x4
ffffffffc0203ac4:	04050513          	addi	a0,a0,64 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203ac8:	9bdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(ret==0);
ffffffffc0203acc:	00004697          	auipc	a3,0x4
ffffffffc0203ad0:	27468693          	addi	a3,a3,628 # ffffffffc0207d40 <default_pmm_manager+0x9e0>
ffffffffc0203ad4:	00003617          	auipc	a2,0x3
ffffffffc0203ad8:	14460613          	addi	a2,a2,324 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203adc:	10200593          	li	a1,258
ffffffffc0203ae0:	00004517          	auipc	a0,0x4
ffffffffc0203ae4:	02050513          	addi	a0,a0,32 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203ae8:	99dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203aec:	00003697          	auipc	a3,0x3
ffffffffc0203af0:	50c68693          	addi	a3,a3,1292 # ffffffffc0206ff8 <commands+0x8a0>
ffffffffc0203af4:	00003617          	auipc	a2,0x3
ffffffffc0203af8:	12460613          	addi	a2,a2,292 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203afc:	0bf00593          	li	a1,191
ffffffffc0203b00:	00004517          	auipc	a0,0x4
ffffffffc0203b04:	00050513          	mv	a0,a0
ffffffffc0203b08:	97dfc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203b0c <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b0c:	000a9797          	auipc	a5,0xa9
ffffffffc0203b10:	97478793          	addi	a5,a5,-1676 # ffffffffc02ac480 <sm>
ffffffffc0203b14:	639c                	ld	a5,0(a5)
ffffffffc0203b16:	0107b303          	ld	t1,16(a5)
ffffffffc0203b1a:	8302                	jr	t1

ffffffffc0203b1c <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b1c:	000a9797          	auipc	a5,0xa9
ffffffffc0203b20:	96478793          	addi	a5,a5,-1692 # ffffffffc02ac480 <sm>
ffffffffc0203b24:	639c                	ld	a5,0(a5)
ffffffffc0203b26:	0207b303          	ld	t1,32(a5)
ffffffffc0203b2a:	8302                	jr	t1

ffffffffc0203b2c <swap_out>:
{
ffffffffc0203b2c:	711d                	addi	sp,sp,-96
ffffffffc0203b2e:	ec86                	sd	ra,88(sp)
ffffffffc0203b30:	e8a2                	sd	s0,80(sp)
ffffffffc0203b32:	e4a6                	sd	s1,72(sp)
ffffffffc0203b34:	e0ca                	sd	s2,64(sp)
ffffffffc0203b36:	fc4e                	sd	s3,56(sp)
ffffffffc0203b38:	f852                	sd	s4,48(sp)
ffffffffc0203b3a:	f456                	sd	s5,40(sp)
ffffffffc0203b3c:	f05a                	sd	s6,32(sp)
ffffffffc0203b3e:	ec5e                	sd	s7,24(sp)
ffffffffc0203b40:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b42:	cde9                	beqz	a1,ffffffffc0203c1c <swap_out+0xf0>
ffffffffc0203b44:	8ab2                	mv	s5,a2
ffffffffc0203b46:	892a                	mv	s2,a0
ffffffffc0203b48:	8a2e                	mv	s4,a1
ffffffffc0203b4a:	4401                	li	s0,0
ffffffffc0203b4c:	000a9997          	auipc	s3,0xa9
ffffffffc0203b50:	93498993          	addi	s3,s3,-1740 # ffffffffc02ac480 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b54:	00004b17          	auipc	s6,0x4
ffffffffc0203b58:	294b0b13          	addi	s6,s6,660 # ffffffffc0207de8 <default_pmm_manager+0xa88>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203b5c:	00004b97          	auipc	s7,0x4
ffffffffc0203b60:	274b8b93          	addi	s7,s7,628 # ffffffffc0207dd0 <default_pmm_manager+0xa70>
ffffffffc0203b64:	a825                	j	ffffffffc0203b9c <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b66:	67a2                	ld	a5,8(sp)
ffffffffc0203b68:	8626                	mv	a2,s1
ffffffffc0203b6a:	85a2                	mv	a1,s0
ffffffffc0203b6c:	7f94                	ld	a3,56(a5)
ffffffffc0203b6e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203b70:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b72:	82b1                	srli	a3,a3,0xc
ffffffffc0203b74:	0685                	addi	a3,a3,1
ffffffffc0203b76:	e18fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b7a:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203b7c:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b7e:	7d1c                	ld	a5,56(a0)
ffffffffc0203b80:	83b1                	srli	a5,a5,0xc
ffffffffc0203b82:	0785                	addi	a5,a5,1
ffffffffc0203b84:	07a2                	slli	a5,a5,0x8
ffffffffc0203b86:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203b8a:	b50fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203b8e:	01893503          	ld	a0,24(s2)
ffffffffc0203b92:	85a6                	mv	a1,s1
ffffffffc0203b94:	f5eff0ef          	jal	ra,ffffffffc02032f2 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203b98:	048a0d63          	beq	s4,s0,ffffffffc0203bf2 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203b9c:	0009b783          	ld	a5,0(s3)
ffffffffc0203ba0:	8656                	mv	a2,s5
ffffffffc0203ba2:	002c                	addi	a1,sp,8
ffffffffc0203ba4:	7b9c                	ld	a5,48(a5)
ffffffffc0203ba6:	854a                	mv	a0,s2
ffffffffc0203ba8:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203baa:	e12d                	bnez	a0,ffffffffc0203c0c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203bac:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bae:	01893503          	ld	a0,24(s2)
ffffffffc0203bb2:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203bb4:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bb6:	85a6                	mv	a1,s1
ffffffffc0203bb8:	ba8fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bbc:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bbe:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bc0:	8b85                	andi	a5,a5,1
ffffffffc0203bc2:	cfb9                	beqz	a5,ffffffffc0203c20 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203bc4:	65a2                	ld	a1,8(sp)
ffffffffc0203bc6:	7d9c                	ld	a5,56(a1)
ffffffffc0203bc8:	83b1                	srli	a5,a5,0xc
ffffffffc0203bca:	00178513          	addi	a0,a5,1
ffffffffc0203bce:	0522                	slli	a0,a0,0x8
ffffffffc0203bd0:	038010ef          	jal	ra,ffffffffc0204c08 <swapfs_write>
ffffffffc0203bd4:	d949                	beqz	a0,ffffffffc0203b66 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bd6:	855e                	mv	a0,s7
ffffffffc0203bd8:	db6fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203bdc:	0009b783          	ld	a5,0(s3)
ffffffffc0203be0:	6622                	ld	a2,8(sp)
ffffffffc0203be2:	4681                	li	a3,0
ffffffffc0203be4:	739c                	ld	a5,32(a5)
ffffffffc0203be6:	85a6                	mv	a1,s1
ffffffffc0203be8:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203bea:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203bec:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203bee:	fa8a17e3          	bne	s4,s0,ffffffffc0203b9c <swap_out+0x70>
}
ffffffffc0203bf2:	8522                	mv	a0,s0
ffffffffc0203bf4:	60e6                	ld	ra,88(sp)
ffffffffc0203bf6:	6446                	ld	s0,80(sp)
ffffffffc0203bf8:	64a6                	ld	s1,72(sp)
ffffffffc0203bfa:	6906                	ld	s2,64(sp)
ffffffffc0203bfc:	79e2                	ld	s3,56(sp)
ffffffffc0203bfe:	7a42                	ld	s4,48(sp)
ffffffffc0203c00:	7aa2                	ld	s5,40(sp)
ffffffffc0203c02:	7b02                	ld	s6,32(sp)
ffffffffc0203c04:	6be2                	ld	s7,24(sp)
ffffffffc0203c06:	6c42                	ld	s8,16(sp)
ffffffffc0203c08:	6125                	addi	sp,sp,96
ffffffffc0203c0a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c0c:	85a2                	mv	a1,s0
ffffffffc0203c0e:	00004517          	auipc	a0,0x4
ffffffffc0203c12:	17a50513          	addi	a0,a0,378 # ffffffffc0207d88 <default_pmm_manager+0xa28>
ffffffffc0203c16:	d78fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                  break;
ffffffffc0203c1a:	bfe1                	j	ffffffffc0203bf2 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c1c:	4401                	li	s0,0
ffffffffc0203c1e:	bfd1                	j	ffffffffc0203bf2 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c20:	00004697          	auipc	a3,0x4
ffffffffc0203c24:	19868693          	addi	a3,a3,408 # ffffffffc0207db8 <default_pmm_manager+0xa58>
ffffffffc0203c28:	00003617          	auipc	a2,0x3
ffffffffc0203c2c:	ff060613          	addi	a2,a2,-16 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203c30:	06800593          	li	a1,104
ffffffffc0203c34:	00004517          	auipc	a0,0x4
ffffffffc0203c38:	ecc50513          	addi	a0,a0,-308 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203c3c:	849fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203c40 <swap_in>:
{
ffffffffc0203c40:	7179                	addi	sp,sp,-48
ffffffffc0203c42:	e84a                	sd	s2,16(sp)
ffffffffc0203c44:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203c46:	4505                	li	a0,1
{
ffffffffc0203c48:	ec26                	sd	s1,24(sp)
ffffffffc0203c4a:	e44e                	sd	s3,8(sp)
ffffffffc0203c4c:	f406                	sd	ra,40(sp)
ffffffffc0203c4e:	f022                	sd	s0,32(sp)
ffffffffc0203c50:	84ae                	mv	s1,a1
ffffffffc0203c52:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203c54:	9fefe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203c58:	c129                	beqz	a0,ffffffffc0203c9a <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203c5a:	842a                	mv	s0,a0
ffffffffc0203c5c:	01893503          	ld	a0,24(s2)
ffffffffc0203c60:	4601                	li	a2,0
ffffffffc0203c62:	85a6                	mv	a1,s1
ffffffffc0203c64:	afcfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203c68:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203c6a:	6108                	ld	a0,0(a0)
ffffffffc0203c6c:	85a2                	mv	a1,s0
ffffffffc0203c6e:	703000ef          	jal	ra,ffffffffc0204b70 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203c72:	00093583          	ld	a1,0(s2)
ffffffffc0203c76:	8626                	mv	a2,s1
ffffffffc0203c78:	00004517          	auipc	a0,0x4
ffffffffc0203c7c:	e2850513          	addi	a0,a0,-472 # ffffffffc0207aa0 <default_pmm_manager+0x740>
ffffffffc0203c80:	81a1                	srli	a1,a1,0x8
ffffffffc0203c82:	d0cfc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203c86:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203c88:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203c8c:	7402                	ld	s0,32(sp)
ffffffffc0203c8e:	64e2                	ld	s1,24(sp)
ffffffffc0203c90:	6942                	ld	s2,16(sp)
ffffffffc0203c92:	69a2                	ld	s3,8(sp)
ffffffffc0203c94:	4501                	li	a0,0
ffffffffc0203c96:	6145                	addi	sp,sp,48
ffffffffc0203c98:	8082                	ret
     assert(result!=NULL);
ffffffffc0203c9a:	00004697          	auipc	a3,0x4
ffffffffc0203c9e:	df668693          	addi	a3,a3,-522 # ffffffffc0207a90 <default_pmm_manager+0x730>
ffffffffc0203ca2:	00003617          	auipc	a2,0x3
ffffffffc0203ca6:	f7660613          	addi	a2,a2,-138 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203caa:	07e00593          	li	a1,126
ffffffffc0203cae:	00004517          	auipc	a0,0x4
ffffffffc0203cb2:	e5250513          	addi	a0,a0,-430 # ffffffffc0207b00 <default_pmm_manager+0x7a0>
ffffffffc0203cb6:	fcefc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203cba <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203cba:	000a9797          	auipc	a5,0xa9
ffffffffc0203cbe:	8fe78793          	addi	a5,a5,-1794 # ffffffffc02ac5b8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203cc2:	f51c                	sd	a5,40(a0)
ffffffffc0203cc4:	e79c                	sd	a5,8(a5)
ffffffffc0203cc6:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203cc8:	4501                	li	a0,0
ffffffffc0203cca:	8082                	ret

ffffffffc0203ccc <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203ccc:	4501                	li	a0,0
ffffffffc0203cce:	8082                	ret

ffffffffc0203cd0 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203cd0:	4501                	li	a0,0
ffffffffc0203cd2:	8082                	ret

ffffffffc0203cd4 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203cd4:	4501                	li	a0,0
ffffffffc0203cd6:	8082                	ret

ffffffffc0203cd8 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203cd8:	711d                	addi	sp,sp,-96
ffffffffc0203cda:	fc4e                	sd	s3,56(sp)
ffffffffc0203cdc:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cde:	00004517          	auipc	a0,0x4
ffffffffc0203ce2:	14a50513          	addi	a0,a0,330 # ffffffffc0207e28 <default_pmm_manager+0xac8>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203ce6:	698d                	lui	s3,0x3
ffffffffc0203ce8:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203cea:	e8a2                	sd	s0,80(sp)
ffffffffc0203cec:	e4a6                	sd	s1,72(sp)
ffffffffc0203cee:	ec86                	sd	ra,88(sp)
ffffffffc0203cf0:	e0ca                	sd	s2,64(sp)
ffffffffc0203cf2:	f456                	sd	s5,40(sp)
ffffffffc0203cf4:	f05a                	sd	s6,32(sp)
ffffffffc0203cf6:	ec5e                	sd	s7,24(sp)
ffffffffc0203cf8:	e862                	sd	s8,16(sp)
ffffffffc0203cfa:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc0203cfc:	000a8417          	auipc	s0,0xa8
ffffffffc0203d00:	79040413          	addi	s0,s0,1936 # ffffffffc02ac48c <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d04:	c8afc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d08:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
    assert(pgfault_num==4);
ffffffffc0203d0c:	4004                	lw	s1,0(s0)
ffffffffc0203d0e:	4791                	li	a5,4
ffffffffc0203d10:	2481                	sext.w	s1,s1
ffffffffc0203d12:	14f49963          	bne	s1,a5,ffffffffc0203e64 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d16:	00004517          	auipc	a0,0x4
ffffffffc0203d1a:	15250513          	addi	a0,a0,338 # ffffffffc0207e68 <default_pmm_manager+0xb08>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d1e:	6a85                	lui	s5,0x1
ffffffffc0203d20:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d22:	c6cfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d26:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
    assert(pgfault_num==4);
ffffffffc0203d2a:	00042903          	lw	s2,0(s0)
ffffffffc0203d2e:	2901                	sext.w	s2,s2
ffffffffc0203d30:	2a991a63          	bne	s2,s1,ffffffffc0203fe4 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d34:	00004517          	auipc	a0,0x4
ffffffffc0203d38:	15c50513          	addi	a0,a0,348 # ffffffffc0207e90 <default_pmm_manager+0xb30>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d3c:	6b91                	lui	s7,0x4
ffffffffc0203d3e:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d40:	c4efc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d44:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
    assert(pgfault_num==4);
ffffffffc0203d48:	4004                	lw	s1,0(s0)
ffffffffc0203d4a:	2481                	sext.w	s1,s1
ffffffffc0203d4c:	27249c63          	bne	s1,s2,ffffffffc0203fc4 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d50:	00004517          	auipc	a0,0x4
ffffffffc0203d54:	16850513          	addi	a0,a0,360 # ffffffffc0207eb8 <default_pmm_manager+0xb58>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d58:	6909                	lui	s2,0x2
ffffffffc0203d5a:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d5c:	c32fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d60:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
    assert(pgfault_num==4);
ffffffffc0203d64:	401c                	lw	a5,0(s0)
ffffffffc0203d66:	2781                	sext.w	a5,a5
ffffffffc0203d68:	22979e63          	bne	a5,s1,ffffffffc0203fa4 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203d6c:	00004517          	auipc	a0,0x4
ffffffffc0203d70:	17450513          	addi	a0,a0,372 # ffffffffc0207ee0 <default_pmm_manager+0xb80>
ffffffffc0203d74:	c1afc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203d78:	6795                	lui	a5,0x5
ffffffffc0203d7a:	4739                	li	a4,14
ffffffffc0203d7c:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==5);
ffffffffc0203d80:	4004                	lw	s1,0(s0)
ffffffffc0203d82:	4795                	li	a5,5
ffffffffc0203d84:	2481                	sext.w	s1,s1
ffffffffc0203d86:	1ef49f63          	bne	s1,a5,ffffffffc0203f84 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d8a:	00004517          	auipc	a0,0x4
ffffffffc0203d8e:	12e50513          	addi	a0,a0,302 # ffffffffc0207eb8 <default_pmm_manager+0xb58>
ffffffffc0203d92:	bfcfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d96:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc0203d9a:	401c                	lw	a5,0(s0)
ffffffffc0203d9c:	2781                	sext.w	a5,a5
ffffffffc0203d9e:	1c979363          	bne	a5,s1,ffffffffc0203f64 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203da2:	00004517          	auipc	a0,0x4
ffffffffc0203da6:	0c650513          	addi	a0,a0,198 # ffffffffc0207e68 <default_pmm_manager+0xb08>
ffffffffc0203daa:	be4fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203dae:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203db2:	401c                	lw	a5,0(s0)
ffffffffc0203db4:	4719                	li	a4,6
ffffffffc0203db6:	2781                	sext.w	a5,a5
ffffffffc0203db8:	18e79663          	bne	a5,a4,ffffffffc0203f44 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dbc:	00004517          	auipc	a0,0x4
ffffffffc0203dc0:	0fc50513          	addi	a0,a0,252 # ffffffffc0207eb8 <default_pmm_manager+0xb58>
ffffffffc0203dc4:	bcafc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dc8:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc0203dcc:	401c                	lw	a5,0(s0)
ffffffffc0203dce:	471d                	li	a4,7
ffffffffc0203dd0:	2781                	sext.w	a5,a5
ffffffffc0203dd2:	14e79963          	bne	a5,a4,ffffffffc0203f24 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203dd6:	00004517          	auipc	a0,0x4
ffffffffc0203dda:	05250513          	addi	a0,a0,82 # ffffffffc0207e28 <default_pmm_manager+0xac8>
ffffffffc0203dde:	bb0fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203de2:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203de6:	401c                	lw	a5,0(s0)
ffffffffc0203de8:	4721                	li	a4,8
ffffffffc0203dea:	2781                	sext.w	a5,a5
ffffffffc0203dec:	10e79c63          	bne	a5,a4,ffffffffc0203f04 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203df0:	00004517          	auipc	a0,0x4
ffffffffc0203df4:	0a050513          	addi	a0,a0,160 # ffffffffc0207e90 <default_pmm_manager+0xb30>
ffffffffc0203df8:	b96fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203dfc:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203e00:	401c                	lw	a5,0(s0)
ffffffffc0203e02:	4725                	li	a4,9
ffffffffc0203e04:	2781                	sext.w	a5,a5
ffffffffc0203e06:	0ce79f63          	bne	a5,a4,ffffffffc0203ee4 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e0a:	00004517          	auipc	a0,0x4
ffffffffc0203e0e:	0d650513          	addi	a0,a0,214 # ffffffffc0207ee0 <default_pmm_manager+0xb80>
ffffffffc0203e12:	b7cfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e16:	6795                	lui	a5,0x5
ffffffffc0203e18:	4739                	li	a4,14
ffffffffc0203e1a:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==10);
ffffffffc0203e1e:	4004                	lw	s1,0(s0)
ffffffffc0203e20:	47a9                	li	a5,10
ffffffffc0203e22:	2481                	sext.w	s1,s1
ffffffffc0203e24:	0af49063          	bne	s1,a5,ffffffffc0203ec4 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e28:	00004517          	auipc	a0,0x4
ffffffffc0203e2c:	04050513          	addi	a0,a0,64 # ffffffffc0207e68 <default_pmm_manager+0xb08>
ffffffffc0203e30:	b5efc0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e34:	6785                	lui	a5,0x1
ffffffffc0203e36:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc0203e3a:	06979563          	bne	a5,s1,ffffffffc0203ea4 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc0203e3e:	401c                	lw	a5,0(s0)
ffffffffc0203e40:	472d                	li	a4,11
ffffffffc0203e42:	2781                	sext.w	a5,a5
ffffffffc0203e44:	04e79063          	bne	a5,a4,ffffffffc0203e84 <_fifo_check_swap+0x1ac>
}
ffffffffc0203e48:	60e6                	ld	ra,88(sp)
ffffffffc0203e4a:	6446                	ld	s0,80(sp)
ffffffffc0203e4c:	64a6                	ld	s1,72(sp)
ffffffffc0203e4e:	6906                	ld	s2,64(sp)
ffffffffc0203e50:	79e2                	ld	s3,56(sp)
ffffffffc0203e52:	7a42                	ld	s4,48(sp)
ffffffffc0203e54:	7aa2                	ld	s5,40(sp)
ffffffffc0203e56:	7b02                	ld	s6,32(sp)
ffffffffc0203e58:	6be2                	ld	s7,24(sp)
ffffffffc0203e5a:	6c42                	ld	s8,16(sp)
ffffffffc0203e5c:	6ca2                	ld	s9,8(sp)
ffffffffc0203e5e:	4501                	li	a0,0
ffffffffc0203e60:	6125                	addi	sp,sp,96
ffffffffc0203e62:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203e64:	00004697          	auipc	a3,0x4
ffffffffc0203e68:	e6468693          	addi	a3,a3,-412 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc0203e6c:	00003617          	auipc	a2,0x3
ffffffffc0203e70:	dac60613          	addi	a2,a2,-596 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203e74:	05100593          	li	a1,81
ffffffffc0203e78:	00004517          	auipc	a0,0x4
ffffffffc0203e7c:	fd850513          	addi	a0,a0,-40 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203e80:	e04fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==11);
ffffffffc0203e84:	00004697          	auipc	a3,0x4
ffffffffc0203e88:	10c68693          	addi	a3,a3,268 # ffffffffc0207f90 <default_pmm_manager+0xc30>
ffffffffc0203e8c:	00003617          	auipc	a2,0x3
ffffffffc0203e90:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203e94:	07300593          	li	a1,115
ffffffffc0203e98:	00004517          	auipc	a0,0x4
ffffffffc0203e9c:	fb850513          	addi	a0,a0,-72 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203ea0:	de4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203ea4:	00004697          	auipc	a3,0x4
ffffffffc0203ea8:	0c468693          	addi	a3,a3,196 # ffffffffc0207f68 <default_pmm_manager+0xc08>
ffffffffc0203eac:	00003617          	auipc	a2,0x3
ffffffffc0203eb0:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203eb4:	07100593          	li	a1,113
ffffffffc0203eb8:	00004517          	auipc	a0,0x4
ffffffffc0203ebc:	f9850513          	addi	a0,a0,-104 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203ec0:	dc4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==10);
ffffffffc0203ec4:	00004697          	auipc	a3,0x4
ffffffffc0203ec8:	09468693          	addi	a3,a3,148 # ffffffffc0207f58 <default_pmm_manager+0xbf8>
ffffffffc0203ecc:	00003617          	auipc	a2,0x3
ffffffffc0203ed0:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203ed4:	06f00593          	li	a1,111
ffffffffc0203ed8:	00004517          	auipc	a0,0x4
ffffffffc0203edc:	f7850513          	addi	a0,a0,-136 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203ee0:	da4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==9);
ffffffffc0203ee4:	00004697          	auipc	a3,0x4
ffffffffc0203ee8:	06468693          	addi	a3,a3,100 # ffffffffc0207f48 <default_pmm_manager+0xbe8>
ffffffffc0203eec:	00003617          	auipc	a2,0x3
ffffffffc0203ef0:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203ef4:	06c00593          	li	a1,108
ffffffffc0203ef8:	00004517          	auipc	a0,0x4
ffffffffc0203efc:	f5850513          	addi	a0,a0,-168 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203f00:	d84fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==8);
ffffffffc0203f04:	00004697          	auipc	a3,0x4
ffffffffc0203f08:	03468693          	addi	a3,a3,52 # ffffffffc0207f38 <default_pmm_manager+0xbd8>
ffffffffc0203f0c:	00003617          	auipc	a2,0x3
ffffffffc0203f10:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203f14:	06900593          	li	a1,105
ffffffffc0203f18:	00004517          	auipc	a0,0x4
ffffffffc0203f1c:	f3850513          	addi	a0,a0,-200 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203f20:	d64fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==7);
ffffffffc0203f24:	00004697          	auipc	a3,0x4
ffffffffc0203f28:	00468693          	addi	a3,a3,4 # ffffffffc0207f28 <default_pmm_manager+0xbc8>
ffffffffc0203f2c:	00003617          	auipc	a2,0x3
ffffffffc0203f30:	cec60613          	addi	a2,a2,-788 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203f34:	06600593          	li	a1,102
ffffffffc0203f38:	00004517          	auipc	a0,0x4
ffffffffc0203f3c:	f1850513          	addi	a0,a0,-232 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203f40:	d44fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==6);
ffffffffc0203f44:	00004697          	auipc	a3,0x4
ffffffffc0203f48:	fd468693          	addi	a3,a3,-44 # ffffffffc0207f18 <default_pmm_manager+0xbb8>
ffffffffc0203f4c:	00003617          	auipc	a2,0x3
ffffffffc0203f50:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203f54:	06300593          	li	a1,99
ffffffffc0203f58:	00004517          	auipc	a0,0x4
ffffffffc0203f5c:	ef850513          	addi	a0,a0,-264 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203f60:	d24fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203f64:	00004697          	auipc	a3,0x4
ffffffffc0203f68:	fa468693          	addi	a3,a3,-92 # ffffffffc0207f08 <default_pmm_manager+0xba8>
ffffffffc0203f6c:	00003617          	auipc	a2,0x3
ffffffffc0203f70:	cac60613          	addi	a2,a2,-852 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203f74:	06000593          	li	a1,96
ffffffffc0203f78:	00004517          	auipc	a0,0x4
ffffffffc0203f7c:	ed850513          	addi	a0,a0,-296 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203f80:	d04fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203f84:	00004697          	auipc	a3,0x4
ffffffffc0203f88:	f8468693          	addi	a3,a3,-124 # ffffffffc0207f08 <default_pmm_manager+0xba8>
ffffffffc0203f8c:	00003617          	auipc	a2,0x3
ffffffffc0203f90:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203f94:	05d00593          	li	a1,93
ffffffffc0203f98:	00004517          	auipc	a0,0x4
ffffffffc0203f9c:	eb850513          	addi	a0,a0,-328 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203fa0:	ce4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fa4:	00004697          	auipc	a3,0x4
ffffffffc0203fa8:	d2468693          	addi	a3,a3,-732 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc0203fac:	00003617          	auipc	a2,0x3
ffffffffc0203fb0:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203fb4:	05a00593          	li	a1,90
ffffffffc0203fb8:	00004517          	auipc	a0,0x4
ffffffffc0203fbc:	e9850513          	addi	a0,a0,-360 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203fc0:	cc4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fc4:	00004697          	auipc	a3,0x4
ffffffffc0203fc8:	d0468693          	addi	a3,a3,-764 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc0203fcc:	00003617          	auipc	a2,0x3
ffffffffc0203fd0:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203fd4:	05700593          	li	a1,87
ffffffffc0203fd8:	00004517          	auipc	a0,0x4
ffffffffc0203fdc:	e7850513          	addi	a0,a0,-392 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0203fe0:	ca4fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fe4:	00004697          	auipc	a3,0x4
ffffffffc0203fe8:	ce468693          	addi	a3,a3,-796 # ffffffffc0207cc8 <default_pmm_manager+0x968>
ffffffffc0203fec:	00003617          	auipc	a2,0x3
ffffffffc0203ff0:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0203ff4:	05400593          	li	a1,84
ffffffffc0203ff8:	00004517          	auipc	a0,0x4
ffffffffc0203ffc:	e5850513          	addi	a0,a0,-424 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0204000:	c84fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204004 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0204004:	751c                	ld	a5,40(a0)
{
ffffffffc0204006:	1141                	addi	sp,sp,-16
ffffffffc0204008:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020400a:	cf91                	beqz	a5,ffffffffc0204026 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc020400c:	ee0d                	bnez	a2,ffffffffc0204046 <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc020400e:	679c                	ld	a5,8(a5)
}
ffffffffc0204010:	60a2                	ld	ra,8(sp)
ffffffffc0204012:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0204014:	6394                	ld	a3,0(a5)
ffffffffc0204016:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc0204018:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc020401c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020401e:	e314                	sd	a3,0(a4)
ffffffffc0204020:	e19c                	sd	a5,0(a1)
}
ffffffffc0204022:	0141                	addi	sp,sp,16
ffffffffc0204024:	8082                	ret
         assert(head != NULL);
ffffffffc0204026:	00004697          	auipc	a3,0x4
ffffffffc020402a:	f9a68693          	addi	a3,a3,-102 # ffffffffc0207fc0 <default_pmm_manager+0xc60>
ffffffffc020402e:	00003617          	auipc	a2,0x3
ffffffffc0204032:	bea60613          	addi	a2,a2,-1046 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204036:	04100593          	li	a1,65
ffffffffc020403a:	00004517          	auipc	a0,0x4
ffffffffc020403e:	e1650513          	addi	a0,a0,-490 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0204042:	c42fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(in_tick==0);
ffffffffc0204046:	00004697          	auipc	a3,0x4
ffffffffc020404a:	f8a68693          	addi	a3,a3,-118 # ffffffffc0207fd0 <default_pmm_manager+0xc70>
ffffffffc020404e:	00003617          	auipc	a2,0x3
ffffffffc0204052:	bca60613          	addi	a2,a2,-1078 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204056:	04200593          	li	a1,66
ffffffffc020405a:	00004517          	auipc	a0,0x4
ffffffffc020405e:	df650513          	addi	a0,a0,-522 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
ffffffffc0204062:	c22fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204066 <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc0204066:	02860713          	addi	a4,a2,40
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020406a:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020406c:	cb09                	beqz	a4,ffffffffc020407e <_fifo_map_swappable+0x18>
ffffffffc020406e:	cb81                	beqz	a5,ffffffffc020407e <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204070:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc0204072:	e398                	sd	a4,0(a5)
}
ffffffffc0204074:	4501                	li	a0,0
ffffffffc0204076:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0204078:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020407a:	f614                	sd	a3,40(a2)
ffffffffc020407c:	8082                	ret
{
ffffffffc020407e:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0204080:	00004697          	auipc	a3,0x4
ffffffffc0204084:	f2068693          	addi	a3,a3,-224 # ffffffffc0207fa0 <default_pmm_manager+0xc40>
ffffffffc0204088:	00003617          	auipc	a2,0x3
ffffffffc020408c:	b9060613          	addi	a2,a2,-1136 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204090:	03200593          	li	a1,50
ffffffffc0204094:	00004517          	auipc	a0,0x4
ffffffffc0204098:	dbc50513          	addi	a0,a0,-580 # ffffffffc0207e50 <default_pmm_manager+0xaf0>
{
ffffffffc020409c:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020409e:	be6fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02040a2 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02040a2:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02040a4:	00004697          	auipc	a3,0x4
ffffffffc02040a8:	f5468693          	addi	a3,a3,-172 # ffffffffc0207ff8 <default_pmm_manager+0xc98>
ffffffffc02040ac:	00003617          	auipc	a2,0x3
ffffffffc02040b0:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02040b4:	06d00593          	li	a1,109
ffffffffc02040b8:	00004517          	auipc	a0,0x4
ffffffffc02040bc:	f6050513          	addi	a0,a0,-160 # ffffffffc0208018 <default_pmm_manager+0xcb8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02040c0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02040c2:	bc2fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02040c6 <mm_create>:
mm_create(void) {
ffffffffc02040c6:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040c8:	04000513          	li	a0,64
mm_create(void) {
ffffffffc02040cc:	e022                	sd	s0,0(sp)
ffffffffc02040ce:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040d0:	b87fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02040d4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02040d6:	c515                	beqz	a0,ffffffffc0204102 <mm_create+0x3c>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040d8:	000a8797          	auipc	a5,0xa8
ffffffffc02040dc:	3b078793          	addi	a5,a5,944 # ffffffffc02ac488 <swap_init_ok>
ffffffffc02040e0:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02040e2:	e408                	sd	a0,8(s0)
ffffffffc02040e4:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02040e6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02040ea:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02040ee:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040f2:	2781                	sext.w	a5,a5
ffffffffc02040f4:	ef81                	bnez	a5,ffffffffc020410c <mm_create+0x46>
        else mm->sm_priv = NULL;
ffffffffc02040f6:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02040fa:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02040fe:	02043c23          	sd	zero,56(s0)
}
ffffffffc0204102:	8522                	mv	a0,s0
ffffffffc0204104:	60a2                	ld	ra,8(sp)
ffffffffc0204106:	6402                	ld	s0,0(sp)
ffffffffc0204108:	0141                	addi	sp,sp,16
ffffffffc020410a:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020410c:	a01ff0ef          	jal	ra,ffffffffc0203b0c <swap_init_mm>
ffffffffc0204110:	b7ed                	j	ffffffffc02040fa <mm_create+0x34>

ffffffffc0204112 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204112:	1101                	addi	sp,sp,-32
ffffffffc0204114:	e04a                	sd	s2,0(sp)
ffffffffc0204116:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204118:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020411c:	e822                	sd	s0,16(sp)
ffffffffc020411e:	e426                	sd	s1,8(sp)
ffffffffc0204120:	ec06                	sd	ra,24(sp)
ffffffffc0204122:	84ae                	mv	s1,a1
ffffffffc0204124:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204126:	b31fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
    if (vma != NULL) {
ffffffffc020412a:	c509                	beqz	a0,ffffffffc0204134 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc020412c:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204130:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204132:	cd00                	sw	s0,24(a0)
}
ffffffffc0204134:	60e2                	ld	ra,24(sp)
ffffffffc0204136:	6442                	ld	s0,16(sp)
ffffffffc0204138:	64a2                	ld	s1,8(sp)
ffffffffc020413a:	6902                	ld	s2,0(sp)
ffffffffc020413c:	6105                	addi	sp,sp,32
ffffffffc020413e:	8082                	ret

ffffffffc0204140 <find_vma>:
    if (mm != NULL) {
ffffffffc0204140:	c51d                	beqz	a0,ffffffffc020416e <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0204142:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204144:	c781                	beqz	a5,ffffffffc020414c <find_vma+0xc>
ffffffffc0204146:	6798                	ld	a4,8(a5)
ffffffffc0204148:	02e5f663          	bleu	a4,a1,ffffffffc0204174 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020414c:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc020414e:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0204150:	00f50f63          	beq	a0,a5,ffffffffc020416e <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0204154:	fe87b703          	ld	a4,-24(a5)
ffffffffc0204158:	fee5ebe3          	bltu	a1,a4,ffffffffc020414e <find_vma+0xe>
ffffffffc020415c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0204160:	fee5f7e3          	bleu	a4,a1,ffffffffc020414e <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0204164:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0204166:	c781                	beqz	a5,ffffffffc020416e <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0204168:	e91c                	sd	a5,16(a0)
}
ffffffffc020416a:	853e                	mv	a0,a5
ffffffffc020416c:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc020416e:	4781                	li	a5,0
}
ffffffffc0204170:	853e                	mv	a0,a5
ffffffffc0204172:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204174:	6b98                	ld	a4,16(a5)
ffffffffc0204176:	fce5fbe3          	bleu	a4,a1,ffffffffc020414c <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020417a:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc020417c:	b7fd                	j	ffffffffc020416a <find_vma+0x2a>

ffffffffc020417e <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc020417e:	6590                	ld	a2,8(a1)
ffffffffc0204180:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8560>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0204184:	1141                	addi	sp,sp,-16
ffffffffc0204186:	e406                	sd	ra,8(sp)
ffffffffc0204188:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020418a:	01066863          	bltu	a2,a6,ffffffffc020419a <insert_vma_struct+0x1c>
ffffffffc020418e:	a8b9                	j	ffffffffc02041ec <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0204190:	fe87b683          	ld	a3,-24(a5)
ffffffffc0204194:	04d66763          	bltu	a2,a3,ffffffffc02041e2 <insert_vma_struct+0x64>
ffffffffc0204198:	873e                	mv	a4,a5
ffffffffc020419a:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc020419c:	fef51ae3          	bne	a0,a5,ffffffffc0204190 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02041a0:	02a70463          	beq	a4,a0,ffffffffc02041c8 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02041a4:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02041a8:	fe873883          	ld	a7,-24(a4)
ffffffffc02041ac:	08d8f063          	bleu	a3,a7,ffffffffc020422c <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041b0:	04d66e63          	bltu	a2,a3,ffffffffc020420c <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc02041b4:	00f50a63          	beq	a0,a5,ffffffffc02041c8 <insert_vma_struct+0x4a>
ffffffffc02041b8:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041bc:	0506e863          	bltu	a3,a6,ffffffffc020420c <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02041c0:	ff07b603          	ld	a2,-16(a5)
ffffffffc02041c4:	02c6f263          	bleu	a2,a3,ffffffffc02041e8 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02041c8:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02041ca:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02041cc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02041d0:	e390                	sd	a2,0(a5)
ffffffffc02041d2:	e710                	sd	a2,8(a4)
}
ffffffffc02041d4:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02041d6:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02041d8:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc02041da:	2685                	addiw	a3,a3,1
ffffffffc02041dc:	d114                	sw	a3,32(a0)
}
ffffffffc02041de:	0141                	addi	sp,sp,16
ffffffffc02041e0:	8082                	ret
    if (le_prev != list) {
ffffffffc02041e2:	fca711e3          	bne	a4,a0,ffffffffc02041a4 <insert_vma_struct+0x26>
ffffffffc02041e6:	bfd9                	j	ffffffffc02041bc <insert_vma_struct+0x3e>
ffffffffc02041e8:	ebbff0ef          	jal	ra,ffffffffc02040a2 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041ec:	00004697          	auipc	a3,0x4
ffffffffc02041f0:	f3c68693          	addi	a3,a3,-196 # ffffffffc0208128 <default_pmm_manager+0xdc8>
ffffffffc02041f4:	00003617          	auipc	a2,0x3
ffffffffc02041f8:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02041fc:	07400593          	li	a1,116
ffffffffc0204200:	00004517          	auipc	a0,0x4
ffffffffc0204204:	e1850513          	addi	a0,a0,-488 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204208:	a7cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020420c:	00004697          	auipc	a3,0x4
ffffffffc0204210:	f5c68693          	addi	a3,a3,-164 # ffffffffc0208168 <default_pmm_manager+0xe08>
ffffffffc0204214:	00003617          	auipc	a2,0x3
ffffffffc0204218:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020421c:	06c00593          	li	a1,108
ffffffffc0204220:	00004517          	auipc	a0,0x4
ffffffffc0204224:	df850513          	addi	a0,a0,-520 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204228:	a5cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020422c:	00004697          	auipc	a3,0x4
ffffffffc0204230:	f1c68693          	addi	a3,a3,-228 # ffffffffc0208148 <default_pmm_manager+0xde8>
ffffffffc0204234:	00003617          	auipc	a2,0x3
ffffffffc0204238:	9e460613          	addi	a2,a2,-1564 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020423c:	06b00593          	li	a1,107
ffffffffc0204240:	00004517          	auipc	a0,0x4
ffffffffc0204244:	dd850513          	addi	a0,a0,-552 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204248:	a3cfc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020424c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc020424c:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc020424e:	1141                	addi	sp,sp,-16
ffffffffc0204250:	e406                	sd	ra,8(sp)
ffffffffc0204252:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0204254:	e78d                	bnez	a5,ffffffffc020427e <mm_destroy+0x32>
ffffffffc0204256:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0204258:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc020425a:	00a40c63          	beq	s0,a0,ffffffffc0204272 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020425e:	6118                	ld	a4,0(a0)
ffffffffc0204260:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0204262:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0204264:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0204266:	e398                	sd	a4,0(a5)
ffffffffc0204268:	aabfd0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return listelm->next;
ffffffffc020426c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020426e:	fea418e3          	bne	s0,a0,ffffffffc020425e <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc0204272:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0204274:	6402                	ld	s0,0(sp)
ffffffffc0204276:	60a2                	ld	ra,8(sp)
ffffffffc0204278:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc020427a:	a99fd06f          	j	ffffffffc0201d12 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020427e:	00004697          	auipc	a3,0x4
ffffffffc0204282:	f0a68693          	addi	a3,a3,-246 # ffffffffc0208188 <default_pmm_manager+0xe28>
ffffffffc0204286:	00003617          	auipc	a2,0x3
ffffffffc020428a:	99260613          	addi	a2,a2,-1646 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020428e:	09400593          	li	a1,148
ffffffffc0204292:	00004517          	auipc	a0,0x4
ffffffffc0204296:	d8650513          	addi	a0,a0,-634 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020429a:	9eafc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020429e <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020429e:	6785                	lui	a5,0x1
       struct vma_struct **vma_store) {
ffffffffc02042a0:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042a2:	17fd                	addi	a5,a5,-1
ffffffffc02042a4:	787d                	lui	a6,0xfffff
       struct vma_struct **vma_store) {
ffffffffc02042a6:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042a8:	00f60433          	add	s0,a2,a5
       struct vma_struct **vma_store) {
ffffffffc02042ac:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042ae:	942e                	add	s0,s0,a1
       struct vma_struct **vma_store) {
ffffffffc02042b0:	fc06                	sd	ra,56(sp)
ffffffffc02042b2:	f04a                	sd	s2,32(sp)
ffffffffc02042b4:	ec4e                	sd	s3,24(sp)
ffffffffc02042b6:	e852                	sd	s4,16(sp)
ffffffffc02042b8:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042ba:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc02042be:	002007b7          	lui	a5,0x200
ffffffffc02042c2:	01047433          	and	s0,s0,a6
ffffffffc02042c6:	06f4e363          	bltu	s1,a5,ffffffffc020432c <mm_map+0x8e>
ffffffffc02042ca:	0684f163          	bleu	s0,s1,ffffffffc020432c <mm_map+0x8e>
ffffffffc02042ce:	4785                	li	a5,1
ffffffffc02042d0:	07fe                	slli	a5,a5,0x1f
ffffffffc02042d2:	0487ed63          	bltu	a5,s0,ffffffffc020432c <mm_map+0x8e>
ffffffffc02042d6:	89aa                	mv	s3,a0
ffffffffc02042d8:	8a3a                	mv	s4,a4
ffffffffc02042da:	8ab6                	mv	s5,a3
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02042dc:	c931                	beqz	a0,ffffffffc0204330 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc02042de:	85a6                	mv	a1,s1
ffffffffc02042e0:	e61ff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc02042e4:	c501                	beqz	a0,ffffffffc02042ec <mm_map+0x4e>
ffffffffc02042e6:	651c                	ld	a5,8(a0)
ffffffffc02042e8:	0487e263          	bltu	a5,s0,ffffffffc020432c <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042ec:	03000513          	li	a0,48
ffffffffc02042f0:	967fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02042f4:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02042f6:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc02042f8:	02090163          	beqz	s2,ffffffffc020431a <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02042fc:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02042fe:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0204302:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0204306:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020430a:	85ca                	mv	a1,s2
ffffffffc020430c:	e73ff0ef          	jal	ra,ffffffffc020417e <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204310:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0204312:	000a0463          	beqz	s4,ffffffffc020431a <mm_map+0x7c>
        *vma_store = vma;
ffffffffc0204316:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc020431a:	70e2                	ld	ra,56(sp)
ffffffffc020431c:	7442                	ld	s0,48(sp)
ffffffffc020431e:	74a2                	ld	s1,40(sp)
ffffffffc0204320:	7902                	ld	s2,32(sp)
ffffffffc0204322:	69e2                	ld	s3,24(sp)
ffffffffc0204324:	6a42                	ld	s4,16(sp)
ffffffffc0204326:	6aa2                	ld	s5,8(sp)
ffffffffc0204328:	6121                	addi	sp,sp,64
ffffffffc020432a:	8082                	ret
        return -E_INVAL;
ffffffffc020432c:	5575                	li	a0,-3
ffffffffc020432e:	b7f5                	j	ffffffffc020431a <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0204330:	00004697          	auipc	a3,0x4
ffffffffc0204334:	82068693          	addi	a3,a3,-2016 # ffffffffc0207b50 <default_pmm_manager+0x7f0>
ffffffffc0204338:	00003617          	auipc	a2,0x3
ffffffffc020433c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204340:	0a700593          	li	a1,167
ffffffffc0204344:	00004517          	auipc	a0,0x4
ffffffffc0204348:	cd450513          	addi	a0,a0,-812 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020434c:	938fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204350 <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0204350:	7139                	addi	sp,sp,-64
ffffffffc0204352:	fc06                	sd	ra,56(sp)
ffffffffc0204354:	f822                	sd	s0,48(sp)
ffffffffc0204356:	f426                	sd	s1,40(sp)
ffffffffc0204358:	f04a                	sd	s2,32(sp)
ffffffffc020435a:	ec4e                	sd	s3,24(sp)
ffffffffc020435c:	e852                	sd	s4,16(sp)
ffffffffc020435e:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0204360:	c535                	beqz	a0,ffffffffc02043cc <dup_mmap+0x7c>
ffffffffc0204362:	892a                	mv	s2,a0
ffffffffc0204364:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0204366:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0204368:	e59d                	bnez	a1,ffffffffc0204396 <dup_mmap+0x46>
ffffffffc020436a:	a08d                	j	ffffffffc02043cc <dup_mmap+0x7c>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020436c:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc020436e:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5588>
        insert_vma_struct(to, nvma);
ffffffffc0204372:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc0204374:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc0204378:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma);
ffffffffc020437c:	e03ff0ef          	jal	ra,ffffffffc020417e <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0204380:	ff043683          	ld	a3,-16(s0)
ffffffffc0204384:	fe843603          	ld	a2,-24(s0)
ffffffffc0204388:	6c8c                	ld	a1,24(s1)
ffffffffc020438a:	01893503          	ld	a0,24(s2)
ffffffffc020438e:	4701                	li	a4,0
ffffffffc0204390:	d2ffe0ef          	jal	ra,ffffffffc02030be <copy_range>
ffffffffc0204394:	e105                	bnez	a0,ffffffffc02043b4 <dup_mmap+0x64>
    return listelm->prev;
ffffffffc0204396:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0204398:	02848863          	beq	s1,s0,ffffffffc02043c8 <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020439c:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02043a0:	fe843a83          	ld	s5,-24(s0)
ffffffffc02043a4:	ff043a03          	ld	s4,-16(s0)
ffffffffc02043a8:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043ac:	8abfd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02043b0:	87aa                	mv	a5,a0
    if (vma != NULL) {
ffffffffc02043b2:	fd4d                	bnez	a0,ffffffffc020436c <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc02043b4:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02043b6:	70e2                	ld	ra,56(sp)
ffffffffc02043b8:	7442                	ld	s0,48(sp)
ffffffffc02043ba:	74a2                	ld	s1,40(sp)
ffffffffc02043bc:	7902                	ld	s2,32(sp)
ffffffffc02043be:	69e2                	ld	s3,24(sp)
ffffffffc02043c0:	6a42                	ld	s4,16(sp)
ffffffffc02043c2:	6aa2                	ld	s5,8(sp)
ffffffffc02043c4:	6121                	addi	sp,sp,64
ffffffffc02043c6:	8082                	ret
    return 0;
ffffffffc02043c8:	4501                	li	a0,0
ffffffffc02043ca:	b7f5                	j	ffffffffc02043b6 <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc02043cc:	00004697          	auipc	a3,0x4
ffffffffc02043d0:	d1c68693          	addi	a3,a3,-740 # ffffffffc02080e8 <default_pmm_manager+0xd88>
ffffffffc02043d4:	00003617          	auipc	a2,0x3
ffffffffc02043d8:	84460613          	addi	a2,a2,-1980 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02043dc:	0c000593          	li	a1,192
ffffffffc02043e0:	00004517          	auipc	a0,0x4
ffffffffc02043e4:	c3850513          	addi	a0,a0,-968 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02043e8:	89cfc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02043ec <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc02043ec:	1101                	addi	sp,sp,-32
ffffffffc02043ee:	ec06                	sd	ra,24(sp)
ffffffffc02043f0:	e822                	sd	s0,16(sp)
ffffffffc02043f2:	e426                	sd	s1,8(sp)
ffffffffc02043f4:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02043f6:	c531                	beqz	a0,ffffffffc0204442 <exit_mmap+0x56>
ffffffffc02043f8:	591c                	lw	a5,48(a0)
ffffffffc02043fa:	84aa                	mv	s1,a0
ffffffffc02043fc:	e3b9                	bnez	a5,ffffffffc0204442 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02043fe:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0204400:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0204404:	02850663          	beq	a0,s0,ffffffffc0204430 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204408:	ff043603          	ld	a2,-16(s0)
ffffffffc020440c:	fe843583          	ld	a1,-24(s0)
ffffffffc0204410:	854a                	mv	a0,s2
ffffffffc0204412:	d83fd0ef          	jal	ra,ffffffffc0202194 <unmap_range>
ffffffffc0204416:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204418:	fe8498e3          	bne	s1,s0,ffffffffc0204408 <exit_mmap+0x1c>
ffffffffc020441c:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc020441e:	00848c63          	beq	s1,s0,ffffffffc0204436 <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204422:	ff043603          	ld	a2,-16(s0)
ffffffffc0204426:	fe843583          	ld	a1,-24(s0)
ffffffffc020442a:	854a                	mv	a0,s2
ffffffffc020442c:	e81fd0ef          	jal	ra,ffffffffc02022ac <exit_range>
ffffffffc0204430:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204432:	fe8498e3          	bne	s1,s0,ffffffffc0204422 <exit_mmap+0x36>
    }
}
ffffffffc0204436:	60e2                	ld	ra,24(sp)
ffffffffc0204438:	6442                	ld	s0,16(sp)
ffffffffc020443a:	64a2                	ld	s1,8(sp)
ffffffffc020443c:	6902                	ld	s2,0(sp)
ffffffffc020443e:	6105                	addi	sp,sp,32
ffffffffc0204440:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0204442:	00004697          	auipc	a3,0x4
ffffffffc0204446:	cc668693          	addi	a3,a3,-826 # ffffffffc0208108 <default_pmm_manager+0xda8>
ffffffffc020444a:	00002617          	auipc	a2,0x2
ffffffffc020444e:	7ce60613          	addi	a2,a2,1998 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204452:	0d600593          	li	a1,214
ffffffffc0204456:	00004517          	auipc	a0,0x4
ffffffffc020445a:	bc250513          	addi	a0,a0,-1086 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020445e:	826fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204462 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0204462:	7139                	addi	sp,sp,-64
ffffffffc0204464:	f822                	sd	s0,48(sp)
ffffffffc0204466:	f426                	sd	s1,40(sp)
ffffffffc0204468:	fc06                	sd	ra,56(sp)
ffffffffc020446a:	f04a                	sd	s2,32(sp)
ffffffffc020446c:	ec4e                	sd	s3,24(sp)
ffffffffc020446e:	e852                	sd	s4,16(sp)
ffffffffc0204470:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0204472:	c55ff0ef          	jal	ra,ffffffffc02040c6 <mm_create>
    assert(mm != NULL);
ffffffffc0204476:	842a                	mv	s0,a0
ffffffffc0204478:	03200493          	li	s1,50
ffffffffc020447c:	e919                	bnez	a0,ffffffffc0204492 <vmm_init+0x30>
ffffffffc020447e:	a989                	j	ffffffffc02048d0 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc0204480:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204482:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204484:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204488:	14ed                	addi	s1,s1,-5
ffffffffc020448a:	8522                	mv	a0,s0
ffffffffc020448c:	cf3ff0ef          	jal	ra,ffffffffc020417e <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0204490:	c88d                	beqz	s1,ffffffffc02044c2 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204492:	03000513          	li	a0,48
ffffffffc0204496:	fc0fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc020449a:	85aa                	mv	a1,a0
ffffffffc020449c:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc02044a0:	f165                	bnez	a0,ffffffffc0204480 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc02044a2:	00003697          	auipc	a3,0x3
ffffffffc02044a6:	6e668693          	addi	a3,a3,1766 # ffffffffc0207b88 <default_pmm_manager+0x828>
ffffffffc02044aa:	00002617          	auipc	a2,0x2
ffffffffc02044ae:	76e60613          	addi	a2,a2,1902 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02044b2:	11300593          	li	a1,275
ffffffffc02044b6:	00004517          	auipc	a0,0x4
ffffffffc02044ba:	b6250513          	addi	a0,a0,-1182 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02044be:	fc7fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc02044c2:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02044c6:	1f900913          	li	s2,505
ffffffffc02044ca:	a819                	j	ffffffffc02044e0 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc02044cc:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02044ce:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02044d0:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02044d4:	0495                	addi	s1,s1,5
ffffffffc02044d6:	8522                	mv	a0,s0
ffffffffc02044d8:	ca7ff0ef          	jal	ra,ffffffffc020417e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02044dc:	03248a63          	beq	s1,s2,ffffffffc0204510 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02044e0:	03000513          	li	a0,48
ffffffffc02044e4:	f72fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02044e8:	85aa                	mv	a1,a0
ffffffffc02044ea:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc02044ee:	fd79                	bnez	a0,ffffffffc02044cc <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc02044f0:	00003697          	auipc	a3,0x3
ffffffffc02044f4:	69868693          	addi	a3,a3,1688 # ffffffffc0207b88 <default_pmm_manager+0x828>
ffffffffc02044f8:	00002617          	auipc	a2,0x2
ffffffffc02044fc:	72060613          	addi	a2,a2,1824 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204500:	11900593          	li	a1,281
ffffffffc0204504:	00004517          	auipc	a0,0x4
ffffffffc0204508:	b1450513          	addi	a0,a0,-1260 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020450c:	f79fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204510:	6418                	ld	a4,8(s0)
ffffffffc0204512:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0204514:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0204518:	2ee40063          	beq	s0,a4,ffffffffc02047f8 <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020451c:	fe873603          	ld	a2,-24(a4)
ffffffffc0204520:	ffe78693          	addi	a3,a5,-2
ffffffffc0204524:	24d61a63          	bne	a2,a3,ffffffffc0204778 <vmm_init+0x316>
ffffffffc0204528:	ff073683          	ld	a3,-16(a4)
ffffffffc020452c:	24f69663          	bne	a3,a5,ffffffffc0204778 <vmm_init+0x316>
ffffffffc0204530:	0795                	addi	a5,a5,5
ffffffffc0204532:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0204534:	feb792e3          	bne	a5,a1,ffffffffc0204518 <vmm_init+0xb6>
ffffffffc0204538:	491d                	li	s2,7
ffffffffc020453a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020453c:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0204540:	85a6                	mv	a1,s1
ffffffffc0204542:	8522                	mv	a0,s0
ffffffffc0204544:	bfdff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc0204548:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc020454a:	30050763          	beqz	a0,ffffffffc0204858 <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc020454e:	00148593          	addi	a1,s1,1
ffffffffc0204552:	8522                	mv	a0,s0
ffffffffc0204554:	bedff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc0204558:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc020455a:	2c050f63          	beqz	a0,ffffffffc0204838 <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc020455e:	85ca                	mv	a1,s2
ffffffffc0204560:	8522                	mv	a0,s0
ffffffffc0204562:	bdfff0ef          	jal	ra,ffffffffc0204140 <find_vma>
        assert(vma3 == NULL);
ffffffffc0204566:	2a051963          	bnez	a0,ffffffffc0204818 <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc020456a:	00348593          	addi	a1,s1,3
ffffffffc020456e:	8522                	mv	a0,s0
ffffffffc0204570:	bd1ff0ef          	jal	ra,ffffffffc0204140 <find_vma>
        assert(vma4 == NULL);
ffffffffc0204574:	32051263          	bnez	a0,ffffffffc0204898 <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0204578:	00448593          	addi	a1,s1,4
ffffffffc020457c:	8522                	mv	a0,s0
ffffffffc020457e:	bc3ff0ef          	jal	ra,ffffffffc0204140 <find_vma>
        assert(vma5 == NULL);
ffffffffc0204582:	2e051b63          	bnez	a0,ffffffffc0204878 <vmm_init+0x416>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0204586:	008a3783          	ld	a5,8(s4)
ffffffffc020458a:	20979763          	bne	a5,s1,ffffffffc0204798 <vmm_init+0x336>
ffffffffc020458e:	010a3783          	ld	a5,16(s4)
ffffffffc0204592:	21279363          	bne	a5,s2,ffffffffc0204798 <vmm_init+0x336>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0204596:	0089b783          	ld	a5,8(s3)
ffffffffc020459a:	20979f63          	bne	a5,s1,ffffffffc02047b8 <vmm_init+0x356>
ffffffffc020459e:	0109b783          	ld	a5,16(s3)
ffffffffc02045a2:	21279b63          	bne	a5,s2,ffffffffc02047b8 <vmm_init+0x356>
ffffffffc02045a6:	0495                	addi	s1,s1,5
ffffffffc02045a8:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02045aa:	f9549be3          	bne	s1,s5,ffffffffc0204540 <vmm_init+0xde>
ffffffffc02045ae:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02045b0:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02045b2:	85a6                	mv	a1,s1
ffffffffc02045b4:	8522                	mv	a0,s0
ffffffffc02045b6:	b8bff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc02045ba:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc02045be:	c90d                	beqz	a0,ffffffffc02045f0 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc02045c0:	6914                	ld	a3,16(a0)
ffffffffc02045c2:	6510                	ld	a2,8(a0)
ffffffffc02045c4:	00004517          	auipc	a0,0x4
ffffffffc02045c8:	cdc50513          	addi	a0,a0,-804 # ffffffffc02082a0 <default_pmm_manager+0xf40>
ffffffffc02045cc:	bc3fb0ef          	jal	ra,ffffffffc020018e <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02045d0:	00004697          	auipc	a3,0x4
ffffffffc02045d4:	cf868693          	addi	a3,a3,-776 # ffffffffc02082c8 <default_pmm_manager+0xf68>
ffffffffc02045d8:	00002617          	auipc	a2,0x2
ffffffffc02045dc:	64060613          	addi	a2,a2,1600 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02045e0:	13b00593          	li	a1,315
ffffffffc02045e4:	00004517          	auipc	a0,0x4
ffffffffc02045e8:	a3450513          	addi	a0,a0,-1484 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02045ec:	e99fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02045f0:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc02045f2:	fd2490e3          	bne	s1,s2,ffffffffc02045b2 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc02045f6:	8522                	mv	a0,s0
ffffffffc02045f8:	c55ff0ef          	jal	ra,ffffffffc020424c <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02045fc:	00004517          	auipc	a0,0x4
ffffffffc0204600:	ce450513          	addi	a0,a0,-796 # ffffffffc02082e0 <default_pmm_manager+0xf80>
ffffffffc0204604:	b8bfb0ef          	jal	ra,ffffffffc020018e <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204608:	919fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc020460c:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc020460e:	ab9ff0ef          	jal	ra,ffffffffc02040c6 <mm_create>
ffffffffc0204612:	000a8797          	auipc	a5,0xa8
ffffffffc0204616:	faa7bb23          	sd	a0,-74(a5) # ffffffffc02ac5c8 <check_mm_struct>
ffffffffc020461a:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc020461c:	36050663          	beqz	a0,ffffffffc0204988 <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204620:	000a8797          	auipc	a5,0xa8
ffffffffc0204624:	e5078793          	addi	a5,a5,-432 # ffffffffc02ac470 <boot_pgdir>
ffffffffc0204628:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc020462c:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204630:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0204634:	2c079e63          	bnez	a5,ffffffffc0204910 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204638:	03000513          	li	a0,48
ffffffffc020463c:	e1afd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204640:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc0204642:	18050b63          	beqz	a0,ffffffffc02047d8 <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc0204646:	002007b7          	lui	a5,0x200
ffffffffc020464a:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc020464c:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc020464e:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0204650:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0204652:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc0204654:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0204658:	b27ff0ef          	jal	ra,ffffffffc020417e <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020465c:	10000593          	li	a1,256
ffffffffc0204660:	8526                	mv	a0,s1
ffffffffc0204662:	adfff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc0204666:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc020466a:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc020466e:	2ca41163          	bne	s0,a0,ffffffffc0204930 <vmm_init+0x4ce>
        *(char *)(addr + i) = i;
ffffffffc0204672:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
        sum += i;
ffffffffc0204676:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0204678:	fee79de3          	bne	a5,a4,ffffffffc0204672 <vmm_init+0x210>
        sum += i;
ffffffffc020467c:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc020467e:	10000793          	li	a5,256
        sum += i;
ffffffffc0204682:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x821a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0204686:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc020468a:	0007c683          	lbu	a3,0(a5)
ffffffffc020468e:	0785                	addi	a5,a5,1
ffffffffc0204690:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0204692:	fec79ce3          	bne	a5,a2,ffffffffc020468a <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc0204696:	2c071963          	bnez	a4,ffffffffc0204968 <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc020469a:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020469e:	000a8a97          	auipc	s5,0xa8
ffffffffc02046a2:	ddaa8a93          	addi	s5,s5,-550 # ffffffffc02ac478 <npage>
ffffffffc02046a6:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046aa:	078a                	slli	a5,a5,0x2
ffffffffc02046ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046ae:	20e7f563          	bleu	a4,a5,ffffffffc02048b8 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046b2:	00004697          	auipc	a3,0x4
ffffffffc02046b6:	66e68693          	addi	a3,a3,1646 # ffffffffc0208d20 <nbase>
ffffffffc02046ba:	0006ba03          	ld	s4,0(a3)
ffffffffc02046be:	414786b3          	sub	a3,a5,s4
ffffffffc02046c2:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02046c4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02046c6:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc02046c8:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02046ca:	83b1                	srli	a5,a5,0xc
ffffffffc02046cc:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02046ce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02046d0:	28e7f063          	bleu	a4,a5,ffffffffc0204950 <vmm_init+0x4ee>
ffffffffc02046d4:	000a8797          	auipc	a5,0xa8
ffffffffc02046d8:	e0478793          	addi	a5,a5,-508 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc02046dc:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02046de:	4581                	li	a1,0
ffffffffc02046e0:	854a                	mv	a0,s2
ffffffffc02046e2:	9436                	add	s0,s0,a3
ffffffffc02046e4:	e1ffd0ef          	jal	ra,ffffffffc0202502 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046e8:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02046ea:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046ee:	078a                	slli	a5,a5,0x2
ffffffffc02046f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046f2:	1ce7f363          	bleu	a4,a5,ffffffffc02048b8 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046f6:	000a8417          	auipc	s0,0xa8
ffffffffc02046fa:	df240413          	addi	s0,s0,-526 # ffffffffc02ac4e8 <pages>
ffffffffc02046fe:	6008                	ld	a0,0(s0)
ffffffffc0204700:	414787b3          	sub	a5,a5,s4
ffffffffc0204704:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0204706:	953e                	add	a0,a0,a5
ffffffffc0204708:	4585                	li	a1,1
ffffffffc020470a:	fd0fd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020470e:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204712:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204716:	078a                	slli	a5,a5,0x2
ffffffffc0204718:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020471a:	18e7ff63          	bleu	a4,a5,ffffffffc02048b8 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc020471e:	6008                	ld	a0,0(s0)
ffffffffc0204720:	414787b3          	sub	a5,a5,s4
ffffffffc0204724:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0204726:	4585                	li	a1,1
ffffffffc0204728:	953e                	add	a0,a0,a5
ffffffffc020472a:	fb0fd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    pgdir[0] = 0;
ffffffffc020472e:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0204732:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0204736:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc020473a:	8526                	mv	a0,s1
ffffffffc020473c:	b11ff0ef          	jal	ra,ffffffffc020424c <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0204740:	000a8797          	auipc	a5,0xa8
ffffffffc0204744:	e807b423          	sd	zero,-376(a5) # ffffffffc02ac5c8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204748:	fd8fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc020474c:	1aa99263          	bne	s3,a0,ffffffffc02048f0 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204750:	00004517          	auipc	a0,0x4
ffffffffc0204754:	c2050513          	addi	a0,a0,-992 # ffffffffc0208370 <default_pmm_manager+0x1010>
ffffffffc0204758:	a37fb0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc020475c:	7442                	ld	s0,48(sp)
ffffffffc020475e:	70e2                	ld	ra,56(sp)
ffffffffc0204760:	74a2                	ld	s1,40(sp)
ffffffffc0204762:	7902                	ld	s2,32(sp)
ffffffffc0204764:	69e2                	ld	s3,24(sp)
ffffffffc0204766:	6a42                	ld	s4,16(sp)
ffffffffc0204768:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020476a:	00004517          	auipc	a0,0x4
ffffffffc020476e:	c2650513          	addi	a0,a0,-986 # ffffffffc0208390 <default_pmm_manager+0x1030>
}
ffffffffc0204772:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204774:	a1bfb06f          	j	ffffffffc020018e <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204778:	00004697          	auipc	a3,0x4
ffffffffc020477c:	a4068693          	addi	a3,a3,-1472 # ffffffffc02081b8 <default_pmm_manager+0xe58>
ffffffffc0204780:	00002617          	auipc	a2,0x2
ffffffffc0204784:	49860613          	addi	a2,a2,1176 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204788:	12200593          	li	a1,290
ffffffffc020478c:	00004517          	auipc	a0,0x4
ffffffffc0204790:	88c50513          	addi	a0,a0,-1908 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204794:	cf1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0204798:	00004697          	auipc	a3,0x4
ffffffffc020479c:	aa868693          	addi	a3,a3,-1368 # ffffffffc0208240 <default_pmm_manager+0xee0>
ffffffffc02047a0:	00002617          	auipc	a2,0x2
ffffffffc02047a4:	47860613          	addi	a2,a2,1144 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02047a8:	13200593          	li	a1,306
ffffffffc02047ac:	00004517          	auipc	a0,0x4
ffffffffc02047b0:	86c50513          	addi	a0,a0,-1940 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02047b4:	cd1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02047b8:	00004697          	auipc	a3,0x4
ffffffffc02047bc:	ab868693          	addi	a3,a3,-1352 # ffffffffc0208270 <default_pmm_manager+0xf10>
ffffffffc02047c0:	00002617          	auipc	a2,0x2
ffffffffc02047c4:	45860613          	addi	a2,a2,1112 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02047c8:	13300593          	li	a1,307
ffffffffc02047cc:	00004517          	auipc	a0,0x4
ffffffffc02047d0:	84c50513          	addi	a0,a0,-1972 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02047d4:	cb1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(vma != NULL);
ffffffffc02047d8:	00003697          	auipc	a3,0x3
ffffffffc02047dc:	3b068693          	addi	a3,a3,944 # ffffffffc0207b88 <default_pmm_manager+0x828>
ffffffffc02047e0:	00002617          	auipc	a2,0x2
ffffffffc02047e4:	43860613          	addi	a2,a2,1080 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02047e8:	15200593          	li	a1,338
ffffffffc02047ec:	00004517          	auipc	a0,0x4
ffffffffc02047f0:	82c50513          	addi	a0,a0,-2004 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02047f4:	c91fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02047f8:	00004697          	auipc	a3,0x4
ffffffffc02047fc:	9a868693          	addi	a3,a3,-1624 # ffffffffc02081a0 <default_pmm_manager+0xe40>
ffffffffc0204800:	00002617          	auipc	a2,0x2
ffffffffc0204804:	41860613          	addi	a2,a2,1048 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204808:	12000593          	li	a1,288
ffffffffc020480c:	00004517          	auipc	a0,0x4
ffffffffc0204810:	80c50513          	addi	a0,a0,-2036 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204814:	c71fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma3 == NULL);
ffffffffc0204818:	00004697          	auipc	a3,0x4
ffffffffc020481c:	9f868693          	addi	a3,a3,-1544 # ffffffffc0208210 <default_pmm_manager+0xeb0>
ffffffffc0204820:	00002617          	auipc	a2,0x2
ffffffffc0204824:	3f860613          	addi	a2,a2,1016 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204828:	12c00593          	li	a1,300
ffffffffc020482c:	00003517          	auipc	a0,0x3
ffffffffc0204830:	7ec50513          	addi	a0,a0,2028 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204834:	c51fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2 != NULL);
ffffffffc0204838:	00004697          	auipc	a3,0x4
ffffffffc020483c:	9c868693          	addi	a3,a3,-1592 # ffffffffc0208200 <default_pmm_manager+0xea0>
ffffffffc0204840:	00002617          	auipc	a2,0x2
ffffffffc0204844:	3d860613          	addi	a2,a2,984 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204848:	12a00593          	li	a1,298
ffffffffc020484c:	00003517          	auipc	a0,0x3
ffffffffc0204850:	7cc50513          	addi	a0,a0,1996 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204854:	c31fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1 != NULL);
ffffffffc0204858:	00004697          	auipc	a3,0x4
ffffffffc020485c:	99868693          	addi	a3,a3,-1640 # ffffffffc02081f0 <default_pmm_manager+0xe90>
ffffffffc0204860:	00002617          	auipc	a2,0x2
ffffffffc0204864:	3b860613          	addi	a2,a2,952 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204868:	12800593          	li	a1,296
ffffffffc020486c:	00003517          	auipc	a0,0x3
ffffffffc0204870:	7ac50513          	addi	a0,a0,1964 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204874:	c11fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma5 == NULL);
ffffffffc0204878:	00004697          	auipc	a3,0x4
ffffffffc020487c:	9b868693          	addi	a3,a3,-1608 # ffffffffc0208230 <default_pmm_manager+0xed0>
ffffffffc0204880:	00002617          	auipc	a2,0x2
ffffffffc0204884:	39860613          	addi	a2,a2,920 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204888:	13000593          	li	a1,304
ffffffffc020488c:	00003517          	auipc	a0,0x3
ffffffffc0204890:	78c50513          	addi	a0,a0,1932 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204894:	bf1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma4 == NULL);
ffffffffc0204898:	00004697          	auipc	a3,0x4
ffffffffc020489c:	98868693          	addi	a3,a3,-1656 # ffffffffc0208220 <default_pmm_manager+0xec0>
ffffffffc02048a0:	00002617          	auipc	a2,0x2
ffffffffc02048a4:	37860613          	addi	a2,a2,888 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02048a8:	12e00593          	li	a1,302
ffffffffc02048ac:	00003517          	auipc	a0,0x3
ffffffffc02048b0:	76c50513          	addi	a0,a0,1900 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02048b4:	bd1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048b8:	00003617          	auipc	a2,0x3
ffffffffc02048bc:	b5860613          	addi	a2,a2,-1192 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc02048c0:	06200593          	li	a1,98
ffffffffc02048c4:	00003517          	auipc	a0,0x3
ffffffffc02048c8:	b1450513          	addi	a0,a0,-1260 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02048cc:	bb9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(mm != NULL);
ffffffffc02048d0:	00003697          	auipc	a3,0x3
ffffffffc02048d4:	28068693          	addi	a3,a3,640 # ffffffffc0207b50 <default_pmm_manager+0x7f0>
ffffffffc02048d8:	00002617          	auipc	a2,0x2
ffffffffc02048dc:	34060613          	addi	a2,a2,832 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02048e0:	10c00593          	li	a1,268
ffffffffc02048e4:	00003517          	auipc	a0,0x3
ffffffffc02048e8:	73450513          	addi	a0,a0,1844 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02048ec:	b99fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02048f0:	00004697          	auipc	a3,0x4
ffffffffc02048f4:	a5868693          	addi	a3,a3,-1448 # ffffffffc0208348 <default_pmm_manager+0xfe8>
ffffffffc02048f8:	00002617          	auipc	a2,0x2
ffffffffc02048fc:	32060613          	addi	a2,a2,800 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204900:	17000593          	li	a1,368
ffffffffc0204904:	00003517          	auipc	a0,0x3
ffffffffc0204908:	71450513          	addi	a0,a0,1812 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020490c:	b79fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0204910:	00003697          	auipc	a3,0x3
ffffffffc0204914:	26868693          	addi	a3,a3,616 # ffffffffc0207b78 <default_pmm_manager+0x818>
ffffffffc0204918:	00002617          	auipc	a2,0x2
ffffffffc020491c:	30060613          	addi	a2,a2,768 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204920:	14f00593          	li	a1,335
ffffffffc0204924:	00003517          	auipc	a0,0x3
ffffffffc0204928:	6f450513          	addi	a0,a0,1780 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020492c:	b59fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0204930:	00004697          	auipc	a3,0x4
ffffffffc0204934:	9e868693          	addi	a3,a3,-1560 # ffffffffc0208318 <default_pmm_manager+0xfb8>
ffffffffc0204938:	00002617          	auipc	a2,0x2
ffffffffc020493c:	2e060613          	addi	a2,a2,736 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204940:	15700593          	li	a1,343
ffffffffc0204944:	00003517          	auipc	a0,0x3
ffffffffc0204948:	6d450513          	addi	a0,a0,1748 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc020494c:	b39fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204950:	00003617          	auipc	a2,0x3
ffffffffc0204954:	a6060613          	addi	a2,a2,-1440 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0204958:	06900593          	li	a1,105
ffffffffc020495c:	00003517          	auipc	a0,0x3
ffffffffc0204960:	a7c50513          	addi	a0,a0,-1412 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204964:	b21fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(sum == 0);
ffffffffc0204968:	00004697          	auipc	a3,0x4
ffffffffc020496c:	9d068693          	addi	a3,a3,-1584 # ffffffffc0208338 <default_pmm_manager+0xfd8>
ffffffffc0204970:	00002617          	auipc	a2,0x2
ffffffffc0204974:	2a860613          	addi	a2,a2,680 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204978:	16300593          	li	a1,355
ffffffffc020497c:	00003517          	auipc	a0,0x3
ffffffffc0204980:	69c50513          	addi	a0,a0,1692 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc0204984:	b01fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0204988:	00004697          	auipc	a3,0x4
ffffffffc020498c:	97868693          	addi	a3,a3,-1672 # ffffffffc0208300 <default_pmm_manager+0xfa0>
ffffffffc0204990:	00002617          	auipc	a2,0x2
ffffffffc0204994:	28860613          	addi	a2,a2,648 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0204998:	14b00593          	li	a1,331
ffffffffc020499c:	00003517          	auipc	a0,0x3
ffffffffc02049a0:	67c50513          	addi	a0,a0,1660 # ffffffffc0208018 <default_pmm_manager+0xcb8>
ffffffffc02049a4:	ae1fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02049a8 <do_pgfault>:
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) 
{
ffffffffc02049a8:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02049aa:	85b2                	mv	a1,a2
{
ffffffffc02049ac:	f822                	sd	s0,48(sp)
ffffffffc02049ae:	f426                	sd	s1,40(sp)
ffffffffc02049b0:	fc06                	sd	ra,56(sp)
ffffffffc02049b2:	f04a                	sd	s2,32(sp)
ffffffffc02049b4:	ec4e                	sd	s3,24(sp)
ffffffffc02049b6:	8432                	mv	s0,a2
ffffffffc02049b8:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02049ba:	f86ff0ef          	jal	ra,ffffffffc0204140 <find_vma>

    pgfault_num++;
ffffffffc02049be:	000a8797          	auipc	a5,0xa8
ffffffffc02049c2:	ace78793          	addi	a5,a5,-1330 # ffffffffc02ac48c <pgfault_num>
ffffffffc02049c6:	439c                	lw	a5,0(a5)
ffffffffc02049c8:	2785                	addiw	a5,a5,1
ffffffffc02049ca:	000a8717          	auipc	a4,0xa8
ffffffffc02049ce:	acf72123          	sw	a5,-1342(a4) # ffffffffc02ac48c <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02049d2:	c941                	beqz	a0,ffffffffc0204a62 <do_pgfault+0xba>
ffffffffc02049d4:	651c                	ld	a5,8(a0)
ffffffffc02049d6:	08f46663          	bltu	s0,a5,ffffffffc0204a62 <do_pgfault+0xba>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02049da:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02049dc:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02049de:	8b89                	andi	a5,a5,2
ffffffffc02049e0:	e3a5                	bnez	a5,ffffffffc0204a40 <do_pgfault+0x98>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049e2:	767d                	lui	a2,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02049e4:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049e6:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02049e8:	85a2                	mv	a1,s0
ffffffffc02049ea:	4605                	li	a2,1
ffffffffc02049ec:	d74fd0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02049f0:	c155                	beqz	a0,ffffffffc0204a94 <do_pgfault+0xec>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc02049f2:	610c                	ld	a1,0(a0)
ffffffffc02049f4:	c9a1                	beqz	a1,ffffffffc0204a44 <do_pgfault+0x9c>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02049f6:	000a8797          	auipc	a5,0xa8
ffffffffc02049fa:	a9278793          	addi	a5,a5,-1390 # ffffffffc02ac488 <swap_init_ok>
ffffffffc02049fe:	439c                	lw	a5,0(a5)
ffffffffc0204a00:	2781                	sext.w	a5,a5
ffffffffc0204a02:	cbad                	beqz	a5,ffffffffc0204a74 <do_pgfault+0xcc>
            struct Page *page = NULL;
            if(swap_in(mm,addr,&page)!=0)
ffffffffc0204a04:	0030                	addi	a2,sp,8
ffffffffc0204a06:	85a2                	mv	a1,s0
ffffffffc0204a08:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204a0a:	e402                	sd	zero,8(sp)
            if(swap_in(mm,addr,&page)!=0)
ffffffffc0204a0c:	a34ff0ef          	jal	ra,ffffffffc0203c40 <swap_in>
ffffffffc0204a10:	892a                	mv	s2,a0
ffffffffc0204a12:	e92d                	bnez	a0,ffffffffc0204a84 <do_pgfault+0xdc>
            {
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0204a14:	65a2                	ld	a1,8(sp)
ffffffffc0204a16:	6c88                	ld	a0,24(s1)
ffffffffc0204a18:	86ce                	mv	a3,s3
ffffffffc0204a1a:	8622                	mv	a2,s0
ffffffffc0204a1c:	b5bfd0ef          	jal	ra,ffffffffc0202576 <page_insert>
            swap_map_swappable(mm,addr,page,1);
ffffffffc0204a20:	6622                	ld	a2,8(sp)
ffffffffc0204a22:	4685                	li	a3,1
ffffffffc0204a24:	85a2                	mv	a1,s0
ffffffffc0204a26:	8526                	mv	a0,s1
ffffffffc0204a28:	8f4ff0ef          	jal	ra,ffffffffc0203b1c <swap_map_swappable>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            page->pra_vaddr = addr;
ffffffffc0204a2c:	67a2                	ld	a5,8(sp)
ffffffffc0204a2e:	ff80                	sd	s0,56(a5)
        }
   }
   ret = 0;
failed:
    return ret;
}
ffffffffc0204a30:	70e2                	ld	ra,56(sp)
ffffffffc0204a32:	7442                	ld	s0,48(sp)
ffffffffc0204a34:	854a                	mv	a0,s2
ffffffffc0204a36:	74a2                	ld	s1,40(sp)
ffffffffc0204a38:	7902                	ld	s2,32(sp)
ffffffffc0204a3a:	69e2                	ld	s3,24(sp)
ffffffffc0204a3c:	6121                	addi	sp,sp,64
ffffffffc0204a3e:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204a40:	49dd                	li	s3,23
ffffffffc0204a42:	b745                	j	ffffffffc02049e2 <do_pgfault+0x3a>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204a44:	6c88                	ld	a0,24(s1)
ffffffffc0204a46:	864e                	mv	a2,s3
ffffffffc0204a48:	85a2                	mv	a1,s0
ffffffffc0204a4a:	8affe0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
   ret = 0;
ffffffffc0204a4e:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204a50:	f165                	bnez	a0,ffffffffc0204a30 <do_pgfault+0x88>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204a52:	00003517          	auipc	a0,0x3
ffffffffc0204a56:	62650513          	addi	a0,a0,1574 # ffffffffc0208078 <default_pmm_manager+0xd18>
ffffffffc0204a5a:	f34fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a5e:	5971                	li	s2,-4
            goto failed;
ffffffffc0204a60:	bfc1                	j	ffffffffc0204a30 <do_pgfault+0x88>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204a62:	85a2                	mv	a1,s0
ffffffffc0204a64:	00003517          	auipc	a0,0x3
ffffffffc0204a68:	5c450513          	addi	a0,a0,1476 # ffffffffc0208028 <default_pmm_manager+0xcc8>
ffffffffc0204a6c:	f22fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = -E_INVAL;
ffffffffc0204a70:	5975                	li	s2,-3
        goto failed;
ffffffffc0204a72:	bf7d                	j	ffffffffc0204a30 <do_pgfault+0x88>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204a74:	00003517          	auipc	a0,0x3
ffffffffc0204a78:	64c50513          	addi	a0,a0,1612 # ffffffffc02080c0 <default_pmm_manager+0xd60>
ffffffffc0204a7c:	f12fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a80:	5971                	li	s2,-4
            goto failed;
ffffffffc0204a82:	b77d                	j	ffffffffc0204a30 <do_pgfault+0x88>
                cprintf("swap_in in do_pgfault failed\n");
ffffffffc0204a84:	00003517          	auipc	a0,0x3
ffffffffc0204a88:	61c50513          	addi	a0,a0,1564 # ffffffffc02080a0 <default_pmm_manager+0xd40>
ffffffffc0204a8c:	f02fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a90:	5971                	li	s2,-4
ffffffffc0204a92:	bf79                	j	ffffffffc0204a30 <do_pgfault+0x88>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204a94:	00003517          	auipc	a0,0x3
ffffffffc0204a98:	5c450513          	addi	a0,a0,1476 # ffffffffc0208058 <default_pmm_manager+0xcf8>
ffffffffc0204a9c:	ef2fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204aa0:	5971                	li	s2,-4
        goto failed;
ffffffffc0204aa2:	b779                	j	ffffffffc0204a30 <do_pgfault+0x88>

ffffffffc0204aa4 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204aa4:	7179                	addi	sp,sp,-48
ffffffffc0204aa6:	f022                	sd	s0,32(sp)
ffffffffc0204aa8:	f406                	sd	ra,40(sp)
ffffffffc0204aaa:	ec26                	sd	s1,24(sp)
ffffffffc0204aac:	e84a                	sd	s2,16(sp)
ffffffffc0204aae:	e44e                	sd	s3,8(sp)
ffffffffc0204ab0:	e052                	sd	s4,0(sp)
ffffffffc0204ab2:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0204ab4:	c135                	beqz	a0,ffffffffc0204b18 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204ab6:	002007b7          	lui	a5,0x200
ffffffffc0204aba:	04f5e663          	bltu	a1,a5,ffffffffc0204b06 <user_mem_check+0x62>
ffffffffc0204abe:	00c584b3          	add	s1,a1,a2
ffffffffc0204ac2:	0495f263          	bleu	s1,a1,ffffffffc0204b06 <user_mem_check+0x62>
ffffffffc0204ac6:	4785                	li	a5,1
ffffffffc0204ac8:	07fe                	slli	a5,a5,0x1f
ffffffffc0204aca:	0297ee63          	bltu	a5,s1,ffffffffc0204b06 <user_mem_check+0x62>
ffffffffc0204ace:	892a                	mv	s2,a0
ffffffffc0204ad0:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ad2:	6a05                	lui	s4,0x1
ffffffffc0204ad4:	a821                	j	ffffffffc0204aec <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204ad6:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ada:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204adc:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204ade:	c685                	beqz	a3,ffffffffc0204b06 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204ae0:	c399                	beqz	a5,ffffffffc0204ae6 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ae2:	02e46263          	bltu	s0,a4,ffffffffc0204b06 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204ae6:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204ae8:	04947663          	bleu	s1,s0,ffffffffc0204b34 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204aec:	85a2                	mv	a1,s0
ffffffffc0204aee:	854a                	mv	a0,s2
ffffffffc0204af0:	e50ff0ef          	jal	ra,ffffffffc0204140 <find_vma>
ffffffffc0204af4:	c909                	beqz	a0,ffffffffc0204b06 <user_mem_check+0x62>
ffffffffc0204af6:	6518                	ld	a4,8(a0)
ffffffffc0204af8:	00e46763          	bltu	s0,a4,ffffffffc0204b06 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204afc:	4d1c                	lw	a5,24(a0)
ffffffffc0204afe:	fc099ce3          	bnez	s3,ffffffffc0204ad6 <user_mem_check+0x32>
ffffffffc0204b02:	8b85                	andi	a5,a5,1
ffffffffc0204b04:	f3ed                	bnez	a5,ffffffffc0204ae6 <user_mem_check+0x42>
            return 0;
ffffffffc0204b06:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204b08:	70a2                	ld	ra,40(sp)
ffffffffc0204b0a:	7402                	ld	s0,32(sp)
ffffffffc0204b0c:	64e2                	ld	s1,24(sp)
ffffffffc0204b0e:	6942                	ld	s2,16(sp)
ffffffffc0204b10:	69a2                	ld	s3,8(sp)
ffffffffc0204b12:	6a02                	ld	s4,0(sp)
ffffffffc0204b14:	6145                	addi	sp,sp,48
ffffffffc0204b16:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204b18:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b1c:	4501                	li	a0,0
ffffffffc0204b1e:	fef5e5e3          	bltu	a1,a5,ffffffffc0204b08 <user_mem_check+0x64>
ffffffffc0204b22:	962e                	add	a2,a2,a1
ffffffffc0204b24:	fec5f2e3          	bleu	a2,a1,ffffffffc0204b08 <user_mem_check+0x64>
ffffffffc0204b28:	c8000537          	lui	a0,0xc8000
ffffffffc0204b2c:	0505                	addi	a0,a0,1
ffffffffc0204b2e:	00a63533          	sltu	a0,a2,a0
ffffffffc0204b32:	bfd9                	j	ffffffffc0204b08 <user_mem_check+0x64>
        return 1;
ffffffffc0204b34:	4505                	li	a0,1
ffffffffc0204b36:	bfc9                	j	ffffffffc0204b08 <user_mem_check+0x64>

ffffffffc0204b38 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b38:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b3a:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b3c:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b3e:	ac1fb0ef          	jal	ra,ffffffffc02005fe <ide_device_valid>
ffffffffc0204b42:	cd01                	beqz	a0,ffffffffc0204b5a <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b44:	4505                	li	a0,1
ffffffffc0204b46:	abffb0ef          	jal	ra,ffffffffc0200604 <ide_device_size>
}
ffffffffc0204b4a:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b4c:	810d                	srli	a0,a0,0x3
ffffffffc0204b4e:	000a8797          	auipc	a5,0xa8
ffffffffc0204b52:	a2a7b523          	sd	a0,-1494(a5) # ffffffffc02ac578 <max_swap_offset>
}
ffffffffc0204b56:	0141                	addi	sp,sp,16
ffffffffc0204b58:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204b5a:	00004617          	auipc	a2,0x4
ffffffffc0204b5e:	84e60613          	addi	a2,a2,-1970 # ffffffffc02083a8 <default_pmm_manager+0x1048>
ffffffffc0204b62:	45b5                	li	a1,13
ffffffffc0204b64:	00004517          	auipc	a0,0x4
ffffffffc0204b68:	86450513          	addi	a0,a0,-1948 # ffffffffc02083c8 <default_pmm_manager+0x1068>
ffffffffc0204b6c:	919fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204b70 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204b70:	1141                	addi	sp,sp,-16
ffffffffc0204b72:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b74:	00855793          	srli	a5,a0,0x8
ffffffffc0204b78:	cfb9                	beqz	a5,ffffffffc0204bd6 <swapfs_read+0x66>
ffffffffc0204b7a:	000a8717          	auipc	a4,0xa8
ffffffffc0204b7e:	9fe70713          	addi	a4,a4,-1538 # ffffffffc02ac578 <max_swap_offset>
ffffffffc0204b82:	6318                	ld	a4,0(a4)
ffffffffc0204b84:	04e7f963          	bleu	a4,a5,ffffffffc0204bd6 <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204b88:	000a8717          	auipc	a4,0xa8
ffffffffc0204b8c:	96070713          	addi	a4,a4,-1696 # ffffffffc02ac4e8 <pages>
ffffffffc0204b90:	6310                	ld	a2,0(a4)
ffffffffc0204b92:	00004717          	auipc	a4,0x4
ffffffffc0204b96:	18e70713          	addi	a4,a4,398 # ffffffffc0208d20 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204b9a:	000a8697          	auipc	a3,0xa8
ffffffffc0204b9e:	8de68693          	addi	a3,a3,-1826 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc0204ba2:	40c58633          	sub	a2,a1,a2
ffffffffc0204ba6:	630c                	ld	a1,0(a4)
ffffffffc0204ba8:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204baa:	577d                	li	a4,-1
ffffffffc0204bac:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204bae:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204bb0:	8331                	srli	a4,a4,0xc
ffffffffc0204bb2:	8f71                	and	a4,a4,a2
ffffffffc0204bb4:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bb8:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204bba:	02d77a63          	bleu	a3,a4,ffffffffc0204bee <swapfs_read+0x7e>
ffffffffc0204bbe:	000a8797          	auipc	a5,0xa8
ffffffffc0204bc2:	91a78793          	addi	a5,a5,-1766 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0204bc6:	639c                	ld	a5,0(a5)
}
ffffffffc0204bc8:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bca:	46a1                	li	a3,8
ffffffffc0204bcc:	963e                	add	a2,a2,a5
ffffffffc0204bce:	4505                	li	a0,1
}
ffffffffc0204bd0:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bd2:	a39fb06f          	j	ffffffffc020060a <ide_read_secs>
ffffffffc0204bd6:	86aa                	mv	a3,a0
ffffffffc0204bd8:	00004617          	auipc	a2,0x4
ffffffffc0204bdc:	80860613          	addi	a2,a2,-2040 # ffffffffc02083e0 <default_pmm_manager+0x1080>
ffffffffc0204be0:	45d1                	li	a1,20
ffffffffc0204be2:	00003517          	auipc	a0,0x3
ffffffffc0204be6:	7e650513          	addi	a0,a0,2022 # ffffffffc02083c8 <default_pmm_manager+0x1068>
ffffffffc0204bea:	89bfb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204bee:	86b2                	mv	a3,a2
ffffffffc0204bf0:	06900593          	li	a1,105
ffffffffc0204bf4:	00002617          	auipc	a2,0x2
ffffffffc0204bf8:	7bc60613          	addi	a2,a2,1980 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0204bfc:	00002517          	auipc	a0,0x2
ffffffffc0204c00:	7dc50513          	addi	a0,a0,2012 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204c04:	881fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204c08 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204c08:	1141                	addi	sp,sp,-16
ffffffffc0204c0a:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c0c:	00855793          	srli	a5,a0,0x8
ffffffffc0204c10:	cfb9                	beqz	a5,ffffffffc0204c6e <swapfs_write+0x66>
ffffffffc0204c12:	000a8717          	auipc	a4,0xa8
ffffffffc0204c16:	96670713          	addi	a4,a4,-1690 # ffffffffc02ac578 <max_swap_offset>
ffffffffc0204c1a:	6318                	ld	a4,0(a4)
ffffffffc0204c1c:	04e7f963          	bleu	a4,a5,ffffffffc0204c6e <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204c20:	000a8717          	auipc	a4,0xa8
ffffffffc0204c24:	8c870713          	addi	a4,a4,-1848 # ffffffffc02ac4e8 <pages>
ffffffffc0204c28:	6310                	ld	a2,0(a4)
ffffffffc0204c2a:	00004717          	auipc	a4,0x4
ffffffffc0204c2e:	0f670713          	addi	a4,a4,246 # ffffffffc0208d20 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204c32:	000a8697          	auipc	a3,0xa8
ffffffffc0204c36:	84668693          	addi	a3,a3,-1978 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc0204c3a:	40c58633          	sub	a2,a1,a2
ffffffffc0204c3e:	630c                	ld	a1,0(a4)
ffffffffc0204c40:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204c42:	577d                	li	a4,-1
ffffffffc0204c44:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204c46:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204c48:	8331                	srli	a4,a4,0xc
ffffffffc0204c4a:	8f71                	and	a4,a4,a2
ffffffffc0204c4c:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c50:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c52:	02d77a63          	bleu	a3,a4,ffffffffc0204c86 <swapfs_write+0x7e>
ffffffffc0204c56:	000a8797          	auipc	a5,0xa8
ffffffffc0204c5a:	88278793          	addi	a5,a5,-1918 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0204c5e:	639c                	ld	a5,0(a5)
}
ffffffffc0204c60:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c62:	46a1                	li	a3,8
ffffffffc0204c64:	963e                	add	a2,a2,a5
ffffffffc0204c66:	4505                	li	a0,1
}
ffffffffc0204c68:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c6a:	9c5fb06f          	j	ffffffffc020062e <ide_write_secs>
ffffffffc0204c6e:	86aa                	mv	a3,a0
ffffffffc0204c70:	00003617          	auipc	a2,0x3
ffffffffc0204c74:	77060613          	addi	a2,a2,1904 # ffffffffc02083e0 <default_pmm_manager+0x1080>
ffffffffc0204c78:	45e5                	li	a1,25
ffffffffc0204c7a:	00003517          	auipc	a0,0x3
ffffffffc0204c7e:	74e50513          	addi	a0,a0,1870 # ffffffffc02083c8 <default_pmm_manager+0x1068>
ffffffffc0204c82:	803fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204c86:	86b2                	mv	a3,a2
ffffffffc0204c88:	06900593          	li	a1,105
ffffffffc0204c8c:	00002617          	auipc	a2,0x2
ffffffffc0204c90:	72460613          	addi	a2,a2,1828 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0204c94:	00002517          	auipc	a0,0x2
ffffffffc0204c98:	74450513          	addi	a0,a0,1860 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204c9c:	fe8fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204ca0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204ca0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204ca2:	9402                	jalr	s0

	jal do_exit
ffffffffc0204ca4:	732000ef          	jal	ra,ffffffffc02053d6 <do_exit>

ffffffffc0204ca8 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204ca8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204caa:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204cae:	e022                	sd	s0,0(sp)
ffffffffc0204cb0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204cb2:	fa5fc0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204cb6:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204cb8:	c529                	beqz	a0,ffffffffc0204d02 <alloc_proc+0x5a>
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state = PROC_UNINIT;  //设置进程为未初始化状态
ffffffffc0204cba:	57fd                	li	a5,-1
ffffffffc0204cbc:	1782                	slli	a5,a5,0x20
ffffffffc0204cbe:	e11c                	sd	a5,0(a0)
    proc->runs = 0;             //初始化时间片
    proc->kstack = 0;           //内存栈的地址
    proc->need_resched = 0;     //是否需要调度设为不需要
    proc->parent = NULL;        //父节点设为空
    proc->mm = NULL;            //虚拟内存设为空
    memset(&(proc->context), 0, sizeof(struct context));//上下文的初始化
ffffffffc0204cc0:	07000613          	li	a2,112
ffffffffc0204cc4:	4581                	li	a1,0
    proc->runs = 0;             //初始化时间片
ffffffffc0204cc6:	00052423          	sw	zero,8(a0)
    proc->kstack = 0;           //内存栈的地址
ffffffffc0204cca:	00053823          	sd	zero,16(a0)
    proc->need_resched = 0;     //是否需要调度设为不需要
ffffffffc0204cce:	00053c23          	sd	zero,24(a0)
    proc->parent = NULL;        //父节点设为空
ffffffffc0204cd2:	02053023          	sd	zero,32(a0)
    proc->mm = NULL;            //虚拟内存设为空
ffffffffc0204cd6:	02053423          	sd	zero,40(a0)
    memset(&(proc->context), 0, sizeof(struct context));//上下文的初始化
ffffffffc0204cda:	03050513          	addi	a0,a0,48
ffffffffc0204cde:	11f010ef          	jal	ra,ffffffffc02065fc <memset>
    proc->tf = NULL;            //中断帧指针置为空
    proc->cr3 = boot_cr3;       //页目录设为内核页目录表的基址
ffffffffc0204ce2:	000a7797          	auipc	a5,0xa7
ffffffffc0204ce6:	7fe78793          	addi	a5,a5,2046 # ffffffffc02ac4e0 <boot_cr3>
ffffffffc0204cea:	639c                	ld	a5,0(a5)
    proc->tf = NULL;            //中断帧指针置为空
ffffffffc0204cec:	0a043023          	sd	zero,160(s0)
    proc->flags = 0;            //标志位
ffffffffc0204cf0:	0a042823          	sw	zero,176(s0)
    proc->cr3 = boot_cr3;       //页目录设为内核页目录表的基址
ffffffffc0204cf4:	f45c                	sd	a5,168(s0)
    memset(proc->name, 0, PROC_NAME_LEN);//进程名
ffffffffc0204cf6:	463d                	li	a2,15
ffffffffc0204cf8:	4581                	li	a1,0
ffffffffc0204cfa:	0b440513          	addi	a0,s0,180
ffffffffc0204cfe:	0ff010ef          	jal	ra,ffffffffc02065fc <memset>
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    }
    proc->wait_state = 0;		//初始化进程等待状态
ffffffffc0204d02:	0e042623          	sw	zero,236(s0)
	proc->cptr = proc->optr = proc->yptr = NULL;		//进程相关指针初始化
ffffffffc0204d06:	0e043c23          	sd	zero,248(s0)
ffffffffc0204d0a:	10043023          	sd	zero,256(s0)
ffffffffc0204d0e:	0e043823          	sd	zero,240(s0)
    return proc;
}
ffffffffc0204d12:	8522                	mv	a0,s0
ffffffffc0204d14:	60a2                	ld	ra,8(sp)
ffffffffc0204d16:	6402                	ld	s0,0(sp)
ffffffffc0204d18:	0141                	addi	sp,sp,16
ffffffffc0204d1a:	8082                	ret

ffffffffc0204d1c <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204d1c:	000a7797          	auipc	a5,0xa7
ffffffffc0204d20:	77478793          	addi	a5,a5,1908 # ffffffffc02ac490 <current>
ffffffffc0204d24:	639c                	ld	a5,0(a5)
ffffffffc0204d26:	73c8                	ld	a0,160(a5)
ffffffffc0204d28:	882fc06f          	j	ffffffffc0200daa <forkrets>

ffffffffc0204d2c <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d2c:	000a7797          	auipc	a5,0xa7
ffffffffc0204d30:	76478793          	addi	a5,a5,1892 # ffffffffc02ac490 <current>
ffffffffc0204d34:	639c                	ld	a5,0(a5)
user_main(void *arg) {
ffffffffc0204d36:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d38:	00004617          	auipc	a2,0x4
ffffffffc0204d3c:	ab860613          	addi	a2,a2,-1352 # ffffffffc02087f0 <default_pmm_manager+0x1490>
ffffffffc0204d40:	43cc                	lw	a1,4(a5)
ffffffffc0204d42:	00004517          	auipc	a0,0x4
ffffffffc0204d46:	abe50513          	addi	a0,a0,-1346 # ffffffffc0208800 <default_pmm_manager+0x14a0>
user_main(void *arg) {
ffffffffc0204d4a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d4c:	c42fb0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0204d50:	00004797          	auipc	a5,0x4
ffffffffc0204d54:	aa078793          	addi	a5,a5,-1376 # ffffffffc02087f0 <default_pmm_manager+0x1490>
ffffffffc0204d58:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204d5c:	57870713          	addi	a4,a4,1400 # a2d0 <_binary_obj___user_forktest_out_size>
ffffffffc0204d60:	e43a                	sd	a4,8(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204d62:	853e                	mv	a0,a5
ffffffffc0204d64:	00043717          	auipc	a4,0x43
ffffffffc0204d68:	2dc70713          	addi	a4,a4,732 # ffffffffc0248040 <_binary_obj___user_forktest_out_start>
ffffffffc0204d6c:	f03a                	sd	a4,32(sp)
ffffffffc0204d6e:	f43e                	sd	a5,40(sp)
ffffffffc0204d70:	e802                	sd	zero,16(sp)
ffffffffc0204d72:	7ec010ef          	jal	ra,ffffffffc020655e <strlen>
ffffffffc0204d76:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204d78:	4511                	li	a0,4
ffffffffc0204d7a:	55a2                	lw	a1,40(sp)
ffffffffc0204d7c:	4662                	lw	a2,24(sp)
ffffffffc0204d7e:	5682                	lw	a3,32(sp)
ffffffffc0204d80:	4722                	lw	a4,8(sp)
ffffffffc0204d82:	48a9                	li	a7,10
ffffffffc0204d84:	9002                	ebreak
ffffffffc0204d86:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204d88:	65c2                	ld	a1,16(sp)
ffffffffc0204d8a:	00004517          	auipc	a0,0x4
ffffffffc0204d8e:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0208828 <default_pmm_manager+0x14c8>
ffffffffc0204d92:	bfcfb0ef          	jal	ra,ffffffffc020018e <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204d96:	00004617          	auipc	a2,0x4
ffffffffc0204d9a:	aa260613          	addi	a2,a2,-1374 # ffffffffc0208838 <default_pmm_manager+0x14d8>
ffffffffc0204d9e:	35100593          	li	a1,849
ffffffffc0204da2:	00004517          	auipc	a0,0x4
ffffffffc0204da6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0204daa:	edafb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204dae <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204dae:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204db0:	1141                	addi	sp,sp,-16
ffffffffc0204db2:	e406                	sd	ra,8(sp)
ffffffffc0204db4:	c02007b7          	lui	a5,0xc0200
ffffffffc0204db8:	04f6e263          	bltu	a3,a5,ffffffffc0204dfc <put_pgdir+0x4e>
ffffffffc0204dbc:	000a7797          	auipc	a5,0xa7
ffffffffc0204dc0:	71c78793          	addi	a5,a5,1820 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0204dc4:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0204dc6:	000a7797          	auipc	a5,0xa7
ffffffffc0204dca:	6b278793          	addi	a5,a5,1714 # ffffffffc02ac478 <npage>
ffffffffc0204dce:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0204dd0:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204dd2:	82b1                	srli	a3,a3,0xc
ffffffffc0204dd4:	04f6f063          	bleu	a5,a3,ffffffffc0204e14 <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0204dd8:	00004797          	auipc	a5,0x4
ffffffffc0204ddc:	f4878793          	addi	a5,a5,-184 # ffffffffc0208d20 <nbase>
ffffffffc0204de0:	639c                	ld	a5,0(a5)
ffffffffc0204de2:	000a7717          	auipc	a4,0xa7
ffffffffc0204de6:	70670713          	addi	a4,a4,1798 # ffffffffc02ac4e8 <pages>
ffffffffc0204dea:	6308                	ld	a0,0(a4)
}
ffffffffc0204dec:	60a2                	ld	ra,8(sp)
ffffffffc0204dee:	8e9d                	sub	a3,a3,a5
ffffffffc0204df0:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204df2:	4585                	li	a1,1
ffffffffc0204df4:	9536                	add	a0,a0,a3
}
ffffffffc0204df6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204df8:	8e2fd06f          	j	ffffffffc0201eda <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204dfc:	00002617          	auipc	a2,0x2
ffffffffc0204e00:	5ec60613          	addi	a2,a2,1516 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc0204e04:	06e00593          	li	a1,110
ffffffffc0204e08:	00002517          	auipc	a0,0x2
ffffffffc0204e0c:	5d050513          	addi	a0,a0,1488 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204e10:	e74fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204e14:	00002617          	auipc	a2,0x2
ffffffffc0204e18:	5fc60613          	addi	a2,a2,1532 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc0204e1c:	06200593          	li	a1,98
ffffffffc0204e20:	00002517          	auipc	a0,0x2
ffffffffc0204e24:	5b850513          	addi	a0,a0,1464 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204e28:	e5cfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204e2c <setup_pgdir>:
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e2c:	1101                	addi	sp,sp,-32
ffffffffc0204e2e:	e426                	sd	s1,8(sp)
ffffffffc0204e30:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e32:	4505                	li	a0,1
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e34:	ec06                	sd	ra,24(sp)
ffffffffc0204e36:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e38:	81afd0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0204e3c:	c125                	beqz	a0,ffffffffc0204e9c <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0204e3e:	000a7797          	auipc	a5,0xa7
ffffffffc0204e42:	6aa78793          	addi	a5,a5,1706 # ffffffffc02ac4e8 <pages>
ffffffffc0204e46:	6394                	ld	a3,0(a5)
ffffffffc0204e48:	00004797          	auipc	a5,0x4
ffffffffc0204e4c:	ed878793          	addi	a5,a5,-296 # ffffffffc0208d20 <nbase>
ffffffffc0204e50:	6380                	ld	s0,0(a5)
ffffffffc0204e52:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204e56:	000a7717          	auipc	a4,0xa7
ffffffffc0204e5a:	62270713          	addi	a4,a4,1570 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc0204e5e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204e60:	57fd                	li	a5,-1
ffffffffc0204e62:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0204e64:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc0204e66:	83b1                	srli	a5,a5,0xc
ffffffffc0204e68:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e6a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e6c:	02e7fa63          	bleu	a4,a5,ffffffffc0204ea0 <setup_pgdir+0x74>
ffffffffc0204e70:	000a7797          	auipc	a5,0xa7
ffffffffc0204e74:	66878793          	addi	a5,a5,1640 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0204e78:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0204e7a:	000a7797          	auipc	a5,0xa7
ffffffffc0204e7e:	5f678793          	addi	a5,a5,1526 # ffffffffc02ac470 <boot_pgdir>
ffffffffc0204e82:	638c                	ld	a1,0(a5)
ffffffffc0204e84:	9436                	add	s0,s0,a3
ffffffffc0204e86:	6605                	lui	a2,0x1
ffffffffc0204e88:	8522                	mv	a0,s0
ffffffffc0204e8a:	784010ef          	jal	ra,ffffffffc020660e <memcpy>
    return 0;
ffffffffc0204e8e:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc0204e90:	ec80                	sd	s0,24(s1)
}
ffffffffc0204e92:	60e2                	ld	ra,24(sp)
ffffffffc0204e94:	6442                	ld	s0,16(sp)
ffffffffc0204e96:	64a2                	ld	s1,8(sp)
ffffffffc0204e98:	6105                	addi	sp,sp,32
ffffffffc0204e9a:	8082                	ret
        return -E_NO_MEM;
ffffffffc0204e9c:	5571                	li	a0,-4
ffffffffc0204e9e:	bfd5                	j	ffffffffc0204e92 <setup_pgdir+0x66>
ffffffffc0204ea0:	00002617          	auipc	a2,0x2
ffffffffc0204ea4:	51060613          	addi	a2,a2,1296 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0204ea8:	06900593          	li	a1,105
ffffffffc0204eac:	00002517          	auipc	a0,0x2
ffffffffc0204eb0:	52c50513          	addi	a0,a0,1324 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0204eb4:	dd0fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204eb8 <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204eb8:	1101                	addi	sp,sp,-32
ffffffffc0204eba:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ebc:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204ec0:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ec2:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204ec4:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ec6:	8522                	mv	a0,s0
ffffffffc0204ec8:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204eca:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ecc:	730010ef          	jal	ra,ffffffffc02065fc <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ed0:	8522                	mv	a0,s0
}
ffffffffc0204ed2:	6442                	ld	s0,16(sp)
ffffffffc0204ed4:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ed6:	85a6                	mv	a1,s1
}
ffffffffc0204ed8:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eda:	463d                	li	a2,15
}
ffffffffc0204edc:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ede:	7300106f          	j	ffffffffc020660e <memcpy>

ffffffffc0204ee2 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204ee2:	1101                	addi	sp,sp,-32
    if (proc != current) {
ffffffffc0204ee4:	000a7797          	auipc	a5,0xa7
ffffffffc0204ee8:	5ac78793          	addi	a5,a5,1452 # ffffffffc02ac490 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204eec:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc0204eee:	6384                	ld	s1,0(a5)
proc_run(struct proc_struct *proc) {
ffffffffc0204ef0:	ec06                	sd	ra,24(sp)
ffffffffc0204ef2:	e822                	sd	s0,16(sp)
ffffffffc0204ef4:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc0204ef6:	02a48b63          	beq	s1,a0,ffffffffc0204f2c <proc_run+0x4a>
ffffffffc0204efa:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204efc:	100027f3          	csrr	a5,sstatus
ffffffffc0204f00:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204f02:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204f04:	e3a9                	bnez	a5,ffffffffc0204f46 <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204f06:	745c                	ld	a5,168(s0)
            current = proc; 
ffffffffc0204f08:	000a7717          	auipc	a4,0xa7
ffffffffc0204f0c:	58873423          	sd	s0,1416(a4) # ffffffffc02ac490 <current>
ffffffffc0204f10:	577d                	li	a4,-1
ffffffffc0204f12:	177e                	slli	a4,a4,0x3f
ffffffffc0204f14:	83b1                	srli	a5,a5,0xc
ffffffffc0204f16:	8fd9                	or	a5,a5,a4
ffffffffc0204f18:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204f1c:	03040593          	addi	a1,s0,48
ffffffffc0204f20:	03048513          	addi	a0,s1,48
ffffffffc0204f24:	7cf000ef          	jal	ra,ffffffffc0205ef2 <switch_to>
    if (flag) {
ffffffffc0204f28:	00091863          	bnez	s2,ffffffffc0204f38 <proc_run+0x56>
}
ffffffffc0204f2c:	60e2                	ld	ra,24(sp)
ffffffffc0204f2e:	6442                	ld	s0,16(sp)
ffffffffc0204f30:	64a2                	ld	s1,8(sp)
ffffffffc0204f32:	6902                	ld	s2,0(sp)
ffffffffc0204f34:	6105                	addi	sp,sp,32
ffffffffc0204f36:	8082                	ret
ffffffffc0204f38:	6442                	ld	s0,16(sp)
ffffffffc0204f3a:	60e2                	ld	ra,24(sp)
ffffffffc0204f3c:	64a2                	ld	s1,8(sp)
ffffffffc0204f3e:	6902                	ld	s2,0(sp)
ffffffffc0204f40:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204f42:	f12fb06f          	j	ffffffffc0200654 <intr_enable>
        intr_disable();
ffffffffc0204f46:	f14fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0204f4a:	4905                	li	s2,1
ffffffffc0204f4c:	bf6d                	j	ffffffffc0204f06 <proc_run+0x24>

ffffffffc0204f4e <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc0204f4e:	0005071b          	sext.w	a4,a0
ffffffffc0204f52:	6789                	lui	a5,0x2
ffffffffc0204f54:	fff7069b          	addiw	a3,a4,-1
ffffffffc0204f58:	17f9                	addi	a5,a5,-2
ffffffffc0204f5a:	04d7e063          	bltu	a5,a3,ffffffffc0204f9a <find_proc+0x4c>
find_proc(int pid) {
ffffffffc0204f5e:	1141                	addi	sp,sp,-16
ffffffffc0204f60:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f62:	45a9                	li	a1,10
ffffffffc0204f64:	842a                	mv	s0,a0
ffffffffc0204f66:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc0204f68:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f6a:	1e4010ef          	jal	ra,ffffffffc020614e <hash32>
ffffffffc0204f6e:	02051693          	slli	a3,a0,0x20
ffffffffc0204f72:	82f1                	srli	a3,a3,0x1c
ffffffffc0204f74:	000a3517          	auipc	a0,0xa3
ffffffffc0204f78:	4e450513          	addi	a0,a0,1252 # ffffffffc02a8458 <hash_list>
ffffffffc0204f7c:	96aa                	add	a3,a3,a0
ffffffffc0204f7e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0204f80:	a029                	j	ffffffffc0204f8a <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc0204f82:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7644>
ffffffffc0204f86:	00870c63          	beq	a4,s0,ffffffffc0204f9e <find_proc+0x50>
ffffffffc0204f8a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204f8c:	fef69be3          	bne	a3,a5,ffffffffc0204f82 <find_proc+0x34>
}
ffffffffc0204f90:	60a2                	ld	ra,8(sp)
ffffffffc0204f92:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204f94:	4501                	li	a0,0
}
ffffffffc0204f96:	0141                	addi	sp,sp,16
ffffffffc0204f98:	8082                	ret
    return NULL;
ffffffffc0204f9a:	4501                	li	a0,0
}
ffffffffc0204f9c:	8082                	ret
ffffffffc0204f9e:	60a2                	ld	ra,8(sp)
ffffffffc0204fa0:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204fa2:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204fa6:	0141                	addi	sp,sp,16
ffffffffc0204fa8:	8082                	ret

ffffffffc0204faa <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204faa:	7159                	addi	sp,sp,-112
ffffffffc0204fac:	e0d2                	sd	s4,64(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204fae:	000a7a17          	auipc	s4,0xa7
ffffffffc0204fb2:	4faa0a13          	addi	s4,s4,1274 # ffffffffc02ac4a8 <nr_process>
ffffffffc0204fb6:	000a2703          	lw	a4,0(s4)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204fba:	f486                	sd	ra,104(sp)
ffffffffc0204fbc:	f0a2                	sd	s0,96(sp)
ffffffffc0204fbe:	eca6                	sd	s1,88(sp)
ffffffffc0204fc0:	e8ca                	sd	s2,80(sp)
ffffffffc0204fc2:	e4ce                	sd	s3,72(sp)
ffffffffc0204fc4:	fc56                	sd	s5,56(sp)
ffffffffc0204fc6:	f85a                	sd	s6,48(sp)
ffffffffc0204fc8:	f45e                	sd	s7,40(sp)
ffffffffc0204fca:	f062                	sd	s8,32(sp)
ffffffffc0204fcc:	ec66                	sd	s9,24(sp)
ffffffffc0204fce:	e86a                	sd	s10,16(sp)
ffffffffc0204fd0:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204fd2:	6785                	lui	a5,0x1
ffffffffc0204fd4:	30f75a63          	ble	a5,a4,ffffffffc02052e8 <do_fork+0x33e>
ffffffffc0204fd8:	89aa                	mv	s3,a0
ffffffffc0204fda:	892e                	mv	s2,a1
ffffffffc0204fdc:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204fde:	ccbff0ef          	jal	ra,ffffffffc0204ca8 <alloc_proc>
ffffffffc0204fe2:	842a                	mv	s0,a0
ffffffffc0204fe4:	2e050463          	beqz	a0,ffffffffc02052cc <do_fork+0x322>
    proc->parent = current;
ffffffffc0204fe8:	000a7c17          	auipc	s8,0xa7
ffffffffc0204fec:	4a8c0c13          	addi	s8,s8,1192 # ffffffffc02ac490 <current>
ffffffffc0204ff0:	000c3783          	ld	a5,0(s8)
	assert(current->wait_state == 0);	
ffffffffc0204ff4:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8484>
    proc->parent = current;
ffffffffc0204ff8:	f11c                	sd	a5,32(a0)
	assert(current->wait_state == 0);	
ffffffffc0204ffa:	30071563          	bnez	a4,ffffffffc0205304 <do_fork+0x35a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204ffe:	4509                	li	a0,2
ffffffffc0205000:	e53fc0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
    if (page != NULL) {
ffffffffc0205004:	2c050163          	beqz	a0,ffffffffc02052c6 <do_fork+0x31c>
    return page - pages + nbase;
ffffffffc0205008:	000a7a97          	auipc	s5,0xa7
ffffffffc020500c:	4e0a8a93          	addi	s5,s5,1248 # ffffffffc02ac4e8 <pages>
ffffffffc0205010:	000ab683          	ld	a3,0(s5)
ffffffffc0205014:	00004b17          	auipc	s6,0x4
ffffffffc0205018:	d0cb0b13          	addi	s6,s6,-756 # ffffffffc0208d20 <nbase>
ffffffffc020501c:	000b3783          	ld	a5,0(s6)
ffffffffc0205020:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0205024:	000a7b97          	auipc	s7,0xa7
ffffffffc0205028:	454b8b93          	addi	s7,s7,1108 # ffffffffc02ac478 <npage>
    return page - pages + nbase;
ffffffffc020502c:	8699                	srai	a3,a3,0x6
ffffffffc020502e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205030:	000bb703          	ld	a4,0(s7)
ffffffffc0205034:	57fd                	li	a5,-1
ffffffffc0205036:	83b1                	srli	a5,a5,0xc
ffffffffc0205038:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020503a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020503c:	2ae7f863          	bleu	a4,a5,ffffffffc02052ec <do_fork+0x342>
ffffffffc0205040:	000a7c97          	auipc	s9,0xa7
ffffffffc0205044:	498c8c93          	addi	s9,s9,1176 # ffffffffc02ac4d8 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0205048:	000c3703          	ld	a4,0(s8)
ffffffffc020504c:	000cb783          	ld	a5,0(s9)
ffffffffc0205050:	02873c03          	ld	s8,40(a4)
ffffffffc0205054:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0205056:	e814                	sd	a3,16(s0)
    if (oldmm == NULL) {
ffffffffc0205058:	020c0863          	beqz	s8,ffffffffc0205088 <do_fork+0xde>
    if (clone_flags & CLONE_VM) {
ffffffffc020505c:	1009f993          	andi	s3,s3,256
ffffffffc0205060:	1e098163          	beqz	s3,ffffffffc0205242 <do_fork+0x298>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0205064:	030c2703          	lw	a4,48(s8)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205068:	018c3783          	ld	a5,24(s8)
ffffffffc020506c:	c02006b7          	lui	a3,0xc0200
ffffffffc0205070:	2705                	addiw	a4,a4,1
ffffffffc0205072:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc0205076:	03843423          	sd	s8,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020507a:	2ad7e563          	bltu	a5,a3,ffffffffc0205324 <do_fork+0x37a>
ffffffffc020507e:	000cb703          	ld	a4,0(s9)
ffffffffc0205082:	6814                	ld	a3,16(s0)
ffffffffc0205084:	8f99                	sub	a5,a5,a4
ffffffffc0205086:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205088:	6789                	lui	a5,0x2
ffffffffc020508a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>
ffffffffc020508e:	96be                	add	a3,a3,a5
ffffffffc0205090:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0205092:	87b6                	mv	a5,a3
ffffffffc0205094:	12048813          	addi	a6,s1,288
ffffffffc0205098:	6088                	ld	a0,0(s1)
ffffffffc020509a:	648c                	ld	a1,8(s1)
ffffffffc020509c:	6890                	ld	a2,16(s1)
ffffffffc020509e:	6c98                	ld	a4,24(s1)
ffffffffc02050a0:	e388                	sd	a0,0(a5)
ffffffffc02050a2:	e78c                	sd	a1,8(a5)
ffffffffc02050a4:	eb90                	sd	a2,16(a5)
ffffffffc02050a6:	ef98                	sd	a4,24(a5)
ffffffffc02050a8:	02048493          	addi	s1,s1,32
ffffffffc02050ac:	02078793          	addi	a5,a5,32
ffffffffc02050b0:	ff0494e3          	bne	s1,a6,ffffffffc0205098 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc02050b4:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02050b8:	12090e63          	beqz	s2,ffffffffc02051f4 <do_fork+0x24a>
ffffffffc02050bc:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02050c0:	00000797          	auipc	a5,0x0
ffffffffc02050c4:	c5c78793          	addi	a5,a5,-932 # ffffffffc0204d1c <forkret>
ffffffffc02050c8:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02050ca:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050cc:	100027f3          	csrr	a5,sstatus
ffffffffc02050d0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02050d2:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050d4:	12079f63          	bnez	a5,ffffffffc0205212 <do_fork+0x268>
    if (++ last_pid >= MAX_PID) {
ffffffffc02050d8:	0009c797          	auipc	a5,0x9c
ffffffffc02050dc:	f7878793          	addi	a5,a5,-136 # ffffffffc02a1050 <last_pid.1691>
ffffffffc02050e0:	439c                	lw	a5,0(a5)
ffffffffc02050e2:	6709                	lui	a4,0x2
ffffffffc02050e4:	0017851b          	addiw	a0,a5,1
ffffffffc02050e8:	0009c697          	auipc	a3,0x9c
ffffffffc02050ec:	f6a6a423          	sw	a0,-152(a3) # ffffffffc02a1050 <last_pid.1691>
ffffffffc02050f0:	14e55263          	ble	a4,a0,ffffffffc0205234 <do_fork+0x28a>
    if (last_pid >= next_safe) {
ffffffffc02050f4:	0009c797          	auipc	a5,0x9c
ffffffffc02050f8:	f6078793          	addi	a5,a5,-160 # ffffffffc02a1054 <next_safe.1690>
ffffffffc02050fc:	439c                	lw	a5,0(a5)
ffffffffc02050fe:	000a7497          	auipc	s1,0xa7
ffffffffc0205102:	4d248493          	addi	s1,s1,1234 # ffffffffc02ac5d0 <proc_list>
ffffffffc0205106:	06f54063          	blt	a0,a5,ffffffffc0205166 <do_fork+0x1bc>
        next_safe = MAX_PID;
ffffffffc020510a:	6789                	lui	a5,0x2
ffffffffc020510c:	0009c717          	auipc	a4,0x9c
ffffffffc0205110:	f4f72423          	sw	a5,-184(a4) # ffffffffc02a1054 <next_safe.1690>
ffffffffc0205114:	4581                	li	a1,0
ffffffffc0205116:	87aa                	mv	a5,a0
ffffffffc0205118:	000a7497          	auipc	s1,0xa7
ffffffffc020511c:	4b848493          	addi	s1,s1,1208 # ffffffffc02ac5d0 <proc_list>
    repeat:
ffffffffc0205120:	6889                	lui	a7,0x2
ffffffffc0205122:	882e                	mv	a6,a1
ffffffffc0205124:	6609                	lui	a2,0x2
        le = list;
ffffffffc0205126:	000a7697          	auipc	a3,0xa7
ffffffffc020512a:	4aa68693          	addi	a3,a3,1194 # ffffffffc02ac5d0 <proc_list>
ffffffffc020512e:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc0205130:	00968f63          	beq	a3,s1,ffffffffc020514e <do_fork+0x1a4>
            if (proc->pid == last_pid) {
ffffffffc0205134:	f3c6a703          	lw	a4,-196(a3)
ffffffffc0205138:	0ae78963          	beq	a5,a4,ffffffffc02051ea <do_fork+0x240>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc020513c:	fee7d9e3          	ble	a4,a5,ffffffffc020512e <do_fork+0x184>
ffffffffc0205140:	fec757e3          	ble	a2,a4,ffffffffc020512e <do_fork+0x184>
ffffffffc0205144:	6694                	ld	a3,8(a3)
ffffffffc0205146:	863a                	mv	a2,a4
ffffffffc0205148:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc020514a:	fe9695e3          	bne	a3,s1,ffffffffc0205134 <do_fork+0x18a>
ffffffffc020514e:	c591                	beqz	a1,ffffffffc020515a <do_fork+0x1b0>
ffffffffc0205150:	0009c717          	auipc	a4,0x9c
ffffffffc0205154:	f0f72023          	sw	a5,-256(a4) # ffffffffc02a1050 <last_pid.1691>
ffffffffc0205158:	853e                	mv	a0,a5
ffffffffc020515a:	00080663          	beqz	a6,ffffffffc0205166 <do_fork+0x1bc>
ffffffffc020515e:	0009c797          	auipc	a5,0x9c
ffffffffc0205162:	eec7ab23          	sw	a2,-266(a5) # ffffffffc02a1054 <next_safe.1690>
        proc->pid = get_pid();
ffffffffc0205166:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205168:	45a9                	li	a1,10
ffffffffc020516a:	2501                	sext.w	a0,a0
ffffffffc020516c:	7e3000ef          	jal	ra,ffffffffc020614e <hash32>
ffffffffc0205170:	1502                	slli	a0,a0,0x20
ffffffffc0205172:	000a3797          	auipc	a5,0xa3
ffffffffc0205176:	2e678793          	addi	a5,a5,742 # ffffffffc02a8458 <hash_list>
ffffffffc020517a:	8171                	srli	a0,a0,0x1c
ffffffffc020517c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020517e:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205180:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205182:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc0205186:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205188:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc020518a:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc020518c:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020518e:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc0205192:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc0205194:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0205196:	e21c                	sd	a5,0(a2)
ffffffffc0205198:	000a7597          	auipc	a1,0xa7
ffffffffc020519c:	44f5b023          	sd	a5,1088(a1) # ffffffffc02ac5d8 <proc_list+0x8>
    elm->next = next;
ffffffffc02051a0:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02051a2:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc02051a4:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02051a8:	10e43023          	sd	a4,256(s0)
ffffffffc02051ac:	c311                	beqz	a4,ffffffffc02051b0 <do_fork+0x206>
        proc->optr->yptr = proc;
ffffffffc02051ae:	ff60                	sd	s0,248(a4)
    nr_process ++;
ffffffffc02051b0:	000a2783          	lw	a5,0(s4)
    proc->parent->cptr = proc;
ffffffffc02051b4:	fae0                	sd	s0,240(a3)
    nr_process ++;
ffffffffc02051b6:	2785                	addiw	a5,a5,1
ffffffffc02051b8:	000a7717          	auipc	a4,0xa7
ffffffffc02051bc:	2ef72823          	sw	a5,752(a4) # ffffffffc02ac4a8 <nr_process>
    if (flag) {
ffffffffc02051c0:	10091863          	bnez	s2,ffffffffc02052d0 <do_fork+0x326>
    wakeup_proc(proc);
ffffffffc02051c4:	8522                	mv	a0,s0
ffffffffc02051c6:	597000ef          	jal	ra,ffffffffc0205f5c <wakeup_proc>
    ret = proc->pid;
ffffffffc02051ca:	4048                	lw	a0,4(s0)
}
ffffffffc02051cc:	70a6                	ld	ra,104(sp)
ffffffffc02051ce:	7406                	ld	s0,96(sp)
ffffffffc02051d0:	64e6                	ld	s1,88(sp)
ffffffffc02051d2:	6946                	ld	s2,80(sp)
ffffffffc02051d4:	69a6                	ld	s3,72(sp)
ffffffffc02051d6:	6a06                	ld	s4,64(sp)
ffffffffc02051d8:	7ae2                	ld	s5,56(sp)
ffffffffc02051da:	7b42                	ld	s6,48(sp)
ffffffffc02051dc:	7ba2                	ld	s7,40(sp)
ffffffffc02051de:	7c02                	ld	s8,32(sp)
ffffffffc02051e0:	6ce2                	ld	s9,24(sp)
ffffffffc02051e2:	6d42                	ld	s10,16(sp)
ffffffffc02051e4:	6da2                	ld	s11,8(sp)
ffffffffc02051e6:	6165                	addi	sp,sp,112
ffffffffc02051e8:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc02051ea:	2785                	addiw	a5,a5,1
ffffffffc02051ec:	0ec7d563          	ble	a2,a5,ffffffffc02052d6 <do_fork+0x32c>
ffffffffc02051f0:	4585                	li	a1,1
ffffffffc02051f2:	bf35                	j	ffffffffc020512e <do_fork+0x184>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02051f4:	8936                	mv	s2,a3
ffffffffc02051f6:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02051fa:	00000797          	auipc	a5,0x0
ffffffffc02051fe:	b2278793          	addi	a5,a5,-1246 # ffffffffc0204d1c <forkret>
ffffffffc0205202:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205204:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205206:	100027f3          	csrr	a5,sstatus
ffffffffc020520a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020520c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020520e:	ec0785e3          	beqz	a5,ffffffffc02050d8 <do_fork+0x12e>
        intr_disable();
ffffffffc0205212:	c48fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205216:	0009c797          	auipc	a5,0x9c
ffffffffc020521a:	e3a78793          	addi	a5,a5,-454 # ffffffffc02a1050 <last_pid.1691>
ffffffffc020521e:	439c                	lw	a5,0(a5)
ffffffffc0205220:	6709                	lui	a4,0x2
        return 1;
ffffffffc0205222:	4905                	li	s2,1
ffffffffc0205224:	0017851b          	addiw	a0,a5,1
ffffffffc0205228:	0009c697          	auipc	a3,0x9c
ffffffffc020522c:	e2a6a423          	sw	a0,-472(a3) # ffffffffc02a1050 <last_pid.1691>
ffffffffc0205230:	ece542e3          	blt	a0,a4,ffffffffc02050f4 <do_fork+0x14a>
        last_pid = 1;
ffffffffc0205234:	4785                	li	a5,1
ffffffffc0205236:	0009c717          	auipc	a4,0x9c
ffffffffc020523a:	e0f72d23          	sw	a5,-486(a4) # ffffffffc02a1050 <last_pid.1691>
ffffffffc020523e:	4505                	li	a0,1
ffffffffc0205240:	b5e9                	j	ffffffffc020510a <do_fork+0x160>
    if ((mm = mm_create()) == NULL) {
ffffffffc0205242:	e85fe0ef          	jal	ra,ffffffffc02040c6 <mm_create>
ffffffffc0205246:	8d2a                	mv	s10,a0
ffffffffc0205248:	c539                	beqz	a0,ffffffffc0205296 <do_fork+0x2ec>
    if (setup_pgdir(mm) != 0) {
ffffffffc020524a:	be3ff0ef          	jal	ra,ffffffffc0204e2c <setup_pgdir>
ffffffffc020524e:	e949                	bnez	a0,ffffffffc02052e0 <do_fork+0x336>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205250:	038c0d93          	addi	s11,s8,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0205254:	4785                	li	a5,1
ffffffffc0205256:	40fdb7af          	amoor.d	a5,a5,(s11)
ffffffffc020525a:	8b85                	andi	a5,a5,1
ffffffffc020525c:	4985                	li	s3,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc020525e:	c799                	beqz	a5,ffffffffc020526c <do_fork+0x2c2>
        schedule();
ffffffffc0205260:	579000ef          	jal	ra,ffffffffc0205fd8 <schedule>
ffffffffc0205264:	413db7af          	amoor.d	a5,s3,(s11)
ffffffffc0205268:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc020526a:	fbfd                	bnez	a5,ffffffffc0205260 <do_fork+0x2b6>
        ret = dup_mmap(mm, oldmm);
ffffffffc020526c:	85e2                	mv	a1,s8
ffffffffc020526e:	856a                	mv	a0,s10
ffffffffc0205270:	8e0ff0ef          	jal	ra,ffffffffc0204350 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0205274:	57f9                	li	a5,-2
ffffffffc0205276:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020527a:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc020527c:	c3e9                	beqz	a5,ffffffffc020533e <do_fork+0x394>
    if (ret != 0) {
ffffffffc020527e:	8c6a                	mv	s8,s10
ffffffffc0205280:	de0502e3          	beqz	a0,ffffffffc0205064 <do_fork+0xba>
    exit_mmap(mm);
ffffffffc0205284:	856a                	mv	a0,s10
ffffffffc0205286:	966ff0ef          	jal	ra,ffffffffc02043ec <exit_mmap>
    put_pgdir(mm);
ffffffffc020528a:	856a                	mv	a0,s10
ffffffffc020528c:	b23ff0ef          	jal	ra,ffffffffc0204dae <put_pgdir>
    mm_destroy(mm);
ffffffffc0205290:	856a                	mv	a0,s10
ffffffffc0205292:	fbbfe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205296:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0205298:	c02007b7          	lui	a5,0xc0200
ffffffffc020529c:	0cf6e963          	bltu	a3,a5,ffffffffc020536e <do_fork+0x3c4>
ffffffffc02052a0:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc02052a4:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02052a8:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02052ac:	83b1                	srli	a5,a5,0xc
ffffffffc02052ae:	0ae7f463          	bleu	a4,a5,ffffffffc0205356 <do_fork+0x3ac>
    return &pages[PPN(pa) - nbase];
ffffffffc02052b2:	000b3703          	ld	a4,0(s6)
ffffffffc02052b6:	000ab503          	ld	a0,0(s5)
ffffffffc02052ba:	4589                	li	a1,2
ffffffffc02052bc:	8f99                	sub	a5,a5,a4
ffffffffc02052be:	079a                	slli	a5,a5,0x6
ffffffffc02052c0:	953e                	add	a0,a0,a5
ffffffffc02052c2:	c19fc0ef          	jal	ra,ffffffffc0201eda <free_pages>
    kfree(proc);
ffffffffc02052c6:	8522                	mv	a0,s0
ffffffffc02052c8:	a4bfc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    ret = -E_NO_MEM;
ffffffffc02052cc:	5571                	li	a0,-4
    return ret;
ffffffffc02052ce:	bdfd                	j	ffffffffc02051cc <do_fork+0x222>
        intr_enable();
ffffffffc02052d0:	b84fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc02052d4:	bdc5                	j	ffffffffc02051c4 <do_fork+0x21a>
                    if (last_pid >= MAX_PID) {
ffffffffc02052d6:	0117c363          	blt	a5,a7,ffffffffc02052dc <do_fork+0x332>
                        last_pid = 1;
ffffffffc02052da:	4785                	li	a5,1
                    goto repeat;
ffffffffc02052dc:	4585                	li	a1,1
ffffffffc02052de:	b591                	j	ffffffffc0205122 <do_fork+0x178>
    mm_destroy(mm);
ffffffffc02052e0:	856a                	mv	a0,s10
ffffffffc02052e2:	f6bfe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
ffffffffc02052e6:	bf45                	j	ffffffffc0205296 <do_fork+0x2ec>
    int ret = -E_NO_FREE_PROC;
ffffffffc02052e8:	556d                	li	a0,-5
ffffffffc02052ea:	b5cd                	j	ffffffffc02051cc <do_fork+0x222>
    return KADDR(page2pa(page));
ffffffffc02052ec:	00002617          	auipc	a2,0x2
ffffffffc02052f0:	0c460613          	addi	a2,a2,196 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc02052f4:	06900593          	li	a1,105
ffffffffc02052f8:	00002517          	auipc	a0,0x2
ffffffffc02052fc:	0e050513          	addi	a0,a0,224 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0205300:	984fb0ef          	jal	ra,ffffffffc0200484 <__panic>
	assert(current->wait_state == 0);	
ffffffffc0205304:	00003697          	auipc	a3,0x3
ffffffffc0205308:	2c468693          	addi	a3,a3,708 # ffffffffc02085c8 <default_pmm_manager+0x1268>
ffffffffc020530c:	00002617          	auipc	a2,0x2
ffffffffc0205310:	90c60613          	addi	a2,a2,-1780 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205314:	1b200593          	li	a1,434
ffffffffc0205318:	00003517          	auipc	a0,0x3
ffffffffc020531c:	54050513          	addi	a0,a0,1344 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205320:	964fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205324:	86be                	mv	a3,a5
ffffffffc0205326:	00002617          	auipc	a2,0x2
ffffffffc020532a:	0c260613          	addi	a2,a2,194 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc020532e:	16300593          	li	a1,355
ffffffffc0205332:	00003517          	auipc	a0,0x3
ffffffffc0205336:	52650513          	addi	a0,a0,1318 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc020533a:	94afb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("Unlock failed.\n");
ffffffffc020533e:	00003617          	auipc	a2,0x3
ffffffffc0205342:	2aa60613          	addi	a2,a2,682 # ffffffffc02085e8 <default_pmm_manager+0x1288>
ffffffffc0205346:	03100593          	li	a1,49
ffffffffc020534a:	00003517          	auipc	a0,0x3
ffffffffc020534e:	2ae50513          	addi	a0,a0,686 # ffffffffc02085f8 <default_pmm_manager+0x1298>
ffffffffc0205352:	932fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205356:	00002617          	auipc	a2,0x2
ffffffffc020535a:	0ba60613          	addi	a2,a2,186 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc020535e:	06200593          	li	a1,98
ffffffffc0205362:	00002517          	auipc	a0,0x2
ffffffffc0205366:	07650513          	addi	a0,a0,118 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc020536a:	91afb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020536e:	00002617          	auipc	a2,0x2
ffffffffc0205372:	07a60613          	addi	a2,a2,122 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc0205376:	06e00593          	li	a1,110
ffffffffc020537a:	00002517          	auipc	a0,0x2
ffffffffc020537e:	05e50513          	addi	a0,a0,94 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0205382:	902fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205386 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205386:	7129                	addi	sp,sp,-320
ffffffffc0205388:	fa22                	sd	s0,304(sp)
ffffffffc020538a:	f626                	sd	s1,296(sp)
ffffffffc020538c:	f24a                	sd	s2,288(sp)
ffffffffc020538e:	84ae                	mv	s1,a1
ffffffffc0205390:	892a                	mv	s2,a0
ffffffffc0205392:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205394:	4581                	li	a1,0
ffffffffc0205396:	12000613          	li	a2,288
ffffffffc020539a:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020539c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020539e:	25e010ef          	jal	ra,ffffffffc02065fc <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02053a2:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02053a4:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02053a6:	100027f3          	csrr	a5,sstatus
ffffffffc02053aa:	edd7f793          	andi	a5,a5,-291
ffffffffc02053ae:	1207e793          	ori	a5,a5,288
ffffffffc02053b2:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053b4:	860a                	mv	a2,sp
ffffffffc02053b6:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02053ba:	00000797          	auipc	a5,0x0
ffffffffc02053be:	8e678793          	addi	a5,a5,-1818 # ffffffffc0204ca0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053c2:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02053c4:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053c6:	be5ff0ef          	jal	ra,ffffffffc0204faa <do_fork>
}
ffffffffc02053ca:	70f2                	ld	ra,312(sp)
ffffffffc02053cc:	7452                	ld	s0,304(sp)
ffffffffc02053ce:	74b2                	ld	s1,296(sp)
ffffffffc02053d0:	7912                	ld	s2,288(sp)
ffffffffc02053d2:	6131                	addi	sp,sp,320
ffffffffc02053d4:	8082                	ret

ffffffffc02053d6 <do_exit>:
do_exit(int error_code) {
ffffffffc02053d6:	7179                	addi	sp,sp,-48
ffffffffc02053d8:	e84a                	sd	s2,16(sp)
    if (current == idleproc) {
ffffffffc02053da:	000a7717          	auipc	a4,0xa7
ffffffffc02053de:	0be70713          	addi	a4,a4,190 # ffffffffc02ac498 <idleproc>
ffffffffc02053e2:	000a7917          	auipc	s2,0xa7
ffffffffc02053e6:	0ae90913          	addi	s2,s2,174 # ffffffffc02ac490 <current>
ffffffffc02053ea:	00093783          	ld	a5,0(s2)
ffffffffc02053ee:	6318                	ld	a4,0(a4)
do_exit(int error_code) {
ffffffffc02053f0:	f406                	sd	ra,40(sp)
ffffffffc02053f2:	f022                	sd	s0,32(sp)
ffffffffc02053f4:	ec26                	sd	s1,24(sp)
ffffffffc02053f6:	e44e                	sd	s3,8(sp)
ffffffffc02053f8:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc02053fa:	0ce78c63          	beq	a5,a4,ffffffffc02054d2 <do_exit+0xfc>
    if (current == initproc) {
ffffffffc02053fe:	000a7417          	auipc	s0,0xa7
ffffffffc0205402:	0a240413          	addi	s0,s0,162 # ffffffffc02ac4a0 <initproc>
ffffffffc0205406:	6018                	ld	a4,0(s0)
ffffffffc0205408:	0ee78b63          	beq	a5,a4,ffffffffc02054fe <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc020540c:	7784                	ld	s1,40(a5)
ffffffffc020540e:	89aa                	mv	s3,a0
    if (mm != NULL) {
ffffffffc0205410:	c48d                	beqz	s1,ffffffffc020543a <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc0205412:	000a7797          	auipc	a5,0xa7
ffffffffc0205416:	0ce78793          	addi	a5,a5,206 # ffffffffc02ac4e0 <boot_cr3>
ffffffffc020541a:	639c                	ld	a5,0(a5)
ffffffffc020541c:	577d                	li	a4,-1
ffffffffc020541e:	177e                	slli	a4,a4,0x3f
ffffffffc0205420:	83b1                	srli	a5,a5,0xc
ffffffffc0205422:	8fd9                	or	a5,a5,a4
ffffffffc0205424:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205428:	589c                	lw	a5,48(s1)
ffffffffc020542a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020542e:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205430:	cf4d                	beqz	a4,ffffffffc02054ea <do_exit+0x114>
        current->mm = NULL;
ffffffffc0205432:	00093783          	ld	a5,0(s2)
ffffffffc0205436:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020543a:	00093783          	ld	a5,0(s2)
ffffffffc020543e:	470d                	li	a4,3
ffffffffc0205440:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0205442:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205446:	100027f3          	csrr	a5,sstatus
ffffffffc020544a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020544c:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020544e:	e7e1                	bnez	a5,ffffffffc0205516 <do_exit+0x140>
        proc = current->parent;
ffffffffc0205450:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205454:	800007b7          	lui	a5,0x80000
ffffffffc0205458:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020545a:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc020545c:	0ec52703          	lw	a4,236(a0)
ffffffffc0205460:	0af70f63          	beq	a4,a5,ffffffffc020551e <do_exit+0x148>
ffffffffc0205464:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205468:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020546c:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc020546e:	0985                	addi	s3,s3,1
        while (current->cptr != NULL) {
ffffffffc0205470:	7afc                	ld	a5,240(a3)
ffffffffc0205472:	cb95                	beqz	a5,ffffffffc02054a6 <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc0205474:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5680>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205478:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc020547a:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc020547c:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020547e:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205482:	10e7b023          	sd	a4,256(a5)
ffffffffc0205486:	c311                	beqz	a4,ffffffffc020548a <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc0205488:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020548a:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020548c:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020548e:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205490:	fe9710e3          	bne	a4,s1,ffffffffc0205470 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205494:	0ec52783          	lw	a5,236(a0)
ffffffffc0205498:	fd379ce3          	bne	a5,s3,ffffffffc0205470 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020549c:	2c1000ef          	jal	ra,ffffffffc0205f5c <wakeup_proc>
ffffffffc02054a0:	00093683          	ld	a3,0(s2)
ffffffffc02054a4:	b7f1                	j	ffffffffc0205470 <do_exit+0x9a>
    if (flag) {
ffffffffc02054a6:	020a1363          	bnez	s4,ffffffffc02054cc <do_exit+0xf6>
    schedule();
ffffffffc02054aa:	32f000ef          	jal	ra,ffffffffc0205fd8 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02054ae:	00093783          	ld	a5,0(s2)
ffffffffc02054b2:	00003617          	auipc	a2,0x3
ffffffffc02054b6:	0f660613          	addi	a2,a2,246 # ffffffffc02085a8 <default_pmm_manager+0x1248>
ffffffffc02054ba:	20800593          	li	a1,520
ffffffffc02054be:	43d4                	lw	a3,4(a5)
ffffffffc02054c0:	00003517          	auipc	a0,0x3
ffffffffc02054c4:	39850513          	addi	a0,a0,920 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02054c8:	fbdfa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_enable();
ffffffffc02054cc:	988fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc02054d0:	bfe9                	j	ffffffffc02054aa <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc02054d2:	00003617          	auipc	a2,0x3
ffffffffc02054d6:	0b660613          	addi	a2,a2,182 # ffffffffc0208588 <default_pmm_manager+0x1228>
ffffffffc02054da:	1dc00593          	li	a1,476
ffffffffc02054de:	00003517          	auipc	a0,0x3
ffffffffc02054e2:	37a50513          	addi	a0,a0,890 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02054e6:	f9ffa0ef          	jal	ra,ffffffffc0200484 <__panic>
            exit_mmap(mm);
ffffffffc02054ea:	8526                	mv	a0,s1
ffffffffc02054ec:	f01fe0ef          	jal	ra,ffffffffc02043ec <exit_mmap>
            put_pgdir(mm);
ffffffffc02054f0:	8526                	mv	a0,s1
ffffffffc02054f2:	8bdff0ef          	jal	ra,ffffffffc0204dae <put_pgdir>
            mm_destroy(mm);
ffffffffc02054f6:	8526                	mv	a0,s1
ffffffffc02054f8:	d55fe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
ffffffffc02054fc:	bf1d                	j	ffffffffc0205432 <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc02054fe:	00003617          	auipc	a2,0x3
ffffffffc0205502:	09a60613          	addi	a2,a2,154 # ffffffffc0208598 <default_pmm_manager+0x1238>
ffffffffc0205506:	1df00593          	li	a1,479
ffffffffc020550a:	00003517          	auipc	a0,0x3
ffffffffc020550e:	34e50513          	addi	a0,a0,846 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205512:	f73fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_disable();
ffffffffc0205516:	944fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc020551a:	4a05                	li	s4,1
ffffffffc020551c:	bf15                	j	ffffffffc0205450 <do_exit+0x7a>
            wakeup_proc(proc);
ffffffffc020551e:	23f000ef          	jal	ra,ffffffffc0205f5c <wakeup_proc>
ffffffffc0205522:	b789                	j	ffffffffc0205464 <do_exit+0x8e>

ffffffffc0205524 <do_wait.part.1>:
do_wait(int pid, int *code_store) {
ffffffffc0205524:	7139                	addi	sp,sp,-64
ffffffffc0205526:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc0205528:	80000a37          	lui	s4,0x80000
do_wait(int pid, int *code_store) {
ffffffffc020552c:	f426                	sd	s1,40(sp)
ffffffffc020552e:	f04a                	sd	s2,32(sp)
ffffffffc0205530:	ec4e                	sd	s3,24(sp)
ffffffffc0205532:	e456                	sd	s5,8(sp)
ffffffffc0205534:	e05a                	sd	s6,0(sp)
ffffffffc0205536:	fc06                	sd	ra,56(sp)
ffffffffc0205538:	f822                	sd	s0,48(sp)
ffffffffc020553a:	89aa                	mv	s3,a0
ffffffffc020553c:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc020553e:	000a7917          	auipc	s2,0xa7
ffffffffc0205542:	f5290913          	addi	s2,s2,-174 # ffffffffc02ac490 <current>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205546:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc0205548:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc020554a:	2a05                	addiw	s4,s4,1
    if (pid != 0) {
ffffffffc020554c:	02098f63          	beqz	s3,ffffffffc020558a <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc0205550:	854e                	mv	a0,s3
ffffffffc0205552:	9fdff0ef          	jal	ra,ffffffffc0204f4e <find_proc>
ffffffffc0205556:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current) {
ffffffffc0205558:	12050063          	beqz	a0,ffffffffc0205678 <do_wait.part.1+0x154>
ffffffffc020555c:	00093703          	ld	a4,0(s2)
ffffffffc0205560:	711c                	ld	a5,32(a0)
ffffffffc0205562:	10e79b63          	bne	a5,a4,ffffffffc0205678 <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205566:	411c                	lw	a5,0(a0)
ffffffffc0205568:	02978c63          	beq	a5,s1,ffffffffc02055a0 <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc020556c:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc0205570:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc0205574:	265000ef          	jal	ra,ffffffffc0205fd8 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc0205578:	00093783          	ld	a5,0(s2)
ffffffffc020557c:	0b07a783          	lw	a5,176(a5)
ffffffffc0205580:	8b85                	andi	a5,a5,1
ffffffffc0205582:	d7e9                	beqz	a5,ffffffffc020554c <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc0205584:	555d                	li	a0,-9
ffffffffc0205586:	e51ff0ef          	jal	ra,ffffffffc02053d6 <do_exit>
        proc = current->cptr;
ffffffffc020558a:	00093703          	ld	a4,0(s2)
ffffffffc020558e:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc0205590:	e409                	bnez	s0,ffffffffc020559a <do_wait.part.1+0x76>
ffffffffc0205592:	a0dd                	j	ffffffffc0205678 <do_wait.part.1+0x154>
ffffffffc0205594:	10043403          	ld	s0,256(s0)
ffffffffc0205598:	d871                	beqz	s0,ffffffffc020556c <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020559a:	401c                	lw	a5,0(s0)
ffffffffc020559c:	fe979ce3          	bne	a5,s1,ffffffffc0205594 <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc) {
ffffffffc02055a0:	000a7797          	auipc	a5,0xa7
ffffffffc02055a4:	ef878793          	addi	a5,a5,-264 # ffffffffc02ac498 <idleproc>
ffffffffc02055a8:	639c                	ld	a5,0(a5)
ffffffffc02055aa:	0c878d63          	beq	a5,s0,ffffffffc0205684 <do_wait.part.1+0x160>
ffffffffc02055ae:	000a7797          	auipc	a5,0xa7
ffffffffc02055b2:	ef278793          	addi	a5,a5,-270 # ffffffffc02ac4a0 <initproc>
ffffffffc02055b6:	639c                	ld	a5,0(a5)
ffffffffc02055b8:	0cf40663          	beq	s0,a5,ffffffffc0205684 <do_wait.part.1+0x160>
    if (code_store != NULL) {
ffffffffc02055bc:	000b0663          	beqz	s6,ffffffffc02055c8 <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc02055c0:	0e842783          	lw	a5,232(s0)
ffffffffc02055c4:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055c8:	100027f3          	csrr	a5,sstatus
ffffffffc02055cc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02055ce:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055d0:	e7d5                	bnez	a5,ffffffffc020567c <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc02055d2:	6c70                	ld	a2,216(s0)
ffffffffc02055d4:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc02055d6:	10043703          	ld	a4,256(s0)
ffffffffc02055da:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02055dc:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055de:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02055e0:	6470                	ld	a2,200(s0)
ffffffffc02055e2:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02055e4:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055e6:	e290                	sd	a2,0(a3)
ffffffffc02055e8:	c319                	beqz	a4,ffffffffc02055ee <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc02055ea:	ff7c                	sd	a5,248(a4)
ffffffffc02055ec:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL) {
ffffffffc02055ee:	c3d1                	beqz	a5,ffffffffc0205672 <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc02055f0:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc02055f4:	000a7797          	auipc	a5,0xa7
ffffffffc02055f8:	eb478793          	addi	a5,a5,-332 # ffffffffc02ac4a8 <nr_process>
ffffffffc02055fc:	439c                	lw	a5,0(a5)
ffffffffc02055fe:	37fd                	addiw	a5,a5,-1
ffffffffc0205600:	000a7717          	auipc	a4,0xa7
ffffffffc0205604:	eaf72423          	sw	a5,-344(a4) # ffffffffc02ac4a8 <nr_process>
    if (flag) {
ffffffffc0205608:	e1b5                	bnez	a1,ffffffffc020566c <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020560a:	6814                	ld	a3,16(s0)
ffffffffc020560c:	c02007b7          	lui	a5,0xc0200
ffffffffc0205610:	0af6e263          	bltu	a3,a5,ffffffffc02056b4 <do_wait.part.1+0x190>
ffffffffc0205614:	000a7797          	auipc	a5,0xa7
ffffffffc0205618:	ec478793          	addi	a5,a5,-316 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc020561c:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc020561e:	000a7797          	auipc	a5,0xa7
ffffffffc0205622:	e5a78793          	addi	a5,a5,-422 # ffffffffc02ac478 <npage>
ffffffffc0205626:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0205628:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc020562a:	82b1                	srli	a3,a3,0xc
ffffffffc020562c:	06f6f863          	bleu	a5,a3,ffffffffc020569c <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc0205630:	00003797          	auipc	a5,0x3
ffffffffc0205634:	6f078793          	addi	a5,a5,1776 # ffffffffc0208d20 <nbase>
ffffffffc0205638:	639c                	ld	a5,0(a5)
ffffffffc020563a:	000a7717          	auipc	a4,0xa7
ffffffffc020563e:	eae70713          	addi	a4,a4,-338 # ffffffffc02ac4e8 <pages>
ffffffffc0205642:	6308                	ld	a0,0(a4)
ffffffffc0205644:	8e9d                	sub	a3,a3,a5
ffffffffc0205646:	069a                	slli	a3,a3,0x6
ffffffffc0205648:	9536                	add	a0,a0,a3
ffffffffc020564a:	4589                	li	a1,2
ffffffffc020564c:	88ffc0ef          	jal	ra,ffffffffc0201eda <free_pages>
    kfree(proc);
ffffffffc0205650:	8522                	mv	a0,s0
ffffffffc0205652:	ec0fc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return 0;
ffffffffc0205656:	4501                	li	a0,0
}
ffffffffc0205658:	70e2                	ld	ra,56(sp)
ffffffffc020565a:	7442                	ld	s0,48(sp)
ffffffffc020565c:	74a2                	ld	s1,40(sp)
ffffffffc020565e:	7902                	ld	s2,32(sp)
ffffffffc0205660:	69e2                	ld	s3,24(sp)
ffffffffc0205662:	6a42                	ld	s4,16(sp)
ffffffffc0205664:	6aa2                	ld	s5,8(sp)
ffffffffc0205666:	6b02                	ld	s6,0(sp)
ffffffffc0205668:	6121                	addi	sp,sp,64
ffffffffc020566a:	8082                	ret
        intr_enable();
ffffffffc020566c:	fe9fa0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0205670:	bf69                	j	ffffffffc020560a <do_wait.part.1+0xe6>
       proc->parent->cptr = proc->optr;
ffffffffc0205672:	701c                	ld	a5,32(s0)
ffffffffc0205674:	fbf8                	sd	a4,240(a5)
ffffffffc0205676:	bfbd                	j	ffffffffc02055f4 <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc0205678:	5579                	li	a0,-2
ffffffffc020567a:	bff9                	j	ffffffffc0205658 <do_wait.part.1+0x134>
        intr_disable();
ffffffffc020567c:	fdffa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205680:	4585                	li	a1,1
ffffffffc0205682:	bf81                	j	ffffffffc02055d2 <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc0205684:	00003617          	auipc	a2,0x3
ffffffffc0205688:	f8c60613          	addi	a2,a2,-116 # ffffffffc0208610 <default_pmm_manager+0x12b0>
ffffffffc020568c:	2ff00593          	li	a1,767
ffffffffc0205690:	00003517          	auipc	a0,0x3
ffffffffc0205694:	1c850513          	addi	a0,a0,456 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205698:	dedfa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020569c:	00002617          	auipc	a2,0x2
ffffffffc02056a0:	d7460613          	addi	a2,a2,-652 # ffffffffc0207410 <default_pmm_manager+0xb0>
ffffffffc02056a4:	06200593          	li	a1,98
ffffffffc02056a8:	00002517          	auipc	a0,0x2
ffffffffc02056ac:	d3050513          	addi	a0,a0,-720 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02056b0:	dd5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02056b4:	00002617          	auipc	a2,0x2
ffffffffc02056b8:	d3460613          	addi	a2,a2,-716 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc02056bc:	06e00593          	li	a1,110
ffffffffc02056c0:	00002517          	auipc	a0,0x2
ffffffffc02056c4:	d1850513          	addi	a0,a0,-744 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc02056c8:	dbdfa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02056cc <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc02056cc:	1141                	addi	sp,sp,-16
ffffffffc02056ce:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02056d0:	851fc0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02056d4:	d7efc0ef          	jal	ra,ffffffffc0201c52 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02056d8:	4601                	li	a2,0
ffffffffc02056da:	4581                	li	a1,0
ffffffffc02056dc:	fffff517          	auipc	a0,0xfffff
ffffffffc02056e0:	65050513          	addi	a0,a0,1616 # ffffffffc0204d2c <user_main>
ffffffffc02056e4:	ca3ff0ef          	jal	ra,ffffffffc0205386 <kernel_thread>
    if (pid <= 0) {
ffffffffc02056e8:	00a04563          	bgtz	a0,ffffffffc02056f2 <init_main+0x26>
ffffffffc02056ec:	a841                	j	ffffffffc020577c <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc02056ee:	0eb000ef          	jal	ra,ffffffffc0205fd8 <schedule>
    if (code_store != NULL) {
ffffffffc02056f2:	4581                	li	a1,0
ffffffffc02056f4:	4501                	li	a0,0
ffffffffc02056f6:	e2fff0ef          	jal	ra,ffffffffc0205524 <do_wait.part.1>
    while (do_wait(0, NULL) == 0) {
ffffffffc02056fa:	d975                	beqz	a0,ffffffffc02056ee <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02056fc:	00003517          	auipc	a0,0x3
ffffffffc0205700:	f5450513          	addi	a0,a0,-172 # ffffffffc0208650 <default_pmm_manager+0x12f0>
ffffffffc0205704:	a8bfa0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205708:	000a7797          	auipc	a5,0xa7
ffffffffc020570c:	d9878793          	addi	a5,a5,-616 # ffffffffc02ac4a0 <initproc>
ffffffffc0205710:	639c                	ld	a5,0(a5)
ffffffffc0205712:	7bf8                	ld	a4,240(a5)
ffffffffc0205714:	e721                	bnez	a4,ffffffffc020575c <init_main+0x90>
ffffffffc0205716:	7ff8                	ld	a4,248(a5)
ffffffffc0205718:	e331                	bnez	a4,ffffffffc020575c <init_main+0x90>
ffffffffc020571a:	1007b703          	ld	a4,256(a5)
ffffffffc020571e:	ef1d                	bnez	a4,ffffffffc020575c <init_main+0x90>
    assert(nr_process == 2);
ffffffffc0205720:	000a7717          	auipc	a4,0xa7
ffffffffc0205724:	d8870713          	addi	a4,a4,-632 # ffffffffc02ac4a8 <nr_process>
ffffffffc0205728:	4314                	lw	a3,0(a4)
ffffffffc020572a:	4709                	li	a4,2
ffffffffc020572c:	0ae69463          	bne	a3,a4,ffffffffc02057d4 <init_main+0x108>
    return listelm->next;
ffffffffc0205730:	000a7697          	auipc	a3,0xa7
ffffffffc0205734:	ea068693          	addi	a3,a3,-352 # ffffffffc02ac5d0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205738:	6698                	ld	a4,8(a3)
ffffffffc020573a:	0c878793          	addi	a5,a5,200
ffffffffc020573e:	06f71b63          	bne	a4,a5,ffffffffc02057b4 <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205742:	629c                	ld	a5,0(a3)
ffffffffc0205744:	04f71863          	bne	a4,a5,ffffffffc0205794 <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc0205748:	00003517          	auipc	a0,0x3
ffffffffc020574c:	ff050513          	addi	a0,a0,-16 # ffffffffc0208738 <default_pmm_manager+0x13d8>
ffffffffc0205750:	a3ffa0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
}
ffffffffc0205754:	60a2                	ld	ra,8(sp)
ffffffffc0205756:	4501                	li	a0,0
ffffffffc0205758:	0141                	addi	sp,sp,16
ffffffffc020575a:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020575c:	00003697          	auipc	a3,0x3
ffffffffc0205760:	f1c68693          	addi	a3,a3,-228 # ffffffffc0208678 <default_pmm_manager+0x1318>
ffffffffc0205764:	00001617          	auipc	a2,0x1
ffffffffc0205768:	4b460613          	addi	a2,a2,1204 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc020576c:	36400593          	li	a1,868
ffffffffc0205770:	00003517          	auipc	a0,0x3
ffffffffc0205774:	0e850513          	addi	a0,a0,232 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205778:	d0dfa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create user_main failed.\n");
ffffffffc020577c:	00003617          	auipc	a2,0x3
ffffffffc0205780:	eb460613          	addi	a2,a2,-332 # ffffffffc0208630 <default_pmm_manager+0x12d0>
ffffffffc0205784:	35c00593          	li	a1,860
ffffffffc0205788:	00003517          	auipc	a0,0x3
ffffffffc020578c:	0d050513          	addi	a0,a0,208 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205790:	cf5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205794:	00003697          	auipc	a3,0x3
ffffffffc0205798:	f7468693          	addi	a3,a3,-140 # ffffffffc0208708 <default_pmm_manager+0x13a8>
ffffffffc020579c:	00001617          	auipc	a2,0x1
ffffffffc02057a0:	47c60613          	addi	a2,a2,1148 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02057a4:	36700593          	li	a1,871
ffffffffc02057a8:	00003517          	auipc	a0,0x3
ffffffffc02057ac:	0b050513          	addi	a0,a0,176 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02057b0:	cd5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02057b4:	00003697          	auipc	a3,0x3
ffffffffc02057b8:	f2468693          	addi	a3,a3,-220 # ffffffffc02086d8 <default_pmm_manager+0x1378>
ffffffffc02057bc:	00001617          	auipc	a2,0x1
ffffffffc02057c0:	45c60613          	addi	a2,a2,1116 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02057c4:	36600593          	li	a1,870
ffffffffc02057c8:	00003517          	auipc	a0,0x3
ffffffffc02057cc:	09050513          	addi	a0,a0,144 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02057d0:	cb5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_process == 2);
ffffffffc02057d4:	00003697          	auipc	a3,0x3
ffffffffc02057d8:	ef468693          	addi	a3,a3,-268 # ffffffffc02086c8 <default_pmm_manager+0x1368>
ffffffffc02057dc:	00001617          	auipc	a2,0x1
ffffffffc02057e0:	43c60613          	addi	a2,a2,1084 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc02057e4:	36500593          	li	a1,869
ffffffffc02057e8:	00003517          	auipc	a0,0x3
ffffffffc02057ec:	07050513          	addi	a0,a0,112 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02057f0:	c95fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02057f4 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057f4:	7135                	addi	sp,sp,-160
ffffffffc02057f6:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057f8:	000a7a17          	auipc	s4,0xa7
ffffffffc02057fc:	c98a0a13          	addi	s4,s4,-872 # ffffffffc02ac490 <current>
ffffffffc0205800:	000a3783          	ld	a5,0(s4)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205804:	e14a                	sd	s2,128(sp)
ffffffffc0205806:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205808:	0287b903          	ld	s2,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020580c:	fcce                	sd	s3,120(sp)
ffffffffc020580e:	f0da                	sd	s6,96(sp)
ffffffffc0205810:	89aa                	mv	s3,a0
ffffffffc0205812:	842e                	mv	s0,a1
ffffffffc0205814:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205816:	4681                	li	a3,0
ffffffffc0205818:	862e                	mv	a2,a1
ffffffffc020581a:	85aa                	mv	a1,a0
ffffffffc020581c:	854a                	mv	a0,s2
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020581e:	ed06                	sd	ra,152(sp)
ffffffffc0205820:	e526                	sd	s1,136(sp)
ffffffffc0205822:	f4d6                	sd	s5,104(sp)
ffffffffc0205824:	ecde                	sd	s7,88(sp)
ffffffffc0205826:	e8e2                	sd	s8,80(sp)
ffffffffc0205828:	e4e6                	sd	s9,72(sp)
ffffffffc020582a:	e0ea                	sd	s10,64(sp)
ffffffffc020582c:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020582e:	a76ff0ef          	jal	ra,ffffffffc0204aa4 <user_mem_check>
ffffffffc0205832:	40050463          	beqz	a0,ffffffffc0205c3a <do_execve+0x446>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0205836:	4641                	li	a2,16
ffffffffc0205838:	4581                	li	a1,0
ffffffffc020583a:	1008                	addi	a0,sp,32
ffffffffc020583c:	5c1000ef          	jal	ra,ffffffffc02065fc <memset>
    memcpy(local_name, name, len);
ffffffffc0205840:	47bd                	li	a5,15
ffffffffc0205842:	8622                	mv	a2,s0
ffffffffc0205844:	0687ee63          	bltu	a5,s0,ffffffffc02058c0 <do_execve+0xcc>
ffffffffc0205848:	85ce                	mv	a1,s3
ffffffffc020584a:	1008                	addi	a0,sp,32
ffffffffc020584c:	5c3000ef          	jal	ra,ffffffffc020660e <memcpy>
    if (mm != NULL) {
ffffffffc0205850:	06090f63          	beqz	s2,ffffffffc02058ce <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc0205854:	00002517          	auipc	a0,0x2
ffffffffc0205858:	2fc50513          	addi	a0,a0,764 # ffffffffc0207b50 <default_pmm_manager+0x7f0>
ffffffffc020585c:	96bfa0ef          	jal	ra,ffffffffc02001c6 <cputs>
        lcr3(boot_cr3);
ffffffffc0205860:	000a7797          	auipc	a5,0xa7
ffffffffc0205864:	c8078793          	addi	a5,a5,-896 # ffffffffc02ac4e0 <boot_cr3>
ffffffffc0205868:	639c                	ld	a5,0(a5)
ffffffffc020586a:	577d                	li	a4,-1
ffffffffc020586c:	177e                	slli	a4,a4,0x3f
ffffffffc020586e:	83b1                	srli	a5,a5,0xc
ffffffffc0205870:	8fd9                	or	a5,a5,a4
ffffffffc0205872:	18079073          	csrw	satp,a5
ffffffffc0205876:	03092783          	lw	a5,48(s2)
ffffffffc020587a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020587e:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205882:	28070b63          	beqz	a4,ffffffffc0205b18 <do_execve+0x324>
        current->mm = NULL;
ffffffffc0205886:	000a3783          	ld	a5,0(s4)
ffffffffc020588a:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc020588e:	839fe0ef          	jal	ra,ffffffffc02040c6 <mm_create>
ffffffffc0205892:	892a                	mv	s2,a0
ffffffffc0205894:	c135                	beqz	a0,ffffffffc02058f8 <do_execve+0x104>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205896:	d96ff0ef          	jal	ra,ffffffffc0204e2c <setup_pgdir>
ffffffffc020589a:	e931                	bnez	a0,ffffffffc02058ee <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020589c:	000b2703          	lw	a4,0(s6)
ffffffffc02058a0:	464c47b7          	lui	a5,0x464c4
ffffffffc02058a4:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9aff>
ffffffffc02058a8:	04f70a63          	beq	a4,a5,ffffffffc02058fc <do_execve+0x108>
    put_pgdir(mm);
ffffffffc02058ac:	854a                	mv	a0,s2
ffffffffc02058ae:	d00ff0ef          	jal	ra,ffffffffc0204dae <put_pgdir>
    mm_destroy(mm);
ffffffffc02058b2:	854a                	mv	a0,s2
ffffffffc02058b4:	999fe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02058b8:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc02058ba:	854e                	mv	a0,s3
ffffffffc02058bc:	b1bff0ef          	jal	ra,ffffffffc02053d6 <do_exit>
    memcpy(local_name, name, len);
ffffffffc02058c0:	463d                	li	a2,15
ffffffffc02058c2:	85ce                	mv	a1,s3
ffffffffc02058c4:	1008                	addi	a0,sp,32
ffffffffc02058c6:	549000ef          	jal	ra,ffffffffc020660e <memcpy>
    if (mm != NULL) {
ffffffffc02058ca:	f80915e3          	bnez	s2,ffffffffc0205854 <do_execve+0x60>
    if (current->mm != NULL) {
ffffffffc02058ce:	000a3783          	ld	a5,0(s4)
ffffffffc02058d2:	779c                	ld	a5,40(a5)
ffffffffc02058d4:	dfcd                	beqz	a5,ffffffffc020588e <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02058d6:	00003617          	auipc	a2,0x3
ffffffffc02058da:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0208400 <default_pmm_manager+0x10a0>
ffffffffc02058de:	21200593          	li	a1,530
ffffffffc02058e2:	00003517          	auipc	a0,0x3
ffffffffc02058e6:	f7650513          	addi	a0,a0,-138 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc02058ea:	b9bfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    mm_destroy(mm);
ffffffffc02058ee:	854a                	mv	a0,s2
ffffffffc02058f0:	95dfe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc02058f4:	59f1                	li	s3,-4
ffffffffc02058f6:	b7d1                	j	ffffffffc02058ba <do_execve+0xc6>
ffffffffc02058f8:	59f1                	li	s3,-4
ffffffffc02058fa:	b7c1                	j	ffffffffc02058ba <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058fc:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205900:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205904:	00371793          	slli	a5,a4,0x3
ffffffffc0205908:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020590a:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020590c:	078e                	slli	a5,a5,0x3
ffffffffc020590e:	97a2                	add	a5,a5,s0
ffffffffc0205910:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205912:	02f47b63          	bleu	a5,s0,ffffffffc0205948 <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc0205916:	5bfd                	li	s7,-1
ffffffffc0205918:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc020591c:	000a7d97          	auipc	s11,0xa7
ffffffffc0205920:	bccd8d93          	addi	s11,s11,-1076 # ffffffffc02ac4e8 <pages>
ffffffffc0205924:	00003d17          	auipc	s10,0x3
ffffffffc0205928:	3fcd0d13          	addi	s10,s10,1020 # ffffffffc0208d20 <nbase>
    return KADDR(page2pa(page));
ffffffffc020592c:	e43e                	sd	a5,8(sp)
ffffffffc020592e:	000a7c97          	auipc	s9,0xa7
ffffffffc0205932:	b4ac8c93          	addi	s9,s9,-1206 # ffffffffc02ac478 <npage>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205936:	4018                	lw	a4,0(s0)
ffffffffc0205938:	4785                	li	a5,1
ffffffffc020593a:	0ef70d63          	beq	a4,a5,ffffffffc0205a34 <do_execve+0x240>
    for (; ph < ph_end; ph ++) {
ffffffffc020593e:	67e2                	ld	a5,24(sp)
ffffffffc0205940:	03840413          	addi	s0,s0,56
ffffffffc0205944:	fef469e3          	bltu	s0,a5,ffffffffc0205936 <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205948:	4701                	li	a4,0
ffffffffc020594a:	46ad                	li	a3,11
ffffffffc020594c:	00100637          	lui	a2,0x100
ffffffffc0205950:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205954:	854a                	mv	a0,s2
ffffffffc0205956:	949fe0ef          	jal	ra,ffffffffc020429e <mm_map>
ffffffffc020595a:	89aa                	mv	s3,a0
ffffffffc020595c:	1a051463          	bnez	a0,ffffffffc0205b04 <do_execve+0x310>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205960:	01893503          	ld	a0,24(s2)
ffffffffc0205964:	467d                	li	a2,31
ffffffffc0205966:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc020596a:	98ffd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc020596e:	36050263          	beqz	a0,ffffffffc0205cd2 <do_execve+0x4de>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205972:	01893503          	ld	a0,24(s2)
ffffffffc0205976:	467d                	li	a2,31
ffffffffc0205978:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020597c:	97dfd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc0205980:	32050963          	beqz	a0,ffffffffc0205cb2 <do_execve+0x4be>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205984:	01893503          	ld	a0,24(s2)
ffffffffc0205988:	467d                	li	a2,31
ffffffffc020598a:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc020598e:	96bfd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc0205992:	30050063          	beqz	a0,ffffffffc0205c92 <do_execve+0x49e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205996:	01893503          	ld	a0,24(s2)
ffffffffc020599a:	467d                	li	a2,31
ffffffffc020599c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02059a0:	959fd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc02059a4:	2c050763          	beqz	a0,ffffffffc0205c72 <do_execve+0x47e>
    mm->mm_count += 1;
ffffffffc02059a8:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc02059ac:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02059b0:	01893683          	ld	a3,24(s2)
ffffffffc02059b4:	2785                	addiw	a5,a5,1
ffffffffc02059b6:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc02059ba:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf55a8>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02059be:	c02007b7          	lui	a5,0xc0200
ffffffffc02059c2:	28f6ec63          	bltu	a3,a5,ffffffffc0205c5a <do_execve+0x466>
ffffffffc02059c6:	000a7797          	auipc	a5,0xa7
ffffffffc02059ca:	b1278793          	addi	a5,a5,-1262 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc02059ce:	639c                	ld	a5,0(a5)
ffffffffc02059d0:	577d                	li	a4,-1
ffffffffc02059d2:	177e                	slli	a4,a4,0x3f
ffffffffc02059d4:	8e9d                	sub	a3,a3,a5
ffffffffc02059d6:	00c6d793          	srli	a5,a3,0xc
ffffffffc02059da:	f654                	sd	a3,168(a2)
ffffffffc02059dc:	8fd9                	or	a5,a5,a4
ffffffffc02059de:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02059e2:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059e4:	4581                	li	a1,0
ffffffffc02059e6:	12000613          	li	a2,288
ffffffffc02059ea:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02059ec:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059f0:	40d000ef          	jal	ra,ffffffffc02065fc <memset>
    tf->epc = elf->e_entry; // 用户程序的入口地址
ffffffffc02059f4:	018b3703          	ld	a4,24(s6)
    tf->gpr.sp = USTACKTOP; // 用户栈的栈顶
ffffffffc02059f8:	4785                	li	a5,1
    set_proc_name(current, local_name);
ffffffffc02059fa:	000a3503          	ld	a0,0(s4)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); // 设置适用于用户程序的 SSTATUS
ffffffffc02059fe:	edf4f493          	andi	s1,s1,-289
    tf->gpr.sp = USTACKTOP; // 用户栈的栈顶
ffffffffc0205a02:	07fe                	slli	a5,a5,0x1f
ffffffffc0205a04:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry; // 用户程序的入口地址
ffffffffc0205a06:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE); // 设置适用于用户程序的 SSTATUS
ffffffffc0205a0a:	10943023          	sd	s1,256(s0)
    set_proc_name(current, local_name);
ffffffffc0205a0e:	100c                	addi	a1,sp,32
ffffffffc0205a10:	ca8ff0ef          	jal	ra,ffffffffc0204eb8 <set_proc_name>
}
ffffffffc0205a14:	60ea                	ld	ra,152(sp)
ffffffffc0205a16:	644a                	ld	s0,144(sp)
ffffffffc0205a18:	854e                	mv	a0,s3
ffffffffc0205a1a:	64aa                	ld	s1,136(sp)
ffffffffc0205a1c:	690a                	ld	s2,128(sp)
ffffffffc0205a1e:	79e6                	ld	s3,120(sp)
ffffffffc0205a20:	7a46                	ld	s4,112(sp)
ffffffffc0205a22:	7aa6                	ld	s5,104(sp)
ffffffffc0205a24:	7b06                	ld	s6,96(sp)
ffffffffc0205a26:	6be6                	ld	s7,88(sp)
ffffffffc0205a28:	6c46                	ld	s8,80(sp)
ffffffffc0205a2a:	6ca6                	ld	s9,72(sp)
ffffffffc0205a2c:	6d06                	ld	s10,64(sp)
ffffffffc0205a2e:	7de2                	ld	s11,56(sp)
ffffffffc0205a30:	610d                	addi	sp,sp,160
ffffffffc0205a32:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205a34:	7410                	ld	a2,40(s0)
ffffffffc0205a36:	701c                	ld	a5,32(s0)
ffffffffc0205a38:	20f66363          	bltu	a2,a5,ffffffffc0205c3e <do_execve+0x44a>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205a3c:	405c                	lw	a5,4(s0)
ffffffffc0205a3e:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a42:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205a46:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a48:	0e071263          	bnez	a4,ffffffffc0205b2c <do_execve+0x338>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a4c:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a4e:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a50:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a52:	c789                	beqz	a5,ffffffffc0205a5c <do_execve+0x268>
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a54:	47cd                	li	a5,19
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a56:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a5a:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205a5c:	0026f793          	andi	a5,a3,2
ffffffffc0205a60:	efe1                	bnez	a5,ffffffffc0205b38 <do_execve+0x344>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205a62:	0046f793          	andi	a5,a3,4
ffffffffc0205a66:	c789                	beqz	a5,ffffffffc0205a70 <do_execve+0x27c>
ffffffffc0205a68:	6782                	ld	a5,0(sp)
ffffffffc0205a6a:	0087e793          	ori	a5,a5,8
ffffffffc0205a6e:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205a70:	680c                	ld	a1,16(s0)
ffffffffc0205a72:	4701                	li	a4,0
ffffffffc0205a74:	854a                	mv	a0,s2
ffffffffc0205a76:	829fe0ef          	jal	ra,ffffffffc020429e <mm_map>
ffffffffc0205a7a:	89aa                	mv	s3,a0
ffffffffc0205a7c:	e541                	bnez	a0,ffffffffc0205b04 <do_execve+0x310>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a7e:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a82:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a86:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a8a:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a8c:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a8e:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a90:	00fbfc33          	and	s8,s7,a5
        while (start < end) {
ffffffffc0205a94:	053bef63          	bltu	s7,s3,ffffffffc0205af2 <do_execve+0x2fe>
ffffffffc0205a98:	aa79                	j	ffffffffc0205c36 <do_execve+0x442>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a9a:	6785                	lui	a5,0x1
ffffffffc0205a9c:	418b8533          	sub	a0,s7,s8
ffffffffc0205aa0:	9c3e                	add	s8,s8,a5
ffffffffc0205aa2:	417c0833          	sub	a6,s8,s7
            if (end < la) {
ffffffffc0205aa6:	0189f463          	bleu	s8,s3,ffffffffc0205aae <do_execve+0x2ba>
                size -= la - end;
ffffffffc0205aaa:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205aae:	000db683          	ld	a3,0(s11)
ffffffffc0205ab2:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205ab6:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205ab8:	40d486b3          	sub	a3,s1,a3
ffffffffc0205abc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205abe:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205ac2:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205ac4:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205ac8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205aca:	16c5fc63          	bleu	a2,a1,ffffffffc0205c42 <do_execve+0x44e>
ffffffffc0205ace:	000a7797          	auipc	a5,0xa7
ffffffffc0205ad2:	a0a78793          	addi	a5,a5,-1526 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0205ad6:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ada:	85d6                	mv	a1,s5
ffffffffc0205adc:	8642                	mv	a2,a6
ffffffffc0205ade:	96c6                	add	a3,a3,a7
ffffffffc0205ae0:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205ae2:	9bc2                	add	s7,s7,a6
ffffffffc0205ae4:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ae6:	329000ef          	jal	ra,ffffffffc020660e <memcpy>
            start += size, from += size;
ffffffffc0205aea:	6842                	ld	a6,16(sp)
ffffffffc0205aec:	9ac2                	add	s5,s5,a6
        while (start < end) {
ffffffffc0205aee:	053bf863          	bleu	s3,s7,ffffffffc0205b3e <do_execve+0x34a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205af2:	01893503          	ld	a0,24(s2)
ffffffffc0205af6:	6602                	ld	a2,0(sp)
ffffffffc0205af8:	85e2                	mv	a1,s8
ffffffffc0205afa:	ffefd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc0205afe:	84aa                	mv	s1,a0
ffffffffc0205b00:	fd49                	bnez	a0,ffffffffc0205a9a <do_execve+0x2a6>
        ret = -E_NO_MEM;
ffffffffc0205b02:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205b04:	854a                	mv	a0,s2
ffffffffc0205b06:	8e7fe0ef          	jal	ra,ffffffffc02043ec <exit_mmap>
    put_pgdir(mm);
ffffffffc0205b0a:	854a                	mv	a0,s2
ffffffffc0205b0c:	aa2ff0ef          	jal	ra,ffffffffc0204dae <put_pgdir>
    mm_destroy(mm);
ffffffffc0205b10:	854a                	mv	a0,s2
ffffffffc0205b12:	f3afe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
    return ret;
ffffffffc0205b16:	b355                	j	ffffffffc02058ba <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc0205b18:	854a                	mv	a0,s2
ffffffffc0205b1a:	8d3fe0ef          	jal	ra,ffffffffc02043ec <exit_mmap>
            put_pgdir(mm);
ffffffffc0205b1e:	854a                	mv	a0,s2
ffffffffc0205b20:	a8eff0ef          	jal	ra,ffffffffc0204dae <put_pgdir>
            mm_destroy(mm);
ffffffffc0205b24:	854a                	mv	a0,s2
ffffffffc0205b26:	f26fe0ef          	jal	ra,ffffffffc020424c <mm_destroy>
ffffffffc0205b2a:	bbb1                	j	ffffffffc0205886 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b2c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b30:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b32:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b34:	f20790e3          	bnez	a5,ffffffffc0205a54 <do_execve+0x260>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205b38:	47dd                	li	a5,23
ffffffffc0205b3a:	e03e                	sd	a5,0(sp)
ffffffffc0205b3c:	b71d                	j	ffffffffc0205a62 <do_execve+0x26e>
ffffffffc0205b3e:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205b42:	7414                	ld	a3,40(s0)
ffffffffc0205b44:	99b6                	add	s3,s3,a3
        if (start < la) {
ffffffffc0205b46:	098bf163          	bleu	s8,s7,ffffffffc0205bc8 <do_execve+0x3d4>
            if (start == end) {
ffffffffc0205b4a:	df798ae3          	beq	s3,s7,ffffffffc020593e <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205b4e:	6505                	lui	a0,0x1
ffffffffc0205b50:	955e                	add	a0,a0,s7
ffffffffc0205b52:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205b56:	41798ab3          	sub	s5,s3,s7
            if (end < la) {
ffffffffc0205b5a:	0d89fb63          	bleu	s8,s3,ffffffffc0205c30 <do_execve+0x43c>
    return page - pages + nbase;
ffffffffc0205b5e:	000db683          	ld	a3,0(s11)
ffffffffc0205b62:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205b66:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205b68:	40d486b3          	sub	a3,s1,a3
ffffffffc0205b6c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205b6e:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205b72:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205b74:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b78:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b7a:	0cc5f463          	bleu	a2,a1,ffffffffc0205c42 <do_execve+0x44e>
ffffffffc0205b7e:	000a7617          	auipc	a2,0xa7
ffffffffc0205b82:	95a60613          	addi	a2,a2,-1702 # ffffffffc02ac4d8 <va_pa_offset>
ffffffffc0205b86:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b8a:	4581                	li	a1,0
ffffffffc0205b8c:	8656                	mv	a2,s5
ffffffffc0205b8e:	96c2                	add	a3,a3,a6
ffffffffc0205b90:	9536                	add	a0,a0,a3
ffffffffc0205b92:	26b000ef          	jal	ra,ffffffffc02065fc <memset>
            start += size;
ffffffffc0205b96:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b9a:	0389f463          	bleu	s8,s3,ffffffffc0205bc2 <do_execve+0x3ce>
ffffffffc0205b9e:	dae980e3          	beq	s3,a4,ffffffffc020593e <do_execve+0x14a>
ffffffffc0205ba2:	00003697          	auipc	a3,0x3
ffffffffc0205ba6:	88668693          	addi	a3,a3,-1914 # ffffffffc0208428 <default_pmm_manager+0x10c8>
ffffffffc0205baa:	00001617          	auipc	a2,0x1
ffffffffc0205bae:	06e60613          	addi	a2,a2,110 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205bb2:	26700593          	li	a1,615
ffffffffc0205bb6:	00003517          	auipc	a0,0x3
ffffffffc0205bba:	ca250513          	addi	a0,a0,-862 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205bbe:	8c7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0205bc2:	ff8710e3          	bne	a4,s8,ffffffffc0205ba2 <do_execve+0x3ae>
ffffffffc0205bc6:	8be2                	mv	s7,s8
ffffffffc0205bc8:	000a7a97          	auipc	s5,0xa7
ffffffffc0205bcc:	910a8a93          	addi	s5,s5,-1776 # ffffffffc02ac4d8 <va_pa_offset>
        while (start < end) {
ffffffffc0205bd0:	053be763          	bltu	s7,s3,ffffffffc0205c1e <do_execve+0x42a>
ffffffffc0205bd4:	b3ad                	j	ffffffffc020593e <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205bd6:	6785                	lui	a5,0x1
ffffffffc0205bd8:	418b8533          	sub	a0,s7,s8
ffffffffc0205bdc:	9c3e                	add	s8,s8,a5
ffffffffc0205bde:	417c0633          	sub	a2,s8,s7
            if (end < la) {
ffffffffc0205be2:	0189f463          	bleu	s8,s3,ffffffffc0205bea <do_execve+0x3f6>
                size -= la - end;
ffffffffc0205be6:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205bea:	000db683          	ld	a3,0(s11)
ffffffffc0205bee:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205bf2:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205bf4:	40d486b3          	sub	a3,s1,a3
ffffffffc0205bf8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205bfa:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205bfe:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205c00:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205c04:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205c06:	02b87e63          	bleu	a1,a6,ffffffffc0205c42 <do_execve+0x44e>
ffffffffc0205c0a:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205c0e:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c10:	4581                	li	a1,0
ffffffffc0205c12:	96c2                	add	a3,a3,a6
ffffffffc0205c14:	9536                	add	a0,a0,a3
ffffffffc0205c16:	1e7000ef          	jal	ra,ffffffffc02065fc <memset>
        while (start < end) {
ffffffffc0205c1a:	d33bf2e3          	bleu	s3,s7,ffffffffc020593e <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205c1e:	01893503          	ld	a0,24(s2)
ffffffffc0205c22:	6602                	ld	a2,0(sp)
ffffffffc0205c24:	85e2                	mv	a1,s8
ffffffffc0205c26:	ed2fd0ef          	jal	ra,ffffffffc02032f8 <pgdir_alloc_page>
ffffffffc0205c2a:	84aa                	mv	s1,a0
ffffffffc0205c2c:	f54d                	bnez	a0,ffffffffc0205bd6 <do_execve+0x3e2>
ffffffffc0205c2e:	bdd1                	j	ffffffffc0205b02 <do_execve+0x30e>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c30:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205c34:	b72d                	j	ffffffffc0205b5e <do_execve+0x36a>
        while (start < end) {
ffffffffc0205c36:	89de                	mv	s3,s7
ffffffffc0205c38:	b729                	j	ffffffffc0205b42 <do_execve+0x34e>
        return -E_INVAL;
ffffffffc0205c3a:	59f5                	li	s3,-3
ffffffffc0205c3c:	bbe1                	j	ffffffffc0205a14 <do_execve+0x220>
            ret = -E_INVAL_ELF;
ffffffffc0205c3e:	59e1                	li	s3,-8
ffffffffc0205c40:	b5d1                	j	ffffffffc0205b04 <do_execve+0x310>
ffffffffc0205c42:	00001617          	auipc	a2,0x1
ffffffffc0205c46:	76e60613          	addi	a2,a2,1902 # ffffffffc02073b0 <default_pmm_manager+0x50>
ffffffffc0205c4a:	06900593          	li	a1,105
ffffffffc0205c4e:	00001517          	auipc	a0,0x1
ffffffffc0205c52:	78a50513          	addi	a0,a0,1930 # ffffffffc02073d8 <default_pmm_manager+0x78>
ffffffffc0205c56:	82ffa0ef          	jal	ra,ffffffffc0200484 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205c5a:	00001617          	auipc	a2,0x1
ffffffffc0205c5e:	78e60613          	addi	a2,a2,1934 # ffffffffc02073e8 <default_pmm_manager+0x88>
ffffffffc0205c62:	28200593          	li	a1,642
ffffffffc0205c66:	00003517          	auipc	a0,0x3
ffffffffc0205c6a:	bf250513          	addi	a0,a0,-1038 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205c6e:	817fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c72:	00003697          	auipc	a3,0x3
ffffffffc0205c76:	8ce68693          	addi	a3,a3,-1842 # ffffffffc0208540 <default_pmm_manager+0x11e0>
ffffffffc0205c7a:	00001617          	auipc	a2,0x1
ffffffffc0205c7e:	f9e60613          	addi	a2,a2,-98 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205c82:	27d00593          	li	a1,637
ffffffffc0205c86:	00003517          	auipc	a0,0x3
ffffffffc0205c8a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205c8e:	ff6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c92:	00003697          	auipc	a3,0x3
ffffffffc0205c96:	86668693          	addi	a3,a3,-1946 # ffffffffc02084f8 <default_pmm_manager+0x1198>
ffffffffc0205c9a:	00001617          	auipc	a2,0x1
ffffffffc0205c9e:	f7e60613          	addi	a2,a2,-130 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205ca2:	27c00593          	li	a1,636
ffffffffc0205ca6:	00003517          	auipc	a0,0x3
ffffffffc0205caa:	bb250513          	addi	a0,a0,-1102 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205cae:	fd6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205cb2:	00002697          	auipc	a3,0x2
ffffffffc0205cb6:	7fe68693          	addi	a3,a3,2046 # ffffffffc02084b0 <default_pmm_manager+0x1150>
ffffffffc0205cba:	00001617          	auipc	a2,0x1
ffffffffc0205cbe:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205cc2:	27b00593          	li	a1,635
ffffffffc0205cc6:	00003517          	auipc	a0,0x3
ffffffffc0205cca:	b9250513          	addi	a0,a0,-1134 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205cce:	fb6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205cd2:	00002697          	auipc	a3,0x2
ffffffffc0205cd6:	79668693          	addi	a3,a3,1942 # ffffffffc0208468 <default_pmm_manager+0x1108>
ffffffffc0205cda:	00001617          	auipc	a2,0x1
ffffffffc0205cde:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205ce2:	27a00593          	li	a1,634
ffffffffc0205ce6:	00003517          	auipc	a0,0x3
ffffffffc0205cea:	b7250513          	addi	a0,a0,-1166 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205cee:	f96fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205cf2 <do_yield>:
    current->need_resched = 1;
ffffffffc0205cf2:	000a6797          	auipc	a5,0xa6
ffffffffc0205cf6:	79e78793          	addi	a5,a5,1950 # ffffffffc02ac490 <current>
ffffffffc0205cfa:	639c                	ld	a5,0(a5)
ffffffffc0205cfc:	4705                	li	a4,1
}
ffffffffc0205cfe:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205d00:	ef98                	sd	a4,24(a5)
}
ffffffffc0205d02:	8082                	ret

ffffffffc0205d04 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205d04:	1101                	addi	sp,sp,-32
ffffffffc0205d06:	e822                	sd	s0,16(sp)
ffffffffc0205d08:	e426                	sd	s1,8(sp)
ffffffffc0205d0a:	ec06                	sd	ra,24(sp)
ffffffffc0205d0c:	842e                	mv	s0,a1
ffffffffc0205d0e:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205d10:	cd81                	beqz	a1,ffffffffc0205d28 <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205d12:	000a6797          	auipc	a5,0xa6
ffffffffc0205d16:	77e78793          	addi	a5,a5,1918 # ffffffffc02ac490 <current>
ffffffffc0205d1a:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205d1c:	4685                	li	a3,1
ffffffffc0205d1e:	4611                	li	a2,4
ffffffffc0205d20:	7788                	ld	a0,40(a5)
ffffffffc0205d22:	d83fe0ef          	jal	ra,ffffffffc0204aa4 <user_mem_check>
ffffffffc0205d26:	c909                	beqz	a0,ffffffffc0205d38 <do_wait+0x34>
ffffffffc0205d28:	85a2                	mv	a1,s0
}
ffffffffc0205d2a:	6442                	ld	s0,16(sp)
ffffffffc0205d2c:	60e2                	ld	ra,24(sp)
ffffffffc0205d2e:	8526                	mv	a0,s1
ffffffffc0205d30:	64a2                	ld	s1,8(sp)
ffffffffc0205d32:	6105                	addi	sp,sp,32
ffffffffc0205d34:	ff0ff06f          	j	ffffffffc0205524 <do_wait.part.1>
ffffffffc0205d38:	60e2                	ld	ra,24(sp)
ffffffffc0205d3a:	6442                	ld	s0,16(sp)
ffffffffc0205d3c:	64a2                	ld	s1,8(sp)
ffffffffc0205d3e:	5575                	li	a0,-3
ffffffffc0205d40:	6105                	addi	sp,sp,32
ffffffffc0205d42:	8082                	ret

ffffffffc0205d44 <do_kill>:
do_kill(int pid) {
ffffffffc0205d44:	1141                	addi	sp,sp,-16
ffffffffc0205d46:	e406                	sd	ra,8(sp)
ffffffffc0205d48:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL) {
ffffffffc0205d4a:	a04ff0ef          	jal	ra,ffffffffc0204f4e <find_proc>
ffffffffc0205d4e:	cd0d                	beqz	a0,ffffffffc0205d88 <do_kill+0x44>
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205d50:	0b052703          	lw	a4,176(a0)
ffffffffc0205d54:	00177693          	andi	a3,a4,1
ffffffffc0205d58:	e695                	bnez	a3,ffffffffc0205d84 <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d5a:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205d5e:	00176713          	ori	a4,a4,1
ffffffffc0205d62:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205d66:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d68:	0006c763          	bltz	a3,ffffffffc0205d76 <do_kill+0x32>
}
ffffffffc0205d6c:	8522                	mv	a0,s0
ffffffffc0205d6e:	60a2                	ld	ra,8(sp)
ffffffffc0205d70:	6402                	ld	s0,0(sp)
ffffffffc0205d72:	0141                	addi	sp,sp,16
ffffffffc0205d74:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205d76:	1e6000ef          	jal	ra,ffffffffc0205f5c <wakeup_proc>
}
ffffffffc0205d7a:	8522                	mv	a0,s0
ffffffffc0205d7c:	60a2                	ld	ra,8(sp)
ffffffffc0205d7e:	6402                	ld	s0,0(sp)
ffffffffc0205d80:	0141                	addi	sp,sp,16
ffffffffc0205d82:	8082                	ret
        return -E_KILLED;
ffffffffc0205d84:	545d                	li	s0,-9
ffffffffc0205d86:	b7dd                	j	ffffffffc0205d6c <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205d88:	5475                	li	s0,-3
ffffffffc0205d8a:	b7cd                	j	ffffffffc0205d6c <do_kill+0x28>

ffffffffc0205d8c <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205d8c:	000a7797          	auipc	a5,0xa7
ffffffffc0205d90:	84478793          	addi	a5,a5,-1980 # ffffffffc02ac5d0 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205d94:	1101                	addi	sp,sp,-32
ffffffffc0205d96:	000a7717          	auipc	a4,0xa7
ffffffffc0205d9a:	84f73123          	sd	a5,-1982(a4) # ffffffffc02ac5d8 <proc_list+0x8>
ffffffffc0205d9e:	000a7717          	auipc	a4,0xa7
ffffffffc0205da2:	82f73923          	sd	a5,-1998(a4) # ffffffffc02ac5d0 <proc_list>
ffffffffc0205da6:	ec06                	sd	ra,24(sp)
ffffffffc0205da8:	e822                	sd	s0,16(sp)
ffffffffc0205daa:	e426                	sd	s1,8(sp)
ffffffffc0205dac:	000a2797          	auipc	a5,0xa2
ffffffffc0205db0:	6ac78793          	addi	a5,a5,1708 # ffffffffc02a8458 <hash_list>
ffffffffc0205db4:	000a6717          	auipc	a4,0xa6
ffffffffc0205db8:	6a470713          	addi	a4,a4,1700 # ffffffffc02ac458 <is_panic>
ffffffffc0205dbc:	e79c                	sd	a5,8(a5)
ffffffffc0205dbe:	e39c                	sd	a5,0(a5)
ffffffffc0205dc0:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205dc2:	fee79de3          	bne	a5,a4,ffffffffc0205dbc <proc_init+0x30>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205dc6:	ee3fe0ef          	jal	ra,ffffffffc0204ca8 <alloc_proc>
ffffffffc0205dca:	000a6717          	auipc	a4,0xa6
ffffffffc0205dce:	6ca73723          	sd	a0,1742(a4) # ffffffffc02ac498 <idleproc>
ffffffffc0205dd2:	000a6497          	auipc	s1,0xa6
ffffffffc0205dd6:	6c648493          	addi	s1,s1,1734 # ffffffffc02ac498 <idleproc>
ffffffffc0205dda:	c559                	beqz	a0,ffffffffc0205e68 <proc_init+0xdc>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205ddc:	4709                	li	a4,2
ffffffffc0205dde:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0205de0:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205de2:	00003717          	auipc	a4,0x3
ffffffffc0205de6:	21e70713          	addi	a4,a4,542 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0205dea:	00003597          	auipc	a1,0x3
ffffffffc0205dee:	98658593          	addi	a1,a1,-1658 # ffffffffc0208770 <default_pmm_manager+0x1410>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205df2:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205df4:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0205df6:	8c2ff0ef          	jal	ra,ffffffffc0204eb8 <set_proc_name>
    nr_process ++;
ffffffffc0205dfa:	000a6797          	auipc	a5,0xa6
ffffffffc0205dfe:	6ae78793          	addi	a5,a5,1710 # ffffffffc02ac4a8 <nr_process>
ffffffffc0205e02:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc0205e04:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e06:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205e08:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e0a:	4581                	li	a1,0
ffffffffc0205e0c:	00000517          	auipc	a0,0x0
ffffffffc0205e10:	8c050513          	addi	a0,a0,-1856 # ffffffffc02056cc <init_main>
    nr_process ++;
ffffffffc0205e14:	000a6697          	auipc	a3,0xa6
ffffffffc0205e18:	68f6aa23          	sw	a5,1684(a3) # ffffffffc02ac4a8 <nr_process>
    current = idleproc;
ffffffffc0205e1c:	000a6797          	auipc	a5,0xa6
ffffffffc0205e20:	66e7ba23          	sd	a4,1652(a5) # ffffffffc02ac490 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e24:	d62ff0ef          	jal	ra,ffffffffc0205386 <kernel_thread>
    if (pid <= 0) {
ffffffffc0205e28:	08a05c63          	blez	a0,ffffffffc0205ec0 <proc_init+0x134>
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205e2c:	922ff0ef          	jal	ra,ffffffffc0204f4e <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0205e30:	00003597          	auipc	a1,0x3
ffffffffc0205e34:	96858593          	addi	a1,a1,-1688 # ffffffffc0208798 <default_pmm_manager+0x1438>
    initproc = find_proc(pid);
ffffffffc0205e38:	000a6797          	auipc	a5,0xa6
ffffffffc0205e3c:	66a7b423          	sd	a0,1640(a5) # ffffffffc02ac4a0 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0205e40:	878ff0ef          	jal	ra,ffffffffc0204eb8 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e44:	609c                	ld	a5,0(s1)
ffffffffc0205e46:	cfa9                	beqz	a5,ffffffffc0205ea0 <proc_init+0x114>
ffffffffc0205e48:	43dc                	lw	a5,4(a5)
ffffffffc0205e4a:	ebb9                	bnez	a5,ffffffffc0205ea0 <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e4c:	000a6797          	auipc	a5,0xa6
ffffffffc0205e50:	65478793          	addi	a5,a5,1620 # ffffffffc02ac4a0 <initproc>
ffffffffc0205e54:	639c                	ld	a5,0(a5)
ffffffffc0205e56:	c78d                	beqz	a5,ffffffffc0205e80 <proc_init+0xf4>
ffffffffc0205e58:	43dc                	lw	a5,4(a5)
ffffffffc0205e5a:	02879363          	bne	a5,s0,ffffffffc0205e80 <proc_init+0xf4>
}
ffffffffc0205e5e:	60e2                	ld	ra,24(sp)
ffffffffc0205e60:	6442                	ld	s0,16(sp)
ffffffffc0205e62:	64a2                	ld	s1,8(sp)
ffffffffc0205e64:	6105                	addi	sp,sp,32
ffffffffc0205e66:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc0205e68:	00003617          	auipc	a2,0x3
ffffffffc0205e6c:	8f060613          	addi	a2,a2,-1808 # ffffffffc0208758 <default_pmm_manager+0x13f8>
ffffffffc0205e70:	37900593          	li	a1,889
ffffffffc0205e74:	00003517          	auipc	a0,0x3
ffffffffc0205e78:	9e450513          	addi	a0,a0,-1564 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205e7c:	e08fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e80:	00003697          	auipc	a3,0x3
ffffffffc0205e84:	94868693          	addi	a3,a3,-1720 # ffffffffc02087c8 <default_pmm_manager+0x1468>
ffffffffc0205e88:	00001617          	auipc	a2,0x1
ffffffffc0205e8c:	d9060613          	addi	a2,a2,-624 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205e90:	38e00593          	li	a1,910
ffffffffc0205e94:	00003517          	auipc	a0,0x3
ffffffffc0205e98:	9c450513          	addi	a0,a0,-1596 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205e9c:	de8fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205ea0:	00003697          	auipc	a3,0x3
ffffffffc0205ea4:	90068693          	addi	a3,a3,-1792 # ffffffffc02087a0 <default_pmm_manager+0x1440>
ffffffffc0205ea8:	00001617          	auipc	a2,0x1
ffffffffc0205eac:	d7060613          	addi	a2,a2,-656 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205eb0:	38d00593          	li	a1,909
ffffffffc0205eb4:	00003517          	auipc	a0,0x3
ffffffffc0205eb8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205ebc:	dc8fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create init_main failed.\n");
ffffffffc0205ec0:	00003617          	auipc	a2,0x3
ffffffffc0205ec4:	8b860613          	addi	a2,a2,-1864 # ffffffffc0208778 <default_pmm_manager+0x1418>
ffffffffc0205ec8:	38700593          	li	a1,903
ffffffffc0205ecc:	00003517          	auipc	a0,0x3
ffffffffc0205ed0:	98c50513          	addi	a0,a0,-1652 # ffffffffc0208858 <default_pmm_manager+0x14f8>
ffffffffc0205ed4:	db0fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205ed8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205ed8:	1141                	addi	sp,sp,-16
ffffffffc0205eda:	e022                	sd	s0,0(sp)
ffffffffc0205edc:	e406                	sd	ra,8(sp)
ffffffffc0205ede:	000a6417          	auipc	s0,0xa6
ffffffffc0205ee2:	5b240413          	addi	s0,s0,1458 # ffffffffc02ac490 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205ee6:	6018                	ld	a4,0(s0)
ffffffffc0205ee8:	6f1c                	ld	a5,24(a4)
ffffffffc0205eea:	dffd                	beqz	a5,ffffffffc0205ee8 <cpu_idle+0x10>
            schedule();
ffffffffc0205eec:	0ec000ef          	jal	ra,ffffffffc0205fd8 <schedule>
ffffffffc0205ef0:	bfdd                	j	ffffffffc0205ee6 <cpu_idle+0xe>

ffffffffc0205ef2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205ef2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205ef6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205efa:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205efc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205efe:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205f02:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205f06:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205f0a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205f0e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205f12:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205f16:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205f1a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205f1e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205f22:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205f26:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205f2a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205f2e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205f30:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205f32:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205f36:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205f3a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205f3e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205f42:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205f46:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205f4a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205f4e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205f52:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205f56:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205f5a:	8082                	ret

ffffffffc0205f5c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f5c:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f5e:	1101                	addi	sp,sp,-32
ffffffffc0205f60:	ec06                	sd	ra,24(sp)
ffffffffc0205f62:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f64:	478d                	li	a5,3
ffffffffc0205f66:	04f70a63          	beq	a4,a5,ffffffffc0205fba <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0205f6e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f70:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f72:	ef8d                	bnez	a5,ffffffffc0205fac <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f74:	4789                	li	a5,2
ffffffffc0205f76:	00f70f63          	beq	a4,a5,ffffffffc0205f94 <wakeup_proc+0x38>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f7a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205f7c:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc0205f80:	e409                	bnez	s0,ffffffffc0205f8a <wakeup_proc+0x2e>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f82:	60e2                	ld	ra,24(sp)
ffffffffc0205f84:	6442                	ld	s0,16(sp)
ffffffffc0205f86:	6105                	addi	sp,sp,32
ffffffffc0205f88:	8082                	ret
ffffffffc0205f8a:	6442                	ld	s0,16(sp)
ffffffffc0205f8c:	60e2                	ld	ra,24(sp)
ffffffffc0205f8e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205f90:	ec4fa06f          	j	ffffffffc0200654 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205f94:	00003617          	auipc	a2,0x3
ffffffffc0205f98:	91460613          	addi	a2,a2,-1772 # ffffffffc02088a8 <default_pmm_manager+0x1548>
ffffffffc0205f9c:	45c9                	li	a1,18
ffffffffc0205f9e:	00003517          	auipc	a0,0x3
ffffffffc0205fa2:	8f250513          	addi	a0,a0,-1806 # ffffffffc0208890 <default_pmm_manager+0x1530>
ffffffffc0205fa6:	d4afa0ef          	jal	ra,ffffffffc02004f0 <__warn>
ffffffffc0205faa:	bfd9                	j	ffffffffc0205f80 <wakeup_proc+0x24>
ffffffffc0205fac:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0205fae:	eacfa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205fb2:	6522                	ld	a0,8(sp)
ffffffffc0205fb4:	4405                	li	s0,1
ffffffffc0205fb6:	4118                	lw	a4,0(a0)
ffffffffc0205fb8:	bf75                	j	ffffffffc0205f74 <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fba:	00003697          	auipc	a3,0x3
ffffffffc0205fbe:	8b668693          	addi	a3,a3,-1866 # ffffffffc0208870 <default_pmm_manager+0x1510>
ffffffffc0205fc2:	00001617          	auipc	a2,0x1
ffffffffc0205fc6:	c5660613          	addi	a2,a2,-938 # ffffffffc0206c18 <commands+0x4c0>
ffffffffc0205fca:	45a5                	li	a1,9
ffffffffc0205fcc:	00003517          	auipc	a0,0x3
ffffffffc0205fd0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0208890 <default_pmm_manager+0x1530>
ffffffffc0205fd4:	cb0fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205fd8 <schedule>:

void
schedule(void) {
ffffffffc0205fd8:	1141                	addi	sp,sp,-16
ffffffffc0205fda:	e406                	sd	ra,8(sp)
ffffffffc0205fdc:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205fde:	100027f3          	csrr	a5,sstatus
ffffffffc0205fe2:	8b89                	andi	a5,a5,2
ffffffffc0205fe4:	4401                	li	s0,0
ffffffffc0205fe6:	e3d1                	bnez	a5,ffffffffc020606a <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205fe8:	000a6797          	auipc	a5,0xa6
ffffffffc0205fec:	4a878793          	addi	a5,a5,1192 # ffffffffc02ac490 <current>
ffffffffc0205ff0:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205ff4:	000a6797          	auipc	a5,0xa6
ffffffffc0205ff8:	4a478793          	addi	a5,a5,1188 # ffffffffc02ac498 <idleproc>
ffffffffc0205ffc:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0205ffe:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7558>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206002:	04a88e63          	beq	a7,a0,ffffffffc020605e <schedule+0x86>
ffffffffc0206006:	0c888693          	addi	a3,a7,200
ffffffffc020600a:	000a6617          	auipc	a2,0xa6
ffffffffc020600e:	5c660613          	addi	a2,a2,1478 # ffffffffc02ac5d0 <proc_list>
        le = last;
ffffffffc0206012:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0206014:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206016:	4809                	li	a6,2
    return listelm->next;
ffffffffc0206018:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc020601a:	00c78863          	beq	a5,a2,ffffffffc020602a <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020601e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0206022:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206026:	01070463          	beq	a4,a6,ffffffffc020602e <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc020602a:	fef697e3          	bne	a3,a5,ffffffffc0206018 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020602e:	c589                	beqz	a1,ffffffffc0206038 <schedule+0x60>
ffffffffc0206030:	4198                	lw	a4,0(a1)
ffffffffc0206032:	4789                	li	a5,2
ffffffffc0206034:	00f70e63          	beq	a4,a5,ffffffffc0206050 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206038:	451c                	lw	a5,8(a0)
ffffffffc020603a:	2785                	addiw	a5,a5,1
ffffffffc020603c:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020603e:	00a88463          	beq	a7,a0,ffffffffc0206046 <schedule+0x6e>
            proc_run(next);
ffffffffc0206042:	ea1fe0ef          	jal	ra,ffffffffc0204ee2 <proc_run>
    if (flag) {
ffffffffc0206046:	e419                	bnez	s0,ffffffffc0206054 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206048:	60a2                	ld	ra,8(sp)
ffffffffc020604a:	6402                	ld	s0,0(sp)
ffffffffc020604c:	0141                	addi	sp,sp,16
ffffffffc020604e:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206050:	852e                	mv	a0,a1
ffffffffc0206052:	b7dd                	j	ffffffffc0206038 <schedule+0x60>
}
ffffffffc0206054:	6402                	ld	s0,0(sp)
ffffffffc0206056:	60a2                	ld	ra,8(sp)
ffffffffc0206058:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020605a:	dfafa06f          	j	ffffffffc0200654 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020605e:	000a6617          	auipc	a2,0xa6
ffffffffc0206062:	57260613          	addi	a2,a2,1394 # ffffffffc02ac5d0 <proc_list>
ffffffffc0206066:	86b2                	mv	a3,a2
ffffffffc0206068:	b76d                	j	ffffffffc0206012 <schedule+0x3a>
        intr_disable();
ffffffffc020606a:	df0fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc020606e:	4405                	li	s0,1
ffffffffc0206070:	bfa5                	j	ffffffffc0205fe8 <schedule+0x10>

ffffffffc0206072 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206072:	000a6797          	auipc	a5,0xa6
ffffffffc0206076:	41e78793          	addi	a5,a5,1054 # ffffffffc02ac490 <current>
ffffffffc020607a:	639c                	ld	a5,0(a5)
}
ffffffffc020607c:	43c8                	lw	a0,4(a5)
ffffffffc020607e:	8082                	ret

ffffffffc0206080 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206080:	4501                	li	a0,0
ffffffffc0206082:	8082                	ret

ffffffffc0206084 <sys_putc>:
    cputchar(c);
ffffffffc0206084:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206086:	1141                	addi	sp,sp,-16
ffffffffc0206088:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020608a:	938fa0ef          	jal	ra,ffffffffc02001c2 <cputchar>
}
ffffffffc020608e:	60a2                	ld	ra,8(sp)
ffffffffc0206090:	4501                	li	a0,0
ffffffffc0206092:	0141                	addi	sp,sp,16
ffffffffc0206094:	8082                	ret

ffffffffc0206096 <sys_kill>:
    return do_kill(pid);
ffffffffc0206096:	4108                	lw	a0,0(a0)
ffffffffc0206098:	cadff06f          	j	ffffffffc0205d44 <do_kill>

ffffffffc020609c <sys_yield>:
    return do_yield();
ffffffffc020609c:	c57ff06f          	j	ffffffffc0205cf2 <do_yield>

ffffffffc02060a0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02060a0:	6d14                	ld	a3,24(a0)
ffffffffc02060a2:	6910                	ld	a2,16(a0)
ffffffffc02060a4:	650c                	ld	a1,8(a0)
ffffffffc02060a6:	6108                	ld	a0,0(a0)
ffffffffc02060a8:	f4cff06f          	j	ffffffffc02057f4 <do_execve>

ffffffffc02060ac <sys_wait>:
    return do_wait(pid, store);
ffffffffc02060ac:	650c                	ld	a1,8(a0)
ffffffffc02060ae:	4108                	lw	a0,0(a0)
ffffffffc02060b0:	c55ff06f          	j	ffffffffc0205d04 <do_wait>

ffffffffc02060b4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02060b4:	000a6797          	auipc	a5,0xa6
ffffffffc02060b8:	3dc78793          	addi	a5,a5,988 # ffffffffc02ac490 <current>
ffffffffc02060bc:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc02060be:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02060c0:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060c2:	6a0c                	ld	a1,16(a2)
ffffffffc02060c4:	ee7fe06f          	j	ffffffffc0204faa <do_fork>

ffffffffc02060c8 <sys_exit>:
    return do_exit(error_code);
ffffffffc02060c8:	4108                	lw	a0,0(a0)
ffffffffc02060ca:	b0cff06f          	j	ffffffffc02053d6 <do_exit>

ffffffffc02060ce <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060ce:	715d                	addi	sp,sp,-80
ffffffffc02060d0:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060d2:	000a6497          	auipc	s1,0xa6
ffffffffc02060d6:	3be48493          	addi	s1,s1,958 # ffffffffc02ac490 <current>
ffffffffc02060da:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060dc:	e0a2                	sd	s0,64(sp)
ffffffffc02060de:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060e0:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060e2:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060e4:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060e6:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060ea:	0327ee63          	bltu	a5,s2,ffffffffc0206126 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02060ee:	00391713          	slli	a4,s2,0x3
ffffffffc02060f2:	00003797          	auipc	a5,0x3
ffffffffc02060f6:	81e78793          	addi	a5,a5,-2018 # ffffffffc0208910 <syscalls>
ffffffffc02060fa:	97ba                	add	a5,a5,a4
ffffffffc02060fc:	639c                	ld	a5,0(a5)
ffffffffc02060fe:	c785                	beqz	a5,ffffffffc0206126 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0206100:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0206102:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0206104:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0206106:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0206108:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020610a:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020610c:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020610e:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206110:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0206112:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206114:	0028                	addi	a0,sp,8
ffffffffc0206116:	9782                	jalr	a5
ffffffffc0206118:	e828                	sd	a0,80(s0)
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020611a:	60a6                	ld	ra,72(sp)
ffffffffc020611c:	6406                	ld	s0,64(sp)
ffffffffc020611e:	74e2                	ld	s1,56(sp)
ffffffffc0206120:	7942                	ld	s2,48(sp)
ffffffffc0206122:	6161                	addi	sp,sp,80
ffffffffc0206124:	8082                	ret
    print_trapframe(tf);
ffffffffc0206126:	8522                	mv	a0,s0
ffffffffc0206128:	f22fa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020612c:	609c                	ld	a5,0(s1)
ffffffffc020612e:	86ca                	mv	a3,s2
ffffffffc0206130:	00002617          	auipc	a2,0x2
ffffffffc0206134:	79860613          	addi	a2,a2,1944 # ffffffffc02088c8 <default_pmm_manager+0x1568>
ffffffffc0206138:	43d8                	lw	a4,4(a5)
ffffffffc020613a:	06300593          	li	a1,99
ffffffffc020613e:	0b478793          	addi	a5,a5,180
ffffffffc0206142:	00002517          	auipc	a0,0x2
ffffffffc0206146:	7b650513          	addi	a0,a0,1974 # ffffffffc02088f8 <default_pmm_manager+0x1598>
ffffffffc020614a:	b3afa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020614e <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020614e:	9e3707b7          	lui	a5,0x9e370
ffffffffc0206152:	2785                	addiw	a5,a5,1
ffffffffc0206154:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0206158:	02000793          	li	a5,32
ffffffffc020615c:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0206160:	00b5553b          	srlw	a0,a0,a1
ffffffffc0206164:	8082                	ret

ffffffffc0206166 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206166:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020616a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020616c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206170:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206172:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206176:	f022                	sd	s0,32(sp)
ffffffffc0206178:	ec26                	sd	s1,24(sp)
ffffffffc020617a:	e84a                	sd	s2,16(sp)
ffffffffc020617c:	f406                	sd	ra,40(sp)
ffffffffc020617e:	e44e                	sd	s3,8(sp)
ffffffffc0206180:	84aa                	mv	s1,a0
ffffffffc0206182:	892e                	mv	s2,a1
ffffffffc0206184:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206188:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc020618a:	03067e63          	bleu	a6,a2,ffffffffc02061c6 <printnum+0x60>
ffffffffc020618e:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206190:	00805763          	blez	s0,ffffffffc020619e <printnum+0x38>
ffffffffc0206194:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206196:	85ca                	mv	a1,s2
ffffffffc0206198:	854e                	mv	a0,s3
ffffffffc020619a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020619c:	fc65                	bnez	s0,ffffffffc0206194 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020619e:	1a02                	slli	s4,s4,0x20
ffffffffc02061a0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02061a4:	00003797          	auipc	a5,0x3
ffffffffc02061a8:	a8c78793          	addi	a5,a5,-1396 # ffffffffc0208c30 <error_string+0xc8>
ffffffffc02061ac:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02061ae:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061b0:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02061b4:	70a2                	ld	ra,40(sp)
ffffffffc02061b6:	69a2                	ld	s3,8(sp)
ffffffffc02061b8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061ba:	85ca                	mv	a1,s2
ffffffffc02061bc:	8326                	mv	t1,s1
}
ffffffffc02061be:	6942                	ld	s2,16(sp)
ffffffffc02061c0:	64e2                	ld	s1,24(sp)
ffffffffc02061c2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061c4:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02061c6:	03065633          	divu	a2,a2,a6
ffffffffc02061ca:	8722                	mv	a4,s0
ffffffffc02061cc:	f9bff0ef          	jal	ra,ffffffffc0206166 <printnum>
ffffffffc02061d0:	b7f9                	j	ffffffffc020619e <printnum+0x38>

ffffffffc02061d2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02061d2:	7119                	addi	sp,sp,-128
ffffffffc02061d4:	f4a6                	sd	s1,104(sp)
ffffffffc02061d6:	f0ca                	sd	s2,96(sp)
ffffffffc02061d8:	e8d2                	sd	s4,80(sp)
ffffffffc02061da:	e4d6                	sd	s5,72(sp)
ffffffffc02061dc:	e0da                	sd	s6,64(sp)
ffffffffc02061de:	fc5e                	sd	s7,56(sp)
ffffffffc02061e0:	f862                	sd	s8,48(sp)
ffffffffc02061e2:	f06a                	sd	s10,32(sp)
ffffffffc02061e4:	fc86                	sd	ra,120(sp)
ffffffffc02061e6:	f8a2                	sd	s0,112(sp)
ffffffffc02061e8:	ecce                	sd	s3,88(sp)
ffffffffc02061ea:	f466                	sd	s9,40(sp)
ffffffffc02061ec:	ec6e                	sd	s11,24(sp)
ffffffffc02061ee:	892a                	mv	s2,a0
ffffffffc02061f0:	84ae                	mv	s1,a1
ffffffffc02061f2:	8d32                	mv	s10,a2
ffffffffc02061f4:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02061f6:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061f8:	00003a17          	auipc	s4,0x3
ffffffffc02061fc:	818a0a13          	addi	s4,s4,-2024 # ffffffffc0208a10 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206200:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206204:	00003c17          	auipc	s8,0x3
ffffffffc0206208:	964c0c13          	addi	s8,s8,-1692 # ffffffffc0208b68 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020620c:	000d4503          	lbu	a0,0(s10)
ffffffffc0206210:	02500793          	li	a5,37
ffffffffc0206214:	001d0413          	addi	s0,s10,1
ffffffffc0206218:	00f50e63          	beq	a0,a5,ffffffffc0206234 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020621c:	c521                	beqz	a0,ffffffffc0206264 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020621e:	02500993          	li	s3,37
ffffffffc0206222:	a011                	j	ffffffffc0206226 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0206224:	c121                	beqz	a0,ffffffffc0206264 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0206226:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206228:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020622a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020622c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206230:	ff351ae3          	bne	a0,s3,ffffffffc0206224 <vprintfmt+0x52>
ffffffffc0206234:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206238:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020623c:	4981                	li	s3,0
ffffffffc020623e:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0206240:	5cfd                	li	s9,-1
ffffffffc0206242:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206244:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0206248:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020624a:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020624e:	0ff6f693          	andi	a3,a3,255
ffffffffc0206252:	00140d13          	addi	s10,s0,1
ffffffffc0206256:	20d5e563          	bltu	a1,a3,ffffffffc0206460 <vprintfmt+0x28e>
ffffffffc020625a:	068a                	slli	a3,a3,0x2
ffffffffc020625c:	96d2                	add	a3,a3,s4
ffffffffc020625e:	4294                	lw	a3,0(a3)
ffffffffc0206260:	96d2                	add	a3,a3,s4
ffffffffc0206262:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206264:	70e6                	ld	ra,120(sp)
ffffffffc0206266:	7446                	ld	s0,112(sp)
ffffffffc0206268:	74a6                	ld	s1,104(sp)
ffffffffc020626a:	7906                	ld	s2,96(sp)
ffffffffc020626c:	69e6                	ld	s3,88(sp)
ffffffffc020626e:	6a46                	ld	s4,80(sp)
ffffffffc0206270:	6aa6                	ld	s5,72(sp)
ffffffffc0206272:	6b06                	ld	s6,64(sp)
ffffffffc0206274:	7be2                	ld	s7,56(sp)
ffffffffc0206276:	7c42                	ld	s8,48(sp)
ffffffffc0206278:	7ca2                	ld	s9,40(sp)
ffffffffc020627a:	7d02                	ld	s10,32(sp)
ffffffffc020627c:	6de2                	ld	s11,24(sp)
ffffffffc020627e:	6109                	addi	sp,sp,128
ffffffffc0206280:	8082                	ret
    if (lflag >= 2) {
ffffffffc0206282:	4705                	li	a4,1
ffffffffc0206284:	008a8593          	addi	a1,s5,8
ffffffffc0206288:	01074463          	blt	a4,a6,ffffffffc0206290 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc020628c:	26080363          	beqz	a6,ffffffffc02064f2 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0206290:	000ab603          	ld	a2,0(s5)
ffffffffc0206294:	46c1                	li	a3,16
ffffffffc0206296:	8aae                	mv	s5,a1
ffffffffc0206298:	a06d                	j	ffffffffc0206342 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020629a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020629e:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062a0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02062a2:	b765                	j	ffffffffc020624a <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02062a4:	000aa503          	lw	a0,0(s5)
ffffffffc02062a8:	85a6                	mv	a1,s1
ffffffffc02062aa:	0aa1                	addi	s5,s5,8
ffffffffc02062ac:	9902                	jalr	s2
            break;
ffffffffc02062ae:	bfb9                	j	ffffffffc020620c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02062b0:	4705                	li	a4,1
ffffffffc02062b2:	008a8993          	addi	s3,s5,8
ffffffffc02062b6:	01074463          	blt	a4,a6,ffffffffc02062be <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02062ba:	22080463          	beqz	a6,ffffffffc02064e2 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02062be:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02062c2:	24044463          	bltz	s0,ffffffffc020650a <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02062c6:	8622                	mv	a2,s0
ffffffffc02062c8:	8ace                	mv	s5,s3
ffffffffc02062ca:	46a9                	li	a3,10
ffffffffc02062cc:	a89d                	j	ffffffffc0206342 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02062ce:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062d2:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02062d4:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02062d6:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02062da:	8fb5                	xor	a5,a5,a3
ffffffffc02062dc:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062e0:	1ad74363          	blt	a4,a3,ffffffffc0206486 <vprintfmt+0x2b4>
ffffffffc02062e4:	00369793          	slli	a5,a3,0x3
ffffffffc02062e8:	97e2                	add	a5,a5,s8
ffffffffc02062ea:	639c                	ld	a5,0(a5)
ffffffffc02062ec:	18078d63          	beqz	a5,ffffffffc0206486 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02062f0:	86be                	mv	a3,a5
ffffffffc02062f2:	00000617          	auipc	a2,0x0
ffffffffc02062f6:	35e60613          	addi	a2,a2,862 # ffffffffc0206650 <etext+0x2a>
ffffffffc02062fa:	85a6                	mv	a1,s1
ffffffffc02062fc:	854a                	mv	a0,s2
ffffffffc02062fe:	240000ef          	jal	ra,ffffffffc020653e <printfmt>
ffffffffc0206302:	b729                	j	ffffffffc020620c <vprintfmt+0x3a>
            lflag ++;
ffffffffc0206304:	00144603          	lbu	a2,1(s0)
ffffffffc0206308:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020630a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020630c:	bf3d                	j	ffffffffc020624a <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020630e:	4705                	li	a4,1
ffffffffc0206310:	008a8593          	addi	a1,s5,8
ffffffffc0206314:	01074463          	blt	a4,a6,ffffffffc020631c <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0206318:	1e080263          	beqz	a6,ffffffffc02064fc <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020631c:	000ab603          	ld	a2,0(s5)
ffffffffc0206320:	46a1                	li	a3,8
ffffffffc0206322:	8aae                	mv	s5,a1
ffffffffc0206324:	a839                	j	ffffffffc0206342 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0206326:	03000513          	li	a0,48
ffffffffc020632a:	85a6                	mv	a1,s1
ffffffffc020632c:	e03e                	sd	a5,0(sp)
ffffffffc020632e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0206330:	85a6                	mv	a1,s1
ffffffffc0206332:	07800513          	li	a0,120
ffffffffc0206336:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206338:	0aa1                	addi	s5,s5,8
ffffffffc020633a:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020633e:	6782                	ld	a5,0(sp)
ffffffffc0206340:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206342:	876e                	mv	a4,s11
ffffffffc0206344:	85a6                	mv	a1,s1
ffffffffc0206346:	854a                	mv	a0,s2
ffffffffc0206348:	e1fff0ef          	jal	ra,ffffffffc0206166 <printnum>
            break;
ffffffffc020634c:	b5c1                	j	ffffffffc020620c <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020634e:	000ab603          	ld	a2,0(s5)
ffffffffc0206352:	0aa1                	addi	s5,s5,8
ffffffffc0206354:	1c060663          	beqz	a2,ffffffffc0206520 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0206358:	00160413          	addi	s0,a2,1
ffffffffc020635c:	17b05c63          	blez	s11,ffffffffc02064d4 <vprintfmt+0x302>
ffffffffc0206360:	02d00593          	li	a1,45
ffffffffc0206364:	14b79263          	bne	a5,a1,ffffffffc02064a8 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206368:	00064783          	lbu	a5,0(a2)
ffffffffc020636c:	0007851b          	sext.w	a0,a5
ffffffffc0206370:	c905                	beqz	a0,ffffffffc02063a0 <vprintfmt+0x1ce>
ffffffffc0206372:	000cc563          	bltz	s9,ffffffffc020637c <vprintfmt+0x1aa>
ffffffffc0206376:	3cfd                	addiw	s9,s9,-1
ffffffffc0206378:	036c8263          	beq	s9,s6,ffffffffc020639c <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc020637c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020637e:	18098463          	beqz	s3,ffffffffc0206506 <vprintfmt+0x334>
ffffffffc0206382:	3781                	addiw	a5,a5,-32
ffffffffc0206384:	18fbf163          	bleu	a5,s7,ffffffffc0206506 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0206388:	03f00513          	li	a0,63
ffffffffc020638c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020638e:	0405                	addi	s0,s0,1
ffffffffc0206390:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206394:	3dfd                	addiw	s11,s11,-1
ffffffffc0206396:	0007851b          	sext.w	a0,a5
ffffffffc020639a:	fd61                	bnez	a0,ffffffffc0206372 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020639c:	e7b058e3          	blez	s11,ffffffffc020620c <vprintfmt+0x3a>
ffffffffc02063a0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02063a2:	85a6                	mv	a1,s1
ffffffffc02063a4:	02000513          	li	a0,32
ffffffffc02063a8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02063aa:	e60d81e3          	beqz	s11,ffffffffc020620c <vprintfmt+0x3a>
ffffffffc02063ae:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02063b0:	85a6                	mv	a1,s1
ffffffffc02063b2:	02000513          	li	a0,32
ffffffffc02063b6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02063b8:	fe0d94e3          	bnez	s11,ffffffffc02063a0 <vprintfmt+0x1ce>
ffffffffc02063bc:	bd81                	j	ffffffffc020620c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02063be:	4705                	li	a4,1
ffffffffc02063c0:	008a8593          	addi	a1,s5,8
ffffffffc02063c4:	01074463          	blt	a4,a6,ffffffffc02063cc <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02063c8:	12080063          	beqz	a6,ffffffffc02064e8 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02063cc:	000ab603          	ld	a2,0(s5)
ffffffffc02063d0:	46a9                	li	a3,10
ffffffffc02063d2:	8aae                	mv	s5,a1
ffffffffc02063d4:	b7bd                	j	ffffffffc0206342 <vprintfmt+0x170>
ffffffffc02063d6:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02063da:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063de:	846a                	mv	s0,s10
ffffffffc02063e0:	b5ad                	j	ffffffffc020624a <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02063e2:	85a6                	mv	a1,s1
ffffffffc02063e4:	02500513          	li	a0,37
ffffffffc02063e8:	9902                	jalr	s2
            break;
ffffffffc02063ea:	b50d                	j	ffffffffc020620c <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02063ec:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02063f0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02063f4:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063f6:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02063f8:	e40dd9e3          	bgez	s11,ffffffffc020624a <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02063fc:	8de6                	mv	s11,s9
ffffffffc02063fe:	5cfd                	li	s9,-1
ffffffffc0206400:	b5a9                	j	ffffffffc020624a <vprintfmt+0x78>
            goto reswitch;
ffffffffc0206402:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0206406:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020640a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020640c:	bd3d                	j	ffffffffc020624a <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020640e:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0206412:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206416:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206418:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020641c:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206420:	fcd56ce3          	bltu	a0,a3,ffffffffc02063f8 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0206424:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0206426:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc020642a:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020642e:	0196873b          	addw	a4,a3,s9
ffffffffc0206432:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206436:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc020643a:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020643e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0206442:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206446:	fcd57fe3          	bleu	a3,a0,ffffffffc0206424 <vprintfmt+0x252>
ffffffffc020644a:	b77d                	j	ffffffffc02063f8 <vprintfmt+0x226>
            if (width < 0)
ffffffffc020644c:	fffdc693          	not	a3,s11
ffffffffc0206450:	96fd                	srai	a3,a3,0x3f
ffffffffc0206452:	00ddfdb3          	and	s11,s11,a3
ffffffffc0206456:	00144603          	lbu	a2,1(s0)
ffffffffc020645a:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020645c:	846a                	mv	s0,s10
ffffffffc020645e:	b3f5                	j	ffffffffc020624a <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0206460:	85a6                	mv	a1,s1
ffffffffc0206462:	02500513          	li	a0,37
ffffffffc0206466:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206468:	fff44703          	lbu	a4,-1(s0)
ffffffffc020646c:	02500793          	li	a5,37
ffffffffc0206470:	8d22                	mv	s10,s0
ffffffffc0206472:	d8f70de3          	beq	a4,a5,ffffffffc020620c <vprintfmt+0x3a>
ffffffffc0206476:	02500713          	li	a4,37
ffffffffc020647a:	1d7d                	addi	s10,s10,-1
ffffffffc020647c:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0206480:	fee79de3          	bne	a5,a4,ffffffffc020647a <vprintfmt+0x2a8>
ffffffffc0206484:	b361                	j	ffffffffc020620c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206486:	00003617          	auipc	a2,0x3
ffffffffc020648a:	88a60613          	addi	a2,a2,-1910 # ffffffffc0208d10 <error_string+0x1a8>
ffffffffc020648e:	85a6                	mv	a1,s1
ffffffffc0206490:	854a                	mv	a0,s2
ffffffffc0206492:	0ac000ef          	jal	ra,ffffffffc020653e <printfmt>
ffffffffc0206496:	bb9d                	j	ffffffffc020620c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206498:	00003617          	auipc	a2,0x3
ffffffffc020649c:	87060613          	addi	a2,a2,-1936 # ffffffffc0208d08 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc02064a0:	00003417          	auipc	s0,0x3
ffffffffc02064a4:	86940413          	addi	s0,s0,-1943 # ffffffffc0208d09 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064a8:	8532                	mv	a0,a2
ffffffffc02064aa:	85e6                	mv	a1,s9
ffffffffc02064ac:	e032                	sd	a2,0(sp)
ffffffffc02064ae:	e43e                	sd	a5,8(sp)
ffffffffc02064b0:	0cc000ef          	jal	ra,ffffffffc020657c <strnlen>
ffffffffc02064b4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02064b8:	6602                	ld	a2,0(sp)
ffffffffc02064ba:	01b05d63          	blez	s11,ffffffffc02064d4 <vprintfmt+0x302>
ffffffffc02064be:	67a2                	ld	a5,8(sp)
ffffffffc02064c0:	2781                	sext.w	a5,a5
ffffffffc02064c2:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02064c4:	6522                	ld	a0,8(sp)
ffffffffc02064c6:	85a6                	mv	a1,s1
ffffffffc02064c8:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064ca:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02064cc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064ce:	6602                	ld	a2,0(sp)
ffffffffc02064d0:	fe0d9ae3          	bnez	s11,ffffffffc02064c4 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064d4:	00064783          	lbu	a5,0(a2)
ffffffffc02064d8:	0007851b          	sext.w	a0,a5
ffffffffc02064dc:	e8051be3          	bnez	a0,ffffffffc0206372 <vprintfmt+0x1a0>
ffffffffc02064e0:	b335                	j	ffffffffc020620c <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02064e2:	000aa403          	lw	s0,0(s5)
ffffffffc02064e6:	bbf1                	j	ffffffffc02062c2 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02064e8:	000ae603          	lwu	a2,0(s5)
ffffffffc02064ec:	46a9                	li	a3,10
ffffffffc02064ee:	8aae                	mv	s5,a1
ffffffffc02064f0:	bd89                	j	ffffffffc0206342 <vprintfmt+0x170>
ffffffffc02064f2:	000ae603          	lwu	a2,0(s5)
ffffffffc02064f6:	46c1                	li	a3,16
ffffffffc02064f8:	8aae                	mv	s5,a1
ffffffffc02064fa:	b5a1                	j	ffffffffc0206342 <vprintfmt+0x170>
ffffffffc02064fc:	000ae603          	lwu	a2,0(s5)
ffffffffc0206500:	46a1                	li	a3,8
ffffffffc0206502:	8aae                	mv	s5,a1
ffffffffc0206504:	bd3d                	j	ffffffffc0206342 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0206506:	9902                	jalr	s2
ffffffffc0206508:	b559                	j	ffffffffc020638e <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc020650a:	85a6                	mv	a1,s1
ffffffffc020650c:	02d00513          	li	a0,45
ffffffffc0206510:	e03e                	sd	a5,0(sp)
ffffffffc0206512:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206514:	8ace                	mv	s5,s3
ffffffffc0206516:	40800633          	neg	a2,s0
ffffffffc020651a:	46a9                	li	a3,10
ffffffffc020651c:	6782                	ld	a5,0(sp)
ffffffffc020651e:	b515                	j	ffffffffc0206342 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0206520:	01b05663          	blez	s11,ffffffffc020652c <vprintfmt+0x35a>
ffffffffc0206524:	02d00693          	li	a3,45
ffffffffc0206528:	f6d798e3          	bne	a5,a3,ffffffffc0206498 <vprintfmt+0x2c6>
ffffffffc020652c:	00002417          	auipc	s0,0x2
ffffffffc0206530:	7dd40413          	addi	s0,s0,2013 # ffffffffc0208d09 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206534:	02800513          	li	a0,40
ffffffffc0206538:	02800793          	li	a5,40
ffffffffc020653c:	bd1d                	j	ffffffffc0206372 <vprintfmt+0x1a0>

ffffffffc020653e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020653e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206540:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206544:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206546:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206548:	ec06                	sd	ra,24(sp)
ffffffffc020654a:	f83a                	sd	a4,48(sp)
ffffffffc020654c:	fc3e                	sd	a5,56(sp)
ffffffffc020654e:	e0c2                	sd	a6,64(sp)
ffffffffc0206550:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0206552:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206554:	c7fff0ef          	jal	ra,ffffffffc02061d2 <vprintfmt>
}
ffffffffc0206558:	60e2                	ld	ra,24(sp)
ffffffffc020655a:	6161                	addi	sp,sp,80
ffffffffc020655c:	8082                	ret

ffffffffc020655e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020655e:	00054783          	lbu	a5,0(a0)
ffffffffc0206562:	cb91                	beqz	a5,ffffffffc0206576 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0206564:	4781                	li	a5,0
        cnt ++;
ffffffffc0206566:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0206568:	00f50733          	add	a4,a0,a5
ffffffffc020656c:	00074703          	lbu	a4,0(a4)
ffffffffc0206570:	fb7d                	bnez	a4,ffffffffc0206566 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0206572:	853e                	mv	a0,a5
ffffffffc0206574:	8082                	ret
    size_t cnt = 0;
ffffffffc0206576:	4781                	li	a5,0
}
ffffffffc0206578:	853e                	mv	a0,a5
ffffffffc020657a:	8082                	ret

ffffffffc020657c <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020657c:	c185                	beqz	a1,ffffffffc020659c <strnlen+0x20>
ffffffffc020657e:	00054783          	lbu	a5,0(a0)
ffffffffc0206582:	cf89                	beqz	a5,ffffffffc020659c <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0206584:	4781                	li	a5,0
ffffffffc0206586:	a021                	j	ffffffffc020658e <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206588:	00074703          	lbu	a4,0(a4)
ffffffffc020658c:	c711                	beqz	a4,ffffffffc0206598 <strnlen+0x1c>
        cnt ++;
ffffffffc020658e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206590:	00f50733          	add	a4,a0,a5
ffffffffc0206594:	fef59ae3          	bne	a1,a5,ffffffffc0206588 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0206598:	853e                	mv	a0,a5
ffffffffc020659a:	8082                	ret
    size_t cnt = 0;
ffffffffc020659c:	4781                	li	a5,0
}
ffffffffc020659e:	853e                	mv	a0,a5
ffffffffc02065a0:	8082                	ret

ffffffffc02065a2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02065a2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02065a4:	0585                	addi	a1,a1,1
ffffffffc02065a6:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02065aa:	0785                	addi	a5,a5,1
ffffffffc02065ac:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02065b0:	fb75                	bnez	a4,ffffffffc02065a4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02065b2:	8082                	ret

ffffffffc02065b4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065b4:	00054783          	lbu	a5,0(a0)
ffffffffc02065b8:	0005c703          	lbu	a4,0(a1)
ffffffffc02065bc:	cb91                	beqz	a5,ffffffffc02065d0 <strcmp+0x1c>
ffffffffc02065be:	00e79c63          	bne	a5,a4,ffffffffc02065d6 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02065c2:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065c4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02065c8:	0585                	addi	a1,a1,1
ffffffffc02065ca:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065ce:	fbe5                	bnez	a5,ffffffffc02065be <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02065d0:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02065d2:	9d19                	subw	a0,a0,a4
ffffffffc02065d4:	8082                	ret
ffffffffc02065d6:	0007851b          	sext.w	a0,a5
ffffffffc02065da:	9d19                	subw	a0,a0,a4
ffffffffc02065dc:	8082                	ret

ffffffffc02065de <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02065de:	00054783          	lbu	a5,0(a0)
ffffffffc02065e2:	cb91                	beqz	a5,ffffffffc02065f6 <strchr+0x18>
        if (*s == c) {
ffffffffc02065e4:	00b79563          	bne	a5,a1,ffffffffc02065ee <strchr+0x10>
ffffffffc02065e8:	a809                	j	ffffffffc02065fa <strchr+0x1c>
ffffffffc02065ea:	00b78763          	beq	a5,a1,ffffffffc02065f8 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02065ee:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02065f0:	00054783          	lbu	a5,0(a0)
ffffffffc02065f4:	fbfd                	bnez	a5,ffffffffc02065ea <strchr+0xc>
    }
    return NULL;
ffffffffc02065f6:	4501                	li	a0,0
}
ffffffffc02065f8:	8082                	ret
ffffffffc02065fa:	8082                	ret

ffffffffc02065fc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02065fc:	ca01                	beqz	a2,ffffffffc020660c <memset+0x10>
ffffffffc02065fe:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0206600:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0206602:	0785                	addi	a5,a5,1
ffffffffc0206604:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0206608:	fec79de3          	bne	a5,a2,ffffffffc0206602 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020660c:	8082                	ret

ffffffffc020660e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020660e:	ca19                	beqz	a2,ffffffffc0206624 <memcpy+0x16>
ffffffffc0206610:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0206612:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0206614:	0585                	addi	a1,a1,1
ffffffffc0206616:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020661a:	0785                	addi	a5,a5,1
ffffffffc020661c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0206620:	fec59ae3          	bne	a1,a2,ffffffffc0206614 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0206624:	8082                	ret
