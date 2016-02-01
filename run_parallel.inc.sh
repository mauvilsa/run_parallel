#!/bin/bash

##
## A simple and versatile bash function for parallelizing the execution of
## commands or other bash functions.
##
## @version $Revision: 122 $$Date:: 2016-02-01 #$
## @author Mauricio Villegas <mauricio_ville@yahoo.com>
## @link https://github.com/mauvilsa/run_parallel
##

##
## The MIT License (MIT)
##
## Copyright (c) 2014 to the present, Mauricio Villegas
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
## 

[ "${BASH_SOURCE[0]}" = "$0" ] && 
  echo "run_parallel.inc.sh: error: script intended intended for sourcing, try: . run_parallel.inc.sh" 1>&2 &&
  exit 1;

### Function that prints the version of run_parallel ###
run_parallel_version () {
  echo '$Revision: 122 $$Date: 2016-02-01 20:57:28 +0100 (Mon, 01 Feb 2016) $' \
    | sed 's|^$Revision:|run_parallel: revision|; s| (.*|)|; s|[$][$]Date: |(|;' 1>&2;
}

### A fuction for sorting (by thread) the output of run_parallel ###
run_parallel_output_sort () {
  local SRT=""; [ $# -gt 0 ] && SRT="$1";
  awk '{ count[$1]++;
         printf( "%d %s\n", count[$1], $0 );
       }' \
    | sort -k 2${SRT},2 -k 1n,1 \
    | sed 's|^[0-9][0-9]* ||';
}

### The fuction for parallel execution ###
run_parallel () {(
  local FN="run_parallel";
  local THREADS="1";
  local LIST="";
  local NUMELEM="1";
  local KEEPTMP="no";
  local TMP="";
  if [ $# -lt 2 ]; then
    { echo "$FN: Error: Not enough input arguments";
      echo "Description: Executes instances of a command in parallel. In the command";
      echo "  arguments, '{#}' is replaced by the command instance number (1, 2, ...)";
      echo "  and '{%}' is replaced by the thread ID (see options). The thread ID is";
      echo "  prepended to every line of stderr and stdout. If a list to process";
      echo "  is given, there are three possibilities to supply the list elements to the";
      echo "  command: 1) if an argument is '{*}' elements are given as arguments in that";
      echo "  position, 2) if an argument is '{@}' elements are given in a file and";
      echo "  '{@}' is replaced by the file path, 3) if an argument is '{<}' elements";
      echo "  are given through a named pipe, and 4) if no special argument is provided";
      echo "  the elements are given through stdin. Other replacements only when processing";
      echo "  one element at a time are: '{.}' element without extension, '{/}' element";
      echo "  without path, '{//}' only path of element, and '{/.}' element without either";
      echo "  path or extension.";
      echo "Usage: $FN [OPTIONS] COMMAND ARG1 ARG2 ... [('{@}'|'{*}'|'{<}') ... '{#}' ... '{%}'] ...";
      echo "Options:";
      echo " -T THREADS   Concurrent threads, either an int>0, list {id1},{id2},...";
      echo "              or range {#ini}:[{#inc}:]{#end} (def.=$THREADS)";
      echo " -l LIST      List of elements to process, either a file (- is stdin), list";
      echo "              {el1},{el2},... or range {#ini}:[{#inc}:]{#end} (def.=none)";
      echo " -n NUMELEM   Elements per instance, either an int>0, 'split' or 'balance' (def.=$NUMELEM)";
      echo " -k (yes|no)  Whether to keep temporal files (def.=$KEEPTMP)";
      echo " -d TMPDIR    Use given directory for temporal files, also sets -k yes (def.=false)";
      echo "Environment variables:";
      echo "  TMPDIR      Directory for temporal files, must exist (def.=.)";
      echo "  TMPRND      ID for unique temporal files (def.=rand)";
      echo "Dummy examples:"
      echo "  $ myfunc () {";
      echo "      sleep \$((RANDOM%3));";
      echo "      NUM=\$( wc -w < \$2 );";
      echo "      ITEMS=\$( echo \$( < \$2 ) );";
      echo "      echo \"\$1: processed \$NUM items (\$ITEMS)\";";
      echo "    }";
      echo "  $ seq 1 100 | $FN -T A,B,C -n balance -l - myfunc 'Thread {%} instance {#}' '{@}'";
      echo "  $ seq 1 100 | $FN -T 4 -n 7 -l - myfunc 'Thread {%} instance {#}' '{@}'";
      echo "  $ myfunc () { echo \"Processing file \$1\"; }";
      echo "  $ $FN -T 5 myfunc 'input_{%}.txt'";
      echo "  $ $FN -T 2:3:9 myfunc 'input_{%}.txt'";
    } 1>&2;
    return 1;
  fi

  ### Parse input arguments ###
  while [ $# -gt 0 ]; do
    if [ "${1:0:1}" != "-" ]; then
      break;
    elif [ "$1" = "-T" ]; then
      THREADS="$2";
    elif [ "$1" = "-l" ]; then
      LIST="$2";
    elif [ "$1" = "-n" ]; then
      NUMELEM="$2";
    elif [ "$1" = "-k" ]; then
      KEEPTMP="$2";
    elif [ "$1" = "-d" ]; then
      TMP="$2";
    else
      echo "$FN: error: unexpected input argument: $1" 1>&2;
      return 1;
    fi
    shift 2;
  done

  if [ "$THREADS" = "" ]; then
    THREADS=( $(seq 1 $(nproc)) );
  elif [[ "$THREADS" == *,* ]]; then
    THREADS=( ${THREADS//,/ } );
  elif [[ "$THREADS" == *:* ]]; then
    THREADS=( $(seq ${THREADS//:/ }) );
  else
    THREADS=( $(seq 1 $THREADS) );
  fi
  local NTHREADS=${#THREADS[@]};
  local TOTP="$NTHREADS";
  [ "$NTHREADS" -le 0 ] &&
    echo "$FN: error: unexpected number of threads" 1>&2 &&
    return 1;

  ### Create temporal directory ###
  if [ "$TMP" != "" ]; then
    KEEPTMP="yes";
  else
    TMP="${TMPDIR:-/tmp}";
    local RND="${TMPRND:-}";
    if [ "$RND" = "" ]; then
      TMP=$(mktemp -d --tmpdir="$TMP" ${FN}_XXXXX);
    else
      TMP="$TMP/${FN}_$RND";
      mkdir "$TMP";
    fi
  fi
  [ ! -d "$TMP" ] &&
    echo "$FN: error: failed to write to temporal directory: $TMP" 1>&2 &&
    return 1;
  local FSTYPE=$( df -PT "$TMP" | sed -n '2{ s|^[^ ]* *||; s| .*||; p; }' );
  ( [ "$FSTYPE" = "nfs" ] ||
    [ "$FSTYPE" = "lustre" ] ||
    [[ "$FSTYPE" == *sshfs* ]] ) &&
    echo "$FN: error: temporal directory should be on a local file system: $TMP -> $FSTYPE" 1>&2 &&
    return 1;

  ### Prepare command ###
  local PROTO=("$@");
  local ARGPOS="0";
  local PIPEPOS="0";
  local FILEPOS="0";
  local OTHERARG="0";
  local n;
  for n in $(seq 1 $(($#-1))); do
    if [ "${PROTO[n]}" = "{*}" ]; then
      [ "$LIST" != "" ] && ARGPOS=$n;
    elif [ "${PROTO[n]}" = "{<}" ]; then
      [ "$LIST" != "" ] && PIPEPOS=$n;
    elif [ "${PROTO[n]}" = "{@}" ]; then
      [ "$LIST" != "" ] && FILEPOS=$n;
    elif [[ "${PROTO[n]}" = *"{*}"* ]] ||
         [[ "${PROTO[n]}" = *"{.}"* ]] ||
         [[ "${PROTO[n]}" = *"{/}"* ]] ||
         [[ "${PROTO[n]}" = *"{//}"* ]] ||
         [[ "${PROTO[n]}" = *"{/.}"* ]]; then
      [ "$LIST" != "" ] && OTHERARG=$n;
    elif [ -p "${PROTO[n]}" ]; then
      p=$(ls "$TMP/pipe"* 2>/dev/null | wc -l);
      cat "${PROTO[n]}" > "$TMP/pipe$p";
      PROTO[n]="$TMP/pipe$p";
    fi
  done
  echo "${PROTO[@]}" > "$TMP/state";

  ### Prepare list ###
  local LISTFD="";
  local NLIST="";
  if [ "$LIST" != "" ]; then
    TOTP="-1";
    [ "$LIST" = "-" ] && LIST="/dev/stdin";
    if [ -e "$LIST" ]; then
      exec {LISTFD}< "$LIST";
    elif [[ "$LIST" = *,* ]]; then
      exec {LISTFD}< <( echo "$LIST" | tr ',' '\n' );
    elif [[ "$LIST" = *:* ]]; then
      exec {LISTFD}< <( seq ${LIST//:/ } );
    else
      echo "$FN: error: unexpected list: $LIST" 1>&2;
      [ "$KEEPTMP" != "yes" ] && rm -r "$TMP";
      return 1;
    fi

    if [ "$NUMELEM" = "balance" ] || [ "$NUMELEM" = "split" ]; then
      NLIST=$( tee "$TMP/list" <&$LISTFD | wc -l );
      exec {LISTFD}>&-;
      exec {LISTFD}< "$TMP/list";

      [ "$NUMELEM" = "balance" ] &&
      NLIST=( $( awk -v fact0=0.5 -v NTHREADS="$NTHREADS" -v NLIST="$NLIST" '
        BEGIN {
          if ( NTHREADS == 1 )
            printf( " %d", NLIST );
          else if( NLIST <= 2*NTHREADS )
            for ( n=1; n<=NLIST; n++ )
              printf( " 1" );
          else {
            fact = fact0;
            limit_list = fact*NLIST/NTHREADS;
            limit_level = fact*NLIST;
            nlist = 0;
            for ( n=1; n<=NLIST; n++ ) {
              nlist++;
              if( n >= limit_level || n >= limit_list ) {
                printf( " %d", nlist );
                nlist = 0;
                if( n >= limit_level ) {
                  fact *= fact0;
                  limit_list = limit_level + fact*NLIST/NTHREADS;
                  limit_level += fact*NLIST;
                }
                else
                  limit_list += fact*NLIST/NTHREADS;
              }
            }
            if( nlist > 0 )
              printf( " %d", nlist );
          }
        }' ) );

      [ "$NUMELEM" = "split" ] &&
      NLIST=( $( awk -v NTHREADS="$NTHREADS" -v NLIST="$NLIST" '
        BEGIN {
          if ( NTHREADS == 1 )
            printf( " %d", NLIST );
          else if( NLIST <= NTHREADS )
            for ( n=1; n<=NLIST; n++ )
              printf( " 1" );
          else {
            fact0 = NLIST/NTHREADS;
            fact = fact0;
            accu = fact0;
            nxt = sprintf("%.0f",accu);
            prev = 0;
            for ( n=1; n<=NLIST; n++ )
              if( n == nxt ) {
                printf( " %d", n-prev );
                prev = n;
                accu += fact0;
                nxt = sprintf( "%.0f", accu );
              }
            if( NLIST > prev )
              printf( " %d", n-prev );
          }
        }' ) );

    elif [[ ! "$NUMELEM" =~ ^[0-9]+$ ]]; then
      echo "$FN: error: unexpected number of elements: $NUMELEM" 1>&2;
      [ "$KEEPTMP" != "yes" ] && rm -r "$TMP";
      return 1;
    fi
  fi

  ### Join thread logs prepending IDs to each line ###
  local PROC_LOGS="/::$FN::/q;"' :loop;
    /^$/ { N; /\n==> .* <==$/! { G; s|^\(.*\)\n\([^\n]*\)$|\2\1|; P; }; D; b loop; };
    /^==> .* <==$/ { s|^==> .*/[oe][ur][tr]_\([^ ]*\) <==$|\1\t|; h; d; };
    G; s|^\(.*\)\n\([^\n]*\)$|\2\1|; p;';

  local THREAD;
  for THREAD in "${THREADS[@]}"; do
    #mkfifo "$TMP/out_$THREAD" "$TMP/err_$THREAD"; # for many threads hangs in >> "$TMP/out_$THREAD"; why?
    > "$TMP/out_$THREAD"; > "$TMP/err_$THREAD";
  done
  mkfifo "$TMP/out" "$TMP/err";
  local SEDPID;
  sed -un "$PROC_LOGS" < "$TMP/out"      & SEDPID[0]="$!";
  tail --pid=${SEDPID[0]} -f "$TMP"/out_* > "$TMP/out" &
  sed -un "$PROC_LOGS" < "$TMP/err" 1>&2 & SEDPID[1]="$!";
  tail --pid=${SEDPID[1]} -f "$TMP"/err_* > "$TMP/err" &
  #for THREAD in "${THREADS[@]}"; do
  #  >> "$TMP/out_$THREAD";
  #  >> "$TMP/err_$THREAD";
  #done

  local ENDFD;
  exec {ENDFD}< <( tail --pid=${SEDPID[0]} -f "$TMP/state" | grep --line-buffered ' ended$' );

  ### Cleanup function ###
  trap cleanup INT;
  cleanup () {
    echo "::$FN::" >> "$TMP/out_${THREADS[0]}";
    echo "::$FN::" >> "$TMP/err_${THREADS[0]}";
    local SLEEP="0.01";
    for n in $(seq 1 10); do
      ( ! ( ps -p "${SEDPID[0]}" || ps -p "${SEDPID[1]}" ) >/dev/null ) && break;
      sleep "$SLEEP";
      SLEEP=$(echo "$SLEEP+$SLEEP" | bc -l);
    done
    ( ps -p "${SEDPID[0]}" || ps -p "${SEDPID[1]}" ) >/dev/null && 
      kill ${SEDPID[@]} 2>/dev/null;
    #[ $(uname) = "Darwin" ] &&
    #  echo "$FN: warning: on OS X output may be incomplete" 1>&2;
    NTHREADS=$(grep -c '^THREAD:.* failed$' "$TMP/state");
    [ "$NTHREADS" != 0 ] && grep '^THREAD:.* failed$' "$TMP/state" 1>&2;
    [ "$LISTFD" != "" ] && exec {LISTFD}>&-;
    exec {ENDFD}>&-;
    [ "$KEEPTMP" != "yes" ] && rm -r "$TMP";
    cleanup () { return 0; };
  }

  ### Function to read elements from the list ###
  readlist () {
    local NUM="$NUMELEM";
    if [ "$NUM" = "balance" ] || [ "$NUM" = "split" ]; then
      [ "$NUMP" -gt "${#NLIST[@]}" ] &&
        echo "listdone" >> "$TMP/state" &&
        return 0;
      NUM="${NLIST[$((NUMP-1))]}";
    fi
    for n in $(seq 1 $NUM); do
      local line;
      IFS= read -r -u$LISTFD line;
      [ "$?" != 0 ] &&
        echo "listdone" >> "$TMP/state" &&
        break;
      LISTP+=( "$line" );
    done
  }

  ### Run threads ###
  runcmd () {
    local LISTP=();
    local THREAD="$1";
    local NUMP="$2";
    local CMD=("${PROTO[@]//\{\%\}/$THREAD}");
    CMD=("${CMD[@]//\{\#\}/$NUMP}");
    if [ "$LIST" != "" ]; then
      readlist;
      [ "${#LISTP[@]}" = 0 ] && return 0;
      if [ "$NUMELEM" = 1 ]; then
        CMD=("${CMD[@]//\{\*\}/$LISTP}"); # {*} whole element
        local MLISTP=$(echo "$LISTP" | sed 's|\.[^./]*$||');
        CMD=("${CMD[@]//\{\.\}/$MLISTP}"); # {.} no extension
        MLISTP=$(echo "$LISTP" | sed 's|.*/||');
        CMD=("${CMD[@]//\{\/\}/$MLISTP}"); # {/} no dir
        MLISTP=$(echo "$LISTP" | sed 's|/[^/]*$||');
        CMD=("${CMD[@]//\{\/\/\}/$MLISTP}"); # {//} only dir
        MLISTP=$(echo "$LISTP" | sed 's|.*/||; s|\.[^.]*$||;');
        CMD=("${CMD[@]//\{\/\.\}/$MLISTP}"); # {/.} basename
      fi
    fi
    echo "THREAD:$THREAD:$NUMP starting" >> "$TMP/state";
    { if [ "$ARGPOS" != 0 ]; then
        "${CMD[@]:0:$ARGPOS}" "${LISTP[@]}" "${CMD[@]:$((ARGPOS+1))}";
      elif [ "$PIPEPOS" != 0 ]; then
        "${CMD[@]:0:$PIPEPOS}" <( printf '%s\n' "${LISTP[@]}" ) "${CMD[@]:$((PIPEPOS+1))}";
      elif [ "$FILEPOS" != 0 ]; then
        printf '%s\n' "${LISTP[@]}" > "$TMP/list_$NUMP";
        "${CMD[@]:0:$FILEPOS}" "$TMP/list_$NUMP" "${CMD[@]:$((FILEPOS+1))}";
      elif [ "$OTHERARG" != 0 ] || [ "$NLIST" = 0 ]; then
        "${CMD[@]}";
      else
        echo "$LISTP" | "${CMD[@]}";
      fi
      local RC="$?";
      [ "$RC" != 0 ] && echo "THREAD:$THREAD:$NUMP $RC failed" >> "$TMP/state";
      echo "THREAD:$THREAD:$NUMP ended" >> "$TMP/state";
    } >> "$TMP/out_$THREAD" 2>> "$TMP/err_$THREAD" &
  }

  ( local NUMP=0;
    for THREAD in "${THREADS[@]}"; do
      #>> "$TMP/out_$THREAD";
      #>> "$TMP/err_$THREAD";
      NUMP=$((NUMP+1));
      runcmd "$THREAD" "$NUMP";
    done
    while true; do
      local NUMR=$(( $(grep -c ' starting$' "$TMP/state") - $(grep -c ' ended$' "$TMP/state") ));
      if [ "$NUMP" = "$TOTP" ] ||
         [ $(grep -c '^listdone$' "$TMP/state") != 0 ]; then
        wait;
        break;
      elif [ "$NUMR" -lt "$NTHREADS" ]; then
        NUMP=$((NUMP+1));
        THREAD=$(
          sed -n '/^THREAD:/{ s|^THREAD:\([^:]*\):[^ ]*|\1|; p; }' "$TMP/state" \
            | awk '
                { if( $NF == "ended" )
                    ended[$1] = "";
                  else if( $NF == "starting" )
                    delete ended[$1];
                } END {
                  for( job in ended ) { print job; break; }
                }' );
        runcmd "$THREAD" "$NUMP";
        continue;
      fi
      local ended;
      IFS= read -r -u$ENDFD ended;
    done
  )

  cleanup;
  return "$NTHREADS";
)}
