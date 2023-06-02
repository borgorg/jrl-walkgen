# Copyright 2012,
#
# Sébastien Barthélémy (Aldebaran Robotics)
#
# This file is part of metapod. metapod is free software: you can redistribute
# it and/or modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# metapod is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Lesser Public License for more
# details. You should have received a copy of the GNU Lesser General Public
# License along with metapod.  If not, see <http://www.gnu.org/licenses/>.
# Copyright 2010, 2012, 2013

# GENERATE_CONFIG_HEADER
#
# Generates a configuration header for DLL API import/export
#
# OUTPUT: path (including filename) of the generated file. Usually the filename
# is config.hh LIBRARY_NAME: the name of the library. It will be normalized.
function(GENERATE_CONFIG_HEADER OUTPUT LIBRARY_NAME)
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" LIBRARY_NAME "${LIBRARY_NAME}")
  string(TOLOWER "${LIBRARY_NAME}" "LIBRARY_NAME_LOWER")
  set(EXPORT_SYMBOL "${LIBRARY_NAME_LOWER}_EXPORTS")
  string(TOUPPER "${LIBRARY_NAME}" "LIBRARY_NAME")
  # create the directory (and its parents)
  get_filename_component(OUTPUT_DIR "${OUTPUT}" PATH)
  file(MAKE_DIRECTORY "${OUTPUT_DIR}")
  # Generate the header. The following variables are used in the template
  # LIBRARY_NAME: CPP symbol prefix, should match the compiled library name,
  # usually in upper case EXPORT_SYMBOL: what symbol controls the switch between
  # symbol import/export, usually libname_EXPORTS, with libname in lower case.
  # PROJECT_VERSION: the project version
  configure_file(${PROJECT_SOURCE_DIR}/cmake/config.hh.cmake ${OUTPUT} @ONLY)
endfunction(GENERATE_CONFIG_HEADER)

function(FIND_GENERATOR GENERATOR_NAME)
  set(WITH_${GENERATOR_NAME} FALSE)
  # maybe the user passed the location
  if(${GENERATOR_NAME}_EXECUTABLE)
    set(WITH_${GENERATOR_NAME} TRUE)
  else()
    # last resort: search for it
    find_package(${GENERATOR_NAME} QUIET)
    set(WITH_${GENERATOR_NAME} ${${GENERATOR_NAME}_FOUND})
  endif()
  set(WITH_${GENERATOR_NAME}
      ${WITH_${GENERATOR_NAME}}
      PARENT_SCOPE)
endfunction()

# ADD_SAMPLEURDFMODEL
#
# Call metapodfromurdf to create one of the sample models
#
# NAME: the name of the model. Either simple_arm or simple_humanoid.
function(ADD_SAMPLEURDFMODEL name)
  if(NOT WITH_METAPODFROMURDF)
    error("Could not find metapodfromurdf")
  endif()
  set(_libname "metapod_${name}")
  set(_data_path "$ENV{ROS_WORKSPACE}/install/share/metapod/data/${name}")
  set(_urdf_file "${_data_path}/${name}.urdf")
  set(_config_file "${_data_path}/${name}.config")
  set(_license_file "${_data_path}/${name}_license_file.txt")
  set(_model_dir "$ENV{ROS_WORKSPACE}/install/include/metapod/models/${name}")
  set(METAPODFROMURDF_EXECUTABLE
      "$ENV{ROS_WORKSPACE}/install/bin/metapodfromurdf")

  include_directories("$ENV{ROS_WORKSPACE}/install")
  include_directories("$ENV{ROS_WORKSPACE}/install/include")
  set(_sources ${_model_dir}/config.hh ${_model_dir}/${name}.hh
               ${_model_dir}/${name}.cc)
  message(
    STATUS ${METAPODFROMURDF_EXECUTABLE}
           " --name "
           ${name}
           " --libname "
           ${_libname}
           " --directory "
           ${_model_dir}
           " --config-file "
           ${_config_file}
           " --license-file "
           ${_license_file}
           " "
           ${_urdf_file})
  add_custom_command(
    PRE_BUILD
    OUTPUT ${_sources}
    COMMAND
      ${METAPODFROMURDF_EXECUTABLE} --name ${name} --libname ${_libname}
      --directory ${_model_dir} --config-file ${_config_file} --license-file
      ${_license_file} ${_urdf_file}
    DEPENDS ${METAPODFROMURDF_EXECUTABLE} ${_urdf_file} ${_config_file}
            ${_license_file}
    MAIN_DEPENDENCY ${_urdf_file})
  add_library(${_libname} SHARED ${_sources})
  set_target_properties(
    ${_libname}
    PROPERTIES
      COMPILE_FLAGS
      "-msse -msse2 -msse3 -march=core2 -mfpmath=sse -fivopts -ftree-loop-im -fipa-pta "
  )
  install(TARGETS ${_libname} DESTINATION ${CMAKE_INSTALL_LIBDIR})

endfunction()
