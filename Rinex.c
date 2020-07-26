#include <stdio.h>
#include <dirent.h>
#include <string.h>


int main(void) {
  int i=0;;
  fpos_t pos[256];
  DIR *folder;
  FILE* file, *pfile;
  char filename[256],c,line[256]={'\0'},buff[1000];
  char* ind;
  struct dirent *entry;

  folder=opendir(".");
  if(folder==NULL){
    printf("Unable to open directory.");
    return 1;
  }
  while((entry=readdir(folder))){
    strcpy(filename,entry->d_name);
    if(strstr(filename,".obs")){
      break;
    }
  }
  file=fopen(filename,"r");
  pfile=fopen("Rinex.txt","w");
  if(!file||!pfile){
    printf("Unable to open files.");
    return 1;
  fclose(file);
  fclose(pfile);
  closedir(folder);
  return 0;
}