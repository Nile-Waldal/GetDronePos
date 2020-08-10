#include <stdio.h>
#include <dirent.h>
#include <string.h>


int main(void) {
  int i=0;;
  DIR *folder;
  FILE* file, *pfile;
  char filename[256],line[256]={'\0'};
  char* ind;
  struct dirent *entry;

  //Opens current directory
  folder=opendir(".");
  if(folder==NULL){
    printf("Unable to open directory.");
    return 1;
  }
  
  //Searches for .obs file in the filenames of files in the directory
  while((entry=readdir(folder))){
    strcpy(filename,entry->d_name);
    if(strstr(filename,".obs")){
      break;
    }
  }
  
  //Opens .obs file and creates a file Rinex.txt which will contain the edited data
  file=fopen(filename,"r");
  pfile=fopen("Rinex.txt","w");
  if(!file||!pfile){
    printf("Unable to open files.");
    return 1;
  }
  
  //Reads lines from .obs and writes them to Rinex.txt while the line is not the end of the header. Upon reaching end of header, writes it and exits loop
  while(strstr(line,"END OF HEADER")==NULL){
    fgets(line,256,file);
    
    //If the line has the time of first obs string, writes a line before it
    if(strstr(line,"TIME OF FIRST OBS")!=NULL){
      fputs("                                                            0.2000 INTERVAL     \n",pfile);
    }
    fputs(line,pfile);
    
  }
  
  //Reads lines until two '>' characters have been found, indicating the beginning of data sets for different times. Doing this omits the first data set
  while(i!=2){
    fgets(line,256,file);
    if(strstr(line,">")!=NULL){
      i++;
    }
  }
  
  //Reads and writes lines until the end of the .obs file. Eexecutes once before checking while statement to write the already read beginning of the second data set
  do{
    
    //Replaces 000000 0 with 000000  0 in first line of data sets
    if(strstr(line,">")!=NULL){
      ind=strstr(line,"000000 0");
      for(i=strlen(line)-strlen(ind);i>=7;i--){
        *(ind+i)=*(ind+i-1);
      }
    }
    
    //Prevents last three lines from being written by breaking from loop before the fputs when it reaches the END ... DATA line
    if(strstr(line,"END OF RINEX OBS DATA")!=NULL){
      break;
    }
    fputs(line,pfile);
  }
  while(fgets(line,256,file));
  
  //Closes all files and folders
  fclose(file);
  fclose(pfile);
  closedir(folder);
  return 0;
}
