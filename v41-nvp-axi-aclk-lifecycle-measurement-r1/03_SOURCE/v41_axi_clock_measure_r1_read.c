#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

static uint32_t rd32(int fd, off_t off) {
  uint32_t v=0; ssize_t n=pread(fd,&v,sizeof v,off);
  if(n!=sizeof v){fprintf(stderr,"read failure offset=0x%05lx errno=%d\n",(long)off,errno);exit(2);} return v;
}
static uint64_t rd48(int fd, off_t lo, off_t hi) {
  for(int attempt=0;attempt<2;attempt++){
    uint32_t h1=rd32(fd,hi)&0xffff, l=rd32(fd,lo), h2=rd32(fd,hi)&0xffff;
    if(h1==h2)return ((uint64_t)h1<<32)|l;
  }
  fprintf(stderr,"counter coherence failure\n"); exit(3);
}
int main(int argc,char **argv){
  if(argc!=2){fprintf(stderr,"usage: %s /dev/xdmaN_user\n",argv[0]);return 2;}
  int fd=open(argv[1],O_RDONLY|O_CLOEXEC); if(fd<0){perror("open");return 2;}
  struct timespec ts; clock_gettime(CLOCK_MONOTONIC_RAW,&ts);
  uint64_t freec=rd48(fd,0x200c,0x2010);
  printf("REMOTE_MONOTONIC_NS=%" PRIu64 "\n",(uint64_t)ts.tv_sec*1000000000ull+ts.tv_nsec);
  printf("MEASUREMENT_MAGIC=0x%08" PRIx32 "\n",rd32(fd,0x2000));
  printf("MEASUREMENT_VERSION=%" PRIu32 "\n",rd32(fd,0x2004));
  printf("INSTRUMENT_STATUS=0x%08" PRIx32 "\n",rd32(fd,0x2008));
  printf("AXI_FREERUN_COUNT=%" PRIu64 "\n",freec);
  printf("CNT_AT_INIT_DONE=%" PRIu64 "\n",rd48(fd,0x2014,0x2018));
  printf("CNT_AT_FIRST_USER_LNK_UP=%" PRIu64 "\n",rd48(fd,0x201c,0x2020));
  printf("CNT_AT_FIRST_AXI_ARESETN_HIGH=%" PRIu64 "\n",rd48(fd,0x2024,0x2028));
  printf("CNT_AT_FIRST_AXI_ARESETN_LOW_AFTER_HIGH=%" PRIu64 "\n",rd48(fd,0x202c,0x2030));
  printf("USER_LNK_UP_TRANSITION_COUNT=%" PRIu32 "\n",rd32(fd,0x2034));
  printf("AXI_ARESETN_TRANSITION_COUNT=%" PRIu32 "\n",rd32(fd,0x2038));
  printf("EVENT_FLAGS=0x%08" PRIx32 "\n",rd32(fd,0x203c));
  printf("VCLK=%" PRIu32 "\nSAV=%" PRIu32 "\nFRAME=%" PRIu32 "\n",rd32(fd,0x80),rd32(fd,0x84),rd32(fd,0x88));
  printf("NVP_STATUS=0x%08" PRIx32 "\n",rd32(fd,0x8c));
  printf("NVP_SUMMARY0=0x%08" PRIx32 "\nNVP_SUMMARY1=0x%08" PRIx32 "\n",rd32(fd,0x90),rd32(fd,0x94));
  printf("FIRST_ERROR=0x%08" PRIx32 "\nFIRST_ERROR_META=0x%08" PRIx32 "\n",rd32(fd,0x98),rd32(fd,0x9c));
  close(fd); return 0;
}
