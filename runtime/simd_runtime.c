// XIOM SIMD Runtime -- SSE/AVX/NEON intrinsics
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

#include <stdint.h>
#include <stdlib.h>   /* malloc -- used by every backend (x86/arm/scalar) */
#include <math.h>     /* sqrtf -- used by the scalar fallback backend */

#ifdef __x86_64__
#include <cpuid.h>
#include <x86intrin.h>

int xiom_simd_available(void) {
    unsigned int eax, ebx, ecx, edx;
    __get_cpuid(1, &eax, &ebx, &ecx, &edx);
    int flags = 0;
    if (edx & (1<<25)) flags |= 1;   // SSE
    if (edx & (1<<26)) flags |= 2;   // SSE2
    if (ecx & (1<<28)) flags |= 4;   // AVX
    if (ebx & (1<<5))  flags |= 8;   // AVX2
    __get_cpuid_count(7, 0, &eax, &ebx, &ecx, &edx);
    if (ebx & (1<<16)) flags |= 16;  // AVX-512F
    return flags;
}

int xiom_simd_has_sse(void)    { return (xiom_simd_available() & 1) != 0; }
int xiom_simd_has_sse2(void)   { return (xiom_simd_available() & 2) != 0; }
int xiom_simd_has_avx(void)    { return (xiom_simd_available() & 4) != 0; }
int xiom_simd_has_avx2(void)   { return (xiom_simd_available() & 8) != 0; }
int xiom_simd_has_avx512(void) { return (xiom_simd_available() & 16) != 0; }
int xiom_simd_has_neon(void)   { return 0; }

// 128-bit float ops using SSE

void xiom_simd_f32x4_add(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_add_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_sub(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_sub_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_mul(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_mul_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_div(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_div_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_sqrt(float* a, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vr = _mm_sqrt_ps(va);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_min(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_min_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

void xiom_simd_f32x4_max(float* a, float* b, float* out) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_max_ps(va, vb);
    _mm_storeu_ps(out, vr);
}

__attribute__((target("sse4.1")))
float xiom_simd_f32x4_dot(float* a, float* b) {
    __m128 va = _mm_loadu_ps(a);
    __m128 vb = _mm_loadu_ps(b);
    __m128 vr = _mm_dp_ps(va, vb, 0xF1);  // SSE4.1 dot product
    return _mm_cvtss_f32(vr);
}

// 128-bit integer ops using SSE2

void xiom_simd_i32x4_add(int* a, int* b, int* out) {
    __m128i va = _mm_loadu_si128((__m128i*)a);
    __m128i vb = _mm_loadu_si128((__m128i*)b);
    __m128i vr = _mm_add_epi32(va, vb);
    _mm_storeu_si128((__m128i*)out, vr);
}

void xiom_simd_i32x4_sub(int* a, int* b, int* out) {
    __m128i va = _mm_loadu_si128((__m128i*)a);
    __m128i vb = _mm_loadu_si128((__m128i*)b);
    __m128i vr = _mm_sub_epi32(va, vb);
    _mm_storeu_si128((__m128i*)out, vr);
}

__attribute__((target("sse4.1")))
void xiom_simd_i32x4_mul(int* a, int* b, int* out) {
    __m128i va = _mm_loadu_si128((__m128i*)a);
    __m128i vb = _mm_loadu_si128((__m128i*)b);
    __m128i vr = _mm_mullo_epi32(va, vb);  // SSE4.1
    _mm_storeu_si128((__m128i*)out, vr);
}

// 256-bit float ops using AVX

__attribute__((target("avx")))
void xiom_simd_f32x8_add(float* a, float* b, float* out) {
    __m256 va = _mm256_loadu_ps(a);
    __m256 vb = _mm256_loadu_ps(b);
    __m256 vr = _mm256_add_ps(va, vb);
    _mm256_storeu_ps(out, vr);
}

__attribute__((target("avx")))
void xiom_simd_f32x8_mul(float* a, float* b, float* out) {
    __m256 va = _mm256_loadu_ps(a);
    __m256 vb = _mm256_loadu_ps(b);
    __m256 vr = _mm256_mul_ps(va, vb);
    _mm256_storeu_ps(out, vr);
}

__attribute__((target("avx")))
void xiom_simd_f64x4_add(double* a, double* b, double* out) {
    __m256d va = _mm256_loadu_pd(a);
    __m256d vb = _mm256_loadu_pd(b);
    __m256d vr = _mm256_add_pd(va, vb);
    _mm256_storeu_pd(out, vr);
}

__attribute__((target("avx")))
void xiom_simd_f64x4_mul(double* a, double* b, double* out) {
    __m256d va = _mm256_loadu_pd(a);
    __m256d vb = _mm256_loadu_pd(b);
    __m256d vr = _mm256_mul_pd(va, vb);
    _mm256_storeu_pd(out, vr);
}

// Load / Store

float* xiom_simd_load_f32x4(float* src) {
    __m128 v = _mm_loadu_ps(src);
    float* out = (float*)malloc(16);
    _mm_storeu_ps(out, v);
    return out;
}

void xiom_simd_store_f32x4(float* src, float* dst) {
    __m128 v = _mm_loadu_ps(src);
    _mm_storeu_ps(dst, v);
}

// Conversion

void xiom_simd_f32_to_i32(float* src, int* dst) {
    __m128 v = _mm_loadu_ps(src);
    __m128i vi = _mm_cvttps_epi32(v);
    _mm_storeu_si128((__m128i*)dst, vi);
}

void xiom_simd_i32_to_f32(int* src, float* dst) {
    __m128i vi = _mm_loadu_si128((__m128i*)src);
    __m128 v = _mm_cvtepi32_ps(vi);
    _mm_storeu_ps(dst, v);
}

#elif defined(__aarch64__)
#include <arm_neon.h>

int xiom_simd_available(void) { return 32; }  // NEON always available on ARM64
int xiom_simd_has_sse(void)    { return 0; }
int xiom_simd_has_sse2(void)   { return 0; }
int xiom_simd_has_avx(void)    { return 0; }
int xiom_simd_has_avx2(void)   { return 0; }
int xiom_simd_has_avx512(void) { return 0; }
int xiom_simd_has_neon(void)   { return 1; }

void xiom_simd_f32x4_add(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vaddq_f32(va, vb);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_sub(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vsubq_f32(va, vb);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_mul(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vmulq_f32(va, vb);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_div(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vdivq_f32(va, vb);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_sqrt(float* a, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vr = vsqrtq_f32(va);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_min(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vminq_f32(va, vb);
    vst1q_f32(out, vr);
}

void xiom_simd_f32x4_max(float* a, float* b, float* out) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vr = vmaxq_f32(va, vb);
    vst1q_f32(out, vr);
}

float xiom_simd_f32x4_dot(float* a, float* b) {
    float32x4_t va = vld1q_f32(a);
    float32x4_t vb = vld1q_f32(b);
    float32x4_t vp = vmulq_f32(va, vb);
    float32x2_t vsum = vadd_f32(vget_low_f32(vp), vget_high_f32(vp));
    float result = vget_lane_f32(vsum, 0) + vget_lane_f32(vsum, 1);
    return result;
}

void xiom_simd_i32x4_add(int* a, int* b, int* out) {
    int32x4_t va = vld1q_s32(a);
    int32x4_t vb = vld1q_s32(b);
    int32x4_t vr = vaddq_s32(va, vb);
    vst1q_s32(out, vr);
}

void xiom_simd_i32x4_sub(int* a, int* b, int* out) {
    int32x4_t va = vld1q_s32(a);
    int32x4_t vb = vld1q_s32(b);
    int32x4_t vr = vsubq_s32(va, vb);
    vst1q_s32(out, vr);
}

void xiom_simd_i32x4_mul(int* a, int* b, int* out) {
    int32x4_t va = vld1q_s32(a);
    int32x4_t vb = vld1q_s32(b);
    int32x4_t vr = vmulq_s32(va, vb);
    vst1q_s32(out, vr);
}

float* xiom_simd_load_f32x4(float* src) {
    float32x4_t v = vld1q_f32(src);
    float* out = (float*)malloc(16);
    vst1q_f32(out, v);
    return out;
}

void xiom_simd_store_f32x4(float* src, float* dst) {
    float32x4_t v = vld1q_f32(src);
    vst1q_f32(dst, v);
}

void xiom_simd_f32_to_i32(float* src, int* dst) {
    float32x4_t v = vld1q_f32(src);
    int32x4_t vi = vcvtq_s32_f32(v);
    vst1q_s32(dst, vi);
}

void xiom_simd_i32_to_f32(int* src, float* dst) {
    int32x4_t vi = vld1q_s32(src);
    float32x4_t v = vcvtq_f32_s32(vi);
    vst1q_f32(dst, v);
}

#else
#include <stdlib.h>

// Scalar fallback implementations

int xiom_simd_available(void) { return 0; }
int xiom_simd_has_sse(void)    { return 0; }
int xiom_simd_has_sse2(void)   { return 0; }
int xiom_simd_has_avx(void)    { return 0; }
int xiom_simd_has_avx2(void)   { return 0; }
int xiom_simd_has_avx512(void) { return 0; }
int xiom_simd_has_neon(void)   { return 0; }

void xiom_simd_f32x4_add(float* a, float* b, float* out) {
    out[0] = a[0] + b[0]; out[1] = a[1] + b[1];
    out[2] = a[2] + b[2]; out[3] = a[3] + b[3];
}

void xiom_simd_f32x4_sub(float* a, float* b, float* out) {
    out[0] = a[0] - b[0]; out[1] = a[1] - b[1];
    out[2] = a[2] - b[2]; out[3] = a[3] - b[3];
}

void xiom_simd_f32x4_mul(float* a, float* b, float* out) {
    out[0] = a[0] * b[0]; out[1] = a[1] * b[1];
    out[2] = a[2] * b[2]; out[3] = a[3] * b[3];
}

void xiom_simd_f32x4_div(float* a, float* b, float* out) {
    out[0] = a[0] / b[0]; out[1] = a[1] / b[1];
    out[2] = a[2] / b[2]; out[3] = a[3] / b[3];
}

void xiom_simd_f32x4_sqrt(float* a, float* out) {
    out[0] = sqrtf(a[0]); out[1] = sqrtf(a[1]);
    out[2] = sqrtf(a[2]); out[3] = sqrtf(a[3]);
}

void xiom_simd_f32x4_min(float* a, float* b, float* out) {
    out[0] = a[0] < b[0] ? a[0] : b[0];
    out[1] = a[1] < b[1] ? a[1] : b[1];
    out[2] = a[2] < b[2] ? a[2] : b[2];
    out[3] = a[3] < b[3] ? a[3] : b[3];
}

void xiom_simd_f32x4_max(float* a, float* b, float* out) {
    out[0] = a[0] > b[0] ? a[0] : b[0];
    out[1] = a[1] > b[1] ? a[1] : b[1];
    out[2] = a[2] > b[2] ? a[2] : b[2];
    out[3] = a[3] > b[3] ? a[3] : b[3];
}

float xiom_simd_f32x4_dot(float* a, float* b) {
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3];
}

void xiom_simd_i32x4_add(int* a, int* b, int* out) {
    out[0] = a[0] + b[0]; out[1] = a[1] + b[1];
    out[2] = a[2] + b[2]; out[3] = a[3] + b[3];
}

void xiom_simd_i32x4_sub(int* a, int* b, int* out) {
    out[0] = a[0] - b[0]; out[1] = a[1] - b[1];
    out[2] = a[2] - b[2]; out[3] = a[3] - b[3];
}

void xiom_simd_i32x4_mul(int* a, int* b, int* out) {
    out[0] = a[0] * b[0]; out[1] = a[1] * b[1];
    out[2] = a[2] * b[2]; out[3] = a[3] * b[3];
}

float* xiom_simd_load_f32x4(float* src) {
    float* out = (float*)malloc(16);
    out[0] = src[0]; out[1] = src[1];
    out[2] = src[2]; out[3] = src[3];
    return out;
}

void xiom_simd_store_f32x4(float* src, float* dst) {
    dst[0] = src[0]; dst[1] = src[1];
    dst[2] = src[2]; dst[3] = src[3];
}

void xiom_simd_f32_to_i32(float* src, int* dst) {
    dst[0] = (int)src[0]; dst[1] = (int)src[1];
    dst[2] = (int)src[2]; dst[3] = (int)src[3];
}

void xiom_simd_i32_to_f32(int* src, float* dst) {
    dst[0] = (float)src[0]; dst[1] = (float)src[1];
    dst[2] = (float)src[2]; dst[3] = (float)src[3];
}

// 256-bit fallbacks -- called from .xi wrappers; here as no-op stubs
// real AVX path is in the __x86_64__ block above

void xiom_simd_f32x8_add(float* a, float* b, float* out) {
    out[0] = a[0] + b[0]; out[1] = a[1] + b[1];
    out[2] = a[2] + b[2]; out[3] = a[3] + b[3];
    out[4] = a[4] + b[4]; out[5] = a[5] + b[5];
    out[6] = a[6] + b[6]; out[7] = a[7] + b[7];
}

void xiom_simd_f32x8_mul(float* a, float* b, float* out) {
    out[0] = a[0] * b[0]; out[1] = a[1] * b[1];
    out[2] = a[2] * b[2]; out[3] = a[3] * b[3];
    out[4] = a[4] * b[4]; out[5] = a[5] * b[5];
    out[6] = a[6] * b[6]; out[7] = a[7] * b[7];
}

void xiom_simd_f64x4_add(double* a, double* b, double* out) {
    out[0] = a[0] + b[0]; out[1] = a[1] + b[1];
    out[2] = a[2] + b[2]; out[3] = a[3] + b[3];
}

void xiom_simd_f64x4_mul(double* a, double* b, double* out) {
    out[0] = a[0] * b[0]; out[1] = a[1] * b[1];
    out[2] = a[2] * b[2]; out[3] = a[3] * b[3];
}

#endif
