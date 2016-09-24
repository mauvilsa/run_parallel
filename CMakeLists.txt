cmake_minimum_required( VERSION 3.0.0 )
project( run_parallel LANGUAGES NONE )

add_custom_target( man1 ALL DEPENDS README.md
  COMMAND mkdir -p man1
  COMMAND ${CMAKE_HOME_DIRECTORY}/run_parallel.inc.sh --pandoc | pandoc -s -t man - -o - | gzip > man1/run_parallel.1.gz )

install( PROGRAMS run_parallel.inc.sh DESTINATION bin )
install( DIRECTORY man1 DESTINATION share/man )

add_custom_target( realclean cd ${CMAKE_HOME_DIRECTORY}
  COMMAND rm -fr CMakeFiles CMakeCache.txt cmake_install.cmake install_manifest.txt Makefile man1 )
