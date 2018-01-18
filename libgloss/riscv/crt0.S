#=========================================================================
# crt0.S : Entry point for RISC-V user programs
#=========================================================================

.weak _board_mem_base
.weak _board_mem_size

__mem_base:        .long   0x0
__mem_size:        .long   0x1000000

        .section .data
        /* One single int for program argc */
        .global argc
argc:   .space  4,0
        .global argv
        /* Up to 20 arguments value can be passe to the program */
argv:   .space  4*20, 0
        .global argbuf
        /* 2 Kb of buffer usable by argv */
argbuf: .space  2048, 0
        .global stack
stack:  .space  4,0 

  .text
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax
1:auipc gp, %pcrel_hi(__global_pointer$)
  addi  gp, gp, %pcrel_lo(1b)
.option pop

  # Clear the bss segment
  la      a0, _fbss
  la      a2, _end
  sub     a2, a2, a0
  li      a1, 0
  call    memset

# Set sp to top of memory, stack grows downward
  la      t0, __mem_base
  la      t1, __mem_size
  lw      t0, 0(t0)
  lw      t1, 0(t1)
  add     sp, t0, t1
# Store stack top in stack variable
  la      t0, stack
  sw      sp, 0(t0)

  la      a0, __libc_fini_array   # Register global termination functions
  call    atexit                  #  to be called upon exit
  call    __libc_init_array       # Run global initialization functions
#ifdef OLD
  lw      a0, 0(sp)                  # a0 = argc
  addi    a1, sp, __SIZEOF_POINTER__ # a1 = argv
  li      a2, 0                      # a2 = envp = NULL
#else
  la      a0, argc
  lw      a0, 0(a0)
  la      a1, argv
  li      a2, 0
#endif
  call    main
  tail    exit
  .size  _start, .-_start

  .global _init
  .type   _init, @function
  .global _fini
  .type   _fini, @function
_init:
_fini:
  # These don't have to do anything since we use init_array/fini_array.
  ret
  .size  _init, .-_init
  .size  _fini, .-_fini
