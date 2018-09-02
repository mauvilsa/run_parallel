cmake_minimum_required( VERSION 3.0.0 )
project( run_parallel LANGUAGES NONE )

add_custom_target( man1 ALL DEPENDS run_parallel.inc.sh README.md
  COMMAND sed -n "/^run_parallel - /{ s|^|% |; s| -|(1)|; p; }" ${CMAKE_HOME_DIRECTORY}/README.md > man1.pdoc
  COMMAND sed -n "/@author/{ s|.*@author|%|; p; }" ${CMAKE_HOME_DIRECTORY}/run_parallel.inc.sh >> man1.pdoc
  COMMAND sed -n "/@version/{ s|.* |% |; s|\\\$\$||; p; }" ${CMAKE_HOME_DIRECTORY}/run_parallel.inc.sh >> man1.pdoc
  COMMAND cat README.md >> man1.pdoc
  COMMAND mkdir -p man1
  COMMAND pandoc -s -t man man1.pdoc -o - | gzip > man1/run_parallel.1.gz
  COMMAND rm man1.pdoc
  VERBATIM )

set_property( DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES man1 )

install( PROGRAMS run_parallel.inc.sh DESTINATION bin )
install( DIRECTORY man1 DESTINATION share/man )

add_custom_target( realclean cd ${CMAKE_HOME_DIRECTORY}
  COMMAND rm -fr CMakeFiles CMakeCache.txt cmake_install.cmake install_manifest.txt Makefile man1 )
