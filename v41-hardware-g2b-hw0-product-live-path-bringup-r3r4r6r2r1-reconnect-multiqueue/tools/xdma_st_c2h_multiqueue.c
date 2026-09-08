#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/aio_abi.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>
#define PRIMARY 10240000UL
#define GUARD 4194304UL
typedef struct {struct iocb cb; void *buf; size_t size,off; int guard,accepted,done; int64_t result;} Req;
static uint64_t now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (uint64_t)t.tv_sec*1000000000ULL+t.tv_nsec;}
static void event(const char *s){printf("{\"type\":\"%s\",\"ns\":%"PRIu64"}\n",s,now());fflush(stdout);}
static int write_at(int fd,const void *b,size_t n,size_t off){size_t k=0;while(k<n){ssize_t x=pwrite(fd,(const char*)b+k,n-k,(off_t)(off+k));if(x<0&&errno==EINTR)continue;if(x<=0)return -1;k+=(size_t)x;}return 0;}
static int exclusive(const char *dir,const char *name){char path[4096];if(snprintf(path,sizeof(path),"%s/%s",dir,name)>=(int)sizeof(path))return -1;return open(path,O_WRONLY|O_CREAT|O_EXCL|O_CLOEXEC|O_NOFOLLOW,0600);}
static int persist(Req *r,size_t i,int fds[2],const char *dir,FILE *meta,size_t order,uint64_t stamp,int64_t res2){
 fprintf(meta,"%s,%zu,%zu,%zu,%"PRId64",%"PRId64",%zu,%"PRIu64"\n",r->guard?"GUARD":"PRIMARY",i,r->off,r->size,r->result,res2,order,stamp);fflush(meta);fsync(fileno(meta));
 if(r->result>0){if((uint64_t)r->result>r->size)return -1;if(write_at(fds[r->guard],r->buf,(size_t)r->result,r->off))return -1;fsync(fds[r->guard]);
  if((uint64_t)r->result!=r->size){char name[80];snprintf(name,sizeof(name),"short-request-%zu.bin",i);int f=exclusive(dir,name);if(f<0)return -1;int rc=write_at(f,r->buf,(size_t)r->result,0);fsync(f);close(f);if(rc)return -1;}}
 return 0;
}
int main(int argc,char **argv){
 if(argc==2&&!strcmp(argv[1],"--help")){puts("usage: --probe BYTES NODE PRIVATE_DIR | --finite BYTES NODE PRIVATE_DIR");return 0;}
 if(argc!=5 || (strcmp(argv[1],"--probe")&&strcmp(argv[1],"--finite")))return 64;
 int probe=!strcmp(argv[1],"--probe");char *end=NULL;size_t unit=strtoul(argv[2],&end,10);
 if(*end || !unit || unit%4096 || unit>4194304 || (!probe&&unit!=4096&&unit!=65536&&unit!=262144&&unit!=524288))return 64;
 if(strcmp(argv[3],"/dev/xdma0_c2h_0"))return 64;
 umask(077);setvbuf(stdout,NULL,_IOLBF,0);
 size_t np=probe?1:PRIMARY/unit+(PRIMARY%unit)/4096,ng=probe?0:GUARD/unit,n=np+ng;
 Req *r=calloc(n,sizeof(*r));struct iocb **ptrs=calloc(n,sizeof(*ptrs));if(!r||!ptrs)return 70;
 int fd=open(argv[3],O_RDONLY|O_CLOEXEC|O_NOFOLLOW);if(fd<0){event("OPEN_FAILED");return 71;}
 int fds[2]={exclusive(argv[4],"primary.bin"),exclusive(argv[4],"guard.bin")};
 int mf=exclusive(argv[4],"completions.csv"),sf=exclusive(argv[4],"submissions.csv"),cf=exclusive(argv[4],"cancellations.csv");
 if(fds[0]<0||fds[1]<0||mf<0||sf<0||cf<0)return 72;
 FILE *meta=fdopen(mf,"w"),*sub=fdopen(sf,"w"),*cancel=fdopen(cf,"w");
 fprintf(meta,"Class,Index,Offset,Requested,Result,Result2,CompletionOrder,MonotonicNs\n");
 fprintf(sub,"Class,Index,TargetOffset,Requested,AioData,AcceptedNs\n");fprintf(cancel,"Index,Return,Errno,Result,Result2\n");
 size_t po=0,go=0;
 for(size_t i=0;i<n;i++){
  r[i].guard=i>=np;r[i].size=probe?unit:(i<np?(i<PRIMARY/unit?unit:4096):unit);r[i].off=r[i].guard?go:po;
  if(r[i].guard)go+=r[i].size;else po+=r[i].size;
  if(posix_memalign(&r[i].buf,4096,r[i].size))return 73;
  memset(r[i].buf,0,r[i].size);
  r[i].cb.aio_data=i+1;r[i].cb.aio_lio_opcode=IOCB_CMD_PREAD;r[i].cb.aio_fildes=(uint32_t)fd;r[i].cb.aio_buf=(uint64_t)(uintptr_t)r[i].buf;r[i].cb.aio_nbytes=r[i].size;r[i].cb.aio_offset=0;ptrs[i]=&r[i].cb;
 }
 aio_context_t ctx=0;unsigned capacity=(unsigned)(n+64);if(unit==4096&&capacity<4096)capacity=4096;
 if(syscall(__NR_io_setup,capacity,&ctx)<0){event("IO_SETUP_FAILED");return 74;}
 size_t accepted=0,calls=0,done=0,pdone=0,order=0;int failed=0,primary_emitted=0,all_emitted=0,quiescent=0,cancelled=0;
 while(accepted<n){long x=syscall(__NR_io_submit,ctx,(long)(n-accepted),ptrs+accepted);calls++;
  if(x<0&&errno==EINTR)continue;
  if(x<=0){failed=1;event("SUBMISSION_FAILED");break;}
  for(long j=0;j<x;j++){size_t k=accepted+(size_t)j;r[k].accepted=1;fprintf(sub,"%s,%zu,%zu,%zu,%zu,%"PRIu64"\n",r[k].guard?"GUARD":"PRIMARY",k,r[k].off,r[k].size,k+1,now());}
  accepted+=(size_t)x;
 }
 fflush(sub);fsync(sf);
 if(!failed){printf("{\"type\":\"%s\",\"operating_bytes\":%zu,\"primary_requests\":%zu,\"guard_requests\":%zu,\"total_requests\":%zu,\"primary_bytes\":%zu,\"guard_bytes\":%zu,\"total_bytes\":%zu,\"submit_calls\":%zu,\"accepted\":%zu,\"alignment\":4096,\"ns\":%"PRIu64"}\n",probe?"PROBE_PREQUEUE_READY":"PREQUEUE_READY",unit,np,ng,n,po,go,po+go,calls,accepted,now());}
 while(1){
  struct pollfd input={STDIN_FILENO,POLLIN,0};
  if(poll(&input,1,0)>0&&(input.revents&POLLIN)){
   char command[80];if(fgets(command,sizeof(command),stdin)){
    if(!strncmp(command,"PARENT_QUIESCENT",16))quiescent=1;
    if(!strncmp(command,"CANCEL",6)&&!cancelled){
     cancelled=1;
     for(size_t i=0;i<accepted;i++)if(!r[i].done){struct io_event e={0};errno=0;long rc=syscall(__NR_io_cancel,ctx,&r[i].cb,&e);int err=errno;
      fprintf(cancel,"%zu,%ld,%d,%"PRId64",%"PRId64"\n",i,rc,err,(int64_t)e.res,(int64_t)e.res2);fflush(cancel);fsync(cf);
      if(rc==0){r[i].done=1;r[i].result=(int64_t)e.res;done++;if(persist(&r[i],i,fds,argv[4],meta,order++,now(),(int64_t)e.res2))failed=1;}
     }
     printf("{\"type\":\"CANCEL_ATTEMPT_COMPLETE\",\"pending\":%zu,\"ns\":%"PRIu64"}\n",accepted-done,now());
    }
   }
  }
  if(done==accepted&&quiescent)break;
  struct io_event ev[64];struct timespec timeout={0,2000000};long got=syscall(__NR_io_getevents,ctx,0,64,ev,&timeout);
  if(got<0){if(errno==EINTR)continue;event("GETEVENTS_FAILED");failed=1;got=0;}
  for(long j=0;j<got;j++){
   uint64_t id=ev[j].data;if(id==0||id>accepted||r[id-1].done){event("COMPLETION_ID_FAILED");failed=1;continue;}
   size_t i=(size_t)id-1;r[i].done=1;r[i].result=(int64_t)ev[j].res;done++;uint64_t stamp=now();
   int full=r[i].result==(int64_t)r[i].size&&ev[j].res2==0;
   if(full&&!r[i].guard)pdone++;
   printf("{\"type\":\"COMPLETION\",\"class\":\"%s\",\"index\":%zu,\"requested\":%zu,\"result\":%"PRId64",\"result2\":%"PRId64",\"order\":%zu,\"ns\":%"PRIu64"}\n",r[i].guard?"GUARD":"PRIMARY",i,r[i].size,r[i].result,(int64_t)ev[j].res2,order,stamp);
   if(!probe&&!full){failed=1;event("FINITE_REQUEST_FAILED");}
   if(!probe&&pdone==np&&!primary_emitted){event("PRIMARY_WINDOW_COMPLETE");primary_emitted=1;}
   if(done==accepted&&!all_emitted){event(failed?"ALL_REQUESTS_REAPED_WITH_FAILURE":"ALL_PREQUEUED_REQUESTS_COMPLETE");all_emitted=1;}
   if(persist(&r[i],i,fds,argv[4],meta,order++,stamp,(int64_t)ev[j].res2)){failed=1;event("PERSIST_FAILED");}
  }
  if(!got){struct timespec pause={0,1000000};nanosleep(&pause,NULL);}
 }
 fsync(fds[0]);fsync(fds[1]);fflush(meta);fsync(mf);fflush(cancel);fsync(cf);
 if(syscall(__NR_io_destroy,ctx)<0){event("DESTROY_FAILED");return 75;}
 close(fd);close(fds[0]);close(fds[1]);fclose(meta);fclose(sub);fclose(cancel);
 for(size_t i=0;i<n;i++)free(r[i].buf);free(r);free(ptrs);event("HELPER_EXIT_READY");return failed?1:0;
}
