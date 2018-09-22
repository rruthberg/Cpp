
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>




void regVecAdd(int *a, int *b, int *c, int n) {
	int i;
	for (i = 0; i < n; ++i)
		c[i] = a[i] + b[i];
}

__global__ void vectorAdd(int *a, int *b, int *c, int n) {
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < n)
	{
		c[i] = a[i] + b[i];
	}
}

int main() {
	cudaError_t err = cudaSuccess;
	int numelements = 1024;
	size_t SIZE = numelements * sizeof(int);
	printf("[Vector addition of %d elements]\n", numelements);
	
	//Define pointers
	int *a, *b, *c;
	int *d_a, *d_b, *d_c;

	//Allocate memory on the host
	a = (int *)malloc(SIZE);
	b = (int *)malloc(SIZE);
	c = (int *)malloc(SIZE); 

	//Allocate memory on the device
	err = cudaMalloc((void**)&d_a, SIZE);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}

	err = cudaMalloc((void**)&d_b, SIZE);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}
	
	err = cudaMalloc((void**)&d_c, SIZE);

	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}


	for (int i = 0; i < numelements; ++i)
	{
		a[i] = i;
		b[i] = i;
		c[i] = 0;
	}

	for (int i = 0; i < 10; ++i)
		printf("c[%d] = %d\n", i, c[i]);

	//Copy data from host to device
	err = cudaMemcpy(d_a, a, SIZE, cudaMemcpyHostToDevice);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to A - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}
	err = cudaMemcpy(d_b, b, SIZE, cudaMemcpyHostToDevice);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to B - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}
	err = cudaMemcpy(d_c, c, SIZE, cudaMemcpyHostToDevice);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to C - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}



	vectorAdd<<<1, numelements>>>(d_a, d_b, d_c, numelements); //call specifies blocks and threads by <<< BLOCKS, THREADS >>> so SIZE is the number of threads

	//copy data from device to host
	err = cudaMemcpy(a, d_a, SIZE, cudaMemcpyDeviceToHost);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to A - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}

	err = cudaMemcpy(b, d_b, SIZE, cudaMemcpyDeviceToHost);
	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to B - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}
	
	err = cudaMemcpy(c, d_c, SIZE, cudaMemcpyDeviceToHost);

	if (err != cudaSuccess) {
		fprintf(stderr, "Failed to C - (error code %s)!", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}

	for (int i = 0; i < 10; ++i)
		printf("c[%d] = %d\n", i, c[i]);

	//Free memory on host and device
	free(a);
	free(b);
	free(c);

	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);
}