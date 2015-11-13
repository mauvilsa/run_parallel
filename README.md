# run_parallel

A simple and versatile bash function for parallelizing the execution of
commands or other bash functions. The main features that differentiates it to
other popular tools for parallelizing are:
- Bash functions can be parallelized without need to export them.
- stdout/stdin is prepended with the thread name so that it can later be
  sorted per thread using _run_parallel_output_sort_ (unlike xargs).
- A license which does not require to cite a paper if used for research.

To see the latest usage instructions, first source the file and then execute
the command without any arguments, i.e.:

```
$ source run_parallel.inc.sh
$ run_parallel
```
