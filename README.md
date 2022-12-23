# vpm  
Vosje's package manager
# 
  
This is my package manager written in bash. you can use it to download my programs from my github.  
To add a repository, use the vpmfile from the repository's owner. Ask them if they did not provide one.

## writing my own repofile.
This is a guide on writing your own repofile. After each line is an explanation.
! a program will later be provided to do this for you.
Make sure the filename does not contain any spaces.
file: `my-repo.vpmfile`
```
/# this is a comment. it wil be skipped when reading the file.
type    = repo
/# make sure this is anywhere in the file. it will be used to define if the file is a repo, or a program.
/# for a repo, set it to 'repo'.
name    = the repo's name
/# this can be anything you want.
id      = 
/# this is the repo's name without spaces. !! this is currently not checked, so make sure the id does not contain spaces to make sure there are no errors!
url     = URL
/# this is the url to download the repolist from. a format is given later.
format  = http/zip
/# currently the option's are:
/# http/zip : downloads and extracts the file into the repo's directory. make sure it is a regular zip file with the repolist file's in its root.
/#
/# make sure your file does not contain any empty lines, exept at the end.

```
this file can be as short as:
```
type    = repo
name    = my repo
id      = my-repo
url     = http://mywebsite.com/repos/repofiles.zip
format  = http/zip

```
### the repolist:
A repolist is a bunch of files containing information about your program.
It looks like this:
file: `my-program.vpmfile`
```
type    = program
/# tell vpm this is a program and not a repo
name    = my program
/# the name of your program
id      = my-program
/# the name of your program without spaces. !! this is currently not checked, so make sure the id does not contain spaces to make sure there are no errors!
/# !! when using format 'git', this needs to be the same as the directory 'git clone URL' clones it to.
url     = URL
/# the url to download/clone
format  = git
/# current format's are:
/# git : clone the program using git.
install = ./install.sh
/# the command run inside the program's folder after download
info    = a short desciption about my program
/# tell us something about your program. keep it short!
readme  = README.md
/# the file to display if a user wants a long desciption.
/#
/# make sure your file does not contain any empty lines, exept at the end.

```
the short version:
```
type    = program
name    = my program
id      = my-program
url     = URL
format  = git
install = ./install.sh
info    = a short desciption about my program
readme  = README.md

```
! a program will later be provided to write these file's.

thanks for using vpm! if you find a bug, or have a feature request, make a new issue on github.

[ [github](https://github.com/Vosjedev/packager) || [new issue](https://github.com/Vosjedev/packager/issues/new/choose) ]