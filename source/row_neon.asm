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

  EXPORT I444ToARGBRow_NEON
  EXPORT I422ToARGBRow_NEON
  EXPORT I411ToARGBRow_NEON
  EXPORT I422ToBGRARow_NEON
  EXPORT I422ToABGRRow_NEON
  EXPORT I422AlphaToARGBRow_NEON
  EXPORT I422ToRGB24Row_NEON
  EXPORT I422ToRAWRow_NEON
  EXPORT I422ToRGBARow_NEON
  EXPORT I422ToARGB4444Row_NEON
  EXPORT I422ToARGB1555Row_NEON
  EXPORT I422ToRGB565Row_NEON
  EXPORT I400ToARGBRow_NEON
  EXPORT J400ToARGBRow_NEON
  EXPORT ARGBToRGB24Row_NEON
  EXPORT RAWToRGB24Row_NEON
  EXPORT ARGBToRAWRow_NEON
  EXPORT ARGBToRGB565Row_NEON
  EXPORT ARGBToARGB1555Row_NEON
  EXPORT YUY2ToARGBRow_NEON
  EXPORT UYVYToARGBRow_NEON
  EXPORT ARGBToARGB4444Row_NEON
  EXPORT NV12ToARGBRow_NEON
  EXPORT NV21ToARGBRow_NEON
  EXPORT NV12ToRGB565Row_NEON
  EXPORT NV21ToRGB565Row_NEON
  EXPORT SplitUVRow_NEON
  EXPORT MergeUVRow_NEON
  EXPORT SetRow_NEON
  EXPORT CopyRow_NEON
  EXPORT ARGBSetRow_NEON
  EXPORT MirrorRow_NEON
  EXPORT MirrorUVRow_NEON
  EXPORT ARGBMirrorRow_NEON
  EXPORT RGB24ToARGBRow_NEON
  EXPORT RAWToARGBRow_NEON
  EXPORT RGB565ToARGBRow_NEON
  EXPORT ARGB1555ToARGBRow_NEON
  EXPORT ARGB4444ToARGBRow_NEON
  EXPORT RGBAToUVRow_NEON
  EXPORT ABGRToUVRow_NEON
  EXPORT ABGRToYRow_NEON
  EXPORT RGBAToYRow_NEON
  EXPORT RGB24ToYRow_NEON
  EXPORT ARGB1555ToUVRow_NEON
  EXPORT ARGB4444ToUVRow_NEON
  EXPORT RGB565ToYRow_NEON
  EXPORT RGB565ToUVRow_NEON
  EXPORT ARGB1555ToYRow_NEON
  EXPORT ARGB4444ToYRow_NEON
  EXPORT BGRAToYRow_NEON
  EXPORT ARGBToUV411Row_NEON
  EXPORT ARGBToUV422Row_NEON
  EXPORT ARGBToUV444Row_NEON
  EXPORT YUY2ToUV422Row_NEON
  EXPORT UYVYToUV422Row_NEON
  EXPORT ARGBToBayerGGRow_NEON
  EXPORT ARGBShuffleRow_NEON
  EXPORT ARGBToUVJRow_NEON
  EXPORT BGRAToUVRow_NEON
  EXPORT ABGRToUVRow_NEON
  EXPORT RGBAToUVRow_NEON
  EXPORT ARGBExtractAlphaRow_NEON
  EXPORT ARGBToYJRow_NEON
  EXPORT I422ToUYVYRow_NEON
  EXPORT I422ToYUY2Row_NEON
  EXPORT ARGBToUVRow_NEON
  EXPORT ARGBToYRow_NEON
  EXPORT RAWToUVRow_NEON
  EXPORT RAWToYRow_NEON
  EXPORT RGB24ToUVRow_NEON
  EXPORT UYVYToUVRow_NEON
  EXPORT UYVYToYRow_NEON
  EXPORT ARGBToRGB565DitherRow_NEON
  EXPORT YUY2ToYRow_NEON
  EXPORT YUY2ToUVRow_NEON
  EXPORT SobelToPlaneRow_NEON
  EXPORT SobelRow_NEON
  EXPORT ARGBSubtractRow_NEON
  EXPORT ARGBAddRow_NEON
  EXPORT ARGBAttenuateRow_NEON
  EXPORT ARGBQuantizeRow_NEON
  EXPORT ARGBShadeRow_NEON
  EXPORT ARGBGrayRow_NEON
  EXPORT ARGBSepiaRow_NEON
  EXPORT ARGBColorMatrixRow_NEON
  EXPORT ARGBBlendRow_NEON
  EXPORT InterpolateRow_NEON
  EXPORT ARGBMultiplyRow_NEON
  EXPORT SobelXRow_NEON
  EXPORT SobelYRow_NEON
  EXPORT SobelXYRow_NEON


; ------- CONSTANTS ---------------------

; YUV to RGB conversion constants.
; Y contribution to R,G,B.  Scale and bias.
YG  EQU   18997 ; round(1.164 * 64 * 256 * 256 / 257)
YGB EQU   1160  ; 1.164 * 64 * 16 - adjusted for even error distribution

; U and V contributions to R,G,B
UB  EQU   -128 ; -min(128, round(2.018 * 64))
UG  EQU   25   ; -round(-0.391 * 64)
VG  EQU   52   ; -round(-0.813 * 64)
VR  EQU   -102 ; -round(1.596 * 64)

; Bias values to subtract 16 from Y and 128 from U and V.
BB  EQU  UB * 128 - YGB
BG  EQU  UG * 128 + VG * 128 - YGB
BR  EQU  VR * 128 - YGB


; ------- ARRAYS ------------------------

kUVToRB     DCB   128, 128, 128, 128, 102, 102, 102, 102, 0, 0, 0, 0, 0, 0, 0, 0
kUVToG      DCB   25, 25, 25, 25, 52, 52, 52, 52, 0, 0, 0, 0, 0, 0, 0, 0
kUVBiasBGR  DCW   BB, BG, BR, 0, 0, 0, 0, 0
kYToRgb     DCD   0x0101 * YG, 0, 0, 0

; ------- MACROS ------------------------

  MACRO
  YUV422TORGB_SETUP_REG
    adr        r5, kUVToRB
    vld1.8     {d24}, [r5]
    adr        r5, kUVToG
    vld1.8     {d25}, [r5]
    adr        r5, kUVBiasBGR
    vld1.16    {d26[], d27[]}, [r5]!
    vld1.16    {d8[], d9[]}, [r5]!
    vld1.16    {d28[], d29[]}, [r5]
    adr        r5, kYToRgb
    vld1.32    {d30[], d31[]}, [r5]
  MEND

  ; Read 8 Y, 4 U and 4 V from 422
  MACRO
  READYUV422
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    MEMACCESS	1
    vld1.32    {d2[0]}, [r1]!
    MEMACCESS 2
    vld1.32    {d2[1]}, [r2]!
  MEND

  ; Read 8 Y, 2 U and 2 V from 422
  MACRO
  READYUV411
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    MEMACCESS	1
    vld1.16    {d2[0]}, [r1]!
    MEMACCESS 2
    vld1.16    {d2[1]}, [r2]!
    vmov.u8    d3, d2
    vzip.u8    d2, d3
  MEND

  ; Read 8 Y, 8 U and 8 V from 444
  MACRO
  READYUV444
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    MEMACCESS	1
    vld1.8     {d2}, [r1]!
    MEMACCESS 2
    vld1.8     {d3}, [r2]!
    vpaddl.u8  q1, q1
    vrshrn.u16 d2, q1, #1
  MEND

  ; Read 8 Y and 4 VU from NV21
  MACRO
  READNV21
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    MEMACCESS	1
    vld1.8     {d2}, [r1]!
    vmov.u8    d3, d2                         ; split odd/even uv apart
    vuzp.u8    d3, d2
    vtrn.u32   d2, d3
  MEND

  ; Read 8 Y, and set 4 U and 4 V to 128
  MACRO
  READYUV400
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    vmov.u8    d2, #128
  MEND

  ; Read 8 Y and 4 UV from NV12
  MACRO
  READNV12
    MEMACCESS	0
    vld1.8     {d0}, [r0]!
    MEMACCESS	1
    vld1.8     {d2}, [r1]!
    vmov.u8    d3, d2                         ; split odd/even uv apart
    vuzp.u8    d2, d3
    vtrn.u32   d2, d3
  MEND

  ; Read 8 YUY2
  MACRO
  READYUY2
    MEMACCESS	0
    vld2.8     {d0, d2}, [r0]!
    vmov.u8    d3, d2
    vuzp.u8    d2, d3
    vtrn.u32   d2, d3
  MEND

  ; Read 8 UYVY
  MACRO
  READUYVY
    MEMACCESS	0
    vld2.8     {d2, d3}, [r0]!
    vmov.u8    d0, d3
    vmov.u8    d3, d2
    vuzp.u8    d2, d3
    vtrn.u32   d2, d3
  MEND

  MACRO
  ARGBTOARGB4444
    vshr.u8    d20, d20, #4                     ; B
    vbic.32    d21, d21, d4                     ; G
    vshr.u8    d22, d22, #4                     ; R
    vbic.32    d23, d23, d4                     ; A
    vorr       d0, d20, d21                     ; BG
    vorr       d1, d22, d23                     ; RA
    vzip.u8    d0, d1                           ; BGRA
  MEND

  MACRO
  ARGBTOARGB1555
    vshll.u8    q0, d23, #8                     ; A
    vshll.u8    q8, d22, #8                     ; R
    vshll.u8    q9, d21, #8                     ; G
    vshll.u8    q10, d20, #8                    ; B
    vsri.16     q0, q8, #1                      ; AR
    vsri.16     q0, q9, #6                      ; ARG
    vsri.16     q0, q10, #11                    ; ARGB
  MEND

  MACRO
  ARGBTORGB565
    vshll.u8    q0, d22, #8                     ; R
    vshll.u8    q8, d21, #8                     ; G
    vshll.u8    q9, d20, #8                     ; B
    vsri.16     q0, q8, #5                      ; RG
    vsri.16     q0, q9, #11                     ; RGB
  MEND

  MACRO
  YUV422TORGB
    vmull.u8   q8, d2, d24                     ; u/v B/R component
    vmull.u8   q9, d2, d25                     ; u/v G component
    vmovl.u8   q0, d0                          ; Y
    vmovl.s16  q10, d1
    vmovl.s16  q0, d0
    vmul.s32   q10, q10, q15
    vmul.s32   q0, q0, q15
    vqshrun.s32 d0, q0, #16
    vqshrun.s32 d1, q10, #16                   ; Y
    vadd.s16   d18, d19
    vshll.u16  q1, d16, #16                    ; Replicate u * UB
    vshll.u16  q10, d17, #16                   ; Replicate v * VR
    vshll.u16  q3, d18, #16                    ; Replicate (v*VG + u*UG)
    vaddw.u16  q1, q1, d16
    vaddw.u16  q10, q10, d17
    vaddw.u16  q3, q3, d18
    vqadd.s16  q8, q0, q13                     ; B */
    vqadd.s16  q9, q0, q14                     ; R */
    vqadd.s16  q0, q0, q4                      ; G */
    vqadd.s16  q8, q8, q1                      ; B */
    vqadd.s16  q9, q9, q10                     ; R */
    vqsub.s16  q0, q0, q3                      ; G */
    vqshrun.s16 d20, q8, #6                    ; B */
    vqshrun.s16 d22, q9, #6                    ; R */
    vqshrun.s16 d21, q0, #6                    ; G */
  MEND

  MACRO
  RGB565TOARGB
    vshrn.u16  d6, q0, #5                       ; G xxGGGGGG
    vuzp.u8    d0, d1                           ; d0 xxxBBBBB RRRRRxxx
    vshl.u8    d6, d6, #2                       ; G GGGGGG00 upper 6
    vshr.u8    d1, d1, #3                       ; R 000RRRRR lower 5
    vshl.u8    q0, q0, #3                       ; B,R BBBBB000 upper 5
    vshr.u8    q2, q0, #5                       ; B,R 00000BBB lower 3
    vorr.u8    d0, d0, d4                       ; B
    vshr.u8    d4, d6, #6                       ; G 000000GG lower 2
    vorr.u8    d2, d1, d5                       ; R
    vorr.u8    d1, d4, d6                       ; G
  MEND

  MACRO
  ARGB1555TOARGB
    vshrn.u16  d7, q0, #8                       ; A Arrrrrxx
    vshr.u8    d6, d7, #2                       ; R xxxRRRRR
    vshrn.u16  d5, q0, #5                       ; G xxxGGGGG
    vmovn.u16  d4, q0                           ; B xxxBBBBB
    vshr.u8    d7, d7, #7                       ; A 0000000A
    vneg.s8    d7, d7                           ; A AAAAAAAA upper 8
    vshl.u8    d6, d6, #3                       ; R RRRRR000 upper 5
    vshr.u8    q1, q3, #5                       ; R,A 00000RRR lower 3
    vshl.u8    q0, q2, #3                       ; B,G BBBBB000 upper 5
    vshr.u8    q2, q0, #5                       ; B,G 00000BBB lower 3
    vorr.u8    q1, q1, q3                       ; R,A
    vorr.u8    q0, q0, q2                       ; B,G
  MEND

  MACRO
  ARGB4444TOARGB
    vuzp.u8    d0, d1                           ; d0 BG, d1 RA
    vshl.u8    q2, q0, #4                       ; B,R BBBB0000
    vshr.u8    q1, q0, #4                       ; G,A 0000GGGG
    vshr.u8    q0, q2, #4                       ; B,R 0000BBBB
    vorr.u8    q0, q0, q2                       ; B,R BBBBBBBB
    vshl.u8    q2, q1, #4                       ; G,A GGGG0000
    vorr.u8    q1, q1, q2                       ; G,A GGGGGGGG
    vswp.u8    d1, d2                           ; B,R,G,A -> B,G,R,A
  MEND

  ; 16x2 pixels -> 8x1.  pix is number of argb pixels. e.g. 16.
  MACRO
  RGBTOUV   $QB, $QG, $QR
    vmul.s16    q8,  $QB , q10                 ; B
    vmls.s16   q8,  $QG , q11                 ; G
    vmls.s16   q8,  $QR , q12                 ; R
    vadd.u16   q8, q8, q15                    ; +128 -> unsigned
    vmul.s16   q9,  $QR , q10                 ; R
    vmls.s16   q9,  $QG , q14                 ; G
    vmls.s16   q9,  $QB , q13                 ; B
    vadd.u16   q9, q9, q15                    ; +128 -> unsigned
    vqshrn.u16  d0, q8, #8                    ; 16 bit to 8 bit U
    vqshrn.u16  d1, q9, #8                    ; 16 bit to 8 bit V
  MEND

  ; RGB555TOARGB is same as ARGB1555TOARGB but ignores alpha.
  MACRO
  RGB555TOARGB
    vshrn.u16  d6, q0, #5                       ; G xxxGGGGG
    vuzp.u8    d0, d1                           ; d0 xxxBBBBB xRRRRRxx
    vshl.u8    d6, d6, #3                       ; G GGGGG000 upper 5
    vshr.u8    d1, d1, #2                       ; R 00xRRRRR lower 5
    vshl.u8    q0, q0, #3                       ; B,R BBBBB000 upper 5
    vshr.u8    q2, q0, #5                       ; B,R 00000BBB lower 3
    vorr.u8    d0, d0, d4                       ; B
    vshr.u8    d4, d6, #5                       ; G 00000GGG lower 3
    vorr.u8    d2, d1, d5                       ; R
    vorr.u8    d1, d4, d6                       ; G
  MEND


; ----- METHODS ---------------------------------------

I444ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV444
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d23, #255
  MEMACCESS  3
  vst4.8     {d20, d21, d22, d23}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d23, #255
  MEMACCESS  3
  vst4.8     {d20, d21, d22, d23}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422AlphaToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 = const uint8* src_a
  ;     r4 =  uint8* dst_argb
  push      {r5, r6}
  ldr       r5, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  MEMACCESS  3
  vld1.8     {d23}, [r3]!
  subs       r5, r5, #8
  MEMACCESS  4
  vst4.8     {d20, d21, d22, d23}, [r4]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5, r6}
  bx        lr
  ENDP

I422ToRGBARow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d19, #255
  MEMACCESS  3
  vst4.8     {d19, d20, d21, d22}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP


I411ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV411
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d23, #255
  MEMACCESS  3
  vst4.8     {d20, d21, d22, d23}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP


I422ToBGRARow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_bgra
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vswp.u8    d20, d22
  vmov.u8    d19, #255
  MEMACCESS  3
  vst4.8     {d19, d20, d21, d22}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP


I422ToABGRRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_abgr
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vswp.u8    d20, d22
  vmov.u8    d23, #255
  MEMACCESS  3
  vst4.8     {d20, d21, d22, d23}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToRGB24Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_rgb24
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  MEMACCESS  3
  vst3.8     {d20, d21, d22}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToRAWRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_raw
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vswp.u8    d20, d22
  MEMACCESS	3
  vst3.8     {d20, d21, d22}, [r3]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToARGB4444Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb4444
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
  vmov.u8    d4, #0x0f                        ; bits to clear with vbic.
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d23, #255
  ARGBTOARGB4444
  MEMACCESS  3
  vst1.8     {q0}, [r3]!                      ; store 8 pixels ARGB4444.
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToARGB1555Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_argb1555
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  vmov.u8    d23, #255
  ARGBTOARGB1555
  MEMACCESS  3
  vst1.8     {q0}, [r3]!                    ; store 8 pixels ARGB1555.
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I422ToRGB565Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_rgb565
  push      {r4, r5}
  ldr       r4, [sp,#8]      ; int width
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV422
  YUV422TORGB
  subs       r4, r4, #8
  ARGBTORGB565
  MEMACCESS  3
  vst1.8     {q0}, [r3]!                   ; store 8 pixels ARGB1555.
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r4, r5}
  bx        lr
  ENDP

I400ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_rgb24
  ;     r2 = width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUV400
  YUV422TORGB
  subs       r2, r2, #8
  vmov.u8    d23, #255
  MEMACCESS	1
  vst4.8     {d20, d21, d22, d23}, [r1]!
  bgt        %b1


  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

J400ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = width
  push      {r5}
  vpush     {d20 - d23}

  vmov.u8    d23, #255
1
  MEMACCESS	 0
  vld1.8     {d20}, [r0]!
  vmov       d21, d20
  vmov       d22, d20
  subs       r2, r2, #8
  MEMACCESS	 1
  vst4.8     {d20, d21, d22, d23}, [r1]!
  bgt        %b1


  vpop      {d20 - d23}
  pop       {r5}
  bx        lr
  ENDP


ARGBToRGB24Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_raw
  ;     r2 = pix
  vpush     {d1 - d4}

1
  MEMACCESS	0
  vld4.8     {d1, d2, d3, d4}, [r0]!          ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  MEMACCESS	1
  vst3.8     {d1, d2, d3}, [r1]!              ; store 8 pixels of RGB24.
  bgt        %b1

  vpop      {d1 - d4}
  bx        lr
  ENDP

ARGBToRAWRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = pix
  vpush     {d1 - d4}

1
  MEMACCESS	0
  vld4.8     {d1, d2, d3, d4}, [r0]!          ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vswp.u8    d1, d3                           ; swap R, B
  MEMACCESS	1
  vst3.8     {d1, d2, d3}, [r1]!              ; store 8 pixels of RAW.
  bgt        %b1

  vpop      {d1 - d4}
  bx        lr
  ENDP

ARGBToRGB565Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_rgb565
  ;     r2 = pix
  vpush     {q0}
  vpush     {q8 - q11}

1
  MEMACCESS	0
  vld4.8     {d20, d21, d22, d23}, [r0]!      ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGBTORGB565
  MEMACCESS	1
  vst1.8     {q0}, [r1]!                      ; store 8 pixels RGB565.
  bgt        %b1

  vpop     {q8 - q11}
  vpop     {q0}
  bx        lr
  ENDP

ARGBToARGB1555Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb1555
  ;     r2 = pix
  vpush     {q0}
  vpush     {q8 - q11}

1
  MEMACCESS	0
  vld4.8     {d20, d21, d22, d23}, [r0]!      ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGBTOARGB1555
  MEMACCESS	1
  vst1.8     {q0}, [r1]!                      ; store 8 pixels ARGB1555.
  bgt        %b1

  vpop     {q8 - q11}
  vpop     {q0}
  bx        lr
  ENDP

ARGBToARGB4444Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb4444
  ;     r2 = pix
  vpush     {q0}
  vpush     {q8 - q11}

  vmov.u8    d4, #0x0f                        ; bits to clear with vbic.
1
  MEMACCESS	0
  vld4.8     {d20, d21, d22, d23}, [r0]!      ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGBTOARGB4444
  MEMACCESS	1
  vst1.8     {q0}, [r1]!                      ; store 8 pixels ARGB4444.
  bgt        %b1

  vpop     {q8 - q11}
  vpop     {q0}
  bx        lr
  ENDP

NV12ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_uv
  ;     r2 = uint8* dst_argb
  ;     r3 = int width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG

1
  READNV12
  YUV422TORGB
  subs       r3, r3, #8
  vmov.u8    d23, #255
  MEMACCESS	2
  vst4.8     {d20, d21, d22, d23}, [r2]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

NV21ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_uv
  ;     r2 = uint8* dst_argb
  ;     r3 = int width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG

1
  READNV21
  YUV422TORGB
  subs       r3, r3, #8
  vmov.u8    d23, #255
  MEMACCESS	2
  vst4.8     {d20, d21, d22, d23}, [r2]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

NV12ToRGB565Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_uv
  ;     r2 = uint8* dst_rgb565
  ;     r3 = int width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG

1
  READNV12
  YUV422TORGB
  subs       r3, r3, #8
  ARGBTORGB565
  MEMACCESS	2
  vst1.8     {q0}, [r2]!                      ; store 8 pixels RGB565.
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

NV21ToRGB565Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_uv
  ;     r2 = uint8* dst_rgb565
  ;     r3 = int width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG

1
  READNV21
  YUV422TORGB
  subs       r3, r3, #8
  ARGBTORGB565
  MEMACCESS	2
  vst1.8     {q0}, [r2]!                      ; store 8 pixels RGB565.
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

YUY2ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_yuy2
  ;     r1 = uint8* dst_argb
  ;     r2 = width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READYUY2
  YUV422TORGB
  subs       r2, r2, #8
  vmov.u8    d23, #255
  MEMACCESS	1
  vst4.8     {d20, d21, d22, d23}, [r1]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

UYVYToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_uyvy
  ;     r1 = uint8* dst_argb
  ;     r2 = width
  push      {r5}
  vpush     {q0 - q4}
  vpush     {q8 - q15}

  YUV422TORGB_SETUP_REG
1
  READUYVY
  YUV422TORGB
  subs       r2, r2, #8
  vmov.u8    d23, #255
  MEMACCESS	1
  vst4.8     {d20, d21, d22, d23}, [r1]!
  bgt        %b1

  vpop      {q8 - q15}
  vpop      {q0 - q4}
  pop       {r5}
  bx        lr
  ENDP

; Reads 16 pairs of UV and write even values to dst_u and odd to dst_v.
SplitUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_uv
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int width
  vpush      {q0, q1}

1
  MEMACCESS	0
  vld2.8     {q0, q1}, [r0]!                  ; load 16 pairs of UV
  subs       r3, r3, #16                      ; 16 processed per loop
  MEMACCESS	1
  vst1.8     {q0}, [r1]!                      ; store U
  MEMACCESS	2
  vst1.8     {q1}, [r2]!                      ; store V
  bgt        %b1

  vpop       {q0, q1}
  bx         lr
  ENDP

; Reads 16 U's and V's and writes out 16 pairs of UV
MergeUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_u
  ;     r1 = uint8* src_v
  ;     r2 = uint8* dst_uv
  ;     r3 = int width
  vpush      {q0, q1}

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load U
  MEMACCESS	1
  vld1.8     {q1}, [r1]!                      ; load V
  subs       r3, r3, #16                      ; 16 processed per loop
  MEMACCESS	2
  vst2.u8    {q0, q1}, [r2]!                  ; store 16 pairs of UV
  bgt        %b1

  vpop       {q0, q1}
  bx         lr
  ENDP

; Copy multiple of 32.  vld4.8  allow unaligned and is fastest on a15.
CopyRow_NEON PROC
  ; input
  ;     r0 = const uint8* src
  ;     r1 = uint8* dst
  ;     r2 = int count
  vpush      {q0, q1}

1
  MEMACCESS	0
  vld1.8     {d0, d1, d2, d3}, [r0]!          ; load 32
  subs       r2, r2, #32                      ; 32 processed per loop
  MEMACCESS	1
  vst1.8     {d0, d1, d2, d3}, [r1]!          ; store 32
  bgt        %b1

  vpop       {q0, q1}
  bx         lr
  ENDP

; SetRow writes 'count' bytes using an 8 bit value repeated
SetRow_NEON PROC
  ; input
  ;     r0 = const uint8* src
  ;     r1 = uint8* v8
  ;     r2 = int count
  vpush     {q0}

  vdup.8    q0, r1                            ; duplicate 16 bytes
1
  subs      r2, r2, #16                       ; 16 bytes per loop
  MEMACCESS	0
  vst1.8    {q0}, [r0]!                       ; store
  bgt       %b1

  vpop      {q0}
  bx        lr
  ENDP

; ARGBSetRow writes 'count' pixels using an 32 bit value repeated.
ARGBSetRow_NEON PROC
  ; input
  ;     r0 = const uint8* dst
  ;     r1 = uint8* v32
  ;     r2 = int count
  vpush     {q0}

  vdup.u32  q0, r1                            ; duplicate 4 ints
1
  subs      r2, r2, #4                        ; 4 pixels per loop
  MEMACCESS	0
  vst1.8    {q0}, [r0]!                       ; store
  bgt       %b1

  vpop      {q0}
  bx        lr
  ENDP

MirrorRow_NEON PROC
  ; input
  ;     r0 = const uint8* src
  ;     r1 = uint8* dst
  ;     r2 = int width
  push      {r3}
  vpush     {q0}
  ; Start at end of source row.
  mov        r3, #-16
  add        r0, r0, r2
  sub        r0, #16

1
  MEMACCESS	0
  vld1.8     {q0}, [r0], r3                   ; src -= 16
  subs       r2, #16                          ; 16 pixels per loop.
  vrev64.8   q0, q0
  MEMACCESS	1
  vst1.8     {d1}, [r1]!                      ; dst += 16
  MEMACCESS	1
  vst1.8     {d0}, [r1]!
  bgt        %b1

  vpop      {q0}
  pop       {r3}
  bx        lr
  ENDP


MirrorUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_uv
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_
  ;     r3 = uint8* width
  push      {r12}
  vpush     {q0}
  ; Start at end of source row.
  mov        r12, #-16
  add        r0, r0, r3, lsl #1
  sub        r0, #16

1
  MEMACCESS	0
  vld2.8     {d0, d1}, [r0], r12              ; src -= 16
  subs       r3, #8                           ; 8 pixels per loop.
  vrev64.8   q0, q0
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; dst += 8
  MEMACCESS	2
  vst1.8     {d1}, [r2]!
  bgt        %b1

  vpop      {q0}
  pop       {r12}
  bx        lr
  ENDP

ARGBMirrorRow_NEON PROC
  ; input
  ;     r0 = const uint8* src
  ;     r1 = uint8* dst
  ;     r2 = int width
  push      {r3}
  vpush     {q0}

  ; Start at end of source row.
  mov        r3, #-16
  add        r0, r0, r2, lsl #2
  sub        r0, #16

1
  MEMACCESS	0
  vld1.8     {q0}, [r0], r3                   ; src -= 16
  subs       r2, #4                           ; 4 pixels per loop.
  vrev64.32  q0, q0
  MEMACCESS	1
  vst1.8     {d1}, [r1]!                      ; dst += 16
  MEMACCESS	1
  vst1.8     {d0}, [r1]!
  bgt        %b1

  vpop      {q0}
  pop       {r3}
  bx        lr
  ENDP


RGB24ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb24
  ;     r1 = uint8* dst_argb
  ;     r2 = int pix
  vpush       {d1 - d4}
  vmov.u8    d4, #255                         ; Alpha

1
  MEMACCESS	0
  vld3.8     {d1, d2, d3}, [r0]!              ; load 8 pixels of RGB24.
  subs       r2, r2, #8                       ; 8 processed per loop.
  MEMACCESS	1
  vst4.8     {d1, d2, d3, d4}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop      {d1 - d4}
  bx        lr
  ENDP

RAWToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_raw
  ;     r1 = uint8* dst_argb
  ;     r2 = int pix
  vpush       {d1 - d4}
  vmov.u8    d4, #255                         ; Alpha

1
  MEMACCESS	0
  vld3.8     {d1, d2, d3}, [r0]!              ; load 8 pixels of RAW.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vswp.u8    d1, d3                           ; swap R, B
  MEMACCESS	1
  vst4.8     {d1, d2, d3, d4}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop      {d1 - d4}
  bx        lr
  ENDP

RAWToRGB24Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_raw
  ;     r1 = uint8* dst_rgb24
  ;     r2 = int width
  vpush       {d1 - d4}

1
  MEMACCESS 0
  vld3.8     {d1, d2, d3}, [r0]!              ; load 8 pixels of RAW.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vswp.u8    d1, d3                           ; swap R, B
  MEMACCESS 1
  vst3.8     {d1, d2, d3}, [r1]!              ; store 8 pixels of b g r.
  bgt        %b1

  vpop      {d1 - d4}
  bx        lr
  ENDP

RGB565ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb565
  ;     r1 = uint8* dst_argb
  ;     r2 = int pix
  vpush	     {q0 - q3}
  vmov.u8    d3, #255                         ; Alpha

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 RGB565 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  RGB565TOARGB
  MEMACCESS	1
  vst4.8     {d0, d1, d2, d3}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop	     {q0 - q3}
   bx        lr
  ENDP

ARGB1555ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb1555
  ;     r1 = uint8* dst_argb
  ;     r2 = int pix
  vpush	     {q0 - q3}
  vmov.u8    d3, #255                         ; Alpha

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB1555 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGB1555TOARGB
  MEMACCESS	1
  vst4.8     {d0, d1, d2, d3}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop	     {q0 - q3}
  bx         lr
  ENDP

ARGB4444ToARGBRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb4444
  ;     r1 = uint8* dst_argb
  ;     r2 = int pix
  vpush	     {q0 - q2}
  vmov.u8    d3, #255                         ; Alpha

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB4444 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGB4444TOARGB
  MEMACCESS	1
  vst4.8     {d0, d1, d2, d3}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop	    {q0 - q2}
  bx        lr
  ENDP

ABGRToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_abgr
  ;     r1 = uint8* src_stride_abgr
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int witdh
  vpush      {q0 - q7}
  vpush      {q7 - q14}
  vpush      {q15}

  add        r1, r0, r1                       ; src_stride + src_abgr
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ABGR pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ABGR pixels.
  vpaddl.u8  q2, q2                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q0, q0                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld4.8     {d8, d10, d12, d14}, [r1]!       ; load 8 more ABGR pixels.
  MEMACCESS	1
  vld4.8     {d9, d11, d13, d15}, [r1]!       ; load last 8 ABGR pixels.
  vpadal.u8  q2, q6                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q0, q4                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q2, q1, q0
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop       {q15}
  vpop       {q7 - q14}
  vpop       {q0 - q7}
  pop        {r4}
  bx         lr
  ENDP

RGBAToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgba
  ;     r1 = uint8* src_stride_rgba
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush      {q0 - q7}
  vpush      {q7 - q14}
  vpush      {q15}

  add        r1, r0, r1                       ; src_stride + src_rgba
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 RGBA pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 RGBA pixels.
  vpaddl.u8  q0, q1                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q2                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q3                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld4.8     {d8, d10, d12, d14}, [r1]!       ; load 8 more RGBA pixels.
  MEMACCESS	1
  vld4.8     {d9, d11, d13, d15}, [r1]!       ; load last 8 RGBA pixels.
  vpadal.u8  q0, q5                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q6                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q2, q7                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q0, q1, q2
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop       {q15}
  vpop       {q7 - q14}
  vpop       {q0 - q7}
  pop        {r4}
  bx         lr
  ENDP

ABGRToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_abgr
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	   {d0 - d7}
  vpush	   {q8}

  vmov.u8    d4, #33                          ; R * 0.2578 coefficient
  vmov.u8    d5, #65                          ; G * 0.5078 coefficient
  vmov.u8    d6, #13                          ; B * 0.1016 coefficient
  vmov.u8    d7, #16                          ; Add 16 constant

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 pixels of ABGR.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q8, d0, d4                       ; R
  vmlal.u8   q8, d1, d5                       ; G
  vmlal.u8   q8, d2, d6                       ; B
  vqrshrun.s16 d0, q8, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d7
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop	    {q8}
  vpop	    {d0 - d7}
  bx        lr
  ENDP

RGBAToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgba
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	   {d0 - d7}
  vpush	   {q8}

  vmov.u8    d4, #13                          ; B * 0.1016 coefficient
  vmov.u8    d5, #65                          ; G * 0.5078 coefficient
  vmov.u8    d6, #33                          ; R * 0.2578 coefficient
  vmov.u8    d7, #16                          ; Add 16 constant

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 pixels of RGBA.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q8, d1, d4                       ; B
  vmlal.u8   q8, d2, d5                       ; G
  vmlal.u8   q8, d3, d6                       ; R
  vqrshrun.s16 d0, q8, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d7
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop	     {q8}
  vpop	     {d0 - d7}
  bx		     lr
  ENDP

RGB24ToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb24
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	    {d0 - d7}
  vpush	    {q8}

  vmov.u8    d4, #13                          ; B * 0.1016 coefficient
  vmov.u8    d5, #65                          ; G * 0.5078 coefficient
  vmov.u8    d6, #33                          ; R * 0.2578 coefficient
  vmov.u8    d7, #16                          ; Add 16 constant

1
  MEMACCESS	0
  vld3.8     {d0, d1, d2}, [r0]!              ; load 8 pixels of RGB24.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q8, d0, d4                       ; B
  vmlal.u8   q8, d1, d5                       ; G
  vmlal.u8   q8, d2, d6                       ; R
  vqrshrun.s16 d0, q8, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d7
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop	     {q8}
  vpop	     {d0 - d7}
  bx		     lr
  ENDP

  ; 16x2 pixels -> 8x1.  pix is number of argb pixels. e.g. 16.
ARGB1555ToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb1555
  ;     r1 = uint8* src_stride_argb1555
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_argb
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB1555 pixels.
  RGB555TOARGB
  vpaddl.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; next 8 ARGB1555 pixels.
  RGB555TOARGB
  vpaddl.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; load 8 ARGB1555 pixels.
  RGB555TOARGB
  vpadal.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; next 8 ARGB1555 pixels.
  RGB555TOARGB
  vpadal.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  vrshr.u16  q4, q4, #1                       ; 2x average
  vrshr.u16  q5, q5, #1
  vrshr.u16  q6, q6, #1

  subs       r4, r4, #16                      ; 16 processed per loop.
  vmul.s16   q8, q4, q10                      ; B
  vmls.s16   q8, q5, q11                      ; G
  vmls.s16   q8, q6, q12                      ; R
  vadd.u16   q8, q8, q15                      ; +128 -> unsigned
  vmul.s16   q9, q6, q10                      ; R
  vmls.s16   q9, q5, q14                      ; G
  vmls.s16   q9, q4, q13                      ; B
  vadd.u16   q9, q9, q15                      ; +128 -> unsigned
  vqshrn.u16  d0, q8, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q9, #8                      ; 16 bit to 8 bit V
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop	  	{q8 - q14}
  vpop	    {q0 - q7}
  pop		  	{r4}
  bx		  	lr
  ENDP


; 16x2 pixels -> 8x1.  pix is number of argb pixels. e.g. 16.
ARGB4444ToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb4444
  ;     r1 = uint8* src_stride_argb4444
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_argb
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB4444 pixels.
  ARGB4444TOARGB
  vpaddl.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; next 8 ARGB4444 pixels.
  ARGB4444TOARGB
  vpaddl.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; load 8 ARGB4444 pixels.
  ARGB4444TOARGB
  vpadal.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; next 8 ARGB4444 pixels.
  ARGB4444TOARGB
  vpadal.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  vrshr.u16  q4, q4, #1                       ; 2x average
  vrshr.u16  q5, q5, #1
  vrshr.u16  q6, q6, #1

  subs       r4, r4, #16                      ; 16 processed per loop.
  vmul.s16   q8, q4, q10                      ; B
  vmls.s16   q8, q5, q11                      ; G
  vmls.s16   q8, q6, q12                      ; R
  vadd.u16   q8, q8, q15                      ; +128 -> unsigned
  vmul.s16   q9, q6, q10                      ; R
  vmls.s16   q9, q5, q14                      ; G
  vmls.s16   q9, q4, q13                      ; B
  vadd.u16   q9, q9, q15                      ; +128 -> unsigned
  vqshrn.u16  d0, q8, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q9, #8                      ; 16 bit to 8 bit V
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop		  {q8 - q14}
  vpop	    {q0 - q7}
  pop		  	{r4}
  bx		  	lr
  ENDP

RGB565ToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb565
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	     {q0 - q3}
  vpush 	   {q12 - q13}

  vmov.u8    d24, #13                         ; B * 0.1016 coefficient
  vmov.u8    d25, #65                         ; G * 0.5078 coefficient
  vmov.u8    d26, #33                         ; R * 0.2578 coefficient
  vmov.u8    d27, #16                         ; Add 16 constant

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 RGB565 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  RGB565TOARGB
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d27
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop  		{q12 - q13}
  vpop	    {q0 - q3}
  bx		  	lr
  ENDP

  ; 16x2 pixels -> 8x1.  pix is number of argb pixels. e.g. 16.
RGB565ToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb565
  ;     r1 = uint8* src_stride_rgb565
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_argb
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 RGB565 pixels.
  RGB565TOARGB
  vpaddl.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; next 8 RGB565 pixels.
  RGB565TOARGB
  vpaddl.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpaddl.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpaddl.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; load 8 RGB565 pixels.
  RGB565TOARGB
  vpadal.u8  d8, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d10, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d12, d2                          ; R 8 bytes -> 4 shorts.
  MEMACCESS	1
  vld1.8     {q0}, [r1]!                      ; next 8 RGB565 pixels.
  RGB565TOARGB
  vpadal.u8  d9, d0                           ; B 8 bytes -> 4 shorts.
  vpadal.u8  d11, d1                          ; G 8 bytes -> 4 shorts.
  vpadal.u8  d13, d2                          ; R 8 bytes -> 4 shorts.

  vrshr.u16  q4, q4, #1                       ; 2x average
  vrshr.u16  q5, q5, #1
  vrshr.u16  q6, q6, #1

  subs       r4, r4, #16                      ; 16 processed per loop.
  vmul.s16   q8, q4, q10                      ; B
  vmls.s16   q8, q5, q11                      ; G
  vmls.s16   q8, q6, q12                      ; R
  vadd.u16   q8, q8, q15                      ; +128 -> unsigned
  vmul.s16   q9, q6, q10                      ; R
  vmls.s16   q9, q5, q14                      ; G
  vmls.s16   q9, q4, q13                      ; B
  vadd.u16   q9, q9, q15                      ; +128 -> unsigned
  vqshrn.u16  d0, q8, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q9, #8                      ; 16 bit to 8 bit V
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop	  	{q8 - q14}
  vpop	    {q0 - q7}
  pop		  	{r4}
  bx		  	lr
  ENDP

ARGB1555ToYRow_NEON PROC
   ; input
  ;     r0 = const uint8* src_argb1555
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	     {q0 - q3}
  vpush	     {q12 - q13}

  vmov.u8    d24, #13                         ; B * 0.1016 coefficient
  vmov.u8    d25, #65                         ; G * 0.5078 coefficient
  vmov.u8    d26, #33                         ; R * 0.2578 coefficient
  vmov.u8    d27, #16                         ; Add 16 constant

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB1555 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGB1555TOARGB
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d27
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop		  {q12 - q13}
  vpop	  	{q0 - q3}
  bx		  	lr
  ENDP

ARGB4444ToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb4444
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	     {q0 - q3}
  vpush	     {q12 - q13}

  vmov.u8    d24, #13                         ; B * 0.1016 coefficient
  vmov.u8    d25, #65                         ; G * 0.5078 coefficient
  vmov.u8    d26, #33                         ; R * 0.2578 coefficient
  vmov.u8    d27, #16                         ; Add 16 constant

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 8 ARGB4444 pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  ARGB4444TOARGB
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d27
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop		  {q12 - q13}
  vpop	  	{q0 - q3}
  bx		  	lr
  ENDP

BGRAToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_bgra
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	    {q0 - q3}
  vpush	    {q12 - q13}

  vmov.u8    d4, #33                          ; R * 0.2578 coefficient
  vmov.u8    d5, #65                          ; G * 0.5078 coefficient
  vmov.u8    d6, #13                          ; B * 0.1016 coefficient
  vmov.u8    d7, #16                          ; Add 16 constant

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 pixels of BGRA.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q8, d1, d4                       ; R
  vmlal.u8   q8, d2, d5                       ; G
  vmlal.u8   q8, d3, d6                       ; B
  vqrshrun.s16 d0, q8, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d7
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop		  {q12 - q13}
  vpop		  {q0 - q3}
  bx			  lr
  ENDP

; 32x1 pixels -> 8x1.  pix is number of argb pixels. e.g. 32.
ARGBToUV411Row_NEON PROC
    ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels.
  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	0
  vld4.8     {d8, d10, d12, d14}, [r0]!       ; load 8 more ARGB pixels.
  MEMACCESS	0
  vld4.8     {d9, d11, d13, d15}, [r0]!       ; load last 8 ARGB pixels.
  vpaddl.u8  q4, q4                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q5, q5                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q6, q6                           ; R 16 bytes -> 8 shorts.

  vpadd.u16  d0, d0, d1                       ; B 16 shorts -> 8 shorts.
  vpadd.u16  d1, d8, d9                       ; B
  vpadd.u16  d2, d2, d3                       ; G 16 shorts -> 8 shorts.
  vpadd.u16  d3, d10, d11                     ; G
  vpadd.u16  d4, d4, d5                       ; R 16 shorts -> 8 shorts.
  vpadd.u16  d5, d12, d13                     ; R

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r3, r3, #32                      ; 32 processed per loop.
  vmul.s16   q8, q0, q10                      ; B
  vmls.s16   q8, q1, q11                      ; G
  vmls.s16   q8, q2, q12                      ; R
  vadd.u16   q8, q8, q15                      ; +128 -> unsigned
  vmul.s16   q9, q2, q10                      ; R
  vmls.s16   q9, q1, q14                      ; G
  vmls.s16   q9, q0, q13                      ; B
  vadd.u16   q9, q9, q15                      ; +128 -> unsigned
  vqshrn.u16  d0, q8, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q9, #8                      ; 16 bit to 8 bit V
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels U.
  MEMACCESS	2
  vst1.8     {d1}, [r2]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop	  	{q8 - q14}
  vpop	    {q0 - q7}
  bx		  	lr
  ENDP

ARGBToUV422Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels.

  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.

  subs       r3, r3, #16                      ; 16 processed per loop.
  vmul.s16   q8, q0, q10                      ; B
  vmls.s16   q8, q1, q11                      ; G
  vmls.s16   q8, q2, q12                      ; R
  vadd.u16   q8, q8, q15                      ; +128 -> unsigned

  vmul.s16   q9, q2, q10                      ; R
  vmls.s16   q9, q1, q14                      ; G
  vmls.s16   q9, q0, q13                      ; B
  vadd.u16   q9, q9, q15                      ; +128 -> unsigned

  vqshrn.u16  d0, q8, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q9, #8                      ; 16 bit to 8 bit V

  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels U.
  MEMACCESS	2
  vst1.8     {d1}, [r2]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		   {q15}
  vpop	     {q8 - q14}
  vpop	     {q0 - q7}
  bx		  	 lr
  ENDP

  ; 8x1 pixels.
ARGBToUV444Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int pix
  vpush	     {q0 - q4}
  vpush 	   {q12 - q15}

  vmov.u8    d24, #112                        ; UB / VR 0.875 coefficient
  vmov.u8    d25, #74                         ; UG -0.5781 coefficient
  vmov.u8    d26, #38                         ; UR -0.2969 coefficient
  vmov.u8    d27, #18                         ; VB -0.1406 coefficient
  vmov.u8    d28, #94                         ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vmull.u8   q2, d0, d24                      ; B
  vmlsl.u8   q2, d1, d25                      ; G
  vmlsl.u8   q2, d2, d26                      ; R
  vadd.u16   q2, q2, q15                      ; +128 -> unsigned

  vmull.u8   q3, d2, d24                      ; R
  vmlsl.u8   q3, d1, d28                      ; G
  vmlsl.u8   q3, d0, d27                      ; B
  vadd.u16   q3, q3, q15                      ; +128 -> unsigned

  vqshrn.u16  d0, q2, #8                      ; 16 bit to 8 bit U
  vqshrn.u16  d1, q3, #8                      ; 16 bit to 8 bit V

  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels U.
  MEMACCESS	2
  vst1.8     {d1}, [r2]!                      ; store 8 pixels V.
  bgt        %b1

  vpop	     {q12 - q15}
  vpop	     {q0 - q4}
  bx		  	 lr
  ENDP

YUY2ToUV422Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_yuy2
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int pix
  vpush	     {d0 - d3}

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 16 pixels of YUY2.
  subs       r3, r3, #16                      ; 16 pixels = 8 UVs.
  MEMACCESS	1
  vst1.8     {d1}, [r1]!                      ; store 8 U.
  MEMACCESS	2
  vst1.8     {d3}, [r2]!                      ; store 8 V.
  bgt        %b1

  vpop	     {d0 - d3}
  bx		  	 lr
  ENDP


UYVYToUV422Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_uyvy
  ;     r1 = uint8* dst_u
  ;     r2 = uint8* dst_v
  ;     r3 = int pix
  vpush	     {d0 - d3}

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 16 pixels of UYVY.
  subs       r3, r3, #16                      ; 16 pixels = 8 UVs.
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 U.
  MEMACCESS	2
  vst1.8     {d2}, [r2]!                      ; store 8 V.
  bgt        %b1

  vpop	     {d0 - d3}
  bx		  	 lr
  ENDP

  ; Select G channels from ARGB.  e.g.  GGGGGGGG
ARGBToBayerGGRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_bayer
  ;     r2 = uint32 selector
  ;     r3 =  int pix
  vpush			{q0, q1}

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load row 8 pixels.
  subs       r3, r3, #8                       ; 8 processed per loop
  MEMACCESS	1
  vst1.8     {d1}, [r1]!                      ; store 8 G's.
  bgt        %b1

  vpop		{q0, q1}
  bx			lr
  ENDP

; For BGRAToARGB, ABGRToARGB, RGBAToARGB, and ARGBToRGBA.
ARGBShuffleRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = const uint8* shuffler
  ;     r3 = int pix
  vpush			{q0 - q2}

  MEMACCESS	3
  vld1.8     {q2}, [r2]                       ; shuffler
1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 4 pixels.
  subs       r3, r3, #4                       ; 4 processed per loop
  vtbl.8     d2, {d0, d1}, d4                 ; look up 2 first pixels
  vtbl.8     d3, {d0, d1}, d5                 ; look up 2 next pixels
  MEMACCESS	1
  vst1.8     {q1}, [r1]!                      ; store 4.
  bgt        %b1

  vpop		{q0 - q2}
  bx			lr
  ENDP

  ; TODO(fbarchard): Subsample match C code.
ARGBToUVJRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = int src_stride_argb
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_argb
  vmov.s16   q10, #127 / 2                    ; UB / VR 0.500 coefficient
  vmov.s16   q11, #84 / 2                     ; UG -0.33126 coefficient
  vmov.s16   q12, #43 / 2                     ; UR -0.16874 coefficient
  vmov.s16   q13, #20 / 2                     ; VB -0.08131 coefficient
  vmov.s16   q14, #107 / 2                    ; VG -0.41869 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels.
  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld4.8     {d8, d10, d12, d14}, [r1]!       ; load 8 more ARGB pixels.
  MEMACCESS	1
  vld4.8     {d9, d11, d13, d15}, [r1]!       ; load last 8 ARGB pixels.
  vpadal.u8  q0, q4                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q2, q6                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q0, q1, q2
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop		  {q8 - q14}
  vpop	    {q0 - q7}
  pop		  	{r4}
  bx		  	lr
  ENDP


BGRAToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_bgra
  ;     r1 = int src_stride_bgra
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_bgra
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 BGRA pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 BGRA pixels.
  vpaddl.u8  q3, q3                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld4.8     {d8, d10, d12, d14}, [r1]!       ; load 8 more BGRA pixels.
  MEMACCESS	1
  vld4.8     {d9, d11, d13, d15}, [r1]!       ; load last 8 BGRA pixels.
  vpadal.u8  q3, q7                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q2, q6                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q1, q1, #1                       ; 2x average
  vrshr.u16  q2, q2, #1
  vrshr.u16  q3, q3, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q3, q2, q1
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		  {q15}
  vpop		  {q8 - q14}
  vpop	    {q0 - q7}
  pop		  	{r4}
  bx		  	lr
  ENDP

ARGBExtractAlphaRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush      {q0 - q3}

1
  MEMACCESS 0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels
  subs       r2, r2, #16                      ; 16 processed per loop
  MEMACCESS 1
  vst1.8     {q3}, [r1]!                      ; store 16 A's.
  bgt        %b1

  vpop      {q0 - q3}
  bx        lr
  ENDP

ARGBToYJRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush      {q0 - q2}
  vpush      {q12 - q13}

  vmov.u8    d24, #15                         ; B * 0.11400 coefficient
  vmov.u8    d25, #75                         ; G * 0.58700 coefficient
  vmov.u8    d26, #38                         ; R * 0.29900 coefficient

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 15 bit to 8 bit Y
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop      {q12 - q13}
  vpop      {q0 - q2}
  bx        lr
  ENDP

I422ToYUY2Row_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_yuy2
  push	    {r4}
  ldr       r4, [sp,#4]                      ; int width
  vpush 	  {d0 - d3}

1
  MEMACCESS	0
  vld2.8     {d0, d2}, [r0]!                  ; load 16 Ys
  MEMACCESS	1
  vld1.8     {d1}, [r1]!                      ; load 8 Us
  MEMACCESS	2
  vld1.8     {d3}, [r2]!                      ; load 8 Vs
  subs       r4, r4, #16                      ; 16 pixels
  MEMACCESS	3
  vst4.8     {d0, d1, d2, d3}, [r3]!          ; Store 8 YUY2/16 pixels.
  bgt        %b1

  vpop		  {d0 - d3}
  pop		    {r4}
  bx 		  	lr
  ENDP

I422ToUYVYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y
  ;     r1 = const uint8* src_u
  ;     r2 = const uint8* src_v
  ;     r3 =  uint8* dst_uyvy
  push	     {r4}
  ldr        r4, [sp,#4]                      ; int width
  vpush 	   {d0 - d3}

1
  MEMACCESS	0
  vld2.8     {d1, d3}, [r0]!                  ; load 16 Ys
  MEMACCESS	1
  vld1.8     {d0}, [r1]!                      ; load 8 Us
  MEMACCESS	2
  vld1.8     {d2}, [r2]!                      ; load 8 Vs
  subs       r4, r4, #16                      ; 16 pixels
  MEMACCESS	3
  vst4.8     {d0, d1, d2, d3}, [r3]!          ; Store 8 UYVY/16 pixels.
  bgt        %b1

  vpop		  {d0 - d3}
  pop		    {r4}
  bx 			  lr
  ENDP

  ; TODO(fbarchard): Consider vhadd vertical, then vpaddl horizontal, ashr.
ARGBToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = int src_stride_argb
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_argb
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	0
  vld4.8     {d1, d3, d5, d7}, [r0]!          ; load next 8 ARGB pixels.
  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld4.8     {d8, d10, d12, d14}, [r1]!       ; load 8 more ARGB pixels.
  MEMACCESS	1
  vld4.8     {d9, d11, d13, d15}, [r1]!       ; load last 8 ARGB pixels.
  vpadal.u8  q0, q4                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q2, q6                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q0, q1, q2
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		    {q15}
  vpop		    {q8 - q14}
  vpop	      {q0 - q7}
  pop		    	{r4}
  bx		    	lr
  ENDP

ARGBToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_bgra
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush	     {q0-q2}
  vpush	     {q12,q13}

  vmov.u8    d24, #13                         ; B * 0.1016 coefficient
  vmov.u8    d25, #65                         ; G * 0.5078 coefficient
  vmov.u8    d26, #33                         ; R * 0.2578 coefficient
  vmov.u8    d27, #16                         ; Add 16 constant

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d27
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop		   {q12, q13}
  vpop		   {q0-q2}
  bx	       lr
  ENDP

RAWToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_raw
  ;     r1 = int src_stride_raw
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_raw
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld3.8     {d0, d2, d4}, [r0]!              ; load 8 RAW pixels.
  MEMACCESS	0
  vld3.8     {d1, d3, d5}, [r0]!              ; load next 8 RAW pixels.
  vpaddl.u8  q2, q2                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q0, q0                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld3.8     {d8, d10, d12}, [r1]!            ; load 8 more RAW pixels.
  MEMACCESS	1
  vld3.8     {d9, d11, d13}, [r1]!            ; load last 8 RAW pixels.
  vpadal.u8  q2, q6                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q0, q4                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV	   q2, q1, q0
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		   {q15}
  vpop		   {q8 - q14}
  vpop	   	 {q0 - q7}
  pop		     {r4}
  bx		     lr
  ENDP

RAWToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_raw
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush      {d0 - d7}
  vpush      {q8}

  vmov.u8    d4, #33                          ; R * 0.2578 coefficient
  vmov.u8    d5, #65                          ; G * 0.5078 coefficient
  vmov.u8    d6, #13                          ; B * 0.1016 coefficient
  vmov.u8    d7, #16                          ; Add 16 constant

1
  MEMACCESS	0
  vld3.8     {d0, d1, d2}, [r0]!              ; load 8 pixels of RAW.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q8, d0, d4                       ; B
  vmlal.u8   q8, d1, d5                       ; G
  vmlal.u8   q8, d2, d6                       ; R
  vqrshrun.s16 d0, q8, #7                     ; 16 bit to 8 bit Y
  vqadd.u8   d0, d7
  MEMACCESS	1
  vst1.8     {d0}, [r1]!                      ; store 8 pixels Y.
  bgt        %b1

  vpop 		  {q8}
  vpop		  {d0-d7}
  bx			  lr
  ENDP


RGB24ToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_rgb24
  ;     r1 = int src_stride_rgb24
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; src_stride + src_rgb24
  vmov.s16   q10, #112 / 2                    ; UB / VR 0.875 coefficient
  vmov.s16   q11, #74 / 2                     ; UG -0.5781 coefficient
  vmov.s16   q12, #38 / 2                     ; UR -0.2969 coefficient
  vmov.s16   q13, #18 / 2                     ; VB -0.1406 coefficient
  vmov.s16   q14, #94 / 2                     ; VG -0.7344 coefficient
  vmov.u16   q15, #0x8080                     ; 128.5

1
  MEMACCESS	0
  vld3.8     {d0, d2, d4}, [r0]!              ; load 8 RGB24 pixels.
  MEMACCESS	0
  vld3.8     {d1, d3, d5}, [r0]!              ; load next 8 RGB24 pixels.
  vpaddl.u8  q0, q0                           ; B 16 bytes -> 8 shorts.
  vpaddl.u8  q1, q1                           ; G 16 bytes -> 8 shorts.
  vpaddl.u8  q2, q2                           ; R 16 bytes -> 8 shorts.
  MEMACCESS	1
  vld3.8     {d8, d10, d12}, [r1]!            ; load 8 more RGB24 pixels.
  MEMACCESS	1
  vld3.8     {d9, d11, d13}, [r1]!            ; load last 8 RGB24 pixels.
  vpadal.u8  q0, q4                           ; B 16 bytes -> 8 shorts.
  vpadal.u8  q1, q5                           ; G 16 bytes -> 8 shorts.
  vpadal.u8  q2, q6                           ; R 16 bytes -> 8 shorts.

  vrshr.u16  q0, q0, #1                       ; 2x average
  vrshr.u16  q1, q1, #1
  vrshr.u16  q2, q2, #1

  subs       r4, r4, #16                      ; 32 processed per loop.
  RGBTOUV    q0, q1, q2
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 pixels U.
  MEMACCESS	3
  vst1.8     {d1}, [r3]!                      ; store 8 pixels V.
  bgt        %b1

  vpop		   {q15}
  vpop		   {q8 - q14}
  vpop	   	 {q0 - q7}
  pop		     {r4}
  bx		     lr
  ENDP

UYVYToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_uyvy
  ;     r1 = int stride_uyvy
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {q0 - q7}
  vpush 	   {q8 - q14}
  vpush	     {q15}

  add        r1, r0, r1                       ; stride + src_uyvy
1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 16 pixels of UYVY.
  subs       r4, r4, #16                      ; 16 pixels = 8 UVs.
  MEMACCESS	1
  vld4.8     {d4, d5, d6, d7}, [r1]!          ; load next row UYVY.
  vrhadd.u8  d0, d0, d4                       ; average rows of U
  vrhadd.u8  d2, d2, d6                       ; average rows of V
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 U.
  MEMACCESS	3
  vst1.8     {d2}, [r3]!                      ; store 8 V.
  bgt        %b1

  vpop		    {q15}
  vpop		    {q8 - q14}
  vpop	   	  {q0 - q7}
  pop		    	{r4}
  bx		    	lr
  ENDP

UYVYToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_uyvy
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush		  {q0, q1}

1
  MEMACCESS	0
  vld2.8     {q0, q1}, [r0]!                  ; load 16 pixels of UYVY.
  subs       r2, r2, #16                      ; 16 processed per loop.
  MEMACCESS	1
  vst1.8     {q1}, [r1]!                      ; store 16 pixels of Y.
  bgt        %b1

  vpop		   {q0, q1}
  bx		     lr
  ENDP

YUY2ToUVRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_yuy2
  ;     r1 = int stride_yuy2
  ;     r2 = uint8* dst_u
  ;     r3 = uint8* dst_v
  push       {r4}
  ldr        r4, [sp,#4]                      ; int pix
  vpush	     {d0 - d7}

  add        r1, r0, r1                       ; stride + src_yuy2

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 16 pixels of YUY2.
  subs       r4, r4, #16                      ; 16 pixels = 8 UVs.
  MEMACCESS	1
  vld4.8     {d4, d5, d6, d7}, [r1]!          ; load next row YUY2.
  vrhadd.u8  d1, d1, d5                       ; average rows of U
  vrhadd.u8  d3, d3, d7                       ; average rows of V
  MEMACCESS	2
  vst1.8     {d1}, [r2]!                      ; store 8 U.
  MEMACCESS	3
  vst1.8     {d3}, [r3]!                      ; store 8 V.
  bgt        %b1

  vpop 	   {d0 - d7}
  pop		   {r4}
  bx		   lr
  ENDP

YUY2ToYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_yuy2
  ;     r1 = uint8* dst_y
  ;     r2 = int pix
  vpush     {q0, q1}

1
  MEMACCESS	0
  vld2.8     {q0, q1}, [r0]!                  ; load 16 pixels of YUY2.
  subs       r2, r2, #16                      ; 16 processed per loop.
  MEMACCESS	1
  vst1.8     {q0}, [r1]!                      ; store 16 pixels of Y.
  bgt        %b1

  vpop       {q0, q1}
  bx         lr
  ENDP

ARGBToRGB565DitherRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_rgb
  ;     r2 = const uint32 dither4
  ;     r3 = int width
  vpush       {q0, q1}
  vpush       {q8-q11}

  vdup.32    d2, r2                           ; dither4
1
  MEMACCESS	1
  vld4.8     {d20, d21, d22, d23}, [r0]!      ; load 8 pixels of ARGB.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vqadd.u8   d20, d20, d2
  vqadd.u8   d21, d21, d2
  vqadd.u8   d22, d22, d2
  ARGBTORGB565
  MEMACCESS	0
  vst1.8     {q0}, [r1]!                      ; store 8 pixels RGB565.
  bgt        %b1

  vpop      {q8-q11}
  vpop      {q0, q1}
  bx        lr
  ENDP

; Add 2 rows of ARGB pixels together, 8 pixels at a time.
ARGBAddRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb0
  ;     r1 = uint8* src_argb1
  ;     r2 = uint8* dst_arg
  ;     r3 = int width
   vpush       {q0 - q3}
  ; 8 pixel loop.
1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	1
  vld4.8     {d4, d5, d6, d7}, [r1]!          ; load 8 more ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vqadd.u8   q0, q0, q2                       ; add B, G
  vqadd.u8   q1, q1, q3                       ; add R, A
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop       {q0 - q3}
  bx         lr
  ENDP

; Subtract 2 rows of ARGB pixels, 8 pixels at a time.
ARGBSubtractRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb0
  ;     r1 = uint8* src_argb1
  ;     r2 = uint8* dst_arg
  ;     r3 = int width
   vpush       {q0 - q3}
  ; 8 pixel loop.

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	1
  vld4.8     {d4, d5, d6, d7}, [r1]!          ; load 8 more ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vqsub.u8   q0, q0, q2                       ; subtract B, G
  vqsub.u8   q1, q1, q3                       ; subtract R, A
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop       {q0 - q3}
  bx         lr
  ENDP

; Adds Sobel X and Sobel Y and stores Sobel into ARGB.
; A = 255
; R = Sobel
; G = Sobel
; B = Sobel
SobelRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_sobelx
  ;     r1 = const uint8* src_sobely
  ;     r2 = uint8* dst_argb
  ;     r3 = int width
  vpush       {q0 - q1}
  vmov.u8    d3, #255                         ; alpha
  ; 8 pixel loop.

1
  MEMACCESS	0
  vld1.8     {d0}, [r0]!                      ; load 8 sobelx.
  MEMACCESS	1
  vld1.8     {d1}, [r1]!                      ; load 8 sobely.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vqadd.u8   d0, d0, d1                       ; add
  vmov.u8    d1, d0
  vmov.u8    d2, d0
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop       {q0 - q1}
  bx         lr
  ENDP

; Adds Sobel X and Sobel Y and stores Sobel into plane.
SobelToPlaneRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_sobelx
  ;     r1 = const uint8* src_sobely
  ;     r2 = uint8* dst_y
  ;     r3 = int width
  vpush       {q0 - q1}
  ; 16 pixel loop.

1
  MEMACCESS	0
  vld1.8     {q0}, [r0]!                      ; load 16 sobelx.
  MEMACCESS	1
  vld1.8     {q1}, [r1]!                      ; load 16 sobely.
  subs       r3, r3, #16                      ; 16 processed per loop.
  vqadd.u8   q0, q0, q1                       ; add
  MEMACCESS	2
  vst1.8     {q0}, [r2]!                      ; store 16 pixels.
  bgt        %b1

  vpop       {q0 - q1}
  bx         lr
  ENDP

; Attenuate 8 pixels at a time.
ARGBAttenuateRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = const uint8* dst_argb
  ;     r2 = int width
  vpush       {q0 - q1}
  vpush       {q10 - q12}

  ; Attenuate 8 pixels.
1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q10, d0, d3                      ; b * a
  vmull.u8   q11, d1, d3                      ; g * a
  vmull.u8   q12, d2, d3                      ; r * a
  vqrshrn.u16 d0, q10, #8                     ; b >>= 8
  vqrshrn.u16 d1, q11, #8                     ; g >>= 8
  vqrshrn.u16 d2, q12, #8                     ; r >>= 8
  MEMACCESS	1
  vst4.8     {d0, d1, d2, d3}, [r1]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop  	  {q10 - q12}
  vpop		  {q0 - q1}
  bx			  lr
  ENDP

; Quantize 8 ARGB pixels (32 bytes).
; dst = (dst * scale >> 16) * interval_size + interval_offset;
ARGBQuantizeRow_NEON PROC
  ; input
  ;     r0 = uint8* dst_argb
  ;     r1 = int scale
  ;     r2 = int interval_size
  ;     r3 = int interval_offset
  push       {r2 - r4}
  ldr        r4, [sp,#12]                      ; int width
  vpush	     {q0 - q3}
  vpush	     {q8 - q10}

  vdup.u16   q8, r1
  vshr.u16   q8, q8, #1                       ; scale >>= 1
  vdup.u16   q9, r2                           ; interval multiply.
  vdup.u16   q10, r3                          ; interval add

  ; 8 pixel loop.
1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]           ; load 8 pixels of ARGB.
  subs       r4, r4, #8                       ; 8 processed per loop.
  vmovl.u8   q0, d0                           ; b (0 .. 255)
  vmovl.u8   q1, d2
  vmovl.u8   q2, d4
  vqdmulh.s16 q0, q0, q8                      ; b * scale
  vqdmulh.s16 q1, q1, q8                      ; g
  vqdmulh.s16 q2, q2, q8                      ; r
  vmul.u16   q0, q0, q9                       ; b * interval_size
  vmul.u16   q1, q1, q9                       ; g
  vmul.u16   q2, q2, q9                       ; r
  vadd.u16   q0, q0, q10                      ; b + interval_offset
  vadd.u16   q1, q1, q10                      ; g
  vadd.u16   q2, q2, q10                      ; r
  vqmovn.u16 d0, q0
  vqmovn.u16 d2, q1
  vqmovn.u16 d4, q2
  MEMACCESS	0
  vst4.8     {d0, d2, d4, d6}, [r0]!          ; store 8 pixels of ARGB.
  bgt        %b1

  vpop		  {q8 - q10}
  vpop		  {q0 - q3}
  pop		  	{r2 - r4}
  bx		  	lr
  ENDP

; Shade 8 pixels at a time by specified value.
; NOTE vqrdmulh.s16 q10, q10, d0[0] must use a scaler register from 0 to 8.
; Rounding in vqrdmulh does +1 to high if high bit of low s16 is set.
ARGBShadeRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = int width
  ;     r3 = int value
  vpush	     {q0}
  vpush	     {q10 - q13}

  vdup.u32   q0, r3                           ; duplicate scale value.
  vzip.u8    d0, d1                           ; d0 aarrggbb.
  vshr.u16   q0, q0, #1                       ; scale / 2.

  ; 8 pixel loop.
1
  MEMACCESS	0
  vld4.8     {d20, d22, d24, d26}, [r0]!      ; load 8 pixels of ARGB.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmovl.u8   q10, d20                         ; b (0 .. 255)
  vmovl.u8   q11, d22
  vmovl.u8   q12, d24
  vmovl.u8   q13, d26
  vqrdmulh.s16 q10, q10, d0[0]                ; b * scale * 2
  vqrdmulh.s16 q11, q11, d0[1]                ; g
  vqrdmulh.s16 q12, q12, d0[2]                ; r
  vqrdmulh.s16 q13, q13, d0[3]                ; a
  vqmovn.u16 d20, q10
  vqmovn.u16 d22, q11
  vqmovn.u16 d24, q12
  vqmovn.u16 d26, q13
  MEMACCESS	1
  vst4.8     {d20, d22, d24, d26}, [r1]!      ; store 8 pixels of ARGB.
  bgt        %b1

  vpop		  {q10 - q13}
  vpop		  {q0}
  bx		  	lr
  ENDP

; Convert 8 ARGB pixels (64 bytes) to 8 Gray ARGB pixels
; Similar to ARGBToYJ but stores ARGB.
; C code is (15 * b + 75 * g + 38 * r + 64) >> 7;
ARGBGrayRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = int width
  vpush	     {q0- q2}
  vpush	     {q12 - q13}

  vmov.u8    d24, #15                         ; B * 0.11400 coefficient
  vmov.u8    d25, #75                         ; G * 0.58700 coefficient
  vmov.u8    d26, #38                         ; R * 0.29900 coefficient

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 ARGB pixels.
  subs       r2, r2, #8                       ; 8 processed per loop.
  vmull.u8   q2, d0, d24                      ; B
  vmlal.u8   q2, d1, d25                      ; G
  vmlal.u8   q2, d2, d26                      ; R
  vqrshrun.s16 d0, q2, #7                     ; 15 bit to 8 bit B
  vmov       d1, d0                           ; G
  vmov       d2, d0                           ; R
  MEMACCESS	1
  vst4.8     {d0, d1, d2, d3}, [r1]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop		  {q12 - q13}
  vpop		  {q0 - q2}
  bx			  lr
  ENDP

; Convert 8 ARGB pixels (32 bytes) to 8 Sepia ARGB pixels.
;    b = (r * 35 + g * 68 + b * 17) >> 7
;    g = (r * 45 + g * 88 + b * 22) >> 7
;    r = (r * 50 + g * 98 + b * 24) >> 7
ARGBSepiaRow_NEON PROC
  ; input
  ;     r0 = uint8* dst_argb
  ;     r1 = int width
  vpush	     {q0- q3}
  vpush	     {q10 - q15}

  vmov.u8    d20, #17                         ; BB coefficient
  vmov.u8    d21, #68                         ; BG coefficient
  vmov.u8    d22, #35                         ; BR coefficient
  vmov.u8    d24, #22                         ; GB coefficient
  vmov.u8    d25, #88                         ; GG coefficient
  vmov.u8    d26, #45                         ; GR coefficient
  vmov.u8    d28, #24                         ; BB coefficient
  vmov.u8    d29, #98                         ; BG coefficient
  vmov.u8    d30, #50                         ; BR coefficient

1
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]           ; load 8 ARGB pixels.
  subs       r1, r1, #8                       ; 8 processed per loop.
  vmull.u8   q2, d0, d20                      ; B to Sepia B
  vmlal.u8   q2, d1, d21                      ; G
  vmlal.u8   q2, d2, d22                      ; R
  vmull.u8   q3, d0, d24                      ; B to Sepia G
  vmlal.u8   q3, d1, d25                      ; G
  vmlal.u8   q3, d2, d26                      ; R
  vmull.u8   q8, d0, d28                      ; B to Sepia R
  vmlal.u8   q8, d1, d29                      ; G
  vmlal.u8   q8, d2, d30                      ; R
  vqshrn.u16 d0, q2, #7                       ; 16 bit to 8 bit B
  vqshrn.u16 d1, q3, #7                       ; 16 bit to 8 bit G
  vqshrn.u16 d2, q8, #7                       ; 16 bit to 8 bit R
  MEMACCESS	0
  vst4.8     {d0, d1, d2, d3}, [r0]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop	  	{q10 - q15}
  vpop	  	{q0 - q3}
  bx		  	lr
  ENDP

; Tranform 8 ARGB pixels (32 bytes) with color matrix.
; TODO(fbarchard): Was same as Sepia except matrix is provided.  This function
; needs to saturate.  Consider doing a non-saturating version.
ARGBColorMatrixRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_argb
  ;     r1 = uint8* dst_argb
  ;     r2 = const int8* matrix_argb
  ;     r3 = int width
  vpush	     {q0 - q7}
  vpush	     {q8 - q14}
  vpush		   {q15}

  MEMACCESS	3
  vld1.8     {q2}, [r2]                       ; load 3 ARGB vectors.
  vmovl.s8   q0, d4                           ; B,G coefficients s16.
  vmovl.s8   q1, d5                           ; R,A coefficients s16.

1
  MEMACCESS	0
  vld4.8     {d16, d18, d20, d22}, [r0]!      ; load 8 ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vmovl.u8   q8, d16                          ; b (0 .. 255) 16 bit
  vmovl.u8   q9, d18                          ; g
  vmovl.u8   q10, d20                         ; r
  vmovl.u8   q11, d22                         ; a
  vmul.s16   q12, q8, d0[0]                   ; B = B * Matrix B
  vmul.s16   q13, q8, d1[0]                   ; G = B * Matrix G
  vmul.s16   q14, q8, d2[0]                   ; R = B * Matrix R
  vmul.s16   q15, q8, d3[0]                   ; A = B * Matrix A
  vmul.s16   q4, q9, d0[1]                    ; B += G * Matrix B
  vmul.s16   q5, q9, d1[1]                    ; G += G * Matrix G
  vmul.s16   q6, q9, d2[1]                    ; R += G * Matrix R
  vmul.s16   q7, q9, d3[1]                    ; A += G * Matrix A
  vqadd.s16  q12, q12, q4                     ; Accumulate B
  vqadd.s16  q13, q13, q5                     ; Accumulate G
  vqadd.s16  q14, q14, q6                     ; Accumulate R
  vqadd.s16  q15, q15, q7                     ; Accumulate A
  vmul.s16   q4, q10, d0[2]                   ; B += R * Matrix B
  vmul.s16   q5, q10, d1[2]                   ; G += R * Matrix G
  vmul.s16   q6, q10, d2[2]                   ; R += R * Matrix R
  vmul.s16   q7, q10, d3[2]                   ; A += R * Matrix A
  vqadd.s16  q12, q12, q4                     ; Accumulate B
  vqadd.s16  q13, q13, q5                     ; Accumulate G
  vqadd.s16  q14, q14, q6                     ; Accumulate R
  vqadd.s16  q15, q15, q7                     ; Accumulate A
  vmul.s16   q4, q11, d0[3]                   ; B += A * Matrix B
  vmul.s16   q5, q11, d1[3]                   ; G += A * Matrix G
  vmul.s16   q6, q11, d2[3]                   ; R += A * Matrix R
  vmul.s16   q7, q11, d3[3]                   ; A += A * Matrix A
  vqadd.s16  q12, q12, q4                     ; Accumulate B
  vqadd.s16  q13, q13, q5                     ; Accumulate G
  vqadd.s16  q14, q14, q6                     ; Accumulate R
  vqadd.s16  q15, q15, q7                     ; Accumulate A
  vqshrun.s16 d16, q12, #6                    ; 16 bit to 8 bit B
  vqshrun.s16 d18, q13, #6                    ; 16 bit to 8 bit G
  vqshrun.s16 d20, q14, #6                    ; 16 bit to 8 bit R
  vqshrun.s16 d22, q15, #6                    ; 16 bit to 8 bit A
  MEMACCESS	1
  vst4.8     {d16, d18, d20, d22}, [r1]!      ; store 8 ARGB pixels.
  bgt        %b1

  vpop	  	{q15}
  vpop		  {q8 - q14}
  vpop	  	{q0 - q7}
  bx			  lr
  ENDP

  ; dr * (256 - sa) / 256 + sr = dr - dr * sa / 256 + sr
ARGBBlendRow_NEON PROC
   ; input
  ;     r0 = const uint8* src_argb0
  ;     r1 = const uint8* src_argb1
  ;     r2 = int8* dst_argb
  ;     r3 = int width
  vpush	     {q0 - q3}
  vpush	     {q10 - q12}

  subs       r3, #8
  blt        %f89
  ; Blend 8 pixels.
8
  MEMACCESS	0
  vld4.8     {d0, d1, d2, d3}, [r0]!          ; load 8 pixels of ARGB0.
  MEMACCESS	1
  vld4.8     {d4, d5, d6, d7}, [r1]!          ; load 8 pixels of ARGB1.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vmull.u8   q10, d4, d3                      ; db * a
  vmull.u8   q11, d5, d3                      ; dg * a
  vmull.u8   q12, d6, d3                      ; dr * a
  vqrshrn.u16 d20, q10, #8                    ; db >>= 8
  vqrshrn.u16 d21, q11, #8                    ; dg >>= 8
  vqrshrn.u16 d22, q12, #8                    ; dr >>= 8
  vqsub.u8   q2, q2, q10                      ; dbg - dbg * a / 256
  vqsub.u8   d6, d6, d22                      ; dr - dr * a / 256
  vqadd.u8   q0, q0, q2                       ; + sbg
  vqadd.u8   d2, d2, d6                       ; + sr
  vmov.u8    d3, #255                         ; a = 255
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 pixels of ARGB.
  bge        %b8

89
  adds       r3, #8-1
  blt        %f99

  ; Blend 1 pixels.
1
  MEMACCESS	0
  vld4.8     {d0[0],d1[0],d2[0],d3[0]}, [r0]!   ; load 1 pixel ARGB0.
  MEMACCESS	1
  vld4.8     {d4[0],d5[0],d6[0],d7[0]}, [r1]!   ; load 1 pixel ARGB1.
  subs       r3, r3, #1                       ; 1 processed per loop.
  vmull.u8   q10, d4, d3                      ; db * a
  vmull.u8   q11, d5, d3                      ; dg * a
  vmull.u8   q12, d6, d3                      ; dr * a
  vqrshrn.u16 d20, q10, #8                    ; db >>= 8
  vqrshrn.u16 d21, q11, #8                    ; dg >>= 8
  vqrshrn.u16 d22, q12, #8                    ; dr >>= 8
  vqsub.u8   q2, q2, q10                      ; dbg - dbg * a / 256
  vqsub.u8   d6, d6, d22                      ; dr - dr * a / 256
  vqadd.u8   q0, q0, q2                       ; + sbg
  vqadd.u8   d2, d2, d6                       ; + sr
  vmov.u8    d3, #255                         ; a = 255
  MEMACCESS	2
  vst4.8     {d0[0],d1[0],d2[0],d3[0]}, [r2]!   ; store 1 pixel.
  bge        %b1

99

  vpop 		  {q10 - q12}
  vpop		  {q0 - q3}
  bx			  lr
  ENDP

; Bilinear filter 16x2 -> 16x1
InterpolateRow_NEON PROC
   ; input
  ;     r0 = const uint8* dst_ptr
  ;     r1 = const uint8* src_ptr
  ;     r2 = int8* dst_argb
  ;     r3 = int width
  push       {r4}
  ldr        r4, [sp,#4]                      ; int width
  vpush	     {q0 - q1}
  vpush	     {d4 - d5}
  vpush	  	 {q13 - q14}

  cmp        r4, #0
  beq        %f100
  add        r2, r1
  cmp        r4, #64
  beq        %f75
  cmp        r4, #128
  beq        %f50
  cmp        r4, #192
  beq        %f25

  vdup.8     d5, r4
  rsb        r4, #256
  vdup.8     d4, r4
  ; General purpose row blend.
1
  MEMACCESS	1
  vld1.8     {q0}, [r1]!
  MEMACCESS	2
  vld1.8     {q1}, [r2]!
  subs       r3, r3, #16
  vmull.u8   q13, d0, d4
  vmull.u8   q14, d1, d4
  vmlal.u8   q13, d2, d5
  vmlal.u8   q14, d3, d5
  vrshrn.u16 d0, q13, #8
  vrshrn.u16 d1, q14, #8
  MEMACCESS	0
  vst1.8     {q0}, [r0]!
  bgt        %b1
  b          %f99

  ; Blend 25 / 75.
25
  MEMACCESS	1
  vld1.8     {q0}, [r1]!
  MEMACCESS	2
  vld1.8     {q1}, [r2]!
  subs       r3, r3, #16
  vrhadd.u8  q0, q1
  vrhadd.u8  q0, q1
  MEMACCESS	0
  vst1.8     {q0}, [r0]!
  bgt        %b25
  b          %f99

  ; Blend 50 / 50.
50
  MEMACCESS	1
  vld1.8     {q0}, [r1]!
  MEMACCESS	2
  vld1.8     {q1}, [r2]!
  subs       r3, r3, #16
  vrhadd.u8  q0, q1
  MEMACCESS	0
  vst1.8     {q0}, [r0]!
  bgt        %b50
  b          %f99

  ; Blend 75 / 25.
75
  MEMACCESS	1
  vld1.8     {q1}, [r1]!
  MEMACCESS	2
  vld1.8     {q0}, [r2]!
  subs       r3, r3, #16
  vrhadd.u8  q0, q1
  vrhadd.u8  q0, q1
  MEMACCESS	0
  vst1.8     {q0}, [r0]!
  bgt        %b75
  b          %f99

  ; Blend 100 / 0 - Copy row unchanged.
100
  MEMACCESS	1
  vld1.8     {q0}, [r1]!
  subs       r3, r3, #16
  MEMACCESS	0
  vst1.8     {q0}, [r0]!
  bgt        %b100

99

  vpop		  {q13 - q14}
  vpop		  {d4 - d5}
  vpop		  {q0 - q1}
  pop			  {r4}
  bx			  lr
  ENDP

; Multiply 2 rows of ARGB pixels together, 8 pixels at a time.
ARGBMultiplyRow_NEON PROC
   ; input
  ;     r0 = const uint8* src_argb0
  ;     r1 = const uint8* src_argb1
  ;     r2 = int8* dst_argb
  ;     r3 = int width
  vpush	     {q0 - q3}

  ; 8 pixel loop.
1
  MEMACCESS	0
  vld4.8     {d0, d2, d4, d6}, [r0]!          ; load 8 ARGB pixels.
  MEMACCESS	1
  vld4.8     {d1, d3, d5, d7}, [r1]!          ; load 8 more ARGB pixels.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vmull.u8   q0, d0, d1                       ; multiply B
  vmull.u8   q1, d2, d3                       ; multiply G
  vmull.u8   q2, d4, d5                       ; multiply R
  vmull.u8   q3, d6, d7                       ; multiply A
  vrshrn.u16 d0, q0, #8                       ; 16 bit to 8 bit B
  vrshrn.u16 d1, q1, #8                       ; 16 bit to 8 bit G
  vrshrn.u16 d2, q2, #8                       ; 16 bit to 8 bit R
  vrshrn.u16 d3, q3, #8                       ; 16 bit to 8 bit A
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop	  	 {q0 - q3}
  bx			   lr
  ENDP

; SobelX as a matrix is
; -1  0  1
; -2  0  2
; -1  0  1
SobelXRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y0
  ;     r1 = const uint8* src_y1
  ;     r2 = const uint8* src_y2
  ;     r3 = uint8* dst_sobelx
  push      {r4 - r6}
  ldr       r4, [sp,#12]                      ; int width
  vpush	    {q0 - q1}
  mov		   	r5, 2
  mov		   	r6, 6

1
  MEMACCESS	0
  vld1.8     {d0}, [r0],r5                    ; top
  MEMACCESS	0
  vld1.8     {d1}, [r0],r6
  vsubl.u8   q0, d0, d1
  MEMACCESS	1
  vld1.8     {d2}, [r1],r5                    ; center * 2
  MEMACCESS	1
  vld1.8     {d3}, [r1],r6
  vsubl.u8   q1, d2, d3
  vadd.s16   q0, q0, q1
  vadd.s16   q0, q0, q1
  MEMACCESS	2
  vld1.8     {d2}, [r2],r5                    ; bottom
  MEMACCESS	2
  vld1.8     {d3}, [r2],r6
  subs       r4, r4, #8                       ; 8 pixels
  vsubl.u8   q1, d2, d3
  vadd.s16   q0, q0, q1
  vabs.s16   q0, q0
  vqmovn.u16 d0, q0
  MEMACCESS	3
  vst1.8     {d0}, [r3]!                      ; store 8 sobelx
  bgt        %b1

  vpop	  	{q0 - q1}
  pop		  	{r4 - r6}
  bx		  	lr
  ENDP

; SobelY as a matrix is
; -1 -2 -1
;  0  0  0
;  1  2  1
SobelYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_y0
  ;     r1 = const uint8* src_y1
  ;     r2 = uint8* dst_sobely
  ;     r3 = int width
  vpush	     {q0 - q1}
  push	     {r4 - r5}
  mov		     r4, 1
  mov			   r5, 6

1
  MEMACCESS	0
  vld1.8     {d0}, [r0],r4                    ; left
  MEMACCESS	1
  vld1.8     {d1}, [r1],r4
  vsubl.u8   q0, d0, d1
  MEMACCESS	0
  vld1.8     {d2}, [r0],r4                    ; center * 2
  MEMACCESS	1
  vld1.8     {d3}, [r1],r4
  vsubl.u8   q1, d2, d3
  vadd.s16   q0, q0, q1
  vadd.s16   q0, q0, q1
  MEMACCESS	0
  vld1.8     {d2}, [r0],r5                    ; right
  MEMACCESS	1
  vld1.8     {d3}, [r1],r5
  subs       r3, r3, #8                       ; 8 pixels
  vsubl.u8   q1, d2, d3
  vadd.s16   q0, q0, q1
  vabs.s16   q0, q0
  vqmovn.u16 d0, q0
  MEMACCESS	2
  vst1.8     {d0}, [r2]!                      ; store 8 sobely
  bgt        %b1

  pop		     {r4 - r5}
  vpop	     {q0 - q1}
  bx		     lr
  ENDP

; Mixes Sobel X, Sobel Y and Sobel into ARGB.
; A = 255
; R = Sobel X
; G = Sobel
; B = Sobel Y
SobelXYRow_NEON PROC
  ; input
  ;     r0 = const uint8* src_sobelx
  ;     r1 = const uint8* src_sobely
  ;     r2 = uint8* dst_argb
  ;     r3 = int width
  vpush	     {q0 - q1}

  vmov.u8    d3, #255                         ; alpha
  ; 8 pixel loop.

1
  MEMACCESS	0
  vld1.8     {d2}, [r0]!                      ; load 8 sobelx.
  MEMACCESS	1
  vld1.8     {d0}, [r1]!                      ; load 8 sobely.
  subs       r3, r3, #8                       ; 8 processed per loop.
  vqadd.u8   d1, d0, d2                       ; add
  MEMACCESS	2
  vst4.8     {d0, d1, d2, d3}, [r2]!          ; store 8 ARGB pixels.
  bgt        %b1

  vpop	     {q0 - q1}
  bx		     lr
  ENDP


  END


