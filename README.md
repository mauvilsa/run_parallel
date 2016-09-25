
# NAME

run_parallel - Simple bash function for parallelizing.

# SYNOPSIS

run_parallel [OPTION]... *COMMAND* [ARG]... ('{@}'|'{\*}'|'{<}')... '{#}'... '{%}'...  
run_parallel_output_sort [OPTION]... < *RUN_PARALLEL_OUTPUT*

# DESCRIPTION

run_parallel is a simple and versatile bash function for parallelizing the
execution of commands or other bash functions. The main features that
differentiates it from other popular tools for parallelizing are:

- Bash functions can be parallelized without need to export them.
- A single output for stdout and stdin that are prepended with the thread
  name. They can be sorted later (unlike xargs) per thread using
  _run_parallel_output_sort_ .
- A license which does not require to cite a paper if used for research
  (unlike GNU parallel).

In the command arguments, '{#}' is replaced by the command instance number (1,
2, ...) and '{%}' is replaced by the thread ID (see options). The thread ID is
prepended to every line of stderr and stdout. If a list to process is given,
there are four possibilities to supply the list of elements to the command: 1)
if an argument is '{\*}', elements are given as arguments in that position, 2)
if an argument contains '{@}', elements are given in a file and '{@}' is
replaced by the file path, 3) if an argument is '{<}', elements are given
through a named pipe and '{<}' is replaced by the pipe, and 4) if no special
argument is provided the elements are given through stdin. Other replacements
only when processing one element at a time are: '{.}' element without
extension, '{/}' element without path, '{//}' only path of element, and '{/.}'
element without either path or extension.

# ENVIRONMENT VARIABLES

*TMPDIR*  --  Directory for temporal files, must exist (def.=/tmp)  
*TMPRND*  --  ID for unique temporal files (def.=rand)

# OPTIONS

-T *THREADS*, \--threads *THREADS*  
  Concurrent threads: either an int>0, list id1,id2,... or range
  #ini:[#inc:]#end (def.=1)

-l *LIST*, \--list *LIST*  
  List of elements to process: either a file (- is stdin), list el1,el2,... or
  range #ini:[#inc:]#end (def.=none)

-n *NUMELEM*, \--num *NUMELEM*  
  Elements per instance: either an int>0, 'split' or 'balance'
  (def.=1)

-p *(yes|no)*, \--prepend *(yes|no)*  
  Whether to prepend IDs to outputs (def.=yes)

-k *(yes|no)*, \--keeptmp *(yes|no)*  
  Whether to keep temporal files (def.=no)

-d *TMPDIR*, \--tmpdir *TMPDIR*  
  Use given directory for temporal files, also sets -k yes (def.=false)

-v, \--version  
  Print script version and exit

-h, \--help  
  Print help and exit

# DUMMY EXAMPLES

    myfunc () {  
      sleep $((RANDOM%3));  
      NUM=$( wc -w < $2 );  
      ITEMS=$( echo $( < $2 ) );  
      echo "$1: processed $NUM items ($ITEMS)";  
    }

    seq 1 100 | run_parallel -T 3 -n balance -l - myfunc 'Thread {%} instance {#}' '{@}'  
    seq 1 100 | run_parallel -T A,B,C,D -n 7 -l - myfunc 'Thread {%} instance {#}' '{@}'  
    seq 1 100 | run_parallel -T A,B,C -n 7 -l - myfunc 'Thread {%} instance {#}' '{@}' | run_parallel_output_sort -f -s rd

    myfunc () { echo "Processing file $1"; }

    run_parallel -T 5 myfunc 'input_{%}.txt'  
    run_parallel -T 2:3:9 myfunc 'input_{%}.txt'

# COPYRIGHT

The MIT License (MIT)

Copyright (c) 2014-present, Mauricio Villegas <mauricio_ville@yahoo.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


