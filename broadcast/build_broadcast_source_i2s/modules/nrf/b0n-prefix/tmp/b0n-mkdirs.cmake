# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/t/asset-tracker-template/nrf/samples/nrf5340/netboot")
  file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/samples/nrf5340/netboot")
endif()
file(MAKE_DIRECTORY
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/b0n"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/tmp"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/src/b0n-stamp"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/src"
  "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/src/b0n-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/src/b0n-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/t/asset-tracker-template/nrf/applications/nrf5340_audio/build_broadcast_source_i2s/modules/nrf/b0n-prefix/src/b0n-stamp${cfgdir}") # cfgdir has leading slash
endif()
