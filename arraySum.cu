#include <stdio.h>
#include <sys/time.h>

__global__ void add(int*a, int*b, int*c)
{
	c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];
}

__global__ void fatorialAdd(int *a, int *b, int *c)
{
	int i;
	int maxA = a[blockIdx.x];
	int maxB = b[blockIdx.x];
	int fatA,fatB;
	fatA = fatB = 1;
	for(i = 0;i<fatA;i++)
		fatA *= (maxA - i);
	for(i = 0;i<fatB;i++)
		fatB *= (maxB - i);
	c[blockIdx.x] = fatA + fatB;
}

__global__ void random_ints(int *a, int shift)
{
	a[blockIdx.x] = blockIdx.x + shift;
}

long getMicrotime(){
	struct timeval currentTime;
	gettimeofday(&currentTime, NULL);
	return currentTime.tv_sec * (int)1e6 + currentTime.tv_usec;
}

#define N 10000000
int main(void)
{
	int*a, *b, *c;// host copies of a, b, c
	int*d_a, *d_b, *d_c;// device copies of a, b, c
	int i;
	int size = N * sizeof(int);
	long start,end;
	// Alloc space for device copies of a, b, c
	cudaMalloc((void**)&d_a, size);
	cudaMalloc((void**)&d_b, size);
	cudaMalloc((void**)&d_c, size);
	//Alloc space for host copies of a, b, c and setup input values
	a = (int *)malloc(size);
	random_ints<<<N,1>>>(d_a,13);
	cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);
	b = (int *)malloc(size); 
	random_ints<<<N,1>>>(d_b,2);
	cudaMemcpy(b, d_b, size, cudaMemcpyDeviceToHost);
	c = (int *)malloc(size);
	// Copy inputs to device
	cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);
	// Launch add() kernel on GPU with N blocks
	long mediaTempo = 0;
	for(i = 0; i<1000;i++)
	{
		start = getMicrotime();	
		//add<<<N,1>>>(d_a, d_b, d_c);// Copy result back to host
		fatorialAdd<<<N,1>>>(d_a, d_b, d_c);
		cudaMemcpy(c, d_c, size, cudaMemcpyDeviceToHost);// Cleanup
		end = getMicrotime();
		mediaTempo += (end - start); 
	}
	printf("\nTOTAL TIME: %ld\n",mediaTempo/1000);
	for(i = 1; i<4; i++)
		printf("\nSUM of %i + %i = %i\n",a[N-i],b[N-i],c[N-i]);
	
	int j,k;
	int maxA = 0;
	int maxB = 0;
	int fatA,fatB;
	mediaTempo = 0;
	for(k = 0; k<1000; k++)	
	{
		start = getMicrotime();
		for(i = 0; i < N; i++)
		{
			fatA = fatB = 1;
			maxA = a[i];
			maxB = b[i];
			for(j = 0;j<fatA;j++)
				fatA *= (maxA - j);
			for(j = 0;j<fatB;j++)
				fatB *= (maxB - j);
			c[i] = fatA + fatB;
		}
		end = getMicrotime();
		mediaTempo += (end - start); 
	}
	printf("\nTOTAL TIME: %ld\n",mediaTempo/1000);
	for(i = 1; i<4; i++)
		printf("\nSUM of %i + %i = %i\n",a[N-i],b[N-i],c[N-i]);
	free(a); free(b); free(c);
	cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);
	return 0;
}

