cmake_minimum_required(VERSION 3.16)
project(UndercEmbedExample VERSION 1.5.0 LANGUAGES CXX)
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

foreach(UNDERC_PREFIX IN LISTS CMAKE_PREFIX_PATH)
    list(APPEND CMAKE_MODULE_PATH
        "${UNDERC_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/Underc"
        "${UNDERC_PREFIX}/lib/cmake/Underc"
        "${UNDERC_PREFIX}/lib64/cmake/Underc")
endforeach()
find_package(Underc REQUIRED MODULE)

add_executable(underc-embed main.cpp)
target_link_libraries(underc-embed PRIVATE Underc::underc)
