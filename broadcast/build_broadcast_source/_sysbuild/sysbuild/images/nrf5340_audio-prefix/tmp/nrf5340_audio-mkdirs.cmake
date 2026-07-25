# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio")
  file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio")
endif()
file(MAKE_DIRECTORY
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/nrf5340_audio"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/tmp"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/src/nrf5340_audio-stamp"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/src"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/src/nrf5340_audio-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/src/nrf5340_audio-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source/_sysbuild/sysbuild/images/nrf5340_audio-prefix/src/nrf5340_audio-stamp${cfgdir}") # cfgdir has leading slash
endif()
