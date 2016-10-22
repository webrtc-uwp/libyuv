;
;  Copyright 2012 The LibYuv Project Authors. All rights reserved.
;
;  Use of this source code is governed by a BSD-style license
;  that can be found in the LICENSE file in the root of the source
;  tree. An additional intellectual property rights grant can be found
;  in the file PATENTS. All contributing project authors may
;  be found in the AUTHORS file in the root of the source tree.
;

  AREA  |.text|, CODE, READONLY, ALIGN=2

  GET    source/arm_asm_macros.in

  EXPORT ScaleRowDown2_NEON
  EXPORT ScaleRowDown2Linear_NEON
  EXPORT ScaleRowDown2Box_NEON
  EXPORT ScaleRowDown4_NEON
  EXPORT ScaleRowDown4Box_NEON
  EXPORT ScaleRowDown34_NEON
  EXPORT ScaleRowDown34_0_Box_NEON
  EXPORT ScaleRowDown34_1_Box_NEON
  EXPORT ScaleRowDown38_NEON
  EXPORT ScaleRowDown38_3_Box_NEON
  EXPORT ScaleRowDown38_2_Box_NEON
  EXPORT ScaleAddRows_NEON
  EXPORT ScaleFilterCols_NEON
  EXPORT ScaleARGBRowDown2_NEON
  EXPORT ScaleARGBRowDown2Linear_NEON
  EXPORT ScaleARGBRowDown2Box_NEON
  EXPORT ScaleARGBRowDownEven_NEON
  EXPORT ScaleARGBRowDownEvenBox_NEON
  EXPORT ScaleARGBCols_NEON
  EXPORT ScaleARGBFilterCols_NEON
  EXPORT ScaleARGBCols_NEON

kShuf38       DCB   0, 3, 6, 8, 11, 14, 16, 19, 22, 24, 27, 30, 0, 0, 0, 0
kShuf38_2     DCB   0, 8, 16, 2, 10, 17, 4, 12, 18, 6, 14, 19, 0, 0, 0, 0
;vec16 kMult38_Div6 = { 65536 / 12, 65536 / 12, 65536 / 12, 65536 / 12, 65536 / 12, 65536 / 12, 65536 / 12, 65536 / 12 }
kMult38_Div6  DCW   0x1555,	0x1555,	0x1555,	0x1555,	0x1555,	0x1555, 0x1555, 0x1555
;vec16 kMult38_Div9 = { 65536 / 18, 65536 / 18, 65536 / 18, 65536 / 18, 65536 / 18, 65536 / 18, 65536 / 18, 65536 / 18 };
kMult38_Div9  DCW 0xe38, 0xe38,	0xe38, 0xe38, 0xe38, 0xe38,	0xe38, 0xe38


; Read 32x1 throw away even pixels, and write 16x1
ScaleRowDown2_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst
  ;     r3 = int dst_width
  vpush       {q0, q1}
1
  ; load even pixels into q0, odd into q1
  MEMACCESS  0
  vld2.8     {q0, q1}, [r0]!
  subs       r3, r3, #16                      ; 16 processed per loop
  MEMACCESS  1
  vst1.8     {q1}, [r2]!                      ; store odd pixels
  bgt        %b1

  vpop       {q0, q1}

  bx        lr
  ENDP

; Read 32x1 average down and write 16x1.
ScaleRowDown2Linear_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst
  ;     r3 = int dst_width
  vpush          {q0, q1}
1
  MEMACCESS  0
  vld1.8     {q0, q1}, [r0]!                  ; load pixels and post inc
  subs       r3, r3, #16                      ; 16 processed per loop
  vpaddl.u8  q0, q0                           ; add adjacent
  vpaddl.u8  q1, q1
  vrshrn.u16 d0, q0, #1                       ; downshift, round and pack
  vrshrn.u16 d1, q1, #1
  MEMACCESS  1
  vst1.8     {q0}, [r2]!
  bgt        %b1
  vpop           {q0, q1}

  bx        lr
  ENDP

; Read 32x2 average down and write 16x1
ScaleRowDown2Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst
  ;     r3 = int dst_width
  ; This file was created from a .asm file
  vpush          {q0, q1, q2, q3}
  add        r1, r0
1
  MEMACCESS  0
  vld1.8     {q0, q1}, [r0]!                  ; load row 1 and post inc
  MEMACCESS  1
  vld1.8     {q2, q3}, [r1]!                  ; load row 2 and post inc
  subs       r3, r3, #16                      ; 16 processed per loop
  vpaddl.u8  q0, q0                           ; row 1 add adjacent
  vpaddl.u8  q1, q1
  vpadal.u8  q0, q2                           ; row 2 add adjacent + row1
  vpadal.u8  q1, q3
  vrshrn.u16 d0, q0, #2                       ; downshift, round and pack
  vrshrn.u16 d1, q1, #2
  MEMACCESS  2
  vst1.8     {q0}, [r2]!
  bgt        %b1
  vpop           {q0, q1, q2, q3}

  bx        lr
  ENDP

ScaleRowDown4_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush       {q0, q1}

1
  MEMACCESS   0
  vld4.8      {d0, d1, d2, d3}, [r0]!        ; src line 0
  subs        r3, r3, #8                     ; 8 processed per loop
  MEMACCESS   1
  vst1.8      {d2}, [r2]!
  bgt         %b1

  vpop        {q0, q1}
  bx          lr
  ENDP

ScaleRowDown4Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  push       {r4-r6}
  vpush      {q0-q3}
  add        r4, r0, r1 ; src_ptr + src_stride
  add        r5, r4, r1 ; src_ptr + src_stride * 2
  add        r6, r5, r1 ; src_ptr + src_stride * 3

1
  MEMACCESS  0
  vld1.8     {q0}, [r0]!                       ; load up 16x4
  MEMACCESS  3
  vld1.8     {q1}, [r4]!
  MEMACCESS  4
  vld1.8     {q2}, [r5]!
  MEMACCESS  5
  vld1.8     {q3}, [r6]!
  subs       r3, r3, #4
  vpaddl.u8  q0, q0
  vpadal.u8  q0, q1
  vpadal.u8  q0, q2
  vpadal.u8  q0, q3
  vpaddl.u16 q0, q0
  vrshrn.u32 d0, q0, #4                        ; divide by 16 w/rounding
  vmovn.u16  d0, q0
  MEMACCESS  1
  vst1.32    {d0[0]}, [r2]!
  bgt        %b1

  vpop      {q0-q3}
  pop       {r4-r6}
  bx        lr
  ENDP

ScaleRowDown34_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush     {d0-d3}

1
  MEMACCESS 0
  vld4.8    {d0, d1, d2, d3}, [r0]!     ; src line 0
  subs      r3, r3, #24
  vmov      d2, d3                      ; order d0, d1, d2
  MEMACCESS 1
  vst3.8     {d0, d1, d2}, [r2]!
  bgt        %b1

  vpop      {d0-d3}
  bx        lr
  ENDP

ScaleRowDown34_0_Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush     {q0-q3}
  vpush     {q8-q11}
  vpush     {d24}

  vmov.u8    d24, #3
  add        r1, r0
1
  MEMACCESS    0
  vld4.8       {d0, d1, d2, d3}, [r0]!       ; src line 0
  MEMACCESS    3
  vld4.8       {d4, d5, d6, d7}, [r1]!       ; src line 1
  subs         r3, r3, #24

  ; filter src line 0 with src line 1
  ; expand chars to shorts to allow for room
  ; when adding lines together
  vmovl.u8     q8, d4
  vmovl.u8     q9, d5
  vmovl.u8     q10, d6
  vmovl.u8     q11, d7

  ; 3 * line_0 + line_1
  vmlal.u8     q8, d0, d24
  vmlal.u8     q9, d1, d24
  vmlal.u8     q10, d2, d24
  vmlal.u8     q11, d3, d24

  ; (3 * line_0 + line_1) >> 2
  vqrshrn.u16  d0, q8, #2
  vqrshrn.u16  d1, q9, #2
  vqrshrn.u16  d2, q10, #2
  vqrshrn.u16  d3, q11, #2

  ; a0 = (src[0] * 3 + s[1] * 1) >> 2
  vmovl.u8     q8, d1
  vmlal.u8     q8, d0, d24
  vqrshrn.u16  d0, q8, #2

  ; a1 = (src[1] * 1 + s[2] * 1) >> 1
  vrhadd.u8    d1, d1, d2

  ; a2 = (src[2] * 1 + s[3] * 3) >> 2
  vmovl.u8     q8, d2
  vmlal.u8     q8, d3, d24
  vqrshrn.u16  d2, q8, #2

  MEMACCESS    1
  vst3.8       {d0, d1, d2}, [r2]!

  bgt          %b1


  vpop      {d24}
  vpop      {q8-q11}
  vpop      {q0-q3}
  bx        lr
  ENDP

ScaleRowDown34_1_Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush      {q0-q3}
  vpush      {d24}
  vmov.u8    d24, #3
  add        r1, r0
1
  MEMACCESS    0
  vld4.8       {d0, d1, d2, d3}, [r0]!       ; src line 0
  MEMACCESS    3
  vld4.8       {d4, d5, d6, d7}, [r1]!       ; src line 1
  subs         r3, r3, #24
  ; average src line 0 with src line 1
  vrhadd.u8    q0, q0, q2
  vrhadd.u8    q1, q1, q3

  ; a0 = (src[0] * 3 + s[1] * 1) >> 2
  vmovl.u8     q3, d1
  vmlal.u8     q3, d0, d24
  vqrshrn.u16  d0, q3, #2

  ; a1 = (src[1] * 1 + s[2] * 1) >> 1
  vrhadd.u8    d1, d1, d2

  ; a2 = (src[2] * 1 + s[3] * 3) >> 2
  vmovl.u8     q3, d2
  vmlal.u8     q3, d3, d24
  vqrshrn.u16  d2, q3, #2

  MEMACCESS    1
  vst3.8       {d0, d1, d2}, [r2]!
  bgt          %b1

  vpop      {d24}
  vpop      {q0-q3}
  bx        lr
  ENDP

ScaleRowDown38_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush     {d0-d5}
  push      {r4}

  adr       R4, kShuf38

  vld1.8     {q3}, [r4]
1
  MEMACCESS  0
  vld1.8     {d0, d1, d2, d3}, [r0]!
  subs       r3, r3, #12
  vtbl.u8    d4, {d0, d1, d2, d3}, d6
  vtbl.u8    d5, {d0, d1, d2, d3}, d7
  MEMACCESS(1)
  vst1.8     {d4}, [r2]!
  MEMACCESS(1)
  vst1.32    {d5[0]}, [r2]!
  bgt        %b1

  vpop      {d0-d5}
  pop       {r4}
  bx        lr
  ENDP

ScaleRowDown38_3_Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush     {q0-q3}
  vpush     {q8, q9}
  vpush     {q13-q15}
  push      {r4-r7}
  add       r4, r0, r1
  add       r4, r4, r1      ; src_ptr + src_stride * 2
  adr       r5, kMult38_Div6
  adr       r6, kShuf38_2
  adr       r7, kMult38_Div9

  MEMACCESS  5
  vld1.16    {q13}, [r5]
  MEMACCESS  6
  vld1.8     {q14}, [r6]
  MEMACCESS  7
  vld1.8     {q15}, [r7]
  add        r1, r0
1
  ; d0 = 00 40 01 41 02 42 03 43
  ; d1 = 10 50 11 51 12 52 13 53
  ; d2 = 20 60 21 61 22 62 23 63
  ; d3 = 30 70 31 71 32 72 33 73
  MEMACCESS    0
  vld4.8       {d0, d1, d2, d3}, [r0]!
  MEMACCESS    3
  vld4.8       {d4, d5, d6, d7}, [r1]!
  MEMACCESS    4
  vld4.8       {d16, d17, d18, d19}, [r4]!
  subs         r3, r3, #12

  ; Shuffle the input data around to get align the data
  ;  so adjacent data can be added. 0,1 - 2,3 - 4,5 - 6,7
  ; d0 = 00 10 01 11 02 12 03 13
  ; d1 = 40 50 41 51 42 52 43 53
  vtrn.u8      d0, d1
  vtrn.u8      d4, d5
  vtrn.u8      d16, d17

  ; d2 = 20 30 21 31 22 32 23 33
  ; d3 = 60 70 61 71 62 72 63 73
  vtrn.u8      d2, d3
  vtrn.u8      d6, d7
  vtrn.u8      d18, d19

  ; d0 = 00+10 01+11 02+12 03+13
  ; d2 = 40+50 41+51 42+52 43+53
  vpaddl.u8    q0, q0
  vpaddl.u8    q2, q2
  vpaddl.u8    q8, q8

  ; d3 = 60+70 61+71 62+72 63+73
  vpaddl.u8    d3, d3
  vpaddl.u8    d7, d7
  vpaddl.u8    d19, d19

  ; combine source lines
  vadd.u16     q0, q2
  vadd.u16     q0, q8
  vadd.u16     d4, d3, d7
  vadd.u16     d4, d19

  ; dst_ptr[3] = (s[6 + st * 0] + s[7 + st * 0]
  ;             + s[6 + st * 1] + s[7 + st * 1]
  ;             + s[6 + st * 2] + s[7 + st * 2]) / 6
  vqrdmulh.s16 q2, q2, q13
  vmovn.u16    d4, q2

  ; Shuffle 2,3 reg around so that 2 can be added to the
  ;  0,1 reg and 3 can be added to the 4,5 reg. This
  ;  requires expanding from u8 to u16 as the 0,1 and 4,5
  ;  registers are already expanded. Then do transposes
  ;  to get aligned.
  ; q2 = xx 20 xx 30 xx 21 xx 31 xx 22 xx 32 xx 23 xx 33
  vmovl.u8     q1, d2
  vmovl.u8     q3, d6
  vmovl.u8     q9, d18

  ; combine source lines
  vadd.u16     q1, q3
  vadd.u16     q1, q9

  ; d4 = xx 20 xx 30 xx 22 xx 32
  ; d5 = xx 21 xx 31 xx 23 xx 33
  vtrn.u32     d2, d3

  ; d4 = xx 20 xx 21 xx 22 xx 23
  ; d5 = xx 30 xx 31 xx 32 xx 33
  vtrn.u16     d2, d3

  ; 0+1+2, 3+4+5
  vadd.u16     q0, q1

  ; Need to divide, but can't downshift as the the value
  ;  isn't a power of 2. So multiply by 65536 / n
  ;  and take the upper 16 bits.
  vqrdmulh.s16 q0, q0, q15

  ; Align for table lookup, vtbl requires registers to
  ;  be adjacent
  vmov.u8      d2, d4

  vtbl.u8      d3, {d0, d1, d2}, d28
  vtbl.u8      d4, {d0, d1, d2}, d29

  MEMACCESS    1
  vst1.8       {d3}, [r2]!
  MEMACCESS    1
  vst1.32      {d4[0]}, [r2]!
  bgt          %b1

  pop       {r4-r7}
  vpop      {q13-q15}
  vpop      {q8, q9}
  vpop      {q0-q3}
  bx        lr
  ENDP

ScaleRowDown38_2_Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint8* dst_ptr
  ;     r3 = int dst_width
  vpush     {q0-q3}
  vpush     {q13-q14}
  push      {r4, r5}
  adr       r4, kMult38_Div6
  adr       r5, kShuf38_2

  MEMACCESS    4
  vld1.16      {q13}, [r4]
  MEMACCESS    5
  vld1.8       {q14}, [r5]
  add          r1, r0
1
  ; d0 = 00 40 01 41 02 42 03 43
  ; d1 = 10 50 11 51 12 52 13 53
  ; d2 = 20 60 21 61 22 62 23 63
  ; d3 = 30 70 31 71 32 72 33 73
  MEMACCESS    0
  vld4.8       {d0, d1, d2, d3}, [r0]!
  MEMACCESS    3
  vld4.8       {d4, d5, d6, d7}, [r1]!
  subs         r3, r3, #12

  ; Shuffle the input data around to get align the data
  ;  so adjacent data can be added. 0,1 - 2,3 - 4,5 - 6,7
  ; d0 = 00 10 01 11 02 12 03 13
  ; d1 = 40 50 41 51 42 52 43 53
  vtrn.u8      d0, d1
  vtrn.u8      d4, d5

  ; d2 = 20 30 21 31 22 32 23 33
  ; d3 = 60 70 61 71 62 72 63 73
  vtrn.u8      d2, d3
  vtrn.u8      d6, d7

  ; d0 = 00+10 01+11 02+12 03+13
  ; d2 = 40+50 41+51 42+52 43+53
  vpaddl.u8    q0, q0
  vpaddl.u8    q2, q2

  ; d3 = 60+70 61+71 62+72 63+73
  vpaddl.u8    d3, d3
  vpaddl.u8    d7, d7

  ; combine source lines
  vadd.u16     q0, q2
  vadd.u16     d4, d3, d7

  ; dst_ptr[3] = (s[6] + s[7] + s[6+st] + s[7+st]) / 4
  vqrshrn.u16  d4, q2, #2

  ; Shuffle 2,3 reg around so that 2 can be added to the
  ;  0,1 reg and 3 can be added to the 4,5 reg. This
  ;  requires expanding from u8 to u16 as the 0,1 and 4,5
  ;  registers are already expanded. Then do transposes
  ;  to get aligned.
  ; q2 = xx 20 xx 30 xx 21 xx 31 xx 22 xx 32 xx 23 xx 33
  vmovl.u8     q1, d2
  vmovl.u8     q3, d6

  ; combine source lines
  vadd.u16     q1, q3

  ; d4 = xx 20 xx 30 xx 22 xx 32
  ; d5 = xx 21 xx 31 xx 23 xx 33
  vtrn.u32     d2, d3

  ; d4 = xx 20 xx 21 xx 22 xx 23
  ; d5 = xx 30 xx 31 xx 32 xx 33
  vtrn.u16     d2, d3

  ; 0+1+2, 3+4+5
  vadd.u16     q0, q1

  ; Need to divide, but can't downshift as the the value
  ;  isn't a power of 2. So multiply by 65536 / n
  ;  and take the upper 16 bits.
  vqrdmulh.s16 q0, q0, q13

  ; Align for table lookup, vtbl requires registers to
  ;  be adjacent
  vmov.u8      d2, d4

  vtbl.u8      d3, {d0, d1, d2}, d28
  vtbl.u8      d4, {d0, d1, d2}, d29

  MEMACCESS    1
  vst1.8       {d3}, [r2]!
  MEMACCESS    1
  vst1.32      {d4[0]}, [r2]!
  bgt          %b1

  pop       {r4, r5}
  vpop      {q13-q14}
  vpop      {q0-q3}
  bx        lr
  ENDP

ScaleAddRows_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = src_stride
  ;     r2 = uint16* dst_ptr
  ;     r3 = int dst_width
  push      {r4, r5,  r12}
  ldr       r4, [SP, #12]    ; int src_height
  mov       r5, 0
  vpush     {q0-q3}

1
  mov       r5, r0
  mov       r12, r4
  veor      q2, q2, q2
  veor      q3, q3, q3
2
  ; load 16 pixels into q0
  MEMACCESS   0
  vld1.8     {q0}, [r5], r1
  vaddw.u8   q3, q3, d1
  vaddw.u8   q2, q2, d0
  subs       r12, r12, #1
  bgt        %b2
  MEMACCESS  2
  vst1.16    {q2, q3}, [r2]!                  ; store pixels
  add        r0, r0, #16
  subs       r3, r3, #16                      ; 16 processed per loop
  bgt        %b1

  vpop      {q0-q3}
  pop       {r4, r5, r12}
  bx        lr
  ENDP

; TODO(Yang Zhang): Investigate less load instructions for
; the x/dx stepping
  MACRO
  LOAD2_DATA8_LANE  $n
  lsr        r5, r3, #16
  add        r6, r1, r5
  add        r3, r3, r4
  MEMACCESS  6
  vld2.8     {d6[$n], d7[$n]}, [r6]
  MEND

dx_offset DCD  0, 1, 2, 3

; The NEON version mimics this formula:
; #define BLENDER(a, b, f) (uint8)((int)(a) +
;    ((int)(f) * ((int)(b) - (int)(a)) >> 16))

ScaleFilterCols_NEON PROC
  ; input
  ;     r0 = uint8* dst_ptr
  ;     r1 = uint8* src_ptr
  ;     r2 = int dst_width
  ;     r3 = int x

  push       {r4-r6}

  ldr        r4, [sp, #12]   ; int dx
  adr        r5,  dx_offset
  mov        r6,  r1

  vpush      {q0-q3}
  vpush      {q8-q13}

  vdup.32    q0, r3                           ; x
  vdup.32    q1, r4                           ; dx
  vld1.32    {q2}, [r5]                       ; 0 1 2 3
  vshl.i32   q3, q1, #2                       ; 4 * dx
  vmul.s32   q1, q1, q2
  ; x         , x + 1 * dx, x + 2 * dx, x + 3 * dx
  vadd.s32   q1, q1, q0
  ; x + 4 * dx, x + 5 * dx, x + 6 * dx, x + 7 * dx
  vadd.s32   q2, q1, q3
  vshl.i32   q0, q3, #1                       ; 8 * dx
1
  LOAD2_DATA8_LANE  0
  LOAD2_DATA8_LANE  1
  LOAD2_DATA8_LANE  2
  LOAD2_DATA8_LANE  3
  LOAD2_DATA8_LANE  4
  LOAD2_DATA8_LANE  5
  LOAD2_DATA8_LANE  6
  LOAD2_DATA8_LANE  7
  vmov       q10, q1
  vmov       q11, q2
  vuzp.16    q10, q11
  vmovl.u8   q8, d6
  vmovl.u8   q9, d7
  vsubl.s16  q11, d18, d16
  vsubl.s16  q12, d19, d17
  vmovl.u16  q13, d20
  vmovl.u16  q10, d21
  vmul.s32   q11, q11, q13
  vmul.s32   q12, q12, q10
  vrshrn.s32  d18, q11, #16
  vrshrn.s32  d19, q12, #16
  vadd.s16   q8, q8, q9
  vmovn.s16  d6, q8

  MEMACCESS  0
  vst1.8     {d6}, [r0]!                      ; store pixels
  vadd.s32   q1, q1, q0
  vadd.s32   q2, q2, q0
  subs       r2, r2, #8                       ; 8 processed per loop
  bgt        %b1

  vpop       {q8-q13}
  vpop       {q0-q3}
  pop        {r4-r6}
  bx         lr
  ENDP

ScaleARGBRowDown2_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = ptrdiff_t src_stride
  ;     r2 = uint8* dst
  ;     r3 = int dst_width
  vpush      {q0 - q3}
1
  ; load even pixels into q0, odd into q1
  MEMACCESS  0
  vld2.32    {q0, q1}, [r0]!
  MEMACCESS  0
  vld2.32    {q2, q3}, [r0]!
  subs       r3, r3, #8               ; 8 processed per loop
  MEMACCESS  1
  vst1.8     {q1}, [r2]!              ; store odd pixels
  MEMACCESS  1
  vst1.8     {q3}, [r2]!
  bgt        %b1
  vpop       {q0 - q3}
  bx         lr
  ENDP



ScaleARGBRowDown2Linear_NEON PROC
  ; input
  ;     r0 = uint8* src_argb
  ;     r1 = ptrdiff_t src_stride
  ;     r2 = uint8* dst_argb
  ;     r3 = int dst_width
  vpush      {q0 - q3}
1
  MEMACCESS  0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS  0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop
  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.
  vpaddl.u8  q3, q3                           ; A 16 bytes -> 8 shorts.
  vrshrn.u16 d0, q0, #1                       ; downshift, round and pack
  vrshrn.u16 d1, q1, #1
  vrshrn.u16 d2, q2, #1
  vrshrn.u16 d3, q3, #1
  MEMACCESS  1
  vst4.8     {d0, d1, d2, d3}, [r2]!
  bgt        %b1


  vpop       {q0 - q3}
  bx         lr
  ENDP

ScaleARGBRowDown2Box_NEON PROC
  ; input
  ;     r0 = uint8* src_ptr
  ;     r1 = ptrdiff_t src_stride
  ;     r2 = uint8* dst
  ;     r3 = int dst_width
  vpush      {q0 - q3}
  vpush      {q8 - q11}
  ; change the stride to row 2 pointer
  add        r1, r1, r0

1
  MEMACCESS  0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 argb pixels.
  MEMACCESS  0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 argb pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vpaddl.u8  q0, q0                           ; b 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; g 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; r 16 bytes -> 8 shorts.
  vpaddl.u8  q3, q3                           ; a 16 bytes -> 8 shorts.
  MEMACCESS  1
  vld4.8     {d16, d18, d20, d22}, [r1]!      ; load 8 more argb pixels.
  MEMACCESS  1
  vld4.8     {d17, d19, d21, d23}, [r1]!      ; load last 8 argb pixels.
  vpadal.u8  q0, q8                           ; b 16 bytes -> 8 shorts.
  vpadal.u8  q1, q9                           ; g 16 bytes -> 8 shorts.
  vpadal.u8  q2, q10                          ; r 16 bytes -> 8 shorts.
  vpadal.u8  q3, q11                          ; a 16 bytes -> 8 shorts.
  vrshrn.u16 d0, q0, #2                       ; downshift, round and pack
  vrshrn.u16 d1, q1, #2
  vrshrn.u16 d2, q2, #2
  vrshrn.u16 d3, q3, #2
  MEMACCESS  2
  vst4.8     {d0, d1, d2, d3}, [r2]!
  bgt        %b1

  vpop       {q8 - q11}
  vpop       {q0 - q3}
  bx         lr
  ENDP

ScaleARGBRowDownEven_NEON PROC
  ; input
  ;     r0 = uint8* src_argb
  ;     r1 = ptrdiff_t src_stride
  ;     r2 = int src_stepx
  ;     r3 =  uint8* dst_argb
  push      {r4, r12}
  ldr       r4, [sp, #8]   ;int dst_width
  vpush     {q0}

  mov        r12, r2, lsl #2
1
  MEMACCESS  0
  vld1.32    {d0[0]}, [r0], r12
  MEMACCESS  0
  vld1.32    {d0[1]}, [r0], r12
  MEMACCESS  0
  vld1.32    {d1[0]}, [r0], r12
  MEMACCESS  0
  vld1.32    {d1[1]}, [r0], r12
  subs       r4, r4, #4                       ; 4 pixels per loop.
  MEMACCESS  1
  vst1.8     {q0}, [r3]!
  bgt        %b1

  vpop      {q0}
  pop       {r4, r12}
  bx         lr
  ENDP

ScaleARGBRowDownEvenBox_NEON PROC
  ; input
  ;     r0 = uint8* src_argb
  ;     r1 = ptrdiff_t src_stride
  ;     r2 = int src_stepx
  ;     r3 =  uint8* dst_argb
  push      {r4, r12}
  ldr       r4, [sp, #8]   ;int dst_width
  vpush     {q0 - q3}

  mov        r12, r2, lsl #2
  add        r1, r1, r0
1
  MEMACCESS  0
  vld1.8     {d0}, [r0], r12                  ; Read 4 2x2 blocks -> 2x1
  MEMACCESS  1
  vld1.8     {d1}, [r1], r12
  MEMACCESS  0
  vld1.8     {d2}, [r0], r12
  MEMACCESS  1
  vld1.8     {d3}, [r1], r12
  MEMACCESS  0
  vld1.8     {d4}, [r0], r12
  MEMACCESS  1
  vld1.8     {d5}, [r1], r12
  MEMACCESS  0
  vld1.8     {d6}, [r0], r12
  MEMACCESS  1
  vld1.8     {d7}, [r1], r12
  vaddl.u8   q0, d0, d1
  vaddl.u8   q1, d2, d3
  vaddl.u8   q2, d4, d5
  vaddl.u8   q3, d6, d7
  vswp.8     d1, d2                           ; ab_cd -> ac_bd
  vswp.8     d5, d6                           ; ef_gh -> eg_fh
  vadd.u16   q0, q0, q1                       ; (a+b)_(c+d)
  vadd.u16   q2, q2, q3                       ; (e+f)_(g+h)
  vrshrn.u16 d0, q0, #2                       ; first 2 pixels.
  vrshrn.u16 d1, q2, #2                       ; next 2 pixels.
  subs       r4, r4, #4                       ; 4 pixels per loop.
  MEMACCESS  2
  vst1.8     {q0}, [r3]!
  bgt        %b1

  vpop      {q0 - q3}
  pop       {r4, r12}
  bx         lr
  ENDP

  ; TODO(Yang Zhang): Investigate less load instructions for
  ; the x/dx stepping
  MACRO
  LOAD1_DATA32_LANE $dn,  $n
  lsr        r5, r3, #16
  add        r6, r1, r5, lsl #2
  add        r3, r3, r4
  MEMACCESS  6
  vld1.32    {$dn[$n]}, [r6]
  MEND

ScaleARGBCols_NEON PROC
  ; input
  ;     r0 = uint8* dst_argb
  ;     r1 = const uint8* src_argb
  ;     r2 = int dst_width
  ;     r3 = int x
  push       {r4 - r6}
  ldr        r4, [sp,#12]    ; int dx
  mov        r6, r1
  vpush      {q0, q1}

1
  LOAD1_DATA32_LANE d0, 0
  LOAD1_DATA32_LANE d0, 1
  LOAD1_DATA32_LANE d1, 0
  LOAD1_DATA32_LANE d1, 1
  LOAD1_DATA32_LANE d2, 0
  LOAD1_DATA32_LANE d2, 1
  LOAD1_DATA32_LANE d3, 0
  LOAD1_DATA32_LANE d3, 1

  MEMACCESS	0
  vst1.32     {q0, q1}, [r0]!                 ; store pixels
  subs       r2, r2, #8                       ; 8 processed per loop
  bgt        %b1


  vpop       {q0, q1}
  pop        {r4 - r6}
  bx         lr
  ENDP

  ; TODO(Yang Zhang): Investigate less load instructions for
  ; the x/dx stepping
  MACRO
  LOAD2_DATA32_LANE $dn1, $dn2,  $n
  lsr        r5, r3, #16
  add        r6, r1, r5, lsl #2
  add        r3, r3, r4
  MEMACCESS  6
  vld2.32    {$dn1[$n], $dn2[$n]}, [r6]
  MEND

ScaleARGBFilterCols_NEON PROC
  ; input
  ;     r0 = uint8* dst_argb
  ;     r1 = const uint8* src_argb
  ;     r2 = int dst_width
  ;     r3 = int x

  push       {r4 - r6}
  ldr        r4, [sp,#12]    ;int dx
  adr        r5,  dx_offset
  mov        r6, r1
  vpush      {q0 - q3}
  vpush      {q8 - q15}

  vdup.32    q0, r3                           ; x
  vdup.32    q1, r4                           ; dx
  vld1.32    {q2}, [r5]                       ; 0 1 2 3
  vshl.i32   q9, q1, #2                       ; 4 * dx
  vmul.s32   q1, q1, q2
  vmov.i8    q3, #0x7f                        ; 0x7F
  vmov.i16   q15, #0x7f                       ; 0x7F
  ; x         , x + 1 * dx, x + 2 * dx, x + 3 * dx
  vadd.s32   q8, q1, q0
1
  ; d0, d1: a
  ; d2, d3: b
  LOAD2_DATA32_LANE d0, d2, 0
  LOAD2_DATA32_LANE d0, d2, 1
  LOAD2_DATA32_LANE d1, d3, 0
  LOAD2_DATA32_LANE d1, d3, 1
  vshrn.i32   d22, q8, #9
  vand.16     d22, d22, d30
  vdup.8      d24, d22[0]
  vdup.8      d25, d22[2]
  vdup.8      d26, d22[4]
  vdup.8      d27, d22[6]
  vext.8      d4, d24, d25, #4
  vext.8      d5, d26, d27, #4                ; f
  veor.8      q10, q2, q3                     ; 0x7f ^ f
  vmull.u8    q11, d0, d20
  vmull.u8    q12, d1, d21
  vmull.u8    q13, d2, d4
  vmull.u8    q14, d3, d5
  vadd.i16    q11, q11, q13
  vadd.i16    q12, q12, q14
  vshrn.i16   d0, q11, #7
  vshrn.i16   d1, q12, #7

  MEMACCESS	  0
  vst1.32     {d0, d1}, [r0]!                 ; store pixels
  vadd.s32    q8, q8, q9
  subs        r2, r2, #4                      ; 4 processed per loop
  bgt         %b1

  vpop       {q8 - q15}
  vpop       {q0 - q3}
  pop        {r4 - r6}
  bx         lr
  ENDP

  END



