# Copyright (c) 2015, Ruslan Baratov
# All rights reserved.

include(hunter_internal_error)
include(hunter_lock_directory)
include(hunter_make_directory)
include(hunter_status_debug)
include(hunter_status_print)
include(hunter_test_string_not_empty)

function(hunter_calculate_toolchain_sha1 hunter_self hunter_base)
  hunter_test_string_not_empty("${hunter_self}")
  hunter_test_string_not_empty("${hunter_base}")
  hunter_test_string_not_empty("${CMAKE_BINARY_DIR}")
  hunter_test_string_not_empty("${CMAKE_GENERATOR}")

  if(CMAKE_TOOLCHAIN_FILE)
    set(use_toolchain "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  else()
    set(use_toolchain "")
  endif()

  hunter_status_print("Calculate Toolchain-SHA1")

  set(temp_project_dir "${CMAKE_BINARY_DIR}/_3rdParty/hunter/toolchain")
  set(temp_build_dir "${temp_project_dir}/_builds")
  set(create_script "${hunter_self}/scripts/create-toolchain-info.cmake")
  set(local_toolchain_info "${temp_project_dir}/toolchain.info")

  file(REMOVE_RECURSE "${temp_build_dir}")
  file(REMOVE_RECURSE "${local_toolchain_info}")

  if(HUNTER_STATUS_DEBUG)
    set(logging_params "")
  else()
    set(logging_params "OUTPUT_QUIET")
  endif()

  # create all directories
  file(WRITE "${temp_project_dir}/CMakeLists.txt" "###")

  configure_file(
       "${create_script}"
       "${temp_project_dir}/CMakeLists.txt"
       COPYONLY
  )
  execute_process(
      COMMAND
      "${CMAKE_COMMAND}"
      "-DTOOLCHAIN_INFO_FILE=${local_toolchain_info}"
      "${use_toolchain}"
      "-DHUNTER_SELF=${hunter_self}"
      "-G${CMAKE_GENERATOR}"
      "-H${temp_project_dir}"
      "-B${temp_build_dir}"
      RESULT_VARIABLE
      generate_result
      ${logging_params}
  )
  if(NOT generate_result EQUAL "0")
    hunter_internal_error(
        "Generate failed: exit with code ${generate_result}"
    )
  endif()

  file(SHA1 "${local_toolchain_info}" HUNTER_GATE_TOOLCHAIN_SHA1)
  set(HUNTER_GATE_TOOLCHAIN_SHA1 "${HUNTER_GATE_TOOLCHAIN_SHA1}" PARENT_SCOPE)

  hunter_make_directory("${hunter_base}" "${HUNTER_GATE_SHA1}" hunter_id_path)

  hunter_make_directory(
      "${hunter_id_path}"
      "${HUNTER_GATE_CONFIG_SHA1}"
      hunter_config_id_path
  )

  hunter_make_directory(
      "${hunter_config_id_path}"
      "${HUNTER_GATE_TOOLCHAIN_SHA1}"
      hunter_toolchain_id_path
  )

  set(global_toolchain_info "${hunter_toolchain_id_path}/toolchain.info")
  if(EXISTS "${global_toolchain_info}")
    hunter_status_debug("Already exists: ${global_toolchain_info}")
    return()
  endif()

  hunter_lock_directory("${hunter_toolchain_id_path}")
  if(EXISTS "${global_toolchain_info}")
    hunter_status_debug("Already exists: ${global_toolchain_info}")
    return()
  endif()

  configure_file("${local_toolchain_info}" "${global_toolchain_info}" COPYONLY)
  hunter_status_debug("Toolchain info: ${globa_toolchain_info}")
endfunction()
