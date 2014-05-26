include_directories("${mst_SOURCE_DIR}/include")

add_executable       (mst spanning_tree_clustering.cpp)

install(TARGETS mst
        RUNTIME DESTINATION bin 
        LIBRARY DESTINATION lib 
        ARCHIVE DESTINATION lib)
