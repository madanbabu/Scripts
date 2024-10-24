#include <iostream>
#include <cuda.h>

#define N 1000000  // Number of elements in the vectors

__global__ void vectorAdd(const float *A, const float *B, float *C) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        C[i] = A[i] + B[i];
    }
}

void checkCudaErrors(cudaError_t err) {
    if (err != cudaSuccess) {
        std::cerr << "CUDA Error: " << cudaGetErrorString(err) << std::endl;
        exit(EXIT_FAILURE);
    }
}

int main() {
    float *h_A, *h_B, *h_C;  // Host pointers
    float *d_A, *d_B, *d_C;  // Device pointers

    // Allocate host memory
    h_A = (float*)malloc(N * sizeof(float));
    h_B = (float*)malloc(N * sizeof(float));
    h_C = (float*)malloc(N * sizeof(float));

    // Initialize host vectors
    for (int i = 0; i < N; i++) {
        h_A[i] = static_cast<float>(i);
        h_B[i] = static_cast<float>(i);
    }

    // Allocate device memory
    checkCudaErrors(cudaMalloc((void**)&d_A, N * sizeof(float)));
    checkCudaErrors(cudaMalloc((void**)&d_B, N * sizeof(float)));
    checkCudaErrors(cudaMalloc((void**)&d_C, N * sizeof(float)));

    // Copy vectors from host to device
    checkCudaErrors(cudaMemcpy(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice));

    // Launch kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    
    cudaEventRecord(start);
    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C);
    cudaEventRecord(stop);

    // Copy result back to host
    checkCudaErrors(cudaMemcpy(h_C, d_C, N * sizeof(float), cudaMemcpyDeviceToHost));

    // Wait for the GPU to finish
    cudaEventSynchronize(stop);

    // Measure elapsed time
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    std::cout << "Time taken for vector addition: " << milliseconds << " ms" << std::endl;

    // Clean up
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
