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

  EXPORT TransposeWx8_NEON
  EXPORT TransposeUVWx8_NEON

kVTbl4x4Transpose	DCB	0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15
kVTbl4x4TransposeDi DCB 0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15

TransposeWx8_NEON PROC
  ; input
  ;		r0 = uint8* src
  ;		r1 = int src_stride
  ;		r2 = uint8* dst
  ;		r3 = int dst_stride

  push      {r4-r6}
  ldr       r4, [sp, #12] ; load parameter int width 
  adr       R6, kVTbl4x4Transpose
  vpush     {q0, q1, q2, q3}
  
  ; loops are on blocks of 8. loop will stop when
  ; counter gets to or below 0. starting the counter
  ; at w-8 allow for this
  sub         r4, #8

  ; handle 8x8 blocks. this should be the majority of the plane
1
  mov         r5, r0

  MEMACCESS		0 
  vld1.8      {d0}, [r5], r1
  MEMACCESS     0
  vld1.8      {d1}, [r5], r1
  MEMACCESS     0
  vld1.8      {d2}, [r5], r1
  MEMACCESS     0
  vld1.8      {d3}, [r5], r1
  MEMACCESS     0
  vld1.8      {d4}, [r5], r1
  MEMACCESS     0
  vld1.8      {d5}, [r5], r1
  MEMACCESS     0
  vld1.8      {d6}, [r5], r1
  MEMACCESS     0
  vld1.8      {d7}, [r5]

  vtrn.8      d1, d0
  vtrn.8      d3, d2
  vtrn.8      d5, d4
  vtrn.8      d7, d6

  vtrn.16     d1, d3
  vtrn.16     d0, d2
  vtrn.16     d5, d7
  vtrn.16     d4, d6

  vtrn.32     d1, d5
  vtrn.32     d0, d4
  vtrn.32     d3, d7
  vtrn.32     d2, d6

  vrev16.8    q0, q0
  vrev16.8    q1, q1
  vrev16.8    q2, q2
  vrev16.8    q3, q3

  mov         r5, r2

  MEMACCESS     0
  vst1.8      {d1}, [r5], r3
  MEMACCESS     0
  vst1.8      {d0}, [r5], r3
  MEMACCESS     0
  vst1.8      {d3}, [r5], r3
  MEMACCESS     0
  vst1.8      {d2}, [r5], r3
  MEMACCESS     0
  vst1.8      {d5}, [r5], r3
  MEMACCESS     0
  vst1.8      {d4}, [r5], r3
  MEMACCESS     0
  vst1.8      {d7}, [r5], r3
  MEMACCESS     0
  vst1.8      {d6}, [r5]

  add         r0, #8              ; src += 8
  add         r2, r2, r3, lsl #3  ; dst += 8 * dst_stride
  subs        r4,  #8             ;   -= 8
  bge         %b1

  ; add 8 back to counter. if the result is 0 there are
  ; no residuals.
  adds        r4, #8
  beq         %f4

  ; some residual, so between 1 and 7 lines left to transpose
  cmp         r4, #2
  blt         %f3

  cmp         r4, #4
  blt         %f2

  ; 4x8 block
  mov         r5, r0
  MEMACCESS     0
  vld1.32     {d0[0]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d0[1]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d1[0]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d1[1]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d2[0]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d2[1]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d3[0]}, [r5], r1
  MEMACCESS     0
  vld1.32     {d3[1]}, [r5]

  mov         r5, r2

  MEMACCESS(6)
  vld1.8      {q3}, [r6]

  vtbl.8      d4, {d0, d1}, d6
  vtbl.8      d5, {d0, d1}, d7
  vtbl.8      d0, {d2, d3}, d6
  vtbl.8      d1, {d2, d3}, d7

  ; TODO(frkoenig): Rework shuffle above to
  ; write out with 4 instead of 8 writes.
  MEMACCESS     0
  vst1.32     {d4[0]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d4[1]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d5[0]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d5[1]}, [r5]

  add         r5, r2, #4
  MEMACCESS     0
  vst1.32     {d0[0]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d0[1]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d1[0]}, [r5], r3
  MEMACCESS     0
  vst1.32     {d1[1]}, [r5]

  add         r0, #4              ; src += 4
  add         r2, r2, r3, lsl #2  ; dst += 4 * dst_stride
  subs        r4,  #4             ; w   -= 4
  beq         %f4

  ; some residual, check to see if it includes a 2x8 block,
  ; or less
  cmp         r4, #2
  blt         %f3

  ; 2x8 block
2
  mov         r5, r0
  MEMACCESS     0
  vld1.16     {d0[0]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d1[0]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d0[1]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d1[1]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d0[2]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d1[2]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d0[3]}, [r5], r1
  MEMACCESS     0
  vld1.16     {d1[3]}, [r5]

  vtrn.8      d0, d1

  mov         r5, r2

  MEMACCESS     0
  vst1.64     {d0}, [r5], r3
  MEMACCESS     0
  vst1.64     {d1}, [r5]

  add         r0, #2               ; src += 2
  add         r2, r2, r3, lsl #1   ; dst += 2 * dst_stride
  subs        r4,  #2              ; w   -= 2
  beq         %f4

  ; 1x8 block
3
  MEMACCESS    1
  vld1.8      {d0[0]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[1]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[2]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[3]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[4]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[5]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[6]}, [r0], r1
  MEMACCESS    1
  vld1.8      {d0[7]}, [r0]

  MEMACCESS(3)
  vst1.64     {d0}, [r2]

4
  vpop        {q0, q1, q2, q3}
  pop         {r4-r6}
  bx          lr
  ENDP

TransposeUVWx8_NEON PROC
  ; input
  ;		r0 = uint8* src
  ;		r1 = int src_stride
  ;		r2 = uint8* dst_a
  ;		r3 = int dst_stride_a
  push      {r4-r8}
  ldr       r5, [sp, #20] ; load uint8* dst_b 
  ldr       r6, [sp, #24] ; int dst_stride_b
  ldr       r7, [sp, #28] ; int width
  adr       R8, kVTbl4x4TransposeDi
  vpush     {q0, q1, q2, q3}
  vpush     {q8, q9, q10, q11}
  
  ; loops are on blocks of 8. loop will stop when
  ; counter gets to or below 0. starting the counter
  ; at w-8 allow for this
  sub         r7, #8

  ; handle 8x8 blocks. this should be the majority of the plane
1
  mov         r4, r0

  MEMACCESS   0
  vld2.8      {d0,  d1},  [r4], r1
  MEMACCESS   0
  vld2.8      {d2,  d3},  [r4], r1
  MEMACCESS   0
  vld2.8      {d4,  d5},  [r4], r1
  MEMACCESS   0
  vld2.8      {d6,  d7},  [r4], r1
  MEMACCESS   0
  vld2.8      {d16, d17}, [r4], r1
  MEMACCESS   0
  vld2.8      {d18, d19}, [r4], r1
  MEMACCESS   0
  vld2.8      {d20, d21}, [r4], r1
  MEMACCESS   0
  vld2.8      {d22, d23}, [r4]

  vtrn.8      q1, q0
  vtrn.8      q3, q2
  vtrn.8      q9, q8
  vtrn.8      q11, q10

  vtrn.16     q1, q3
  vtrn.16     q0, q2
  vtrn.16     q9, q11
  vtrn.16     q8, q10

  vtrn.32     q1, q9
  vtrn.32     q0, q8
  vtrn.32     q3, q11
  vtrn.32     q2, q10

  vrev16.8    q0, q0
  vrev16.8    q1, q1
  vrev16.8    q2, q2
  vrev16.8    q3, q3
  vrev16.8    q8, q8
  vrev16.8    q9, q9
  vrev16.8    q10, q10
  vrev16.8    q11, q11

  mov         r4, r2

  MEMACCESS   0
  vst1.8      {d2},  [r4], r3
  MEMACCESS   0
  vst1.8      {d0},  [r4], r3
  MEMACCESS   0
  vst1.8      {d6},  [r4], r3
  MEMACCESS   0
  vst1.8      {d4},  [r4], r3
  MEMACCESS   0
  vst1.8      {d18}, [r4], r3
  MEMACCESS   0
  vst1.8      {d16}, [r4], r3
  MEMACCESS   0
  vst1.8      {d22}, [r4], r3
  MEMACCESS   0
  vst1.8      {d20}, [r4]

  mov         r4, r5

  MEMACCESS   0
  vst1.8      {d3},  [r4], r6
  MEMACCESS   0
  vst1.8      {d1},  [r4], r6
  MEMACCESS   0
  vst1.8      {d7},  [r4], r6
  MEMACCESS   0
  vst1.8      {d5},  [r4], r6
  MEMACCESS   0
  vst1.8      {d19}, [r4], r6
  MEMACCESS   0
  vst1.8      {d17}, [r4], r6
  MEMACCESS   0
  vst1.8      {d23}, [r4], r6
  MEMACCESS   0
  vst1.8      {d21}, [r4]

  add         r0, #8*2                      ; src   += 8*2
  add         r2, r2, r3, lsl #3            ; dst_a += 8 * dst_stride_a
  add         r5, r5, r6, lsl #3            ; dst_b += 8 * dst_stride_b
  subs        r7,  #8                       ; w     -= 8
  bge         %b1

  ; add 8 back to counter. if the result is 0 there are
  ; no residuals.
  adds        r7, #8
  beq         %f4

  ; some residual, so between 1 and 7 lines left to transpose
  cmp         r7, #2
  blt         %f3

  cmp         r7, #4
  blt         %f2

  ; TODO(frkoenig): Clean this up
  ; 4x8 block
  mov         r4, r0
  MEMACCESS   0
  vld1.64     {d0}, [r4], r1
  MEMACCESS   0
  vld1.64     {d1}, [r4], r1
  MEMACCESS   0
  vld1.64     {d2}, [r4], r1
  MEMACCESS   0
  vld1.64     {d3}, [r4], r1
  MEMACCESS   0
  vld1.64     {d4}, [r4], r1
  MEMACCESS   0
  vld1.64     {d5}, [r4], r1
  MEMACCESS   0
  vld1.64     {d6}, [r4], r1
  MEMACCESS   0
  vld1.64     {d7}, [r4]

  MEMACCESS		8
  vld1.8      {q15}, [r8]

  vtrn.8      q0, q1
  vtrn.8      q2, q3

  vtbl.8      d16, {d0, d1}, d30
  vtbl.8      d17, {d0, d1}, d31
  vtbl.8      d18, {d2, d3}, d30
  vtbl.8      d19, {d2, d3}, d31
  vtbl.8      d20, {d4, d5}, d30
  vtbl.8      d21, {d4, d5}, d31
  vtbl.8      d22, {d6, d7}, d30
  vtbl.8      d23, {d6, d7}, d31

  mov         r4, r2

  MEMACCESS   0
  vst1.32     {d16[0]},  [r4], r3
  MEMACCESS   0
  vst1.32     {d16[1]},  [r4], r3
  MEMACCESS   0
  vst1.32     {d17[0]},  [r4], r3
  MEMACCESS   0
  vst1.32     {d17[1]},  [r4], r3

  add         r4, r2, #4
  MEMACCESS   0
  vst1.32     {d20[0]}, [r4], r3
  MEMACCESS   0
  vst1.32     {d20[1]}, [r4], r3
  MEMACCESS   0
  vst1.32     {d21[0]}, [r4], r3
  MEMACCESS   0
  vst1.32     {d21[1]}, [r4]

  mov         r4, r5

  MEMACCESS   0
  vst1.32     {d18[0]}, [r4], r6
  MEMACCESS   0
  vst1.32     {d18[1]}, [r4], r6
  MEMACCESS   0
  vst1.32     {d19[0]}, [r4], r6
  MEMACCESS   0
  vst1.32     {d19[1]}, [r4], r6

  add         r4, r5, #4
  MEMACCESS   0
  vst1.32     {d22[0]},  [r4], r6
  MEMACCESS   0
  vst1.32     {d22[1]},  [r4], r6
  MEMACCESS   0
  vst1.32     {d23[0]},  [r4], r6
  MEMACCESS   0
  vst1.32     {d23[1]},  [r4]

  add         r0, #4*2                        ; src   += 4 * 2
  add         r2, r2, r3, lsl #2              ; dst_a += 4 * dst_stride_a
  add         r5, r5, r6, lsl #2              ; dst_b += 4 * dst_stride_b
  subs        r7,  #4                         ; w     -= 4
  beq         %f4

  ; some residual, check to see if it includes a 2x8 block,
  ; or less
  cmp         r7, #2
  blt         %f3

  ; 2x8 block
2
  mov         r4, r0
  MEMACCESS   0
  vld2.16     {d0[0], d2[0]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d1[0], d3[0]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d0[1], d2[1]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d1[1], d3[1]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d0[2], d2[2]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d1[2], d3[2]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d0[3], d2[3]}, [r4], r1
  MEMACCESS   0
  vld2.16     {d1[3], d3[3]}, [r4]

  vtrn.8      d0, d1
  vtrn.8      d2, d3

  mov         r4, r2

  MEMACCESS   0
  vst1.64     {d0}, [r4], r3
  MEMACCESS   0
  vst1.64     {d2}, [r4]

  mov         r4, r5

  MEMACCESS   0
  vst1.64     {d1}, [r4], r6
  MEMACCESS   0
  vst1.64     {d3}, [r4]

  add         r0, #2*2                        ; src   += 2 * 2
  add         r2, r2, r3, lsl #1              ; dst_a += 2 * dst_stride_a
  add         r5, r5, r6, lsl #1              ; dst_b += 2 * dst_stride_b
  subs        r7,  #2                         ; w     -= 2
  beq         %f4

  ; 1x8 block
3
  MEMACCESS    1
  vld2.8      {d0[0], d1[0]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[1], d1[1]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[2], d1[2]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[3], d1[3]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[4], d1[4]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[5], d1[5]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[6], d1[6]}, [r0], r1
  MEMACCESS    1
  vld2.8      {d0[7], d1[7]}, [r0]

  MEMACCESS(3)
  vst1.64     {d0}, [r2]
  MEMACCESS(5)
  vst1.64     {d1}, [r5]
4

  vpop        {q8, q9, q10, q11}
  vpop        {q0, q1, q2, q3}
  pop         {r4-r8}
  bx          lr
  ENDP

  END



