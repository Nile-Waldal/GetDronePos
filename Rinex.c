#include <stdio.h>
#include <dirent.h>
#include <string.h>
#define _CRT_SECURE_NO_WARNINGS


int main(void) {
  int i=0,yr[2],mth[2],dy[2],hr[2],min[2];
  long len;
  float sec[2];
  DIR *folder;
  FILE* file, *pfile;
  char filename[256],line[256]={'\0'},end[256],goal[256],repl[256],goal1[256],repl1[256];
  char* ind;
  struct dirent *entry;

  //Opens current directory
  folder = opendir(".");
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
      //Reads the time data from the first two data sets for future use
      sscanf(line,"> %d  %d  %d %d %d %f 0 %s",&yr[i],&mth[i],&dy[i],&hr[i],&min[i],&sec[i],end);
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
  
  
  //Closes all files and reopens Rinex.txt for reading and writing
  fclose(file);
  fclose(pfile);
  pfile=fopen("Rinex.txt","r+");

  if(!pfile){
    printf("Unable to open files.");
    return 1;
  }

  //Prepares several strings, which are formatted as the problem spots in the header, 
  //containing the incorrect first data set date and time and the correct second data set date and
  //time. If statements are required for accounting for the different cases when the day and month
  //are two or one digits.
  if(mth[0]<10&&dy[0]>=10){
    sprintf(goal,"%d0%d%d",yr[0],mth[0],dy[0]);
  }
  else if(mth[0]>=10&&dy[0]>=10){
    sprintf(goal,"%d%d%d",yr[0],mth[0],dy[0]);
  }
  else if(mth[0]>=10&&dy[0]<10){
    sprintf(goal,"%d%d0%d",yr[0],mth[0],dy[0]);
  }
  else{
    sprintf(goal,"%d0%d0%d",yr[0],mth[0],dy[0]);
  }

  if(mth[1]<10&&dy[1]>=10){
    sprintf(repl,"%d0%d%d",yr[1],mth[1],dy[1]);;
  }
  else if(mth[1]>=10&&dy[1]>=10){
    sprintf(repl,"%d%d%d",yr[1],mth[1],dy[1]);
  }
  else if(mth[1]>=10&&dy[1]<10){
    sprintf(repl,"%d%d0%d",yr[1],mth[1],dy[1]);;
  }
  else{
    sprintf(repl,"%d0%d0%d",yr[1],mth[1],dy[1]);
  }

  if(mth[0]<10&&dy[0]>=10){
    sprintf(goal1,"%d     %d    %d",yr[0],mth[0],dy[0]);
  }
  else if(mth[0]>=10&&dy[0]>=10){
    sprintf(goal1,"%d    %d    %d",yr[0],mth[0],dy[0]);
  }
  else if(mth[0]>=10&&dy[0]<10){
    sprintf(goal1,"%d    %d     %d",yr[0],mth[0],dy[0]);
  }
  else{
    sprintf(goal1,"%d     %d     %d",yr[0],mth[0],dy[0]);
  }

  if(mth[1]<10&&dy[1]>=10){
    sprintf(repl1,"%d     %d    %d",yr[1],mth[1],dy[1]);;
  }
  else if(mth[1]>=10&&dy[1]>=10){
    sprintf(repl1,"%d    %d    %d",yr[1],mth[1],dy[1]);
  }
  else if(mth[1]>=10&&dy[1]<10){
    sprintf(repl1,"%d    %d     %d",yr[1],mth[1],dy[1]);;
  }
  else{
    sprintf(repl1,"%d     %d     %d",yr[1],mth[1],dy[1]);
  }

//Loops through the header lines and replaces the incorrect dates with the correct ones
  fgets(line,256,pfile);

  do{
    //finds a pointer to the first date string if it exists
    ind=strstr(line,goal);

    if(ind!=NULL){
      //replaces the date with the corrected one
      for(i=0;i<8;i++){
        *(ind+i)=repl[i];
      }

      //Resets file pointer to begininng of line and prints the corrected line
      len=strlen(line);
      fseek(pfile,-len-1,SEEK_CUR);
      fputs(line,pfile);
	  fseek(pfile, 0, SEEK_CUR);
    }

    //finds a pointer to the second date string if it exists
    ind=strstr(line,goal1);

    if(ind!=NULL){
      //replaces the date with the corrected one
      for(i=0;i<16;i++){
        *(ind+i)=repl1[i];
      }

      //Resets file pointer to begininng of line and prints the corrected line
      len=(long) strlen(line);
      fseek(pfile,-len-1,SEEK_CUR);
      fputs(line,pfile);
	  fseek(pfile, 0, SEEK_CUR);
    }
  }
  while(fgets(line,256,pfile)&&!strstr(line,"END OF HEADER"));

  //Closes all directories and files
  fclose(pfile);
  closedir(folder);
  return 0;
}
