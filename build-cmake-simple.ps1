#run this script on a fully setup developer powershell
#. .\build-cmake-simple.ps1
cmake -G "NMake Makefiles" -B out-build-cmake-simple-release -S ./src -DCMAKE_PREFIX_PATH="$env:DEP_DIR\libffi-380-vc-x64r" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$env:DEP_DIR\underc"
cmake --build out-build-cmake-simple-release
