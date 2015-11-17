.code64
.globl _cpuid

_cpuid:
	pushq %rbp
	movq %rsp, %rbp
	movq $0 ,%rax
	cpuid
	movl %ebx, (%rdi)
	movl %ecx, 4(%rdi)
	movl %edx, 8(%rdi)
	movq %rbp, %rsp
	popq %rbp
	ret