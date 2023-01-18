#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include <time.h>
#include <stdlib.h>

void delay(int dl){
   for (int i=0;i<dl;){
      i = i + 1;
   }
}

#define CTRL_BASE_ADDR 0x00000000
#define IMEM_BASE_ADDR 0x00004000
#define WMEM_BASE_ADDR 0x00005000
#define OMEM_BASE_ADDR 0x00006000
#define ADDR_AP_START  0x00
#define ADDR_AP_DONE   0x04
#define ADDR_AP_IDLE   0x08
#define ADDR_DIM_L	   0x10
#define ADDR_DIM_M	   0x14
#define ADDR_DIM_N	   0x18

#define GEMM_DIM_L     16
#define GEMM_DIM_M     16
#define GEMM_DIM_N     16

int main()
{
    init_platform();
    int error = 0;
    u32 rd_data;
    u32 ap_idle = 0x0;
    u32 i_mat[GEMM_DIM_N][GEMM_DIM_L];
    u32 w_mat[GEMM_DIM_L][GEMM_DIM_M];
    u32 o_mat[GEMM_DIM_N][GEMM_DIM_M];
    Xil_In32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_DONE);

    // Make golden data
    for (int n=0;n<GEMM_DIM_N;n++){
    	for (int l=0;l<GEMM_DIM_L;l++){
    		i_mat[n][l] = ((rand() & 0x7fffu)<<17 | (rand() & 0x7fffu)<<2 ) | (rand() & 0x7fffu)>>13;
    	}
    }
	for (int l=0;l<GEMM_DIM_L;l++){
		for (int m=0;m<GEMM_DIM_M;m++){
			w_mat[l][m] = ((rand() & 0x7fffu)<<17 | (rand() & 0x7fffu)<<2 ) | (rand() & 0x7fffu)>>13;
		}
	}
	for (int n=0;n<GEMM_DIM_N;n++){
		for (int m=0;m<GEMM_DIM_M;m++){
			o_mat[n][m] = 0;
			for (int l=0;l<GEMM_DIM_L;l++){
				o_mat[n][m] = ((int) i_mat[n][l]) * ((int) w_mat[l][m]) + ((int) o_mat[n][m]);
			}
		}
	}

	// Setup BRAM memory
	for (int n=0;n<GEMM_DIM_N;n++){
		for (int l=0;l<GEMM_DIM_L;l++){
			Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + IMEM_BASE_ADDR + ((n*GEMM_DIM_L) + l)*4, i_mat[n][l]);
		}
	}
	for (int l=0;l<GEMM_DIM_L;l++){
		for (int m=0;m<GEMM_DIM_M;m++){
			Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + WMEM_BASE_ADDR + ((m*GEMM_DIM_L) + l)*4, w_mat[l][m]);
		}
	}

	// Check whether the engine is idle
	ap_idle = 0x0;
	while (ap_idle == 0x0){
		ap_idle = Xil_In32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_IDLE);
		delay(100000);
	}

	// Set control registers
	Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + ADDR_DIM_L, GEMM_DIM_L);
	Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + ADDR_DIM_M, GEMM_DIM_M);
	Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + ADDR_DIM_N, GEMM_DIM_N);
	Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_START, 0x1);
	delay(10000000);
	Xil_Out32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_START, 0x0);

	// Check whether the engine is idle
	ap_idle = 0x0;
	while (ap_idle == 0x0){
		ap_idle = Xil_In32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_IDLE);
		delay(100000);
	}

	// Read BRAM
	for (int n=0;n<GEMM_DIM_N;n++){
		for (int m=0;m<GEMM_DIM_M;m++){
			rd_data = Xil_In32(XPAR_USR_RTL_APB_BASEADDR + OMEM_BASE_ADDR + ((n*GEMM_DIM_M) + m)*4);
			if (rd_data != o_mat[n][m]) {
				error = error + 1;
			}
		}
	}

	// Reset LED
	rd_data = Xil_In32(XPAR_USR_RTL_APB_BASEADDR + ADDR_AP_DONE);
	delay(100000);

    cleanup_platform();
    return 0;
}
