cmake_minimum_required(VERSION 3.16)
project(UnderC_CLI VERSION 1.5.0 LANGUAGES CXX)
include(GNUInstallDirs)
option(UCC_SHARED "Link the CLI to a shared UnderC installation" OFF)
foreach(UNDERC_PREFIX IN LISTS CMAKE_PREFIX_PATH)
    list(APPEND CMAKE_MODULE_PATH
        "${UNDERC_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/Underc"
        "${UNDERC_PREFIX}/lib/cmake/Underc"
        "${UNDERC_PREFIX}/lib64/cmake/Underc")
endforeach()
find_package(Underc REQUIRED MODULE)
add_executable(ucc main.cpp)
set_target_properties(ucc PROPERTIES CXX_STANDARD 98 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS ON)
if(UNIX)
    set_property(TARGET ucc PROPERTY INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")
endif()
target_compile_definitions(ucc PRIVATE $<$<BOOL:${UCC_SHARED}>:UCC_SHARED=1>)
target_link_libraries(ucc PRIVATE Underc::underc)
install(TARGETS ucc RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
