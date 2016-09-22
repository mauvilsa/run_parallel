# run_parallel

A simple and versatile bash function for parallelizing the execution of
commands or other bash functions. The main features that differentiates it
from other popular tools for parallelizing are:
- Bash functions can be parallelized without need to export them.
- A single output for stdout and stdin that are prepended with the thread
  name. They can be sorted later (unlike xargs) per thread using
  _run_parallel_output_sort_ .
- A license which does not require to cite a paper if used for research
  (unlike GNU parallel).

To see the latest usage instructions, first source the file and then execute
the command with argument --help, i.e.:

```
$ source run_parallel.inc.sh
$ run_parallel --help
Description: Executes instances of a command in parallel. In the command
  arguments, '{#}' is replaced by the command instance number (1, 2, ...)
  and '{%}' is replaced by the thread ID (see options). The thread ID is
  prepended to every line of stderr and stdout. If a list to process
  is given, there are four possibilities to supply the list of elements to the
  command: 1) if an argument is '{*}', elements are given as arguments in that
  position, 2) if an argument contains '{@}', elements are given in a file and
  '{@}' is replaced by the file path, 3) if an argument is '{<}', elements
  are given through a named pipe and '{<}' is replaced by the pipe, and 4) if
  no special argument is provided the elements are given through stdin. Other
  replacements only when processing one element at a time are: '{.}' element
  without extension, '{/}' element without path, '{//}' only path of element,
  and '{/.}' element without either path or extension.
Usage: run_parallel [OPTIONS] COMMAND ARG1 ARG2 ... [('{@}'|'{*}'|'{<}') ... '{#}' ... '{%}'] ...
Options:
 -T THREADS      Concurrent threads, either an int>0, list {id1},{id2},...
                 or range {#ini}:[{#inc}:]{#end} (def.=1)
 -l LIST         List of elements to process, either a file (- is stdin), list
                 {el1},{el2},... or range {#ini}:[{#inc}:]{#end} (def.=none)
 -n NUMELEM      Elements per instance, either an int>0, 'split' or 'balance' (def.=1)
 -k (yes|no)     Whether to keep temporal files (def.=no)
 -p (yes|no)     Whether to prepend IDs to outputs (def.=yes)
 -d TMPDIR       Use given directory for temporal files, also sets -k yes (def.=false)
 -v | --version  Print script version and exit
 -h | --help     Print this help and exit
Environment variables:
  TMPDIR      Directory for temporal files, must exist (def.=/tmp)
  TMPRND      ID for unique temporal files (def.=rand)
Dummy examples:
  myfunc () {
    sleep $((RANDOM%3));
    NUM=$( wc -w < $2 );
    ITEMS=$( echo $( < $2 ) );
    echo "$1: processed $NUM items ($ITEMS)";
  }
  seq 1 100 | run_parallel -T A,B,C -n balance -l - myfunc 'Thread {%} instance {#}' '{@}' | tee OUTPUT
  run_parallel_output_sort -f -s rd < OUTPUT
  seq 1 100 | run_parallel -T 4 -n 7 -l - myfunc 'Thread {%} instance {#}' '{@}'
  myfunc () { echo "Processing file $1"; }
  run_parallel -T 5 myfunc 'input_{%}.txt'
  run_parallel -T 2:3:9 myfunc 'input_{%}.txt'
```
