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
  }
  while(strstr(line,"END OF HEADER")==NULL){
    fgets(line,256,file);
    if(strstr(line,"TIME OF FIRST OBS")!=NULL){
      fputs("                                                            0.2000 INTERVAL     \n",pfile);
    }
    fputs(line,pfile);
    
  }
  while(i!=2){
    fgets(line,256,file);
    if(strstr(line,">")!=NULL){
      i++;
    }
  }
  do{
    if(strstr(line,">")!=NULL){
      ind=strstr(line,"000000 0");
      for(i=strlen(line)-strlen(ind);i>=7;i--){
        *(ind+i)=*(ind+i-1);
      }
    }
    if(strstr(line,"END OF RINEX OBS DATA")!=NULL){
      break;
    }
    fputs(line,pfile);
  }
  while(fgets(line,256,file));
  fclose(file);
  fclose(pfile);
  closedir(folder);
  return 0;
}
