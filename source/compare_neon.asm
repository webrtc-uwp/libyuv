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

  EXPORT HammingDistance_NEON
  EXPORT SumSquareError_NEON

HammingDistance_NEON PROC
  ; input
  ;   r0 = src_a
  ;   r1 = src_b
  ;   r2 = count
  ; output
  ;   r0 = uint32
  push        {r3}
  vpush       {q0-q4}
  vpush       {d0-d1}

  vmov.u16    q4, #0  ; accumulator

1
  vld1.8      {q0, q1}, [r0]!
  vld1.8      {q2, q3}, [r1]!
  veor.32    q0, q0, q2
  veor.32    q1, q1, q3
  vcnt.i8    q0, q0
  vcnt.i8    q1, q1
  subs       r2, r2, #32
  vadd.u8    q0, q0, q1                     ; 16 byte counts
  vpadal.u8  q4, q0                         ; 8 shorts
  bgt        %b1

  vpaddl.u16 q0, q4                         ; 4 ints
  vpadd.u32  d0, d0, d1
  vpadd.u32  d0, d0, d0
  vmov.32    r3, d0[0]

  pop         {r3}
  vpop        {d0-d1}
  vpop        {q0-q4}

  ENDP

SumSquareError_NEON PROC
  ; input
  ;		r0 = uint8* src_a
  ;		r1 = uint8* src_b
  ;		r3 = int count
  ; output
  ;	  r0 = uint32
  vpush			 {q0, q1, q2, q3}
  vpush			 {q8, q9, q10, q11}

  vmov.u8    q8, #0
  vmov.u8    q10, #0
  vmov.u8    q9, #0
  vmov.u8    q11, #0
1
  vld1.8     {q0}, [r0]!
  vld1.8     {q1}, [r1]!
  subs       r2, r2, #16
  vsubl.u8   q2, d0, d2
  vsubl.u8   q3, d1, d3
  vmlal.s16  q8, d4, d4
  vmlal.s16  q9, d6, d6
  vmlal.s16  q10, d5, d5
  vmlal.s16  q11, d7, d7
  bgt				 %b1

  vadd.u32   q8, q8, q9
  vadd.u32   q10, q10, q11
  vadd.u32   q11, q8, q10
  vpaddl.u32 q1, q11
  vadd.u64   d0, d2, d3
  vmov.32    r0, d0[0]
  vpop			 {q8, q9, q10, q11}
  vpop			 {q0, q1, q2, q3}
  bx				 lr
  ENDP

  END
