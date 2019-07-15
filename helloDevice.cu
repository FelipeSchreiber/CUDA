#include <stdio.h>

__global__ void mykernel(void){}

int main(void)
{
	mykernel<<<1,1>>>();
	printf("\nhello world\n");
	return 0;
}
